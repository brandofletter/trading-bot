# backtesting/backtester.py

from dataclasses import dataclass
import pandas as pd

from backtesting.metrics import sharpe_ratio, max_drawdown
from features.indicators import add_indicators
from strategies.rule_strategy import generate_signal


@dataclass
class BacktestResult:
    symbol: str
    strategy_name: str
    total_return: float
    sharpe: float
    max_drawdown: float
    trades: int
    final_equity: float
    strategy_params: dict


class Backtester:
    def __init__(self, capital: float):
        self.initial_capital = capital

    def run(self, symbol: str, df: pd.DataFrame, strategy_params: dict) -> BacktestResult:
        data = add_indicators(
            df,
            short_window=strategy_params["sma_short"],
            long_window=strategy_params["sma_long"],
        ).copy()

        cash = self.initial_capital
        units = 0.0
        entry_price = None
        trades = 0
        equity_history = []

        for _, row in data.iterrows():
            price = float(row["Close"])
            signal = generate_signal(row, strategy_params)

            if signal == 1 and units == 0:
                units = cash / price
                cash = 0.0
                entry_price = price
                trades += 1

            elif units > 0:
                pnl_pct = (price - entry_price) / entry_price if entry_price else 0.0

                stop_loss_hit = pnl_pct <= -strategy_params["stop_loss"]
                take_profit_hit = pnl_pct >= strategy_params["take_profit"]

                if signal == -1 or stop_loss_hit or take_profit_hit:
                    cash = units * price
                    units = 0.0
                    entry_price = None
                    trades += 1

            equity = cash if units == 0 else units * price
            equity_history.append(equity)

        if units > 0:
            final_price = float(data.iloc[-1]["Close"])
            cash = units * final_price
            units = 0.0

        equity_curve = pd.Series(equity_history, index=data.index[: len(equity_history)])
        returns = equity_curve.pct_change().fillna(0.0)

        final_equity = float(cash)
        total_return = (final_equity / self.initial_capital) - 1.0

        return BacktestResult(
            symbol=symbol,
            strategy_name=strategy_params["name"],
            total_return=float(total_return),
            sharpe=sharpe_ratio(returns),
            max_drawdown=max_drawdown(equity_curve),
            trades=trades,
            final_equity=final_equity,
            strategy_params=strategy_params,
        )