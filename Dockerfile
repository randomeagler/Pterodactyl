FROM debian:13
WORKDIR /
# Install necessary packages
RUN apt update
RUN apt install -y curl ca-certificates gnupg2 sudo lsb-release

# Add additional repositories for PHP
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
RUN curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
RUN curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash

# Install Dependencies
RUN apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN mkdir -p /var/www/pterodactyl
WORKDIR /var/www/pterodactyl
RUN curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
RUN tar -xzvf panel.tar.gz
RUN chmod -R 755 storage/* bootstrap/cache/

RUN mariadb -u root -p
COPY db.sh /db.sh
RUN chmod +x /db.sh
RUN /db.sh
COPY env.sh /env.sh
RUN chmod +x /env.sh
RUN /env.sh
RUN php artisan p:environment:setup
RUN php artisan p:environment:database
# Important!
RUN php artisan migrate --seed --force
RUN php artisan p:user:make
RUN chown -R www-data:www-data /var/www/pterodactyl/*
