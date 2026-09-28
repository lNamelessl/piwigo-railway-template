#!/usr/bin/env bash
# Piwigo acceptance battery A1-A7 (zero-credential).
# Usage: verify.sh <public-domain> [adminuser] [adminpass]
set -u
DOMAIN="${1:?usage: verify.sh <domain> [adminuser] [adminpass]}"
AU="${2:-admin}"
AP="${3:-RlwPw$(openssl rand -hex 6)}"
J=/tmp/pw_cookies.txt
STEP() { echo; echo "=== $1 ==="; }

STEP "A2 pre-wizard state"
C1=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/")
L1=$(curl -s -o /dev/null -w "%{redirect_url}" "https://$DOMAIN/")
H1=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/healthz")
I1=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/install.php")
echo "GET / -> $C1 (Location: $L1) | /healthz -> $H1 | /install.php -> $I1"

STEP "A3 wizard POST (DB config + admin creation)"
PW=$(curl -s "https://$DOMAIN/healthz" >/dev/null; true)
DBHOST=$( [ -f /tmp/pw_dbhost ] && cat /tmp/pw_dbhost || echo "mariadb.railway.internal" )
DBUSER=$( [ -f /tmp/pw_dbuser ] && cat /tmp/pw_dbuser || echo "piwigo" )
DBNAME=$( [ -f /tmp/pw_dbname ] && cat /tmp/pw_dbname || echo "piwigodb" )
DBPASS=$(cat /tmp/pw_dbpass)
RESP=$(curl -s "https://$DOMAIN/install.php" \
  --data-urlencode "install=1" \
  --data-urlencode "dbhost=$DBHOST" \
  --data-urlencode "dbuser=$DBUSER" \
  --data-urlencode "dbpasswd=$DBPASS" \
  --data-urlencode "dbname=$DBNAME" \
  --data-urlencode "prefix=piwigo_" \
  --data-urlencode "admin_name=$AU" \
  --data-urlencode "admin_pass1=$AP" \
  --data-urlencode "admin_pass2=$AP" \
  --data-urlencode "admin_mail=admin@example.com")
echo "$RESP" | grep -o "Congratulations, Piwigo installation is completed" || { echo "INSTALL FAILED, response:"; echo "$RESP" | grep -io "error[^<]*\|fatal[^<]*" | head -5; echo "$RESP" | head -c 800; }
echo "$AU" > /tmp/pw_adminuser; echo "$AP" > /tmp/pw_adminpass

STEP "A4 admin login + panel"
curl -s -c "$J" -o /dev/null "https://$DOMAIN/install.php"
L=$(curl -s -b "$J" -c "$J" -o /dev/null -w "%{http_code} %{redirect_url}" "https://$DOMAIN/identification.php" \
  --data-urlencode "login=1" --data-urlencode "username=$AU" --data-urlencode "password=$AP" --data-urlencode "redirect=admin.php")
echo "POST identification.php -> $L"
A4=$(curl -s -b "$J" -o /dev/null -w "%{http_code}" "https://$DOMAIN/admin.php")
echo "GET /admin.php -> $A4"

echo; echo "admin=$AU pass=$AP (also in /tmp/pw_adminpass)"
