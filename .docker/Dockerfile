# Stage 1: PHP with extensions
FROM php:8.2-fpm as php-stage

# Assuming Drupal files are in the root of your build context,
# Copy application code into the image
COPY . /var/www/html

# Install mysqli and pdo_mysql for MySQL support
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Stage 2: Nginx setup
FROM nginx:latest

# Create necessary directories with appropriate permissions
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/log/nginx \
    /var/www/html \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/www/html \
    && chmod -R 755 /var/cache/nginx /var/log/nginx /var/www/html \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx

# Switch to the nginx user for subsequent commands and runtime
USER nginx

# Copy the Nginx configuration
COPY --chown=nginx:nginx .docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy application code from php-stage into the Nginx image
COPY --chown=nginx:nginx --from=php-stage /var/www/html /var/www/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
