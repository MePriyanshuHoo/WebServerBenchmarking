# Multi-stage Dockerfile for JS vs Go Benchmark Suite
FROM ubuntu:22.04 as base

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    jq \
    lsof \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install wrk from source (more reliable than package manager)
RUN git clone https://github.com/wg/wrk.git /tmp/wrk \
    && cd /tmp/wrk \
    && make \
    && mv wrk /usr/local/bin/ \
    && rm -rf /tmp/wrk

# Install Go
ARG GO_VERSION=1.21.5
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Set up environment
ENV PATH="/usr/local/go/bin:/root/.bun/bin:${PATH}"
ENV GOPATH="/go"
ENV GOCACHE="/tmp/go-cache"

# Create app directory
WORKDIR /app

# Copy project files
COPY . .

# Install Go dependencies
RUN cd servers/go-vanilla && go mod tidy && go mod download
RUN cd servers/go-fiber && go mod tidy && go mod download
RUN cd scripts && go mod tidy && go mod download

# Install Bun dependencies
RUN cd servers/hono-bun && bun install

# Make scripts executable
RUN chmod +x scripts/benchmark.sh quick-start.sh

# Create results directory
RUN mkdir -p results

# Verify installations
RUN go version
RUN bun --version
RUN wrk --version 2>&1 | head -1
RUN jq --version

# Health check to ensure all servers can start
RUN echo "Running health checks..." \
    && timeout 10s bash -c 'cd servers/go-vanilla && go run . &' || true \
    && sleep 2 \
    && pkill -f "go run" || true \
    && echo "Health check completed"

# Set default environment variables for benchmarking
ENV DURATION=30
ENV CONNECTIONS=100
ENV THREADS=4
ENV CI=true

# Expose port for servers (though we use localhost in benchmarks)
EXPOSE 8080

# Default command
CMD ["./scripts/benchmark.sh"]

# Labels for better organization
LABEL maintainer="Benchmark Suite"
LABEL description="JS vs Go Web Framework Benchmark Container"
LABEL version="1.0.0"

# Alternative entrypoints for different use cases
# docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark
# docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark ./scripts/benchmark.sh --duration 60
# docker run --rm -it jsvsgo-benchmark bash  # For interactive use

# Build instructions:
# docker build -t jsvsgo-benchmark .
# docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark

# For custom benchmark parameters:
# docker run --rm -v $(pwd)/results:/app/results jsvsgo-benchmark ./scripts/benchmark.sh --duration 60 --connections 200 --threads 8

# For development/debugging:
# docker run --rm -it -v $(pwd):/app jsvsgo-benchmark bash
