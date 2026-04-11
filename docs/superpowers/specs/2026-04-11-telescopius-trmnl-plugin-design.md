# Telescopius TRMNL Plugin — Design Spec

**Date:** 2026-04-11
**Status:** Approved

## Overview

A TRMNL private plugin that displays tonight's highlighted astronomy objects from the Telescopius API on an e-ink display. Shows up to 5 deep sky objects and comets best positioned for observation from Palmela, Portugal, with glanceable info: name, catalog IDs, object type, magnitude, and visibility window.

Future goal: release to TRMNL plugin marketplace (requires server-side third-party plugin architecture — out of scope for this spec).

---

## API & Data

### Polling Configuration

- **Endpoint:** `GET https://api.telescopius.com/v2.0/targets/highlights`
- **Refresh interval:** 1440 minutes (daily)
- **Framework version:** 3.0.3
- **Auth header:** `Authorization=Key <API_KEY>`

**Query parameters:**
| Parameter | Value | Reason |
|-----------|-------|--------|
| `types` | `DEEP_SKY_OBJECT,COMET` | Covers galaxies, nebulae, clusters, comets |
| `lat` | `38.563` | Palmela, Portugal |
| `lon` | `-8.881` | Palmela, Portugal |
| `timezone` | `Europe/Lisbon` | Correct rise/set times |
| `min_alt` | `20` | Only objects reaching 20°+ above horizon |
| `time_format` | `24hr` | 24-hour clock |
| `compute_current` | `1` | Include current sky position data |

### Response Structure

The API returns `{ matched: N, page_results: [...] }`. Each item:

```json
{
  "object": {
    "main_id": "M 104",
    "main_name": "Sombrero Galaxy",
    "ids": ["M 104", "NGC 4594", "MCG -02-32-020", "PGC 42407", ...],
    "names": ["Sombrero Galaxy"],
    "types": ["sgx", "gxy", "deep_sky_object", ...],
    "con_name": "Virgo",
    "visual_mag": 8
  },
  "tonight_times": {
    "rise": "21:30",
    "transit": "00:53",
    "set": "04:28"
  }
}
```

### Data Processing Rules

**Display name:** Use `object.main_name` if present, else `object.main_id`.

**Catalog IDs:** Extract up to 2 from `object.ids` using this priority order:
1. Messier (prefix `M `)
2. NGC (prefix `NGC `)
3. Caldwell (prefix `C `)
4. LBN (prefix `LBN `)

Skip any ID that duplicates the display name. Show 0–2 IDs depending on what's available.

**Object type:** Scan `object.types` left-to-right, map first recognised code:

| Code(s) | Label |
|---------|-------|
| `sgx` | Spiral Galaxy |
| `egx` | Elliptical Galaxy |
| `lgx` | Lenticular Galaxy |
| `igx` | Irregular Galaxy |
| `gxy` | Galaxy |
| `ggxs` | Galaxy Group |
| `eneb` | Emission Nebula |
| `rneb` | Reflection Nebula |
| `pneb` | Planetary Nebula |
| `dineb` | Diffuse Nebula |
| `snr` | Supernova Remnant |
| `gcl` | Globular Cluster |
| `ocl`, `opcl` | Open Cluster |
| `comet` | Comet |
| fallback | Deep Sky Object |

**Magnitude:** `object.visual_mag` displayed as `Mag X.X`. Omitted if null (some comets).

**Visibility window:** `tonight_times.rise` – `tonight_times.set` displayed as `Visible HH:MM – HH:MM`. Transit time not shown (not useful for glanceable display).

---

## Layout Templates

All four templates live in `private_plugin_227426/`. The TRMNL platform automatically wraps content in the appropriate `<div class="view view--X">`, so templates begin with `<div class="layout">`.

### Component Pattern (Option A — Compact Two-Line)

Each object uses the TRMNL v3 `.item` component:
- `.meta` — index number (1–5)
- `.content` — two lines of info

**Line 1 (title):** `Name · CatalogID1 · CatalogID2`
**Line 2 (labels):** `Type · Constellation · Mag X.X · Visible HH:MM – HH:MM`

Type label uses `label--gray` for mid-gray on 2-bit displays; degrades to standard rendering on 1-bit displays. `item--emphasis-1` on the meta bar provides subtle shading on 2-bit.

### `full.liquid` — 5 objects, full detail

- 5 items (`limit:5`)
- Line 1: name + up to 2 catalog IDs
- Line 2: type (gray) · constellation · magnitude · visibility window

### `half_horizontal.liquid` — 5 objects, no constellation

- 5 items (`limit:5`)
- Line 1: name + up to 2 catalog IDs
- Line 2: type (gray) · magnitude · visibility window

### `half_vertical.liquid` — 3 objects, 1 catalog ID

- 3 items (`limit:3`)
- Line 1: name + 1 catalog ID (M or NGC priority)
- Line 2: type (gray) · magnitude · visibility window

### `quadrant.liquid` — 3 objects, minimal

- 3 items (`limit:3`)
- Simple `.item` (no meta/index)
- Single line: name · 1 catalog ID · magnitude
- No type, constellation, or visibility times

### Title Bar (all layouts)

```html
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

Attribution is required by Telescopius Terms & Conditions.

---

## Files

| File | Change |
|------|--------|
| `private_plugin_227426/settings.yml` | Update `polling_url` with query params; bump `framework_version` to `3.0.3` |
| `private_plugin_227426/full.liquid` | Rewrite |
| `private_plugin_227426/half_horizontal.liquid` | Create |
| `private_plugin_227426/half_vertical.liquid` | Create |
| `private_plugin_227426/quadrant.liquid` | Create |
| `CLAUDE.md` | Update to reflect new structure and API details |

---

## Verification

1. Re-zip `private_plugin_227426/` and upload to TRMNL
2. Force refresh from TRMNL dashboard
3. Confirm debug log shows data in `merge_variables` (was empty before due to missing query params)
4. Verify all 4 layout types render correctly on device
5. Confirm attribution "Powered by Telescopius" appears in title bar
