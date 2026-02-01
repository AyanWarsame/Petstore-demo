# ARM64 Compatible Nginx Frontend
FROM nginx:alpine

LABEL maintainer="petstore-demo"
LABEL description="Pet Store Frontend - ARM64 Compatible Nginx"

# Remove default nginx configuration and content
RUN rm -rf /usr/share/nginx/html/* && \
    rm -f /etc/nginx/conf.d/default.conf

# Copy frontend static files and nginx configuration
COPY index.html style.css script.js /usr/share/nginx/html/
COPY assets/ /usr/share/nginx/html/assets/ 2>/dev/null || true
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create nginx cache and temp directories
RUN mkdir -p /var/cache/nginx /var/run/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run/nginx && \
    chmod -R 755 /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

EXPOSE 80

# Run as non-root for security
USER nginx

CMD ["nginx", "-g", "daemon off;"]
