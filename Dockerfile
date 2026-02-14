# Stage 1: Build the Flutter Web App
FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build
# ... (intermediate lines) ...
RUN flutter build web --release --web-renderer html --base-href /

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output to Nginx's html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration to handle SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]