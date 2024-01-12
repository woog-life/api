FROM eclipse-temurin:21-jammy AS smithy
RUN apt-get update -qq && apt-get install -y --no-install-recommends unzip && apt-get clean

WORKDIR /apidocs

# renovate: type=git-digest repo=https://github.com/woog-life/apispec
ENV APISPEC_VERSION=a714d82975952d2da3b64d1e35b1ca2fae362e2f

RUN wget https://github.com/woog-life/apispec/archive/$APISPEC_VERSION.zip -O apispec.zip  \
    && unzip apispec.zip  \
    && mv apispec-$APISPEC_VERSION/* . \
    && rm apispec.zip \
    && rm -r apispec-$APISPEC_VERSION
RUN ./gradlew build

FROM dart:3.2.4 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o app

FROM swaggerapi/swagger-ui:v5.11.0@sha256:b02a61c633b74257d9e5141a4821451bd95f48a834acc23946c84bf81587f214 AS swagger

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
