# React Web Match Tracker

This folder is the React Web checkpoint for the Local-First Match Tracker monorepo.

## Current checkpoint

This first pass is intentionally safe and read-only:

- Vite + React + TypeScript app scaffolded in `react-web/`;
- dashboard UI mirrors the Flutter broadcast-style theme;
- shared match projection code understands the same `matches` and `match_events` document fields;
- sample data proves the dashboard, score, and timeline layout before Ditto Web auth is added.

It does **not** bundle a Ditto playground token into browser JavaScript.

## Why React Web only?

This is a browser app. React Native would be a separate mobile checkpoint with different native setup, permissions, and Ditto tooling.

## Run locally

```bash
cd react-web
npm install
npm run dev
```

Open the printed localhost URL.

## Validate

```bash
cd react-web
npm run typecheck
npm run build
```

## Ditto Web wiring plan

The next checkpoint is to replace `sampleData.ts` with real Ditto Web reads.

Before doing that, choose an auth strategy:

1. **Demo-only direct token**: fastest, but exposes `DITTO_PLAYGROUND_TOKEN` in the browser bundle.
2. **Safer token exchange/proxy**: better architecture, but requires a tiny backend or auth endpoint.
3. **Small-peers-only browser checkpoint**: avoids server auth but will not sync with the existing Ditto Server data.

Until that decision is explicit, this folder avoids committing browser-side token wiring.
