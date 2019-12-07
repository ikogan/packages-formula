# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "packages/map.jinja" import packages with context %}

{% set req_states = packages.pkgs.required.states %}
{% set req_packages = packages.pkgs.required.pkgs %}
{% set held_packages = packages.pkgs.held %}
{% set wanted_packages = packages.pkgs.wanted %}
{% set unwanted_packages = packages.pkgs.unwanted %}

{% if wanted_packages and not wanted_packages|is_list %}
    {% set wanted_packages = (wanted_packages.keys())|list %}
{% endif %}
{% if unwanted_packages and not unwanted_packages|is_list %}
    {% set unwanted_packages = (unwanted_packages.keys())|list %}
{% endif %}

{% if req_states %}
include:
  {% for dep in req_states %}
  - {{ dep }}
  {% endfor %}
{% endif %}

### PRE-REQ PKGS (without these, some of the WANTED PKGS will fail to install)
pkg_req_pkgs:
  pkg.installed:
    - pkgs: {{ req_packages | json }}
    {% if req_states %}
    - require:
      {% for dep in req_states %}
      - sls: {{ dep }}
      {% endfor %}
    {% endif %}

{% if held_packages != {} %}
held_pkgs:
  pkg.installed:
    {% if held_packages is mapping %}
    - pkgs:
      {% for p, v in held_packages.items() %}
      - {{ p }}: {{ v }}
      {% endfor %}
    {% else %}
    - pkgs: {{ held_packages | json }}
    {% endif %}
    {% if grains['os_family'] not in ['Suse'] %}
    - hold: true
    - update_holds: true
    {% endif %}
    - require:
      - pkg: pkg_req_pkgs
        {% for dep in req_states %}
      - sls: {{ dep }}
        {% endfor %}
{% endif %}

wanted_pkgs:
  pkg.installed:
    - pkgs: {{ wanted_packages | json }}
    {% if grains['os_family'] not in ['Suse'] and (grains['os'] != 'Fedora' or grains['osmajorrelease'] < 30) %}
    - hold: false
    {% endif %}
    - require:
      - pkg: pkg_req_pkgs
      {% if req_states %}
        {% for dep in req_states %}
      - sls: {{ dep }}
        {% endfor %}
      {% endif %}

unwanted_pkgs:
  pkg.purged:
    - pkgs: {{ unwanted_packages | json }}

