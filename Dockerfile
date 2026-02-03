# Stage 1: Build cowsay binary
FROM golang:alpine AS builder
RUN go install github.com/Code-Hex/Neo-cowsay/cmd/v2/cowsay@latest

# Stage 2: Final image
FROM alpine:latest

# Install prerequisites
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
    bash \
    fortune \
    netcat-openbsd

# Copy binary from builder
COPY --from=builder /go/bin/cowsay /usr/local/bin/cowsay

ENV PATH="/usr/games:${PATH}"

WORKDIR /app

COPY wisecow.sh .

RUN chmod +x wisecow.sh

EXPOSE 4499

CMD ["./wisecow.sh"]