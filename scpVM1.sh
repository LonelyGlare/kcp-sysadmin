       
        
        
sudo apt update >/dev/null 2>&1
sudo apt install -y nginx mariadb-server mariadb-common php-fpm php-mysql expect 
sudo apt install -y php-curl php-gd php-intl php-mbstring php-soap
sudo apt install -y php-xml php-xmlrpc php-zip 
sudo parted /dev/sdc -s mklabel gpt
sudo wipefs -a /dev/sdc ##Borrar tabla de particiones antigua para crear volumen fisico
sudo pvcreate /dev/sdc
sudo vgcreate BDD /dev/sdc
sudo lvcreate -n MariaBDD -l 100%FREE BDD
sudo mkfs.ext4 /dev/BDD/MariaBDD
sudo mount /dev/BDD/MariaBDD /var/lib/mysql ##Espacio entre rutas. Montaje necesita archivo de destino
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
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-enabled/wordpress.conf   
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password derp" # new password for the MySQL root user
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password derp" # repeat password for the MySQL root user