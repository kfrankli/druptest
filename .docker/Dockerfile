# Use the official PHP image with FPM
FROM php:8.2-fpm as php-stage

# Install mysqli and pdo_mysql for MySQL support, and other necessary extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Use the official Nginx image
FROM nginx:latest

# Copy the Nginx configuration
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Remove the default Nginx static assets and server definition
RUN rm -rf /usr/share/nginx/html/* \
    && rm /etc/nginx/conf.d/default.conf

# Copy the application code to the Nginx web root directory
COPY . /var/www/html

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Expose port 80 for HTTP and 443 for HTTPS (if you plan to use SSL)
EXPOSE 80 443

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
