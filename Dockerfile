# Stage 1: Build the Flutter Web App
FROM ubuntu:latest AS build

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter specific version
WORKDIR /usr/local
RUN git clone https://github.com/flutter/flutter.git -b 3.24.3

# Add flutter to path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to download artifacts (only web needed)
RUN flutter config --no-analytics && \
    flutter config --enable-web && \
    flutter doctor -v

WORKDIR /app

# Copy pubspec files first to cache dependencies
COPY pubspec.* ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Decode secret file from env variable
ARG FIREBASE_OPTIONS_BASE64
RUN echo "$FIREBASE_OPTIONS_BASE64" | base64 -d > lib/firebase_options.dart

# Build the web application
RUN flutter build web --release --web-renderer html --base-href /

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output to Nginx's html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration to handle SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]