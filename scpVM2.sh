##
if ! grep -q "${mountdir}.*ext4" /etc/fstab; then
cat << _EOF_ >> /etc/fstab
# ${lvname} volume
${mapper} ${mountdir} ext4 defaults,auto,nofail 0 0
_EOF_
fi

apt-get update -y >/dev/null 2>&1
apt install -y nginx php-fpm php-mysql expect 
apt install -y php-curl php-gd php-intl php-mbstring php-soap
apt install -y php-xml php-xmlrpc php-zip 

##Puntos montaje 
parted /dev/sdc -s mklabel gpt
wipefs -a /dev/sdc ##Borrar tabla de particiones antigua para crear volumen fisico ##Debido a no usar vagrant destroy
pvcreate /dev/sdc
vgcreate BDD /dev/sdc
lvcreate -n ElasticSearch -l 100%FREE BDD
mkfs.ext4 /dev/BDD/ElasticSearch
mount /dev/BDD/ElasticSearch /var/lib/elasticsearch ##Espacio entre rutas. Montaje necesita archivo de destino (pointer)

##Obtain ElasticSearch https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html
 wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
    apt-get install apt-transport-https
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
    apt-get update -y


##Install JRE
apt-get install -y default-jre

##Install ElasticSearch
apt-get install -y elasticsearch
chown elasticsearch:elasticsearch /var/lib/elasticsearch
systemctl daemon-reload ##Necesario para reiniciar lo que el sistema ha leido de los unit files
systemctl enable elasticsearch --now


##Obtain & install Logstash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get install -y logstash
cp /vagrant/software/02-beats-input.conf /etc/logstash/conf.d/
cp /vagrant/software/10-syslog.filter.conf /etc/logstash/conf.d/
cp /vagrant/software/30.elasticsearch-output.conf /etc/logstash/conf.d/
chmod 644 /etc/logstash/conf.d/*.conf
systemctl enable logstash --now



#Install Kibana & authn Kibana
apt-get install -y kibana 
cp /vagrant/software/kibana.conf /etc/nginx/sites-available/default
touch /etc/nginx/htpasswd.users
if ! grep -q kibanaadmin /etc/nginx/htpasswd.users; then
    echo "kibanaadmin:$(openssl passwd -apr1 -in /vagrant/.kibana)" >> /etc/nginx/htpasswd.users
fi
systemctl restart nginx kibana ##Reinicio necesario para detectar cambios