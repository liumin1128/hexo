---
title: 国内镜像安装mongodb
date: 2018-11-21 00:20:21
tags: [mongodb,运维]
categories: 后端
---

国内镜像安装mongodb

```
wget https://mirrors.aliyun.com/mongodb/yum/redhat/7Server/mongodb-org/4.0/x86_64/RPMS/mongodb-org-4.0.3-1.el7.x86_64.rpm
wget https://mirrors.aliyun.com/mongodb/yum/redhat/7Server/mongodb-org/4.0/x86_64/RPMS/mongodb-org-mongos-4.0.3-1.el7.x86_64.rpm
wget https://mirrors.aliyun.com/mongodb/yum/redhat/7Server/mongodb-org/4.0/x86_64/RPMS/mongodb-org-server-4.0.3-1.el7.x86_64.rpm
wget https://mirrors.aliyun.com/mongodb/yum/redhat/7Server/mongodb-org/4.0/x86_64/RPMS/mongodb-org-shell-4.0.3-1.el7.x86_64.rpm           
wget https://mirrors.aliyun.com/mongodb/yum/redhat/7Server/mongodb-org/4.0/x86_64/RPMS/mongodb-org-tools-4.0.3-1.el7.x86_64.rpm

rpm -ivh mongodb-org-4.0.3-1.el7.x86_64.rpm
rpm -ivh mongodb-org-mongos-4.0.3-1.el7.x86_64.rpm
rpm -ivh mongodb-org-server-4.0.3-1.el7.x86_64.rpm
rpm -ivh mongodb-org-shell-4.0.3-1.el7.x86_64.rpm           
rpm -ivh mongodb-org-tools-4.0.3-1.el7.x86_64.rpm

service mongod start
service mongod status
```