FROM dart:2.13 AS builder

WORKDIR /app

COPY pubspec.* ./
RUN pub get

COPY . .

RUN pub run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o app

FROM scratch

ARG build
ENV BUILD_SHA=$build

#RUN apt-get update && apt-get install sqlite3 libsqlite3-dev -y && apt-get clean
COPY --from=builder /runtime/ /
COPY --from=builder /app/app /app/

EXPOSE 8080
CMD [ "/app/app" ]
