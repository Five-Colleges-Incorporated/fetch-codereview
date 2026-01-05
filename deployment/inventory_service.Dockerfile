# syntax=docker/dockerfile:1

FROM registry.hub.docker.com/library/python:3.11.4 AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml poetry.lock /app/
RUN <<UV
#! /usr/bin/env bash
set -euo pipefail
uv venv --no-managed-python
uv pip install poetry==1.6.1
uv pip install --no-deps -r <(
	POETRY_NO_INTERACTION=1 \
	POETRY_WARNINGS_EXPORT=false \
	.venv/bin/poetry export --without-hashes
)
.venv/bin/poetry install --only-root
uv pip install 'fastapi[standard]==0.115.8'
UV

FROM scratch AS app
COPY app /app
COPY migrations /app/migrations
COPY alembic.ini /app/alembic.ini

FROM registry.hub.docker.com/library/python:3.11.4-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY --from=app /app /app

CMD [".venv/bin/fastapi", "run", "main.py"]
