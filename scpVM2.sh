sudo su -

pvcreate /dev/sdc
vgcreate vlm_elk /dev/sdc
lvcreate -n lvlm_elk -l 100%FREE vlm_elk
mkfs.ext4 /dev/vlm_elk/lvlm_elk
mkdir /var/lib/elasticsearch
mount /dev/vlm_elk/lvlm_elk /var/lib/elasticsearch
echo "/dev/mapper/vlm_elk-lvlm_elk    /var/lib/elasticsearch  ext4,defaults,0 0" | sudo tee /etc/fstab


apt-get update -y >/dev/null 2>&1
apt install -y nginx php-fpm php-mysql expect 
apt install -y php-curl php-gd php-intl php-mbstring php-soap
apt install -y php-xml php-xmlrpc php-zip 

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
apt-get install -y logstash
cp /vagrant/software/elk/02-beats-input.conf /etc/logstash/conf.d/
cp /vagrant/software/elk/30-elasticsearch-output.conf /etc/logstash/conf.d/
cp /vagrant/software/elk/10-syslog-filter.conf /etc/logstash/conf.d/
chmod 644 /etc/logstash/conf.d/*.conf
systemctl start logstash
systemctl enable logstash


#Install Kibana & authn Kibana
apt-get install -y kibana 
cp /vagrant/software/elk/kibana.conf /etc/nginx/sites-available/default
touch /etc/nginx/htpasswd.users
if ! grep -q kibanaadmin /etc/nginx/htpasswd.users; then
    echo "kibanaadmin:$(openssl passwd -apr1 -in /vagrant/.kibana)" >> /etc/nginx/htpasswd.users
fi
systemctl restart nginx kibana ##Reinicio necesario para detectar cambios
systemctl enable elasticsearch --now