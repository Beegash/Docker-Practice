FROM debian:bookworm


RUN apt-get update && apt-get install -y nginx openssl ca-certificates && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html \
 && echo "<h1>Nginx is working!</h1>" > /var/www/html/index.html

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY conf/ssl /etc/nginx/ssl

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
