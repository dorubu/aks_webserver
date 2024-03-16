from flask import Flask, Response, jsonify
import requests
import time
from datetime import datetime

app = Flask(__name__)


def get_bitcoin_price():
    """
    Fetches the current Bitcoin price from CryptoCompare API.
    """

    url = "https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=USD"
    response = requests.get(url)
    data = response.json()
    return data["USD"]


@app.route("/bitcoin_price")
def bitcoin_price():
    """
    Route to get the current Bitcoin price.
    Refreshes every 5 seconds.
    """

    price = get_bitcoin_price()
    return Response(
        """
<meta http-equiv="refresh" content="5" />
Bitcoin price: {} at time: {}.""".format(
            price, datetime.strftime(datetime.now(), "%H:%M:%S %d-%m-%Y")
        )
    )


def get_historical_bitcoin_prices():
    """
    Fetches historical Bitcoin prices rom CryptoCompare API for the last 10 minutes
    """

    end_time = int(time.time())  # Current timestamp
    start_time = end_time - 600  # 10 minutes ago
    url = f"https://min-api.cryptocompare.com/data/v2/histominute?fsym=BTC&tsym=USD&limit=10&toTs={end_time}"
    response = requests.get(url)
    data = response.json()
    return [item["close"] for item in data["Data"]["Data"]]


@app.route("/bitcoin_average")
def bitcoin_average():
    """
    Route to get the current Bitcoin price and average over the last 10 minutes.
    """

    current_price = get_bitcoin_price()
    historical_prices = get_historical_bitcoin_prices()
    average_price = sum(historical_prices) / len(historical_prices)
    return jsonify(
        {"current_price": current_price, "average_price_last_10_minutes": average_price}
    )


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
