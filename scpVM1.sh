       
        
        
sudo apt-get update >/dev/null 2>&1
sudo apt install -y nginx mariadb-server mariadb-common php-fpm php-mysql expect 
sudo apt install -y php-curl php-gd php-intl php-mbstring php-soap
sudo apt install -y php-xml php-xmlrpc php-zip 

##Puntos montaje 
sudo parted /dev/sdc -s mklabel gpt
##sudo wipefs -a /dev/sdc ##Borrar tabla de particiones antigua para crear volumen fisico ##Debido a no usar vagrant destroy
sudo pvcreate /dev/sdc
sudo vgcreate BDD /dev/sdc
sudo lvcreate -n MariaBDD -l 100%FREE BDD
sudo mkfs.ext4 /dev/BDD/MariaBDD
sudo mount /dev/BDD/MariaBDD /var/lib/mysql ##Espacio entre rutas. Montaje necesita archivo de destino

##Configuracion Wordpress Nginx
cat << EOF | sudo tee /etc/nginx/sites-available/wordpress.conf
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

##MariaDB Secure
mysql_install_db --datadir=/var/lib/mysql --user=mysql
mysql --user=root < /vagrant/software/MariaDB.sql

##Install Word Press y creacion BBDD
wget https://wordpress.org/latest.tar.gz -O /var/www/latest.tar.gz
tar -C /var/www -xvzf /var/www/latest.tar.gz
chown www-data:www-data /var/www/wordpress ##Actualizar permisos para usuario/grupo www-data
rm /var/www/latest.tar.gz
cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
chown nobody:nogroup /var/www/wordpress/wp-config.php
sed -i 's/database_name_here/wordpress/g' /var/www/wordpress/wp-config.php
sed -i 's/username_here/wpuser/g' /var/www/wordpress/wp-config.php
sed -i 's/password_here/keepcodingWP/g' /var/www/wordpress/wp-config.php

##Configure nginx
cp /vagrant/software/nginx.conf /etc/nginx/sites-available/wordpress
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/default
systemctl restart nginx #Reincio necesario para actualizar nginx

##Install filebeat
apt-get install -y filebeat
filebeat modules enable system
filebeat modules enable nginx
rm -f /etc/filebeat/filebeat.yml
cp /vagrant/software/filebeat.yml /etc/filebeat/filebeat.yml
systemctl enable filebeat --now