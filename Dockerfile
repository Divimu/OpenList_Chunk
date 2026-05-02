# OpenList_Chunk Dockerfile
# Build: docker build -t username/openlist-chunk .
# Usage: docker run -d -p 5244:5244 -v /path/to/data:/opt/openlist/data username/openlist-chunk

# ---- Build stage ----
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git bash curl jq

WORKDIR /build

# Download frontend assets first (for better caching)
RUN FRONTEND_REPO="OpenListTeam/OpenList-Frontend" && \
    RELEASE_JSON=$(curl -fsSL --max-time 10 \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${FRONTEND_REPO}/releases/tags/rolling" 2>/dev/null) && \
    if [ -z "$RELEASE_JSON" ] || echo "$RELEASE_JSON" | grep -q "Not Found"; then \
      RELEASE_JSON=$(curl -fsSL --max-time 10 \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${FRONTEND_REPO}/releases/latest"); \
    fi && \
    TAR_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[].browser_download_url // empty' | \
      grep "openlist-frontend-dist" | grep -v "lite" | grep "\.tar\.gz$" | head -1) && \
    if [ -n "$TAR_URL" ]; then \
      curl -fsSL "$TAR_URL" -o dist.tar.gz && \
      mkdir -p /build/public/dist && \
      tar -xzf dist.tar.gz -C /build/public/dist && \
      rm -f dist.tar.gz; \
    fi

# Copy and build
COPY go.mod go.sum ./
RUN go mod download

COPY ./ ./

RUN go mod tidy && CGO_ENABLED=0 go build \
    -ldflags="-w -s" \
    -tags=jsoniter \
    -o /build/openlist .

# ---- Runtime stage ----
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -g 1001 openlist && \
    adduser -D -u 1001 -G openlist openlist && \
    mkdir -p /opt/openlist/data

WORKDIR /opt/openlist/

COPY --from=builder --chmod=755 --chown=1001:1001 /build/openlist ./
COPY --from=builder --chmod=755 --chown=1001:1001 /build/public ./public/
COPY --chmod=755 entrypoint.sh /entrypoint.sh

USER openlist

VOLUME /opt/openlist/data/
EXPOSE 5244

ENV UMASK=022
CMD ["/entrypoint.sh"]
