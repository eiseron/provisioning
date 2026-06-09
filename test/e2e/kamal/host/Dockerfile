FROM docker:27-dind
RUN apk add --no-cache openssh-server openssh-client-default bash
RUN ssh-keygen -A \
 && adduser -D -s /bin/bash deploy \
 && sed -i 's/^deploy:!/deploy:*/' /etc/shadow \
 && mkdir -p /home/deploy/.ssh && chmod 700 /home/deploy/.ssh
COPY deploy_key.pub /home/deploy/.ssh/authorized_keys
RUN chmod 600 /home/deploy/.ssh/authorized_keys && chown -R deploy:deploy /home/deploy/.ssh
COPY entrypoint.sh /usr/local/bin/e2e-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/e2e-entrypoint.sh"]
CMD []
