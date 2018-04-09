# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "packages/map.jinja" import packages with context %}

{% set req_states = packages.pips.required.states %}
{% set req_pkgs = packages.pips.required.pkgs %}
{% set wanted_pips = packages.pips.wanted %}
{% set unwanted_pips = packages.pips.unwanted %}

{% if wanted_pips and not wanted_pips|is_list %}
    {% set wanted_pips = wanted_pips.keys() %}
{% endif %}
{% if unwanted_pips and not unwanted_pips|is_list %}
    {% set unwanted_pips = unwanted_pips.keys() %}
{% endif %}

### REQ PKGS (without these, some of the WANTED PIPS will fail to install)
pip_req_pkgs:
  pkg.installed:
    - pkgs: {{ req_pkgs }}

### PYTHON PKGS to install using PIP
# (requires the python-pip deb/rpm installed, either by the system or listed in
# the required packages
{% for pn in wanted_pips %}
{{ pn }}:
  pip.installed:
    - reload_modules: true
    - require:
      - pkg: pip_req_pkgs
      {% if req_states %}
        {% for dep in req_states %}
      - sls: {{ dep }}
        {% endfor %}
      {% endif %}
{% endfor %}

{% for upn in unwanted_pips %}
{{ upn }}:
  pip.removed
{% endfor %}
