FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
COPY version.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD [ "python", "app.py" ]