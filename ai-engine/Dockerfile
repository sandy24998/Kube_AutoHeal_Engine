FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .
COPY decision_engine.py .
COPY kubernetes_client.py .

EXPOSE 5000

CMD ["python", "main.py"]
