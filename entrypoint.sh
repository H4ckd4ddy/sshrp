#!/bin/sh

if [ ! -f '/etc/ssh/ssh_host_rsa_key' ]; then
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f '/etc/ssh/ssh_host_dsa_key' ]; then
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

# Delete all previous match user forward
sed -i '1,/DONT-TOUCH/!d' /etc/ssh/sshd_config

# Delete all users in sshrp group
for username in `getent passwd | cut -d':' -f1`
do
	if id -nG "$username" | grep -qw "sshrp"; then
		deluser --remove-home $username
	fi
done

if [ ! $(getent group sshrp) ]; then
	addgroup sshrp
fi

for user in $(find /config/users/* -type d)
do
	username=${user##*/}

	config=$(cat "$user/config.json")

	dhost=$(echo $config | jq '.destination_host' | tr -d '"')
	duser=$(echo $config | jq '.destination_user' | tr -d '"')
	dport=$(echo $config | jq '.destination_port' | tr -d '"')
	
	if [ $dhost == 'null' ]; then
		break
	fi
	if [ $duser == 'null' ]; then
		duser='root'
	fi
	if [ $dport == 'null' ]; then
		dport=22
	fi

	if id -u $user >/dev/null 2>&1; then
		echo "The username $username is already used by system"
		break
	fi

	adduser -D $username -G sshrp
	passwd -u $username

	mkdir /home/$username/.ssh
	

	authorized_keys="$user/authorized_keys"
	id_rsa="$user/id_rsa"
	password_file="$user/password"

	if [ -f $authorized_keys ]; then
		cp $authorized_keys /home/$username/.ssh/authorized_keys
	#else
	#	break
	fi

	if [ -f $password_file ]; then
		printf '%s\n' "$username:$(cat $password_file)" | chpasswd -e
	fi

	if [ -f $id_rsa ]; then
		cp $id_rsa /home/$username/.ssh/id_rsa
		cp $id_rsa.pub /home/$username/.ssh/id_rsa.pub
	else
		break
	fi

	chmod 744 /home/$username/.ssh
	chmod 744 /home/$username/.ssh/authorized_keys
	chmod 600 /home/$username/.ssh/id_rsa

	chown -R $username:sshrp /home/$username/.ssh

	echo "" >> /etc/ssh/sshd_config
	echo "Match User $username" >> /etc/ssh/sshd_config
    echo "  ForceCommand ssh -o \"StrictHostKeyChecking=no\" -i /home/$username/.ssh/id_rsa $duser@$dhost -p $dport \$SSH_ORIGINAL_COMMAND" >> /etc/ssh/sshd_config

done

/usr/sbin/sshd -D