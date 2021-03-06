[![Build Status](http://img.shields.io/travis/cchurch/ansible-role-letsencrypt.svg)](https://travis-ci.org/cchurch/ansible-role-letsencrypt)
[![Galaxy](http://img.shields.io/badge/galaxy-cchurch.letsencrypt-blue.svg)](https://galaxy.ansible.com/cchurch/letsencrypt/)

LetsEncrypt
===========

Create SSL certificates with Let's Encrypt using the
[`acme_certificate`](https://docs.ansible.com/ansible/latest/modules/acme_certificate_module.html)
module (formerly known as the `letsencrypt` module). Requires Ansible 2.4 or later.

Requirements
------------

OpenSSL must be installed on the target system if exising keys or CSR are not
available and must be generated.

Role Variables
--------------

The following variables may be defined to customize this role. Variables
highlighted in **`bold`** below are the ones typically used to configure the
role:

- **`letsencrypt_domain`**: The domain name for which the certificate will be
  generated (required).
- **`letsencrypt_account_key_path`**: The path to the private key for the Let's
  Encrypt account (required). This key will be generated if the file does not
  exist.
- **`letsencrypt_key_path`**: The path to the private key used for the CSR and
  resulting certificate (required). This key will be generated if the file does
  not exist and cannot be the same as `letsencrypt_account_key_path`.
- `letsencrypt_key_options`: Additional options to append to the
  `openssl genrsa` command above; default is `"2048"` to ensure 2048-bit keys
  are generated.
- **`letsencrypt_csr_path`**: The path to the CSR that will submitted to Let's
  Encrypt (required). This CSR will be generated if the file does not exist.
- `letsencrypt_csr_subj`: The subject for the generated CSR; default is
  `"/C=US/ST=Any/L=Wherever/O=Whatever/CN={{ letsencrypt_domain }}"`.
- **`letsencrypt_crt_path`**: The path to the resulting certificate that will be
  checked and/or generated by Let's Encrypt (required).
- `letsencrypt_account_email`: The account email to be submitted with the Let's
  Encrypt request.
- `letsencrypt_acme_directory_staging`: The URL of the Let's Encrypt staging
  API; default is `"https://acme-staging.api.letsencrypt.org/directory"`.
- `letsencrypt_acme_directory_production`: The URL of the Let's Encrypt
  production API; default is `"https://acme-v01.api.letsencrypt.org/directory"`.
- **`letsencrypt_acme_directory`**: The URL to use for Let's Encrypt requests;
  default is `"{{ letsencrypt_acme_directory_staging }}"`. Set to
  `"{{ letsencrypt_acme_directory_producion }}"` to generate a valid certificate.
- `letsencrypt_acme_version`: The version of the ACME endpoint; default is to
  use the module's default value. Only supported for Ansible 2.5 and later.
- `letsencrypt_challenge_type`: The challenge type for the Let's Encrypt
  request; default is `"http-01"`.
- `letsencrypt_agreement`: The URI to the terms of service document; default is
  `"https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf"`.
- `letsencrypt_terms_agreed`: Boolean indicating agreement to terms of service;
  default is `true`, only valid when `letsencrypt_acme_version != "1"`.

The following variable may be defined for the play or role invocation (but not
as an inventory group or host variable):

- `letsencrypt_notify_fulfill`: Handler to notify to fulfill the Let's Encrypt
  challenge; default is `"fulfill letsencrypt challenge"`. The
  `letsencrypt_challenge` variable will be set for use by any handler tasks, and
  the expression
  `letsencrypt_challenge["challenge_data"][letsencrypt_domain][letsencrypt_challenge_type]`
  should be used to determine more information about what is needed to fulfill
  the challenge. The role uses `meta: flush_handlers` to call registered
  handlers immediately when a challenge is available.
- `letsencrypt_notify_completed`: Handler to notify once the Let's Encrypt
  challenge has been completed and the certificate has been updated; default is
  `"letsencrypt challenge completed"`.

The [`listen`](http://docs.ansible.com/ansible/latest/playbooks_intro.html#handlers-running-operations-on-change)
option for handlers can be used to register one or more handler tasks to run to
fulfill a challenge or take action when a certificate has been updated.

Example Playbook
----------------

The following example playbook creates the necessary keys and CSR to use with
LetsEncrypt, creates the necessary directories and files to complete the
LetsEncrypt challenge, and generates/updates the resulting certificate:

    - hosts: all
      vars:
        webroot: /usr/share/nginx/html/
        letsencrypt_domain: test.mydomain.com
        letsencrypt_account_key_path: /etc/pki/tls/private/letsencrypt-account.key
        letsencrypt_key_path: /etc/pki/tls/private/letsencrypt.key
        letsencrypt_csr_path: /etc/pki/tls/misc/{{ letsencrypt_domain }}.csr
        letsencrypt_crt_path: /etc/pki/tls/certs/{{ letsencrypt_domain }}.crt
        letsencrypt_acme_directory: "{{ letsencrypt_acme_directory_production }}"
      roles:
        - role: cchurch.letsencrypt
      handlers:
        - name: create directories needed to fulfill letsencrypt challenge
          file:
            path: "{{ webroot }}/{{ letsencrypt_challenge['challenge_data'][letsencrypt_domain][letsencrypt_challenge_type]['resource'] | dirname }}"
            state: directory
          listen: fulfill letsencrypt challenge
        - name: create file needed to fulfill letsencrypt challenge
          copy:
            content: "{{ letsencrypt_challenge['challenge_data'][letsencrypt_domain][letsencrypt_challenge_type]['resource_value'] }}"
            dest: "{{ webroot }}/{{ letsencrypt_challenge['challenge_data'][letsencrypt_domain][letsencrypt_challenge_type]['resource'] }}"
          listen: fulfill letsencrypt challenge
        - name: restart nginx when cert has been updated
          service:
            name: nginx
            state: restarted
          listen: letsencrypt challenge completed

License
-------

BSD

Author Information
------------------

Chris Church ([cchurch](https://github.com/cchurch))
