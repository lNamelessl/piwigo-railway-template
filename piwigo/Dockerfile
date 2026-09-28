# Piwigo on Railway — thin wrapper on the OFFICIAL image.
#
# The official image is Alpine nginx + php-fpm 8.4 (there is no :apache tag —
# the modern piwigo/piwigo image never ships one) and on first boot copies the
# pristine app from /var/www/source/piwigo into /var/www/html/piwigo, which is
# the persistent volume. Everything that matters lives there: galleries/,
# upload/ (photos), _data/, and local/config/database.inc.php (the install
# marker written by the classic web wizard).
#
# We add exactly one thing: a dotless static health route. Railway rejects
# healthcheck paths containing dots (so /install.php is out) and / returns 302
# to the wizard until the classic install is completed (so it is out too).
# /healthz is baked into the pristine source tree so it lands in the webroot
# after the first-boot copy, and is re-copied by the upstream self-upgrade
# (cp -arT) whenever the image tag advances.
FROM piwigo/piwigo:16.4.0

RUN printf 'OK' > /var/www/source/piwigo/healthz
