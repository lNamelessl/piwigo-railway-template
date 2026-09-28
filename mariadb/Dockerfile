# MariaDB 11.8 for Piwigo (Piwigo requires MariaDB >= 10.1; the official
# piwigo-docker compose uses mariadb:lts). The upstream defaults are baked as
# image ENV so the marketplace deploy needs zero manual inputs. The piwigo
# user's password is NOT set here — it comes from the shared MYSQL_PASSWORD
# expression variable (referenced by the piwigo service as
# ${{mariadb.MYSQL_PASSWORD}}).
FROM mariadb:11.8

ENV MYSQL_DATABASE=piwigodb \
    MYSQL_USER=piwigo \
    MARIADB_RANDOM_ROOT_PASSWORD=yes \
    MARIADB_AUTO_UPGRADE=yes \
    TZ=UTC

CMD ["mariadbd", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci", "--innodb-file-per-table=1"]
