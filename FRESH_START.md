# Start from scratch – reset DB and test full flow

Use this when you want to wipe the Spoticord database and link state and test the flow from the beginning (same code, same installs).

---

## 1. Prerequisites (one-time)

- **PostgreSQL** running locally (e.g. `brew services start postgresql` on macOS).
- **Rust** and **Node.js** installed.
- **Spoticord** and **Spoticord Link** env files already set (e.g. `spoticord/.env`, `spoticord-link/.env.local`).

---

## 2. Reset: drop and recreate the database

**Important:** Stop the Spoticord bot and Spoticord Link (Ctrl+C in both terminals) before dropping the database, or PostgreSQL will refuse with “database is being accessed by other users”.

From your project root (or any directory where `psql` can connect as your user):

```bash
# Drop existing database (disconnect any running Spoticord/Link first!)
psql postgres://aayush@localhost:5432/postgres -c "DROP DATABASE IF EXISTS spoticord;"

# Create empty database
psql postgres://aayush@localhost:5432/postgres -c "CREATE DATABASE spoticord;"
```

Tables are **not** created here. They are created automatically when Spoticord runs (migrations run on first connect).

---

## 3. Install dependencies (if needed)

```bash
# Spoticord (Rust)
cd /Users/aayush/Developer/spotify-bot/spoticord
cargo build --release

# Spoticord Link (Next.js)
cd /Users/aayush/Developer/spotify-bot/spoticord-link
npm install
```

---

## 4. Run the full stack

Use two terminals.

**Terminal 1 – Spoticord Link (port 3001):**

```bash
cd /Users/aayush/Developer/spotify-bot/spoticord-link
npm run dev
```

Wait until you see something like “Ready on http://127.0.0.1:3001”.

**Terminal 2 – Spoticord bot:**

```bash
cd /Users/aayush/Developer/spotify-bot/spoticord
./target/release/spoticord
```

Or with cargo:

```bash
cd /Users/aayush/Developer/spotify-bot/spoticord
cargo run --release
```

On first connect, Spoticord runs migrations and creates the `user`, `link_request`, and `account` tables. Your `.env` must have `DATABASE_URL=postgres://aayush@localhost:5432/spoticord` (or your actual URL).

---

## 5. Test the flow

1. **Discord** – In a server where the bot is added, run `/link`.
2. **Browser** – Open the link URL (e.g. `http://127.0.0.1:3001`), complete Spotify auth.
3. **Discord** – Run `/join` in a voice channel, then control playback from the Spotify app (device name will be the new default from your migration, e.g. “Spoticord” or whatever you set).

---

## 6. Quick reset (DB only)

To reset again without reinstalling anything:

```bash
psql postgres://aayush@localhost:5432/postgres -c "DROP DATABASE IF EXISTS spoticord;"
psql postgres://aayush@localhost:5432/postgres -c "CREATE DATABASE spoticord;"
```

Then start Link and Spoticord again; migrations will recreate tables on connect.

---

## 7. Finding your Guild ID (for dev / `GUILD_ID`)

Slash commands are registered **per guild** in debug builds so they appear instantly in your test server. You need your Discord server’s (guild) ID in `spoticord/.env` as `GUILD_ID`.

1. In Discord: **User Settings → App Settings → Advanced** → turn **Developer Mode** on.
2. Open your server, then **right‑click the server name** (top left).
3. Click **Copy Server ID**. That value is your guild ID.
4. In `spoticord/.env` add or set:
   ```bash
   GUILD_ID=1234567890123456789
   ```
   (use the ID you copied).

In **release** builds, commands are registered **globally** and `GUILD_ID` is not used.

---

## 8. `/playlist` and adding new slash commands

- **`/playlist`** – Lists your Spotify playlists and lets you start playing one from Discord.
  - Requires a linked account (`/link`) and, to hear audio, Spoticord in a voice channel (`/join`) so it’s your active Spotify device.
  - Use the dropdown on the reply to choose a playlist to play.

To **add or register a new slash command** (e.g. `/playlist`):

1. **Implement the command** in `spoticord/src/commands/` (e.g. `core/playlist.rs` with `#[poise::command(slash_command)]`).
2. **Export it** in the right `mod.rs` (e.g. `commands/core/mod.rs`: `mod playlist;` and `pub use playlist::*`).
3. **Register it** in `spoticord/src/bot.rs` in `framework_opts()` → `commands: vec![ ..., commands::core::playlist(), ]`.
4. **Restart the bot.** In debug, commands are registered for `GUILD_ID`; in release, they’re registered globally (can take a short while to appear everywhere).
