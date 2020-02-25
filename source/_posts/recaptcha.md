---
layout: title
title: recaptcha
date: 2020-02-25 09:02:04
tags:
---

### v2

点击验证

```
  <script src="https://www.recaptcha.net/recaptcha/api.js" async defer></script>
  <div class="g-recaptcha" data-sitekey="6Lff7tsUAAAAAAUXohp9oK_0kUokuc1GBMML8sz-"></div>

```

### v3

得分验证

```
  <script src="https://www.recaptcha.net/recaptcha/api.js?render=6Lek7NsUAAAAAJXDWigJdnrQhek6oJRYLfS3J5mq"></script>

  <script>
      grecaptcha.ready(function() {
          grecaptcha.execute('6Lek7NsUAAAAAJXDWigJdnrQhek6oJRYLfS3J5mq', {action: 'homepage'}).then(function(token) {
            alert(token)
          });
      });
  </script>
```
