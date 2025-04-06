FROM python:3.9-slim
RUN apt-get update && apt-get install -y \
    aircrack-ng \
    wireshark-common \
    xpdf-utils \
    redis-server \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "run:app"]
