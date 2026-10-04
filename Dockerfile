# Test stage: carries pytest and the test suite, and never ships. The Jenkins
# pipeline builds it with `--target test` and runs it. Nothing below depends
# on it, so a plain `docker build .` skips it entirely.
FROM python:3.12-slim AS test

WORKDIR /app
COPY app/requirements.txt app/requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY app/ .
CMD ["pytest", "-v", "test_app.py"]

# Runtime stage: the image that actually ships.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5001

WORKDIR /app

# Requirements copied and installed before app code, so this layer stays
# cached on rebuilds that only change app.py.
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 5001

# curl is not in the slim base image, so probe with Python's stdlib.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/health')" || exit 1

CMD ["python", "app.py"]
