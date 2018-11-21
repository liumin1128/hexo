---
title: 轻松驾驭https
date: 2018-01-05 00:20:21
tags: [https,运维,nginx]
categories: 后端
---

# 创建 Let's Encrypt 账号


```
openssl genrsa 4096 > account.key
```

#创建普通域名私钥

```
openssl genrsa 4096 > domain.key
```

#单个域名


```
openssl req -new -sha256 -key domain.key -subj "/CN=foofish.net" > domain.csr
```

#多个域名


```
openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/pki/tls/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:liumin.me,DNS:www.liumin.me,DNS:react.mobi,DNS:www.react.mobi,DNS:api.react.mobi")) > domain.csr
```
#如果出错，你可能需要查找openssl.conf


```
find / | grep ".*openssl.*"
```

# 配置nginx，以后还会用到

```
server {
    listen 80;
    server_name www.liumin.me liumin.me api.react.mobi www.react.mobi react.mobi;
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/challenges/;
        try_files $uri =404;
    }
}
```

#生成证书


```
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat signed.crt intermediate.pem > chained.pem
```

#编写脚本以自动运行

```
#!/usr/bin/sh
python /var/www/challenges/acme_tiny.py --account-key /var/www/challenges/account.key --csr /var/www/challenges/domain.csr --acme-dir /var/www/challenges/ > /tmp/signed.crt || exit
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat /tmp/signed.crt intermediate.pem > /var/www/challenges/chained.pem
service nginx reload
```

#验证任务是否正常

```
sh ./renew_cert.sh
```

#添加定时任务


```
crontab -e
0 0 1 * * /var/www/challenges/renew_cert.sh 2>> /var/www/challenges/acme_tiny.log
crontab -l
```

#完整nginx配置，http自动转https


```
server {
    listen 80;
    server_name liumin.me www.liumin.me api.react.mobi www.react.mobi react.mobi;
    location ^~ /.well-known/acme-challenge/ {
        alias /var/www/challenges/;
        try_files $uri =404;
    }
    location / {
        rewrite ^(.*)$ https://$host$1 last;
    }
}

server {
    listen 443;
    server_name www.react.mobi, react.mobi;
    location / {
        proxy_pass http://127.0.0.1:3102;
    }

    ssl on;
    ssl_certificate /var/www/challenges/chained.pem;
    ssl_certificate_key /var/www/challenges/domain.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    ssl_session_cache shared:SSL:50m;
    # ssl_dhparam /var/www/challenges/server.dhparam;
    ssl_prefer_server_ciphers on;
}

server {
    listen 443;
    server_name api.react.mobi;
    location / {
        proxy_pass http://127.0.0.1:3101;
    }

    ssl on;
    ssl_certificate /var/www/challenges/chained.pem;
    ssl_certificate_key /var/www/challenges/domain.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    ssl_session_cache shared:SSL:50m;
    # ssl_dhparam /var/www/challenges/server.dhparam;
    ssl_prefer_server_ciphers on;
}
```

