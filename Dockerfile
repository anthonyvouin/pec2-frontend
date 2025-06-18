# ---------- STAGE 1: Build Flutter ----------
FROM debian:latest AS build-env

RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils

ARG FLUTTER_SDK=/usr/local/flutter
ARG FLUTTER_VERSION=3.29.3
ARG APP=/app

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK && \
    cd $FLUTTER_SDK && \
    git fetch && \
    git checkout $FLUTTER_VERSION

ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:$PATH"

RUN flutter doctor -v

WORKDIR $APP
COPY . $APP

RUN flutter clean && flutter pub get && flutter build web

# ---------- STAGE 2: Serve via NGINX ----------
FROM nginx:1.25.2-alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY docker/nginx/nginx.conf /etc/nginx/http.d/default.conf.template
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]