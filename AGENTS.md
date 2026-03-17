# Development & Deployment

## CI/CD (Woodpecker)

- Woodpecker configuration is in `.woodpecker.yml`
- Woodpecker runs on home server (`nixserver`), NOT locally
- To update Woodpecker config, push changes to GitHub (`.woodpecker.yml` is fetched from repo)

## Nixserver

- Located at `~/Projects/nixserver`
- Contains docker-compose.yml for registry + Woodpecker CI
- Do NOT run docker-compose locally - only on home server
