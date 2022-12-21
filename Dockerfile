FROM cirrusci/flutter:3.3.10 AS build

RUN flutter doctor -v
RUN flutter config --enable-web

RUN mkdir /app/
WORKDIR /app/
COPY . /app/

RUN flutter pub get # TODO: optimize
RUN flutter build web

FROM nginx:1.23.3-alpine
COPY --from=build /app/build/web /usr/share/nginx/html