#!/usr/bin/env python3
# Should be copied to target machine at /etc/cron.d/ip_update.py

import os
import hashlib
import logging
import requests
import subprocess
from jinja2 import Template

# -------- FUNCTIONS --------
def read_file(file_path, fail_on_404=False):
  try:
    with open(file_path) as f:
      return f.read().strip()
  except FileNotFoundError:
    if fail_on_404:
      logging.error(f"File not found: {file_path}")
      exit(1)
    
    return ""

def write_file(file_path, content):
  with open(file_path, "w") as f:
    f.write(content)

def create_files():
  for f in [NFTABLE_CONF_PATH, NGINX_CFIP_CONF_PATH]:
    if not os.path.exists(f):
      open(f, "w").close()
      logging.info(f"Created missing file: {f}")

def render_template(template_str, context):
  template = Template(template_str)
  return template.render(**context)

def fetch_cloudflare_ips():
    ipv4 = sorted(requests.get(CF_IPV4_URL).text.strip().splitlines())
    ipv6 = sorted(requests.get(CF_IPV6_URL).text.strip().splitlines())
    return ipv4, ipv6

def compute_hash(ipv4, ipv6):
  combined = "\n".join(ipv4 + ipv6).encode()
  return hashlib.sha256(combined).hexdigest()

def apply_configs(name, cmd=[]):
  try:
    subprocess.run(cmd, check=True, capture_output=True, text=True)
    logging.info(f"{name} reloaded successfully")
  except subprocess.CalledProcessError as e:
    logging.error(f"Failed to reload {name}: {e.stderr}")

# -------- CONFIG --------
NGINX_CFIP_CONF_PATH = "/etc/nginx/conf.d/cf_ips.conf"
NFTABLE_CONF_PATH = "/etc/nftables.conf"

CF_IPV4_URL = "https://www.cloudflare.com/ips-v4"
CF_IPV6_URL = "https://www.cloudflare.com/ips-v6"

NFTABLE_TEMPLATE = read_file("nftables.conf.j2", fail_on_404=True)
NGINX_CF_IPS_TEMPLATE = read_file("cf_ips.conf.j2", fail_on_404=True)

LOG_FILE = "exec-report.log"
CF_IP_HASH_FILE = "/etc/cf_ip_hash.txt"

# -------- LOGGING --------
logging.basicConfig(filename=LOG_FILE,
                    format='%(asctime)s %(levelname)s: %(message)s',
                    level=logging.INFO)

# -------- MAIN --------
def main():
  try:
    create_files()
    ipv4, ipv6 = fetch_cloudflare_ips()
    new_hash = compute_hash(ipv4, ipv6)
    old_hash = read_file(CF_IP_HASH_FILE)

    if new_hash != old_hash:
      write_file(CF_IP_HASH_FILE, new_hash)
      render_context = {
        "cf_ipv4": ipv4,
        "cf_ipv6": ipv6
      }

      nginx_rendered = render_template(NGINX_CF_IPS_TEMPLATE, render_context)
      nftable_rendered = render_template(NFTABLE_TEMPLATE, render_context)

      write_file(NGINX_CFIP_CONF_PATH, nginx_rendered)
      write_file(NFTABLE_CONF_PATH, nftable_rendered)

      apply_configs(name="nginx", cmd=["nginx", "-s", "reload"])
      apply_configs(name="nftable", cmd=["nft", "-f", NFTABLE_CONF_PATH])

      logging.info("Config files updated and services reloaded successfully.")
    else:
      logging.info("No changes in Cloudflare IPs range! Exiting...")
  except Exception as e:
    logging.error(f"Error occurred: {e}")
    exit(1)

if __name__ == "__main__":
  main()
