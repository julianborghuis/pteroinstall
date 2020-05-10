#!/bin/bash
MYSQL_PASSWORD=`head -c 10 /dev/random | base64`
FQDN=`hostname --ip-address`
apt update
yes | sudo apt-get install nano
service apache2 stop
yes | sudo apt-get install apt-transport-https
yes | apt -y install software-properties-common curl
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
apt update
apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip mariadb-server nginx tar unzi$
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.16/panel.tar.gz
tar --strip-components=1 -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
mysql -u root -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -u root -e "CREATE DATABASE panel;"
mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=$MYSQL_PASSWORD
php artisan p:environment:setup -n --author=info@cmfm.nl --url=http://$FQDN --timezone=Europe/Amsterdam --cache=redis --session=database --queue=redis --redis-host=127.0.0.1 --redis-$
sudo systemctl enable --now redis-server
sed -i -e "s/MAIL_DRIVER=smtp/MAIL_DRIVER=log/g" /var/www/pterodactyl/.env
php artisan migrate --seed --force
php artisan p:user:make --email=julian@kpnmail.nl --username=admin --name-first=admin --name-last=admin --password=admin --admin=1
php artisan p:location:make --short=cmfm --long="cmfm."
chown -R www-data:www-data *
curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/pteroq.service
sudo systemctl enable --now pteroq.service
systemctl stop nginx
service nginx stop
service apache2 stop
curl -o /etc/nginx/sites-available/pterodactyl.conf https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/nginxnonssl0.7.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
service apache2 stop
service nginx start
systemctl start nginx
curl -o /etc/nginx/sites-available/pterodactyl.conf https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/nginxnonssl0.7.conf
sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf
sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
service apache2 stop
service nginx start
systemctl start nginx
systemctl restart nginx
echo "First part done"
sleep 5
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
sleep 3
systemctl enable docker
sudo curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt -y install nodejs make gcc g++
sleep 2
mkdir -p /srv/daemon /srv/daemon-data
cd /srv/daemon
curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
sleep 5
npm install --only=production
sleep 3
curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/Fabian-Ser/pterodactylinstallscript/master/wings0.7.service
systemctl enable --now wings
systemctl stop wings
