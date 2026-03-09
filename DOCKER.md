# Running with Docker Compose

Run the full stack (PostgreSQL + Spoticord bot + Spoticord Link) with Docker.

## Quick start

1. **Create `.env` from the example and add your secrets:**

   ```bash
   cp .env.example .env
   # Edit .env: set DISCORD_TOKEN, SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET
   ```

   You can copy values from your existing `spoticord/.env` and `spoticord-link/.env.local`.

2. **Start the stack:**

   ```bash
   docker compose up -d
   ```

3. **Open the Link app** at [http://localhost:3000](http://localhost:3000) (or the port you set as `LINK_PORT` in `.env`).

4. In Discord, use `/link` and complete the flow in the browser. Then `/join` in a voice channel.

## Hosting somewhere (VPS, cloud, etc.)

1. **Set public URLs in `.env`** so Discord/Spotify redirect users to your server:

   ```env
   LINK_URL=https://link.yourdomain.com/
   SPOTIFY_REDIRECT_URI=https://link.yourdomain.com/authorize
   ```

2. **In the Spotify Developer Dashboard**, add `https://link.yourdomain.com/authorize` to the app’s Redirect URIs.

3. **Put a reverse proxy (e.g. Caddy, Nginx, Traefik) in front** of the Link service so it’s served over HTTPS. Expose the Link container port (e.g. 3000) only to the proxy, not to the internet.

4. **Optionally set stronger Postgres credentials** in `.env`:

   ```env
   POSTGRES_USER=spoticord
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_DB=spoticord
   ```

5. Run `docker compose up -d` on the server.

## Commands

- **Logs:** `docker compose logs -f`
- **Stop:** `docker compose down`
- **Stop and remove DB data:** `docker compose down -v`

## What’s in the stack

| Service         | Role                          | Image / build                    |
|----------------|-------------------------------|----------------------------------|
| `db`           | PostgreSQL 16                 | `postgres:16-alpine`             |
| `spoticord-link` | Next.js Link app (OAuth UI) | Built from `spoticord-link/`     |
| `spoticord`    | Discord bot                   | Built from repo root (`Dockerfile.spoticord`) |

The bot and Link both use the same `DATABASE_URL` pointing at the `db` service. Migrations run when Spoticord starts.

---

## Deploy on Railway

One service runs both the bot and the Link app; PostgreSQL is a separate Railway service.

1. **New project** → Add **PostgreSQL** (from Railway’s data tab). Note the `DATABASE_URL` (or reference it as `${{Postgres.DATABASE_URL}}` if using references).

2. **New service** → Deploy from this repo. Set **Dockerfile path** to `Dockerfile.railway` (root directory = repo root).

3. **Variables** (in the service’s Variables tab):

   - `DATABASE_URL` – from the Postgres service (or `${{Postgres.DATABASE_URL}}`).
   - `DISCORD_TOKEN` – your Discord bot token.
   - `SPOTIFY_CLIENT_ID` – Spotify app client ID.
   - `SPOTIFY_CLIENT_SECRET` – Spotify app client secret.
   - `LINK_URL` – your Railway app URL with trailing slash, e.g. `https://your-app.up.railway.app/`.
   - `SPOTIFY_REDIRECT_URI` – same base + `/authorize`, e.g. `https://your-app.up.railway.app/authorize`.
   - Optional: `GUILD_ID` – Discord server ID for dev (slash commands in one server).

4. **Spotify Developer Dashboard** → your app → Redirect URIs → add the same `SPOTIFY_REDIRECT_URI` (e.g. `https://your-app.up.railway.app/authorize`).

5. Deploy. The web process listens on `PORT` (set by Railway); the Discord bot runs in the same container.
