{% extends '_layout.swig' %}
{% import '_macro/post.swig' as post_template %}
{% import '_macro/sidebar.swig' as sidebar_template %}

{% block title %}{{ title }}{% if theme.index_with_subtitle and subtitle %} – {{ subtitle }}{% endif %}{% endblock %}

{% block page_class %}
  {% if is_home() %}page-home{% endif -%}
{% endblock %}


{% block content %}

  <script type="text/javascript" async src="https://www.recaptcha.net/recaptcha/api.js?render=6Lek7NsUAAAAAJXDWigJdnrQhek6oJRYLfS3J5mq"></script>
  <div class="g-recaptcha" data-sitekey="6Lek7NsUAAAAAJXDWigJdnrQhek6oJRYLfS3J5mq">
    <input />
  </div>

  <section id="posts" class="posts-expand">
    {% for post in page.posts %}
      {{ post_template.render(post, true) }}
    {% endfor %}
  </section>

  {% include '_partials/pagination.swig' %}
{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(false) }}
{% endblock %}


