FROM rabbitmq:4.1-alpine

ENV RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf

RUN set -e; \
    apk add --no-cache tini bash openssl; \
    rabbitmq-plugins enable --offline rabbitmq_management

COPY conf/rabbitmq.conf /etc/rabbitmq/rabbitmq.conf
COPY scripts/rabbitmq_server_start.sh /usr/local/bin/init.sh

RUN set -e; \
    chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf && \
    chmod 644 /etc/rabbitmq/rabbitmq.conf && \
    chmod +x /usr/local/bin/init.sh

EXPOSE 5672 15672
VOLUME ["/var/lib/rabbitmq"]
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "-c", "/usr/local/bin/init.sh"]

LABEL maintainer="Daniel Lima <dk@eliger.dev.br>" \
      description="RabbitMQ Container with personalized configuration" \
      version="1.2"