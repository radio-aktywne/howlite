ARG RADICALE_IMAGE_TAG=3.1.5.1

FROM tomsquest/docker-radicale:$RADICALE_IMAGE_TAG

# add bash, because it's not available by default on alpine
# and apache2-utils for htpasswd
RUN apk add --no-cache bash apache2-utils

WORKDIR /app

RUN mkdir -p ./data/

COPY ./emitimes/start.sh ./start.sh
RUN chmod +x ./start.sh

COPY ./emitimes/conf/ ./conf/

RUN addgroup --gid 1000 container && chmod -R g+rwxs . && chown -R :container .
USER radicale:container

ENV EMITIMES_PORT=36000 \
    EMITIMES_USER=user \
    EMITIMES_PASSWORD=password \
    EMITIMES_CALENDAR=emitimes

EXPOSE 36000

ENTRYPOINT ["./start.sh"]
CMD []
