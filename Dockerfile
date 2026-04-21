FROM twinproduction/gatus:latest AS gatus

FROM nginx:alpine
RUN apk add --no-cache supervisor ca-certificates curl

COPY --from=gatus /app/gatus /app/gatus
RUN mkdir -p /config && rm -f /etc/nginx/conf.d/default.conf

COPY config.yaml     /config/config.yaml
COPY nginx.conf      /etc/nginx/conf.d/default.conf
COPY index.html      /usr/share/nginx/html/index.html
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 8080
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
