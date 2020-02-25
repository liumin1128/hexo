---
title: 服务器迁移到centos
date: 2018-03-30 10:55:49
tags: [node,linux]
categories: 后端
---

### 迁移服务器到centos

更新内核，并升级CentOS


```
yum update kernel  
yum update && yum upgrade
```

git

```
yum -y install git
```

zsh

```
yum -y install zsh
```

o-my-zsh

```
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

nvm

```
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | zsh
```

source ~/.zshrc

```
export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node
```

或者

```
NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node nvm install
```

### nginx

```
vim /etc/yum.repos.d/nginx.repo

[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1

yum list |grep nginx
yum -y install nginx

```
