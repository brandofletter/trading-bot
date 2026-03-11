
from execution.broker_interface import AlpacaAdapter
from execution.crypto_exchange_adapter import CCXTExchangeAdapter
from execution.crypto_paper_adapter import CryptoPaperAdapter


class ConnectionManager:
    def __init__(self):
        self._connections = {
            "alpaca_paper": lambda: AlpacaAdapter(mode="paper"),
            "alpaca_live": lambda: AlpacaAdapter(mode="live"),
            "binance": lambda: CCXTExchangeAdapter("binance"),
            "crypto_paper": lambda: CryptoPaperAdapter(),
        }

    def list_connections(self):
        out = []
        for name, factory in self._connections.items():
            try:
                conn = factory()
                out.append({
                    "name": name,
                    "connected": conn.is_connected(),
                    "type": conn.account_type(),
                })
            except Exception as e:
                out.append({
                    "name": name,
                    "connected": False,
                    "type": "unknown",
                    "error": str(e),
                })
        return out

    def get(self, name: str):
        if name not in self._connections:
            raise ValueError(f"Unknown connection: {name}")
        return self._connections[name]()
