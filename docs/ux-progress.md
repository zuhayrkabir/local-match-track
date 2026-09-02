# UX Progress Tracker

## Source of truth

- Primary reference: `/Users/zuhayrkabir/Downloads/match-tracker-ux-directions.html`
- Selected direction: Option C, “Broadcast Dark”
- Supporting references:
  - `/Users/zuhayrkabir/Downloads/C_Dashboard.dc.html`
  - `/Users/zuhayrkabir/Downloads/C_Phone.dc.html`

## Completed

- [x] Added Option C color tokens and typography helpers.
- [x] Added Oswald for scoreboard/display text and Chivo for interface/body text.
- [x] Extracted dashboard UI into a dedicated `match_dashboard` feature folder.
- [x] Built a broadcast-style masthead with demo tags, Ditto 5.1 label, mesh demo label, and live aggregate stats.
- [x] Built a featured match panel with oversized score, clock, remaining time, and lower-third latest-event treatment.
- [x] Re-centered the featured scoreline so it reads more like a broadcast scoreboard and less like it is falling down the card.
- [x] Preserved the small cube/grid match overview for secondary games.
- [x] Added hover/focus/tap match promotion so secondary match cubes can become the featured dashboard match.
- [x] Fixed the compact detail timeline so it filters synced events by the currently selected match.
- [x] Fixed compact match selector and clock-pill overflow on phone-sized screens.
- [x] Removed the theme toggle so every platform uses the Option C broadcast-dark theme.
- [x] Restyled the match detail page to share dashboard-style panels, typography, accents, and timeline rows.
- [x] Reused the broadcast dashboard's team-sided chronological timeline on the match detail page.
- [x] Added Assistant Referee mode for proposing offside/foul reviews.
- [x] Added referee review-request panel for accepting or rejecting assistant proposals.
- [x] Added referee-online gating so assistants can view the match but cannot send proposals until a synced referee heartbeat is fresh.
- [x] Added a right rail for a team-sided chronological timeline and live pitches on wide screens.
- [x] Upgraded the timeline to show home/away team headers, central minute markers, event-type colors, and richer event copy.
- [x] Added responsive fallback so the right rail stacks below the featured match on narrow screens.
- [x] Added visible loading and error panels that fit the Option C visual language.
- [x] Restyled the opening role-selection page to match the dark broadcast dashboard theme.
- [x] Kept dashboard data wired to the existing Ditto-backed providers instead of introducing fake UI-only state.

## Still worth improving after the demo baseline

- [ ] Add golden/widget layout tests for mobile, tablet, and desktop dashboard widths.
- [ ] Add a dedicated phone-first referee control redesign inspired by `C_Phone.dc.html`.
- [ ] Bundle local font assets if the app needs guaranteed first-run offline typography without relying on cached Google Fonts.
- [ ] Add richer tournament statistics such as total goals per pitch, card leaders, and substitution totals.
- [ ] Consider a projector/demo mode toggle that hides referee controls and enlarges the dashboard even more.
