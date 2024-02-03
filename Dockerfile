# Development Stage
FROM python:3.9 AS development

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt
    FROM jenkins/jenkins:latest

USER root

# Install kubectl
RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

USER jenkins


COPY . .

# Run tests
RUN pytest -v

# Production Stage
FROM python:3.9

WORKDIR /app

COPY --from=development /app .

RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


EXPOSE 8000

ENV PORT=8000

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "-w", "4", "app:app"]
