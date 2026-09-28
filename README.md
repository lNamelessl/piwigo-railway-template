# Piwigo on Railway

One-click deploy of [Piwigo](https://piwigo.org) — the classic open-source photo gallery (20+ years of development) — with the official image, MariaDB, and persistent galleries. Zero deploy-form input.

Deploy it from Railway's template marketplace, or fork this repo and deploy manually.

## What gets deployed

| Service | Image (pinned) | Manifest digest |
|---|---|---|
| Piwigo | `piwigo/piwigo:16.4.0` (official, Alpine nginx + php-fpm) | `sha256:e0790a162075942c440286dedd849522f5b8fe23df9f053bf7faf6cc78a5b093` |
| MariaDB | `mariadb:11.8` | `sha256:79d59758afc91b89b120b0a8904d637f5a3b3e1c4900f29b740d6d46c72fef68` |

- **Official image, classic wizard**: the official `piwigo/piwigo` image (nginx + PHP-FPM — note: no `:apache` tag exists upstream) serves the classic Piwigo install wizard on first visit: database config + admin account creation.
- **Persistent galleries**: a single volume at `/var/www/html/piwigo` holds the whole app webroot — photos (`upload/`), albums (`galleries/`), compiled templates + cache (`_data/`), and the database config (`local/config/database.inc.php`). Everything survives restarts and redeploys; upstream self-upgrades only overwrite app files on a new image tag.
- **Private database**: MariaDB is reachable only over Railway's private network (`mariadb.railway.internal:3306`) — nothing is exposed publicly.
- **Zero deploy input**: all database defaults are baked into the images; the only two variables are generated/referenced expressions.

## First visit (2-minute classic wizard)

1. Open your Railway domain. Piwigo redirects to the install wizard.
2. **Database page** — copy the four values (two are in the Piwigo service's **Variables** tab):
   | Wizard field | Value |
   |---|---|
   | Host | `PIWIGO_DB_HOST` variable (resolves to `mariadb.railway.internal`) |
   | User | `piwigo` |
   | Password | `PIWIGO_DB_PASSWORD` variable (generated per deploy) |
   | Database name | `piwigodb` |
   | Table prefix | leave the default `piwigo_` |
3. **Admin page** — choose your admin username, password, and email. This is your gallery administrator.
4. Done — you land in the gallery. Add photos via **Administration → Photos → Add** (web uploader), or sync large libraries with Piwigo's FTP/USB-album features.

## Environment variables

The template needs **no deploy-form input**. Only three variables exist — all generated or referenced automatically:

| Variable | Service | Value |
|---|---|---|
| `MYSQL_PASSWORD` | mariadb | `${{secret(32)}}` — generated fresh per deployment, single source of truth |
| `PIWIGO_DB_HOST` | piwigo | `${{mariadb.RAILWAY_PRIVATE_DOMAIN}}` |
| `PIWIGO_DB_PASSWORD` | piwigo | `${{mariadb.MYSQL_PASSWORD}}` (reference — never duplicate the `secret()` call) |

Everything else uses image defaults baked at build time: `MYSQL_DATABASE=piwigodb`, `MYSQL_USER=piwigo`, and a random root password for MariaDB. These two variables exist purely so the wizard's database page is a two-value copy-paste — the Piwigo app itself does not read them.

## Photo storage and uploads

- Photos land on the Piwigo service's volume at `/var/www/html/piwigo/upload/` (web uploads) or `galleries/` (synced albums).
- The bundled nginx config caps each HTTP upload at **32 MB** per photo (PHP itself allows 100 MB). For larger originals, use Piwigo's album-sync workflow instead of the web uploader.
- Size the volume to your library (start with 5 GB; resize anytime). Thumbnails and image derivatives are generated on the fly and cached in `_data/`.
- The MariaDB container runs an internal, loopback-only mail relay — outbound notifications need an SMTP configured inside Piwigo after login (Administration → Configuration → Options → Notification).

## Backups

1. **Database**: dump MariaDB from the `mariadb` service (`railway ssh` → `mariadb-dump -upiwigo -p piwigodb`, or point a scheduled dump tool at `mariadb.railway.internal:3306`).
2. **Files**: photos, albums, and config live on the Piwigo service's volume — snapshot it separately. Deleting the volume deletes photos **and** the install marker (`local/config/database.inc.php`), which would bring back the install wizard on the next boot.

## Troubleshooting

- **Wizard database page fails to connect**: the MariaDB service may still be initializing right after a fresh deploy — wait ~1 minute and retry. Values must match the table above exactly (host and password must come from the Variables tab, not be typed by hand).
- **Upload rejected (413 / "file too large")**: you hit the 32 MB per-photo HTTP cap — use album sync for larger files.
- **Photos vanish after redeploying**: the `/var/www/html/piwigo` volume was removed or its mount path changed.
- **First boot looks slow**: the first boot copies the app into the fresh volume — a few seconds; later boots skip the copy.

## Cost

Two ~512 MB services + two small volumes ≈ **$5–10/month** on Railway's trial or Hobby plan. Raise the Piwigo service RAM and volume size as your photo library grows.

## Wrapper changes vs the official images

The services build thin wrappers on top of the pinned official images:

1. **`piwigo`**: adds a single static `/healthz` route (baked into the pristine source tree). Railway rejects healthcheck paths containing dots (`install.php` is unusable) and `/` redirects to the wizard until the classic install is done. No ownership changes — the upstream init script already runs as root, applies ACLs for the nginx user, and chowns the webroot to UID/GID 1000.
2. **`mariadb`**: bakes `MYSQL_DATABASE`, `MYSQL_USER`, and a random root password as image defaults; serves utf8mb4. No init scripts needed — Piwigo's wizard creates its own schema.
