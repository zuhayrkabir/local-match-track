# React Web Match Tracker

This folder is the React Web checkpoint for the Local-First Match Tracker monorepo.

## Current checkpoint

This pass has two modes:

- Vite + React + TypeScript app scaffolded in `react-web/`;
- dashboard UI mirrors the Flutter broadcast-style theme;
- shared match projection code understands the same `matches` and `match_events` document fields;
- sample data proves the dashboard, score, and timeline layout without opening Ditto;
- optional demo Ditto Server mode opens a browser Ditto peer and reads real `matches` / `match_events`.

Demo Ditto Server mode is read-only in the UI. It does **not** create matches or write referee events.

## Why React Web only?

This is a browser app. React Native would be a separate mobile checkpoint with different native setup, permissions, and Ditto tooling.

## Run locally

```bash
cd react-web
npm install
npm run dev
```

Open the printed localhost URL.

## Optional demo Ditto Server mode

Browser JavaScript is inspectable. Only use a disposable development/playground
token here, and do not deploy this mode publicly.

Create or update the repo-root `.env` file with explicitly demo-scoped Vite
variables:

```bash
VITE_DEMO_DITTO_DATABASE_ID="your-database-id"
VITE_DEMO_DITTO_SERVER_URL="https://your-ditto-server-url"
VITE_DEMO_DITTO_PLAYGROUND_TOKEN="your-disposable-development-token"
```

Then run `npm run dev` and select **Demo Ditto Server** in the app.

## Validate

```bash
cd react-web
npm run typecheck
npm run build
```

## Production auth note

The demo mode intentionally favors speed over security. A production browser app
should use a backend/token-exchange flow so the long-lived playground token is
not shipped to the browser.
