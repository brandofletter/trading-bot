from setuptools import setup, find_packages

setup(
    name="quant_lab",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "torch",
        "numpy",
        "pandas",
        "yfinance",
        "fastapi",
        "uvicorn",
        "ray",
        "optuna",
        "textblob",
        "scikit-learn",
        "alpaca-trade-api"
    ],
    entry_points={
        "console_scripts":[
            "quant-research=quant_lab.main.research_pipeline:run",
            "quant-paper=quant_lab.main.paper_trading:run",
            "quant-live=quant_lab.main.live_trading:run"
        ]
    }
)