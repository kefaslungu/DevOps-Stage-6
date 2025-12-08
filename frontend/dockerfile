FROM node:16-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++ git

# Copy package files
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Receive build arguments from docker-compose
ARG VITE_AUTH_API_URL
ARG VITE_TODOS_API_URL
ARG VITE_USERS_API_URL

# Set as environment variables for npm build
ENV VITE_AUTH_API_URL=$VITE_AUTH_API_URL
ENV VITE_TODOS_API_URL=$VITE_TODOS_API_URL
ENV VITE_USERS_API_URL=$VITE_USERS_API_URL

# Debug: Print the values (will show during build)
RUN echo "Building with AUTH_API_URL: $VITE_AUTH_API_URL"

# Build the app
RUN npm run build

# Production stage
FROM node:16-alpine

WORKDIR /app
RUN npm install -g serve
COPY --from=builder /app/dist ./dist

EXPOSE 8080
CMD ["serve", "-s", "dist", "-l", "8080", "--no-clipboard"]
