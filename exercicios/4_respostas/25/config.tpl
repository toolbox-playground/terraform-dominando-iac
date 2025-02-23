# config.tpl
server {
  listen 80;
  server_name ${server_name};
  root /var/www/${server_name};
}
