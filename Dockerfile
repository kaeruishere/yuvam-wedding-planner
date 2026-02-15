# Stage 1: Build
FROM ubuntu:latest AS build

# Dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa && rm -rf /var/lib/apt/lists/*

# Flutter SDK (Stable)
WORKDIR /usr/local
RUN git clone https://github.com/flutter/flutter.git -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Config
RUN flutter config --no-analytics && flutter config --enable-web && flutter doctor -v

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# [ÖNEMLİ-1] Firebase Config'i Environment Variable'dan al (Yoksa hata vermez, boş geçer)
ARG FIREBASE_OPTIONS_BASE64
RUN if [ -n "$FIREBASE_OPTIONS_BASE64" ]; then echo "$FIREBASE_OPTIONS_BASE64" | base64 -d > lib/firebase_options.dart; fi

# [ÖNEMLİ-2] --web-renderer html bayrağı ile build al (iOS Çözümü)
RUN flutter build web --release --base-href /

# Stage 2: Serve
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
# Nginx ayar dosyasını kopyala
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
