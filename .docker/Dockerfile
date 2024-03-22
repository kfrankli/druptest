# Stage 1: PHP with extensions
FROM php:8.2-fpm as php-stage

# Install mysqli and pdo_mysql for MySQL support
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Stage 2: Nginx setup
FROM nginx:latest

# Create necessary directories and adjust permissions
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/log/nginx \
    /var/www/html \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/www/html \
    && chmod -R 755 /var/cache/nginx /var/log/nginx /var/www/html

# Copy the Nginx configuration
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Remove default Nginx configuration and assets
RUN rm /etc/nginx/conf.d/default.conf

# Copy the PHP application code to the Nginx web root directory
# Assuming your application code is in the root of your repository
COPY --from=php-stage /var/www/html /var/www/html

# Copy custom PHP-FPM pool configuration if needed
# COPY --from=php-stage /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Expose port 80 for HTTP and 443 for HTTPS (if you plan to use SSL)
EXPOSE 80 443

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
