# Build Stage: use the official node image to build the static site
FROM node:23 AS builder

# Set environment variables for versions
ARG HUGO_VERSION=0.144.2
ARG GO_VERSION=1.24.0

# Install dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates openssl git curl wget build-essential && \
    rm -rf /var/lib/apt/lists/*

# Determine architecture and install Hugo Extended
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then ARCH=arm64; else ARCH=amd64; fi && \
    wget -O hugo_extended_${HUGO_VERSION}.tar.gz https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.tar.gz && \
    tar xf hugo_extended_${HUGO_VERSION}.tar.gz && \
    mv hugo /usr/bin/hugo && \
    rm hugo_extended_${HUGO_VERSION}.tar.gz && \
    echo "Hugo installed"

# Determine architecture and install Go
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then ARCH=arm64; else ARCH=amd64; fi && \
    wget -O go${GO_VERSION}.linux-${ARCH}.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-${ARCH}.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz && \
    rm go${GO_VERSION}.linux-${ARCH}.tar.gz && \
    echo "Go installed"

# Export Go path
ENV PATH=$PATH:/usr/local/go/bin

# Optionally verify versions (can be removed if not needed)
RUN git --version && \
    hugo version && \
    go version

# Copy package files and install npm dependencies
COPY package*.json ./
RUN npm install

# Copy rest of the project files and build the static site
COPY . .
RUN npm run build

# Production Stage: use a lightweight server to serve static files
FROM nginx:alpine

# Copy the built static site from the builder stage
# Change 'build' below if your build output directory is different
COPY --from=builder /public /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
