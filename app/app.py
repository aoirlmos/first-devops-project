import os
import socket
import time

from flask import Flask, Response, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)

app = Flask(__name__)

GREETING = os.environ.get("GREETING", "Hello from the DevOps demo app")

REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total HTTP requests handled",
    ["method", "endpoint", "http_status"],
)

REQUEST_LATENCY = Histogram(
    "app_request_duration_seconds",
    "HTTP request latency in seconds",
    ["endpoint"],
)


@app.before_request
def start_timer():
    request.start_time = time.time()


@app.after_request
def record_metrics(response):
    # Skip /metrics itself, otherwise every Prometheus scrape inflates the
    # request count and the graph becomes a measure of how often we scrape.
    if request.path != "/metrics":
        endpoint = request.url_rule.endpoint if request.url_rule else "unknown"
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=endpoint,
            http_status=response.status_code,
        ).inc()
        duration = time.time() - getattr(request, "start_time", time.time())
        REQUEST_LATENCY.labels(endpoint=endpoint).observe(duration)
    return response


@app.route("/")
def index():
    return {
        "message": GREETING,
        "hostname": socket.gethostname(),
        "version": os.environ.get("APP_VERSION", "dev"),
    }


@app.route("/health")
def health():
    return {"status": "ok"}, 200


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    # 5001 rather than Flask's usual 5000: macOS AirPlay Receiver occupies 5000.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5001)))
