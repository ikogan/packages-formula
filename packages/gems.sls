# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "packages/map.jinja" import packages with context %}

{% set req_states = packages.gems.required.states %}
{% set req_pkgs = packages.gems.required.pkgs %}
{% set wanted_gems = packages.gems.wanted %}
{% set unwanted_gems = packages.gems.unwanted %}

{% if wanted_gems and not wanted_gems|is_list %}
    {% set wanted_gems = (wanted_gems.keys())|list %}
{% endif %}
{% if unwanted_gems and not unwanted_gems|is_list %}
    {% set unwanted_gems = (unwanted_gems.keys())|list %}
{% endif %}

{% if req_states %}
include:
  {% for dep in req_states %}
  - {{ dep }}
  {% endfor %}
{% endif %}

### REQ PKGS (without these, some of the WANTED GEMS will fail to install)
gem_req_pkgs:
  pkg.installed:
    - pkgs: {{ req_pkgs | json }}

### GEMS to install
# (requires the ruby/rubygem deb/rpm installed, either by the system or listed in
# the required packages
{% for gm in wanted_gems %}
{{ gm }}:
  gem.installed:
    - require:
      - pkg: gem_req_pkgs
      {% if req_states %}
        {% for dep in req_states %}
      - sls: {{ dep }}
        {% endfor %}
      {% endif %}
{% endfor %}

{% for ugm in unwanted_gems %}
{{ ugm }}:
  gem.removed
{% endfor %}
