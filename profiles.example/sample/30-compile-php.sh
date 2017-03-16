#!/bin/bash

# Example of a complicated extra job that you can do after everything's set up

# PHP

echo
echo "*********************"
echo "-- Compiling PHP --"
echo "*********************"
echo

# Assume we're executing from migrate-me root for simplicity
SHAREDFILES="`pwd`/profiles/shared-files"

# Dependencies
echo "Installing dependencies"
sudo apt-get --no-install-recommends -y install zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libxml2 libxml2-dev libssl1.0.0 libssl-dev libpng12-0 libpng12-dev libjpeg8 libjpeg8-dev libpcre3 libpcre3-dev libcurl4-openssl-dev readline-common libreadline-dev libmcrypt4 libmcrypt-dev libmemcached11 libmemcached-dev
if [ "$?" -gt 0 ]; then echo "Some dependencies didn't install correctly :("; exit 1; fi

# Switch to or unpack working dir from packages that we've previously cached
cd /usr/local/src/
if [ ! -e php* -a ! -e packages/php* ]; then
  echo "Couldn't find php source directory or package. Looked in /usr/local/src/ and /usr/local/src/packages. Exiting."
  exit 1
fi

if [ ! -e php* ]; then
  sudo tar -xjf packages/php*.tar.bz2
fi

cd php*

sudo `cat ~/Configuration\ Files/configure\ strings/php`
if [ "$?" -gt 0 ]; then echo "Configuration not successful. Please debug manually.";  exit 1; fi

sudo make
if [ "$?" -gt 0 ]; then echo "Make not successful. Please debug manually."; exit 1; fi

sudo make test

sudo make install
if [ "$?" -gt 0 ]; then echo "Installation not successful. Please debug manually."; exit 1; fi

cd /usr/local/programs/php*
PHP_DIR=`pwd`

if [ -e /usr/local/bin/overlay_files ]; then
  sudo bin/php /usr/local/bin/overlay_files install --target=/usr/local
  if [ "$?" -gt 0 ]; then echo "Couldn't link php files into standard path. You'll have to do this manually."; fi
fi

sudo rm "$PHP_DIR/lib/php.ini" "$PHP_DIR/etc/php-fpm.conf"
sudo cp "$SHAREDFILES"/linux/usr/local/conf/php.ini "$PHP_DIR/lib/"
if [ "$?" -gt 0 ]; then echo "Couldn't copy php.ini configuration file. You'll have to do this manually."; fi
sudo cp "$SHAREDFILES"/linux/usr/local/conf/php-fpm.conf "$PHP_DIR/etc/"
if [ "$?" -gt 0 ]; then echo "Couldn't link php-fpm.conf configuration file. You'll have to do this manually."; fi

echo "Made it through. PHP should now work."


