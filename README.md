# ocserv-auto-config
Automatically install and configure ocserv on Ubuntu 18.04 or above. Including obtaining and installing certificate from letsencrypt.

## Prerequisite:

You must have a domain managed by cloudflare. You also need to know your **Global API Key** which can be found at the bottom of your "My Profile" section.

## Usgage:

```shell

wget https://raw.githubusercontent.com/dreamsafari/ocserv-auto-config/master/install_ocserv.sh && chmod +x install_ocserv.sh
sudo ./install_ocserv.sh sub-domain_name domain_name cloudflare_email cloudflare_API_key

```

