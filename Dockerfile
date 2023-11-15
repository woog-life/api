FROM eclipse-temurin:21-jammy AS smithy
RUN apt-get update -qq && apt-get install -y --no-install-recommends unzip && apt-get clean

WORKDIR /apidocs

# renovate: type=git-digest repo=https://github.com/woog-life/apispec
ENV APISPEC_VERSION=edc8a14d7e13f1fc210ff0b221e625dfa65fc0ff

RUN wget https://github.com/woog-life/apispec/archive/$APISPEC_VERSION.zip -O apispec.zip  \
    && unzip apispec.zip  \
    && mv apispec-$APISPEC_VERSION/* . \
    && rm apispec.zip \
    && rm -r apispec-$APISPEC_VERSION
RUN ./gradlew build

FROM dart:3.1.5 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o app

FROM swaggerapi/swagger-ui:v5.10.0@sha256:154c7f39e4b7bf0c2db046ee426cfa568a2165dff8c4a64403cbcea1c934188b AS swagger

# We don't want the script to actually start nginx
RUN head -n -1 /docker-entrypoint.sh > /tmp.sh && mv /tmp.sh /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Replaces path to OpenAPI.json in /usr/share/nginx/html/swagger-initializer.js
RUN SWAGGER_JSON_URL="/docs/openapi.json" /docker-entrypoint.sh nginx

FROM scratch

COPY --from=swagger /usr/share/nginx/html/ /docs
COPY --from=smithy /apidocs/build/smithyprojections/woog-api-spec/source/openapi/Wooglife.openapi.json /docs/openapi.json

COPY --from=builder /runtime/ /
COPY --from=builder /app/app /app/

ARG APP_VERSION
ENV BUILD_SHA=$APP_VERSION
ENV DOCS_PATH="/docs"

EXPOSE 8080
CMD [ "/app/app" ]
