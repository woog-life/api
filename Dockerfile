FROM openjdk:19-jdk-bullseye as smithy
WORKDIR /apidocs
RUN wget https://github.com/woog-life/apispec/archive/refs/heads/main.zip && unzip main.zip && mv apispec-main/* .
RUN ./gradlew build

FROM dart:2.16 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN pub get

COPY . .

RUN pub run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o app

FROM scratch

COPY swagger-ui/ /docs
COPY --from=smithy /apidocs/build/smithyprojections/woog-api-spec/source/openapi/Wooglife.openapi.json /docs/openapi.json

COPY --from=builder /runtime/ /
COPY --from=builder /app/app /app/

ARG build
ENV BUILD_SHA=$build
ENV DOCS_PATH="/docs"

EXPOSE 8080
CMD [ "/app/app" ]
