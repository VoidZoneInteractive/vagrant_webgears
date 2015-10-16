#!/usr/bin/env bash

# Vagran initialization script by Grz3gorz Gurz3da

# Update stuff
apt-get update

# Apache module install
apt-get install -y apache2

# PHP module install
apt-get install -y php5
apt-get install -y php5-apcu
apt-get install -y php5-xdebug
apt-get install -y php5-mysql
apt-get install -y php5-curl
apt-get install -y mc

# MySQL module install
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

# Configure MySQL (unsafe, but accesible from outside, for development purpose)
sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# Install text browser
sudo apt-get install -y links

# Install editor that can be used on Macbook ;)
sudo apt-get install -y nano

# Configure PHP5 date stuff
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Warsaw/" /etc/php5/cli/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Warsaw/" /etc/php5/apache2/php.ini

# Start MySQL
sudo service mysql restart

# Do some privilege mumbo-jumbo (change apache user to vagrant)
sudo /bin/sed -i 's/APACHE_RUN_USER=www-data/APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
sudo /bin/sed -i 's/APACHE_RUN_GROUP=www-data/APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars

# Install composer
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# If you want to install Symfony via composer, uncomment lines below
# cd /vagrant/html
# composer create-project symfony/framework-standard-edition my_project_name

# Get Symfony installer
sudo curl -LsS http://symfony.com/installer -o /usr/local/bin/symfony
sudo chmod a+x /usr/local/bin/symfony

# Disable iptables
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -F

sudo mkdir /vagrant/html

if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

# Create database for Symfony
sudo echo "CREATE DATABASE webgears" | mysql -uroot -proot

# Allow remote access to mysql root user
sudo echo "UPDATE mysql.user SET Host='%' WHERE Host='localhost' AND User='root';" | mysql -uroot -proot
sudo echo "FLUSH PRIVILEGES;" | mysql -uroot -proot

# Install new Symfony instance
cd /vagrant/html
symfony new webgears

# Configure additional apache modules and stuff and restart service
ln -fs /vagrant/assets/vhost.conf /etc/apache2/sites-available/000-default.conf
sudo a2enmod rewrite
sudo a2enmod headers
sudo service apache2 restart

# Remove localhost limitation from dev (very unsafe, only for Vagrant purpose)
sudo /bin/sed -i "s/header('HTTP\/1.0 403 Forbidden');/\/\/header('HTTP\/1.0 403 Forbidden');/" /vagrant/html/webgears/web/app_dev.php
sudo /bin/sed -i "s/exit('You are not allowed to access this file. Check '.basename(__FILE__).' for more information.');/\/\/exit('You are not allowed to access this file. Check '.basename(__FILE__).' for more information.');/" /vagrant/html/webgears/web/app_dev.php

sudo /bin/sed -i "s/header('HTTP\/1.0 403 Forbidden');/\/\/header('HTTP\/1.0 403 Forbidden');/" /vagrant/html/webgears/web/config.php
sudo /bin/sed -i "s/exit('This script is only accessible from localhost.');/\/\/exit('This script is only accessible from localhost.');/" /vagrant/html/webgears/web/config.php


cd /vagrant/html/webgears
sudo php app/console server:start 0.0.0.0:8000