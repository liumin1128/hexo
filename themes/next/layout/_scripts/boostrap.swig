{%
  set boot_scripts = [
    'src/bootstrap.js'
  ]
%}

{% for bs in boot_scripts %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ bs }}?v={{ version }}"></script>

  <script type="text/javascript" async src="https://www.recaptcha.net/recaptcha/api.js"></script>
{% endfor %}
