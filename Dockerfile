FROM google/dart:2.12 AS builder

WORKDIR /app

COPY pubspec.* .
RUN pub get
COPY bin bin/
COPY lib lib/
RUN dart compile exe bin/main.dart -o app

FROM debian:buster-slim
WORKDIR /app
COPY --from=builder /app/app .
EXPOSE 8080
CMD [ "/app/app" ]
