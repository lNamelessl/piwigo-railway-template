# Piwigo on Railway — the classic open-source photo gallery, one click

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/piwigo-template)

Deploy [Piwigo](https://piwigo.org) — the photo gallery software with 20+ years of development behind it — plus MariaDB on Railway in one click. Zero deploy-form input: everything is pre-wired, and you finish with Piwigo's classic 2-minute install wizard (database values are copy-paste, admin account is yours to choose).

**What you get**

- **Official Piwigo image** (`piwigo/piwigo:16.4.0`, nginx + PHP-FPM, ImageMagick, ffmpeg, exiftool built in) — no `:apache` variant exists upstream; this is the official container.
- **MariaDB 11.8** on Railway's private network — reachable only from your gallery, never the public internet.
- **Persistent galleries**: a single Railway volume at `/var/www/html/piwigo` holds your photos, albums, thumbnails cache, and the install config. Photos and admin accounts survive restarts and redeploys.
- **Zero deploy-form input**: the MariaDB password is generated fresh per deployment; the Piwigo service references it. No secrets are baked into the template.

## First visit — the classic 2-minute wizard

1. Open your Railway domain. Piwigo greets you with its install wizard.
2. On the database page, copy 4 values — 2 come from the Piwigo service's **Variables** tab (`PIWIGO_DB_HOST`, `PIWIGO_DB_PASSWORD`), 2 are fixed constants (`piwigo` / `piwigodb` — documented in the repo README). Leave the table prefix as default.
3. On the admin page, pick your own administrator username, password, and email.
4. You land in your gallery. Add photos via **Administration → Photos → Add**, then set your first album to **Public** (Albums → edit album → Permissions) so visitors can browse it.

**Notes for self-hosters**

- Web uploads are capped at **32 MB per photo** by the bundled nginx config — use Piwigo's album-sync workflow (FTP/USB) for larger originals.
- Size the volume to your library; thumbnails are generated on the fly by ImageMagick.
- Outbound email (notifications, newsletters) needs SMTP configured inside Piwigo after login.

# Deploy and Host

## About Hosting

Hosting Piwigo self-hosted means you own your photo archive: two services are provisioned — a Piwigo web/gallery service (official image, port 80, volume at `/var/www/html/piwigo`) and a MariaDB 11.8 database service (private networking, volume at `/var/lib/mysql`). Both services restart on failure automatically. The gallery needs about 512 MB of RAM; MariaDB about 512 MB — roughly $5–10/month on Hobby, growing with your photo library's storage.

## Why Deploy

Piwigo's official container ships the classic web install wizard, which asks for database host, user, password, and name on first visit. Deployed manually, that means digging credentials out of a database container and wiring them by hand. This template pre-wires everything: the database hostname and password appear as resolved variables on the Piwigo service's Variables tab, ready to paste into the wizard. The database is private-network only, the gallery gets a public HTTPS domain, and both data volumes persist across restarts and redeploys.

## Common Use Cases

- A personal photo gallery with albums, tags, and per-album privacy — searchable and browseable.
- A family or club photo archive where multiple users upload to shared or private albums.
- A photographer's client-proofing gallery with download permissions and comment threads.
- A lightweight alternative to Immich/Damselfly when you want classic web-gallery features (faces, map, calendar, themes, 50+ plugins) without heavy ML infrastructure.

## Dependencies for

### Deployment Dependencies

- **MariaDB 11.8** (`mariadb:11.8`) — provisioned by the template with `MYSQL_DATABASE=piwigodb`, `MYSQL_USER=piwigo`, and a per-deployment generated `MYSQL_PASSWORD`. Only variables used: `MYSQL_PASSWORD` (generated `${{secret(32)}}`), `PIWIGO_DB_HOST` and `PIWIGO_DB_PASSWORD` on the Piwigo service (both references, resolved automatically).
- **Persistent volumes**: `/var/www/html/piwigo` (photos, albums, config) and `/var/lib/mysql` (database files).
- No deploy-form input is required; after deploy, complete the install wizard in the browser (2 values from the Variables tab + your admin account).
