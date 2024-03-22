# Stage 1: PHP with extensions
FROM php:8.2-fpm as php-stage

# Install mysqli and pdo_mysql for MySQL support
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Stage 2: Nginx setup
FROM nginx:latest

# Create Nginx cache and temp directories and adjust permissions
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
             /var/log/nginx \
             /var/www/html \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/www/html \
    && chmod -R 755 /var/cache/nginx /var/log/nginx /var/www/html

# Switch to user nginx for subsequent commands
USER nginx

# Copy the Nginx configuration (Ensure the path matches your project structure)
COPY --chown=nginx:nginx .docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Note: The default.conf might not be necessary if you're providing a full nginx.conf
# Remove default Nginx configuration and assets (If required, uncomment the next line)
# RUN rm /etc/nginx/conf.d/default.conf

# Copy the application code (Ensure the path matches your project structure and correct permissions)
COPY --chown=nginx:nginx --from=php-stage /var/www/html /var/www/html

# Expose port 80 for HTTP and 443 for HTTPS (if you plan to use SSL)
EXPOSE 80 443

# Since we're now running as a non-root user, we cannot bind to privileged ports (< 1024).
# If your service needs to bind to a privileged port, you'll need to handle this at the OpenShift level with an SCC.

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
