#!/bin/bash
DOMAIN=$1
PORT=$2
MAIL_RECIPIENT=$3

prerequisites() {
	wget https://raw.githubusercontent.com/amostech/awf-public-ssl/master/should_renew.py
	chmod u+x should_renew.py
	apt-get install -y python-pip
	pip install pyopenssl
	pip install pyOpenSSL --upgrade
}

prerequisites
(./should_renew.py $DOMAIN $PORT)
renew=$?
rm -rf should_renew.py

if [ "$renew" -eq "1" ]
then
	/opt/awf-ssl-proxmox/auto-renew.sh

	NOW=$(date +"%d%m%Y%H%M%S")

	rm -rf sslrenew.log
	expiry_date=$(echo | openssl s_client -showcerts -servername $DOMAIN -connect $DOMAIN:$PORT 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2)

	echo "To: $MAIL_RECIPIENT
		Content-Type: text/html; charset=UTF-8
	    From: $MAIL_RECIPIENT
	    Subject: [SSL] - Renewing certificates for $DOMAIN @ $hostname " `date` >> sslrenew.log

	echo '<html><body>' >> sslrenew.log
	echo "<div style='background: #ff6600; color: #fff; padding: 25px;'>" >> sslrenew.log
	echo '<strong>' $hostname ' certificate auto-renew job was kicked off: ' $NOW '</strong>' >> sslrenew.log
	echo "</div>" >> sslrenew.log
	echo "<br />" >> sslrenew.log
	echo "For reference, check $DOMAIN to see if the certificate is valid." >> sslrenew.log
	echo `New Expiry date in CERTIFICATE: $expiry_date` >> sslrenew.log
	echo "</body></html>" >> sslrenew.log

	cat sslrenew.log | mail -s "[SSL] - Renewing certificates for $DOMAIN @ $hostname `date`" $MAIL_RECIPIENT
else
	echo "All good for now... Nothing to do. Won't renew!"
	exit 0
fi
