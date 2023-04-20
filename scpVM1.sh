sudo su -


pvcreate /dev/sdc
vgcreate vlm_BDD /dev/sdc
lvcreate -n lvlm_BDD -l 100%FREE vlm_BDD
mkfs.ext4 /dev/vlm_BDD/lvlm_BDD
mkdir /var/lib/mysql
mount /dev/vlm_BDD/lvlm_BDD /var/lib/mysql
echo "/dev/mapper/vlm_BDD-lvlm_BDD   /var/lib/mysql  ext4,defaults,0 0" | sudo tee /etc/fstab



apt-get update >/dev/null 2>&1
 apt install -y mariadb-server mariadb-common nginx php-fpm php-mysql expect 
 apt install -y php-curl php-gd php-intl php-mbstring php-soap
 apt install -y php-xml php-xmlrpc php-zip 

##Configuracion Wordpress Nginx

cat << EOF |  tee /etc/nginx/sites-available/wordpress
    server {
        listen 80;
        root /var/www/wordpress;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name localhost;
        location / {
            try_files \$uri \$uri/ =404;
        }
        location ~ \.php\$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        }
        location ~ /\.ht {
            deny all;
        }
    }
EOF

rm  /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
systemctl restart nginx
systemctl restart php7.4-fpm

##MariaDB Secure
mysql_install_db --datadir=/var/lib/mysql --user=mysql
mysql --user=root < /vagrant/software/MariaDB.sql

##Install filebeat
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update
apt install -y filebeat
filebeat modules enable system
filebeat modules enable nginx

#Configurar Filebeat
cp /vagrant/software/filebeat.yml /etc/filebeat/filebeat.yml
systemctl enable filebeat --now
systemctl restart filebeat

##Install Word Press y creacion BBDD
wget https://wordpress.org/latest.tar.gz -O /var/www/latest.tar.gz
tar -C /var/www -xvzf /var/www/latest.tar.gz
chown www-data:www-data /var/www/wordpress ##Actualizar permisos para usuario/grupo www-data
rm /var/www/latest.tar.gz
cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
chown nobody:nogroup /var/www/wordpress/wp-config.php
sed -i 's/database_name_here/wordpress/g' /var/www/wordpress/wp-config.php
sed -i 's/username_here/wordpressuser/g' /var/www/wordpress/wp-config.php
sed -i 's/password_here/keepcodingWP/g' /var/www/wordpress/wp-config.php

