# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TRMNL private plugin that displays astronomy highlights from the Telescopius API on a TRMNL e-Ink display.

## Architecture

- **Strategy**: Polling — TRMNL fetches `https://api.telescopius.com/v2.0/targets/highlights?types=DEEP_SKY_OBJECT,COMET&lat=38.563&lon=-8.881&timezone=Europe/Lisbon&min_alt=20&time_format=24hr&compute_current=1` every 24 hours (1440 min) via HTTP GET
- **Auth**: `Authorization=Key <TELESCOPIUS_API_KEY>` header (key stored in `.env`)
- **Rendering**: Liquid templates receive the API response and render it using TRMNL Framework v3.0.3 CSS/component system
- **Data path**: `{matched, page_results: [...]}` → `page_results` array → Liquid `{% for item in page_results %}` → e-Ink display
- **Catalog ID priority**: M → NGC → C → LBN; max 2 IDs shown in full/half_horizontal, max 1 in half_vertical/quadrant

## File Layout

```
private_plugin_227426/
  settings.yml    # Plugin config: polling URL with location/filter params, framework 3.0.3
  full.liquid     # Full screen: 5 objects, name + 2 catalog IDs, type, constellation, mag, visible window
  half_horizontal.liquid  # Half horizontal: 5 objects, no constellation
  half_vertical.liquid    # Half vertical: 3 objects, 1 catalog ID
  quadrant.liquid         # Quadrant: 3 objects, name + 1 ID + magnitude only
.env              # TELESCOPIUS_API_KEY
PROJECT.md        # Resource links (API docs, framework docs, local dev server)
```

## Local Development

Edit locally → run `./sync-trmnlp.sh` → preview at http://192.168.2.168:4567

trmnlp server runs on a remote dev box via Docker. Files synced over SSH.

## Key References

- Telescopius API docs (Swagger): https://api.telescopius.com/
- TRMNL API docs: https://docs.trmnl.com/go/llms.txt
- TRMNL Framework (UI components/CSS): https://context7.com/websites/usetrmnl_framework

## Notes

- Plugin ID: 227426
- The API response structure nests target data under `item.object` (e.g. `item.object.main_name`, `item.object.main_id`)
- Dark mode and screen padding are both disabled in settings
