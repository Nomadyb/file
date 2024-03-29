# Base image
FROM python:3.8-slim-buster as base


FROM base as builder

ARG OPENCVE_REPOSITORY
ARG OPENCVE_VERSION
ARG HTTP_PROXY
ARG HTTPS_PROXY


RUN if [ -z "$OPENCVE_REPOSITORY" ]; then \
      echo "OPENCVE_REPOSITORY ARG is not set"; \
      exit 1; \
    fi

RUN if [ -z "$OPENCVE_VERSION" ]; then \
      echo "OPENCVE_VERSION ARG is not set"; \
      exit 1; \
    fi



ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opencve


RUN git clone --depth 1 -b ${OPENCVE_VERSION} "${OPENCVE_REPOSITORY}" . || \
    git clone --depth 1 -b ${OPENCVE_VERSION} "${OPENCVE_REPOSITORY}" .

WORKDIR /app

RUN python3 -m venv /app/venv

ENV PATH="/app/venv/bin:$PATH"

RUN python3 -m pip install --upgrade pip

RUN python3 -m pip install /opencve/


COPY run.sh .

# Final stage
FROM base

ARG OPENCVE_REPOSITORY
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG OPENCVE_VERSION

ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

LABEL name="opencve"
LABEL maintainer="dev@opencve.io"
LABEL url="${OPENCVE_REPOSITORY}"

RUN apt-get update && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opencve /opencve
COPY --from=builder /app /app

WORKDIR /app

ENV PATH="/app/venv/bin:$PATH"

ENV OPENCVE_HOME="/app"

ENTRYPOINT ["./run.sh"]
