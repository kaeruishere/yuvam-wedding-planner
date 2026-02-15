FROM ubuntu:latest AS build

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local
RUN git clone https://github.com/flutter/flutter.git -b stable

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --no-analytics && \
    flutter config --enable-web && \
    flutter doctor -v

WORKDIR /app

COPY . .

RUN flutter pub get

ARG FIREBASE_OPTIONS_BASE64
RUN echo "$FIREBASE_OPTIONS_BASE64" | base64 -d > lib/firebase_options.dart

RUN flutter build web --release --renderer html --base-href /

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
