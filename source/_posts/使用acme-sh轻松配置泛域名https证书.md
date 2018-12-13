---
title: 使用acme.sh轻松配置泛域名https证书
date: 2018-12-13 14:04:39
tags: [运维,https]
---

分享下载最新的泛域名https配置方案

**Github**

[https://github.com/Neilpang/acme.sh](https://github.com/Neilpang/acme.sh)

**中文文档**

https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E

_如果连文档都懒得看，那下文可以帮你_

**简易教程**


```
cd ~
curl  https://get.acme.sh | sh
```

如果你的域名在阿里云


```
vi ~/.zshrc

export Ali_Key="LTAIFkSTVWry7ojD"
export Ali_Secret="spFIgh04epVykdeUBM0jP4H20lOdVt"
```

配置域名，获取证书

```
./acme.sh --issue --dns dns_ali -d react.mobi -d *.react.mobi
```

应用证书到nginx

```
mkdir /etc/nginx/ssl

acme.sh  --installcert  -d  react.mobi   \
        --key-file   /etc/nginx/ssl/react.mobi.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer \
        --reloadcmd  "service nginx force-reload"
```
贴出完整nginx配置


```
server {
    listen 80;
    server_name react.mobi www.react.mobi api.react.mobi;

    location / {
        rewrite ^(.*)$ https://$host$1 last;
    }
}

server {
    listen 443 ssl http2;
    server_name www.react.mobi, react.mobi;

    location / {
        proxy_pass http://127.0.0.1:3102;
    }

    ssl on;
    ssl_certificate /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/react.mobi.key;
    # ssl_session_timeout 5m;
    # ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    # ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    # ssl_session_cache shared:SSL:50m;
    # ssl_prefer_server_ciphers on;
}

server {
    listen 443 ssl http2;
    server_name api.react.mobi;

    location / {
        proxy_pass http://127.0.0.1:3101;
    }

    ssl on;
    ssl_certificate /etc/nginx/ssl/fullchain.cer;
    ssl_certificate_key /etc/nginx/ssl/react.mobi.key;
    # ssl_session_timeout 5m;
    # ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    # ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    # ssl_session_cache shared:SSL:50m;
    # ssl_prefer_server_ciphers on;
}
```