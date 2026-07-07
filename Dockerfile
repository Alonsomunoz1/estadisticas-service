# syntax=docker/dockerfile:1
# ============================================================
# estadisticas-service  -  imagen de producción (multi-stage, usuario no root)
# ============================================================

# ---- Stage 1: builder (instala dependencias en un venv) ----
FROM python:3.12-slim AS builder
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ---- Stage 2: runtime (copia solo el venv y el código) ----
FROM python:3.12-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Usuario sin privilegios (no root) por seguridad
RUN groupadd --system app && useradd --system --gid app --no-create-home appuser
WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY . .

USER appuser
EXPOSE 8006

# Arranque con uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8006"]
