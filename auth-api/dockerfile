# Multi-stage build for Go service
FROM golang:1.23 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-api .

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/auth-api .
EXPOSE 8081
CMD ["./auth-api"]
