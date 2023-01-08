##
if ! grep -q "${mountdir}.*ext4" /etc/fstab; then
cat << _EOF_ >> /etc/fstab
# ${lvname} volume
${mapper} ${mountdir} ext4 defaults,auto,nofail 0 0
_EOF_
fi      
        
        
 apt-get update >/dev/null 2>&1
 apt install -y mariadb-server mariadb-common nginx php-fpm php-mysql expect 
 apt install -y php-curl php-gd php-intl php-mbstring php-soap
 apt install -y php-xml php-xmlrpc php-zip 

##Puntos montaje 
 parted /dev/sdc -s mklabel gpt
 wipefs -a /dev/sdc ##Borrar tabla de particiones antigua para crear volumen fisico ##Debido a no usar vagrant destroy
 pvcreate /dev/sdc
 vgcreate BDD /dev/sdc
 lvcreate -n MariaBDD -l 100%FREE BDD
 mkfs.ext4 /dev/BDD/MariaBDD
 mount /dev/BDD/MariaBDD /var/lib/mysql ##Espacio entre rutas. Montaje necesita archivo de destino

##Configuracion Wordpress Nginx
cat << EOF |  tee /etc/nginx/sites-available/wordpress.conf
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
cp /vagrant/software/nginx-wp.conf /etc/nginx/sites-available/wordpress
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/default
systemctl restart nginx #Reincio necesario para actualizar nginx

##Install filebeat
##apt-get install apt-transport-https
##wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
##echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.5.3-amd64.deb
sudo dpkg -i filebeat-8.5.3-amd64.deb
##apt-get install -y filebeat
systemctl restart filebeat
filebeat modules enable system
filebeat modules enable nginx
rm -f /etc/filebeat/filebeat.yml
cp /vagrant/software/filebeat.yml /etc/filebeat/filebeat.yml
##systemctl enable filebeat --now