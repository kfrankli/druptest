# Stage 1: PHP with extensions
FROM php:8.2-fpm as php-stage

# Install system dependencies required for Composer and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Assuming Drupal files are in the root of your build context,
# Copy application code into the image
COPY . /var/www/html

# Set the WORKDIR to /var/www/html so composer install runs in the correct directory
WORKDIR /var/www/html

# Run composer install to install PHP dependencies
# --no-scripts --no-dev to skip any scripts and dev dependencies for production
RUN composer install --no-scripts --no-dev --optimize-autoloader --ignore-platform-req=ext-gd

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

# Copy the Nginx configuration and application code
COPY --chown=nginx:nginx .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx --from=php-stage /var/www/html /var/www/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
