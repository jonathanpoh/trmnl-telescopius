# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

TRMNL private plugin that displays astronomy highlights from the Telescopius API on a TRMNL e-Ink display.

## Architecture

- **Strategy**: Polling — TRMNL fetches `https://api.telescopius.com/v2.0/targets/highlights` every 24 hours (1440 min) via HTTP GET
- **Auth**: `Authorization=Key <TELESCOPIUS_API_KEY>` header (key stored in `.env`)
- **Rendering**: Liquid template (`full.liquid`) receives the API response and renders it using TRMNL Framework v2.3.7 CSS/component system
- **Data path**: API JSON → `page_results` array → Liquid `{% for item in page_results %}` → e-Ink display

## File Layout

```
private_plugin_227426/
  settings.yml    # Plugin config: polling URL, headers, refresh interval, framework version
  full.liquid     # UI template rendered by TRMNL framework
.env              # TELESCOPIUS_API_KEY
PROJECT.md        # Resource links (API docs, framework docs, local dev server)
```

## Local Development

Use the TRMNL local dev server: https://github.com/usetrmnl/trmnlp

## Key References

- Telescopius API docs (Swagger): https://api.telescopius.com/
- TRMNL API docs: https://docs.trmnl.com/go/llms.txt
- TRMNL Framework (UI components/CSS): https://context7.com/websites/usetrmnl_framework

## Notes

- Plugin ID: 227426
- The API response structure nests target data under `item.object` (e.g. `item.object.main_name`, `item.object.main_id`)
- Dark mode and screen padding are both disabled in settings
