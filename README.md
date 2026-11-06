# Immich (Raspberry Pi, SSO via Authentik)

> Self-hosted photo and video library on the Raspberry Pi 5, reachable from the
> internet through the WireGuard + Caddy proxy. Login via Authentik (OIDC).

## Architecture

```
Browser / mobile app → VPS → WireGuard → RPi Caddy (TLS) → immich-server (127.0.0.1:9002)
                                                              ├→ machine-learning (smart search, faces)
                                                              ├→ postgres (pgvector)
                                                              └→ redis
```

- Only `immich-server` publishes a port, bound to `127.0.0.1`. Caddy is the only way in.
- Postgres and Redis expose no ports.
- Postgres runs with data checksums. The healthcheck fails if any checksum error is reported.
- Authentik is resolved on the host via `extra_hosts`, so OIDC calls don't hairpin through the VPS.

## Pi 5 note: pgvector instead of pgvecto-rs

The Raspberry Pi 5 kernel uses 16 KB memory pages. The default Immich database image
(`tensorchord/pgvecto-rs`) is incompatible with it, so this stack uses
`pgvector/pgvector:pg16` instead.

## First boot

```bash
./generate-secrets.sh            # creates .env and fills DB_PASSWORD
vim .env                         # set IMMICH_URL and DOMAIN
docker compose up -d
docker compose ps                # postgres and redis must be healthy
curl -I http://127.0.0.1:9002    # expect 200
```

Caddy on the Pi:

```
photos.example.com {
    reverse_proxy 127.0.0.1:9002
}
```

## SSO (Authentik)

In Authentik, create an OAuth2/OpenID provider (confidential client) with these redirect URIs:

```
app.immich:///oauth-callback
https://photos.example.com/auth/login
https://photos.example.com/user-settings
```

Scopes: `openid`, `email`, `profile`, plus a custom `email-fallback` scope mapping (shared with Open WebUI).

In Immich: **Administration → Settings → Authentication → OAuth**

| Field      | Value                                              |
|------------|----------------------------------------------------|
| Issuer URL | `https://auth.example.com/application/o/immich/`   |
| Client ID  | from Authentik                                     |
| Secret     | from Authentik                                     |
| Scope      | `openid email profile`                             |

## Data

Everything persistent lives under `./data/` (uploads, ML model cache, Postgres), which is git-ignored.
