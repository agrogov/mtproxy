FROM alpine:3.7

COPY ./patches /mtproxy/patches

RUN apk add --no-cache --virtual .build-deps \
    git make gcc musl-dev linux-headers openssl-dev \
    && git clone --single-branch --depth 1 https://github.com/TelegramMessenger/MTProxy.git /mtproxy/sources \
    && cd /mtproxy/sources \
    && patch -p0 -i /mtproxy/patches/randr_compat.patch \
    && make -j$(getconf _NPROCESSORS_ONLN)

FROM alpine:3.7
LABEL maintainer="Alexey Rogov <@agrogov>" \
      description="Telegram Messenger MTProto zero-configuration proxy server"

RUN apk add --no-cache curl \
  && ln -s /usr/lib/libcrypto.so.42 /usr/lib/libcrypto.so.1.0.0

WORKDIR /mtproxy

COPY --from=0 /mtproxy/sources/objs/bin/mtproto-proxy .
COPY docker-entrypoint.sh /

VOLUME /data
EXPOSE 2398 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ \
  "--port", "2398", \
  "--http-ports", "443", \
  "--slaves", "2", \
  "--max-special-connections", "60000" \
]
