server {
    listen ${LISTEN_PORT};

    location /static/static {
        alias /vol/web/static;
    }

    location /static/media {
        alias /vol/web/media;
    }

    location / {
        include                 gunicorn_headers;
        proxy_redirect          off;
        proxy_pass              http://${APP_HOST}:${APP_PORT};
        client_max_body_size    10M;
    }
}
