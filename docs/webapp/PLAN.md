# Static Configuration Generator — Build Plan

**Status**: Built (v1, official-ALZ rebuild), enhancements pending
**Location**: `frontend/`
**Type**: Static HTML/CSS/vanilla JS — no backend, no build step, no server

---

## What This Is

`frontend/` is a single static page that lets a user visually configure an Azure Landing Zone deployment and generates a `.tfvars` file for it — entirely client-side. There is no server, no database, no authentication, and no API calls. The user downloads or copies the generated file and feeds it into the Terraform layers under `terraform/live/` (locally via `terraform apply -var-file=...`, or by committing it and letting the GitHub Actions pipeline pick it up).

This intentionally replaced an earlier, unfinished direction that assumed a Node.js/Express backend with GitHub OAuth, job polling, and a database — that approach was abandoned as unnecessary overhead for what is fundamentally a form-to-file transformation.

## Files

| File | Purpose |
|---|---|
| `frontend/index.html` | 9-section form (org/location, network architecture, monitoring, policy assignments, management group names, resource naming, network CIDRs, tagging, review/generate) |
| `frontend/app.js` | `OfficialALZGenerator` class — reads the form, validates input, generates `.tfvars` content, handles download/copy-to-clipboard |
| `frontend/styles.css` | Styling, responsive layout |

## How to Use It

1. Open `frontend/index.html` directly in a browser (no server needed), or serve it statically (e.g. `python3 -m http.server` from `frontend/`, or GitHub Pages)
2. Fill in organization details, pick a network topology, select policy assignments, configure CIDRs and tags
3. Click "Generate Configuration"
4. Download the `.tfvars` file, or copy it to clipboard
5. Place it in the appropriate `terraform/live/<layer>/` directory and run `terraform plan -var-file=<file>` / `terraform apply -var-file=<file>`, or commit it and let the CI/CD pipeline handle it

## Current Policy Coverage

`frontend/app.js` currently defines 47 policy assignments across 5 management-group scopes, sourced from the official Azure Landing Zones policy reference:

| Scope | Count |
|---|---|
| Intermediate Root | 10 |
| Platform | 15 |
| Landing Zones | 15 |
| Landing Zones/Corp | 5 |
| Specialized | 2 |

**Open item**: this list has not yet been cross-checked against the actual policy definitions implemented in `terraform/modules/policy-baseline/` — some generator toggles may not correspond to a real Terraform policy, and some real policies may not be exposed as a toggle. See [TODO.md](../../TODO.md) Phase 3.

## Known Gaps / Next Steps

- [ ] Reconcile the generator's policy list against `terraform/modules/policy-baseline/` so every toggle maps to something real
- [ ] The generator exposes module-level toggles (e.g. Defender) for modules that aren't yet wired into any `terraform/live/*` root call — either wire them in or mark them clearly as "not yet integrated" in the UI
- [ ] Host the page somewhere reachable (GitHub Pages) instead of requiring a local file open
- [ ] Write a short end-user guide (fill form → download → where the file goes)

Full task list tracked in [TODO.md](../../TODO.md) Phase 3.
