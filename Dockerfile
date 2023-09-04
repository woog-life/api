FROM openjdk:19-jdk-bullseye AS smithy
WORKDIR /apidocs
RUN wget https://github.com/woog-life/apispec/archive/refs/heads/main.zip && unzip main.zip && mv apispec-main/* .
RUN ./gradlew build

FROM dart:3.1.0 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o app

FROM swaggerapi/swagger-ui:v5.5.0@sha256:7407ee6d46d8902316b683acaa48e46f660f4febdff26c3fa6566208c27477ee AS swagger

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

ARG build
ENV BUILD_SHA=$build
ENV DOCS_PATH="/docs"

EXPOSE 8080
CMD [ "/app/app" ]
