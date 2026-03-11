# quant_lab/backtesting/metrics.py

import math
import numpy as np
import pandas as pd


def sharpe_ratio(returns: pd.Series, periods_per_year: int = 24 * 252) -> float:
    returns = returns.dropna()
    if len(returns) < 2:
        return 0.0

    std = returns.std()
    if std == 0 or math.isnan(std):
        return 0.0

    return float((returns.mean() / std) * np.sqrt(periods_per_year))


def max_drawdown(equity_curve: pd.Series) -> float:
    if equity_curve.empty:
        return 0.0
    running_max = equity_curve.cummax()
    drawdown = (equity_curve - running_max) / running_max
    return float(drawdown.min())