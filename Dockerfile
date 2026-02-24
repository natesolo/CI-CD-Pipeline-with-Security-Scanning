FROM nginx:1.27-alpine

# Remove default assets and add a minimal placeholder app.
RUN rm -rf /usr/share/nginx/html/* \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup \
    && mkdir -p /tmp/nginx /var/cache/nginx /var/run \
    && chown -R appuser:appgroup /tmp/nginx /var/cache/nginx /var/run /var/log/nginx /etc/nginx/conf.d

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
