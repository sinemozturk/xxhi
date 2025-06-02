FROM nginx:alpine

# Install any additional dependencies if needed
RUN apk add --no-cache curl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static files
COPY index.html /usr/share/nginx/html/index.html

# Create necessary directories and set permissions
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/run && \
    chmod -R 755 /var/log/nginx /var/cache/nginx /var/run

# Expose port 80
EXPOSE 80

# Health check - updated to use /health endpoint
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/health || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

