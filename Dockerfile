FROM alpine

RUN apk add openssh jq

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

RUN mkdir /config;chmod 400 /config && \
	ln -s /config/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key && \
	ln -s /config/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key

RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config

RUN echo '#-----DONT-TOUCH-----#' >> /etc/ssh/sshd_config

CMD ["/entrypoint.sh"]
