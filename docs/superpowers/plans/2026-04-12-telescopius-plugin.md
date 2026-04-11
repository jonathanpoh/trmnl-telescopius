# Telescopius TRMNL Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished TRMNL plugin that displays 5 highlighted deep sky objects/comets for Palmela, Portugal across all four TRMNL layout sizes.

**Architecture:** Four Liquid template files driven by a single polling URL that returns `page_results` from the Telescopius highlights API. Each template extracts catalog IDs by priority (M → NGC → C → LBN) and maps type codes to human-readable labels inline. No server-side logic — pure Liquid.

**Tech Stack:** Liquid (Shopify dialect), TRMNL Framework v3.0.3, Telescopius REST API

---

## File Map

| File | Action |
|------|--------|
| `private_plugin_227426/settings.yml` | Already updated — polling URL with params, framework 3.0.3 |
| `private_plugin_227426/full.liquid` | Rewrite |
| `private_plugin_227426/half_horizontal.liquid` | Create |
| `private_plugin_227426/half_vertical.liquid` | Create |
| `private_plugin_227426/quadrant.liquid` | Create |
| `CLAUDE.md` | Update |

**Dev workflow:** Edit locally → `./sync-trmnlp.sh` → preview at http://192.168.2.168:4567

**Reusable Liquid blocks** (repeated in each template — no partials available in TRMNL):

`display_name`:
```liquid
{%- assign display_name = item.object.main_name | default: item.object.main_id -%}
```

`catalog_ids` (max 2, priority M → NGC → C → LBN, skip if same as display_name):
```liquid
{%- assign catalog_ids = "" -%}
{%- assign id_count = 0 -%}
{%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "M" and id != display_name -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endif -%}{%- endfor -%}
{%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "NGC" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
{%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "C" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
{%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "LBN" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
```

`type_label` (scan types left-to-right, first recognised code wins):
```liquid
{%- assign type_label = "Deep Sky Object" -%}
{%- for t in item.object.types -%}
  {%- if t == "sgx" -%}{%- assign type_label = "Spiral Galaxy" -%}{%- break -%}
  {%- elsif t == "egx" -%}{%- assign type_label = "Elliptical Galaxy" -%}{%- break -%}
  {%- elsif t == "lgx" -%}{%- assign type_label = "Lenticular Galaxy" -%}{%- break -%}
  {%- elsif t == "igx" -%}{%- assign type_label = "Irregular Galaxy" -%}{%- break -%}
  {%- elsif t == "gxy" -%}{%- assign type_label = "Galaxy" -%}{%- break -%}
  {%- elsif t == "ggxs" -%}{%- assign type_label = "Galaxy Group" -%}{%- break -%}
  {%- elsif t == "eneb" -%}{%- assign type_label = "Emission Nebula" -%}{%- break -%}
  {%- elsif t == "rneb" -%}{%- assign type_label = "Reflection Nebula" -%}{%- break -%}
  {%- elsif t == "pneb" -%}{%- assign type_label = "Planetary Nebula" -%}{%- break -%}
  {%- elsif t == "dineb" -%}{%- assign type_label = "Diffuse Nebula" -%}{%- break -%}
  {%- elsif t == "snr" -%}{%- assign type_label = "Supernova Remnant" -%}{%- break -%}
  {%- elsif t == "gcl" -%}{%- assign type_label = "Globular Cluster" -%}{%- break -%}
  {%- elsif t == "ocl" or t == "opcl" -%}{%- assign type_label = "Open Cluster" -%}{%- break -%}
  {%- elsif t == "comet" -%}{%- assign type_label = "Comet" -%}{%- break -%}
  {%- endif -%}
{%- endfor -%}
```

`title_bar` (required on all layouts):
```liquid
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

---

## Task 1: Write `full.liquid`

**Files:**
- Modify: `private_plugin_227426/full.liquid`

5 objects. Two-line item: name + up to 2 catalog IDs on line 1; type (gray) + constellation (gray) + magnitude + visibility window on line 2.

- [ ] **Step 1: Write the template**

Replace the entire contents of `private_plugin_227426/full.liquid` with:

```liquid
<div class="layout layout--col">
  <div class="columns">
    <div class="column">
      {%- for item in page_results limit:5 -%}
        {%- assign display_name = item.object.main_name | default: item.object.main_id -%}
        {%- assign catalog_ids = "" -%}
        {%- assign id_count = 0 -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "M" and id != display_name -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "NGC" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "C" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "LBN" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- assign type_label = "Deep Sky Object" -%}
        {%- for t in item.object.types -%}
          {%- if t == "sgx" -%}{%- assign type_label = "Spiral Galaxy" -%}{%- break -%}
          {%- elsif t == "egx" -%}{%- assign type_label = "Elliptical Galaxy" -%}{%- break -%}
          {%- elsif t == "lgx" -%}{%- assign type_label = "Lenticular Galaxy" -%}{%- break -%}
          {%- elsif t == "igx" -%}{%- assign type_label = "Irregular Galaxy" -%}{%- break -%}
          {%- elsif t == "gxy" -%}{%- assign type_label = "Galaxy" -%}{%- break -%}
          {%- elsif t == "ggxs" -%}{%- assign type_label = "Galaxy Group" -%}{%- break -%}
          {%- elsif t == "eneb" -%}{%- assign type_label = "Emission Nebula" -%}{%- break -%}
          {%- elsif t == "rneb" -%}{%- assign type_label = "Reflection Nebula" -%}{%- break -%}
          {%- elsif t == "pneb" -%}{%- assign type_label = "Planetary Nebula" -%}{%- break -%}
          {%- elsif t == "dineb" -%}{%- assign type_label = "Diffuse Nebula" -%}{%- break -%}
          {%- elsif t == "snr" -%}{%- assign type_label = "Supernova Remnant" -%}{%- break -%}
          {%- elsif t == "gcl" -%}{%- assign type_label = "Globular Cluster" -%}{%- break -%}
          {%- elsif t == "ocl" or t == "opcl" -%}{%- assign type_label = "Open Cluster" -%}{%- break -%}
          {%- elsif t == "comet" -%}{%- assign type_label = "Comet" -%}{%- break -%}
          {%- endif -%}
        {%- endfor -%}
        <div class="item item--emphasis-1">
          <div class="meta"><span class="index">{{ forloop.index }}</span></div>
          <div class="content">
            <span class="title title--small" data-clamp="1">{{ display_name }}{% if catalog_ids != "" %} · {{ catalog_ids }}{% endif %}</span>
            <div class="flex gap--xsmall">
              <span class="label label--small label--gray">{{ type_label }}</span>
              <span class="label label--small label--gray">{{ item.object.con_name }}</span>
              {%- if item.object.visual_mag -%}<span class="label label--small">Mag {{ item.object.visual_mag }}</span>{%- endif -%}
              {%- if item.tonight_times.rise -%}<span class="label label--small">{{ item.tonight_times.rise }} – {{ item.tonight_times.set }}</span>{%- endif -%}
            </div>
          </div>
        </div>
      {%- endfor -%}
    </div>
  </div>
</div>
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

- [ ] **Step 2: Sync and verify**

```bash
./sync-trmnlp.sh
```

Open http://192.168.2.168:4567 and confirm:
- 5 objects listed with index numbers 1–5
- Line 1: common name + catalog IDs (e.g. `Sombrero Galaxy · M 104 · NGC 4594`)
- Line 2: type in gray + constellation in gray + magnitude + visibility window (e.g. `Spiral Galaxy · Virgo · Mag 8 · 21:30 – 04:28`)
- Title bar shows "Powered by Telescopius" on the right

- [ ] **Step 3: Commit**

```bash
git -C /Users/jpoh/Projects/trmnl-telescopius add private_plugin_227426/full.liquid private_plugin_227426/settings.yml
git -C /Users/jpoh/Projects/trmnl-telescopius commit -m "feat: rewrite full layout with two-line item design"
```

---

## Task 2: Write `half_horizontal.liquid`

**Files:**
- Create: `private_plugin_227426/half_horizontal.liquid`

5 objects. Same two-line layout as full, but constellation dropped (too wide for half-width).

- [ ] **Step 1: Write the template**

Create `private_plugin_227426/half_horizontal.liquid`:

```liquid
<div class="layout layout--col">
  <div class="columns">
    <div class="column">
      {%- for item in page_results limit:5 -%}
        {%- assign display_name = item.object.main_name | default: item.object.main_id -%}
        {%- assign catalog_ids = "" -%}
        {%- assign id_count = 0 -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "M" and id != display_name -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "NGC" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "C" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 2 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "LBN" and id != display_name -%}{%- unless catalog_ids contains id -%}{%- if catalog_ids == "" -%}{%- assign catalog_ids = id -%}{%- else -%}{%- assign catalog_ids = catalog_ids | append: " · " | append: id -%}{%- endif -%}{%- assign id_count = id_count | plus: 1 -%}{%- endunless -%}{%- endif -%}{%- endfor -%}
        {%- assign type_label = "Deep Sky Object" -%}
        {%- for t in item.object.types -%}
          {%- if t == "sgx" -%}{%- assign type_label = "Spiral Galaxy" -%}{%- break -%}
          {%- elsif t == "egx" -%}{%- assign type_label = "Elliptical Galaxy" -%}{%- break -%}
          {%- elsif t == "lgx" -%}{%- assign type_label = "Lenticular Galaxy" -%}{%- break -%}
          {%- elsif t == "igx" -%}{%- assign type_label = "Irregular Galaxy" -%}{%- break -%}
          {%- elsif t == "gxy" -%}{%- assign type_label = "Galaxy" -%}{%- break -%}
          {%- elsif t == "ggxs" -%}{%- assign type_label = "Galaxy Group" -%}{%- break -%}
          {%- elsif t == "eneb" -%}{%- assign type_label = "Emission Nebula" -%}{%- break -%}
          {%- elsif t == "rneb" -%}{%- assign type_label = "Reflection Nebula" -%}{%- break -%}
          {%- elsif t == "pneb" -%}{%- assign type_label = "Planetary Nebula" -%}{%- break -%}
          {%- elsif t == "dineb" -%}{%- assign type_label = "Diffuse Nebula" -%}{%- break -%}
          {%- elsif t == "snr" -%}{%- assign type_label = "Supernova Remnant" -%}{%- break -%}
          {%- elsif t == "gcl" -%}{%- assign type_label = "Globular Cluster" -%}{%- break -%}
          {%- elsif t == "ocl" or t == "opcl" -%}{%- assign type_label = "Open Cluster" -%}{%- break -%}
          {%- elsif t == "comet" -%}{%- assign type_label = "Comet" -%}{%- break -%}
          {%- endif -%}
        {%- endfor -%}
        <div class="item item--emphasis-1">
          <div class="meta"><span class="index">{{ forloop.index }}</span></div>
          <div class="content">
            <span class="title title--small" data-clamp="1">{{ display_name }}{% if catalog_ids != "" %} · {{ catalog_ids }}{% endif %}</span>
            <div class="flex gap--xsmall">
              <span class="label label--small label--gray">{{ type_label }}</span>
              {%- if item.object.visual_mag -%}<span class="label label--small">Mag {{ item.object.visual_mag }}</span>{%- endif -%}
              {%- if item.tonight_times.rise -%}<span class="label label--small">{{ item.tonight_times.rise }} – {{ item.tonight_times.set }}</span>{%- endif -%}
            </div>
          </div>
        </div>
      {%- endfor -%}
    </div>
  </div>
</div>
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

- [ ] **Step 2: Sync and verify**

```bash
./sync-trmnlp.sh
```

Switch to the half_horizontal layout in the trmnlp preview. Confirm:
- 5 objects listed
- Constellation absent from line 2
- Otherwise same as full layout

- [ ] **Step 3: Commit**

```bash
git -C /Users/jpoh/Projects/trmnl-telescopius add private_plugin_227426/half_horizontal.liquid
git -C /Users/jpoh/Projects/trmnl-telescopius commit -m "feat: add half_horizontal layout"
```

---

## Task 3: Write `half_vertical.liquid`

**Files:**
- Create: `private_plugin_227426/half_vertical.liquid`

3 objects. 1 catalog ID max (narrower column). No constellation.

- [ ] **Step 1: Write the template**

Create `private_plugin_227426/half_vertical.liquid`:

```liquid
<div class="layout layout--col">
  <div class="columns">
    <div class="column">
      {%- for item in page_results limit:3 -%}
        {%- assign display_name = item.object.main_name | default: item.object.main_id -%}
        {%- assign catalog_ids = "" -%}
        {%- assign id_count = 0 -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "M" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "NGC" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "C" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "LBN" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- assign type_label = "Deep Sky Object" -%}
        {%- for t in item.object.types -%}
          {%- if t == "sgx" -%}{%- assign type_label = "Spiral Galaxy" -%}{%- break -%}
          {%- elsif t == "egx" -%}{%- assign type_label = "Elliptical Galaxy" -%}{%- break -%}
          {%- elsif t == "lgx" -%}{%- assign type_label = "Lenticular Galaxy" -%}{%- break -%}
          {%- elsif t == "igx" -%}{%- assign type_label = "Irregular Galaxy" -%}{%- break -%}
          {%- elsif t == "gxy" -%}{%- assign type_label = "Galaxy" -%}{%- break -%}
          {%- elsif t == "ggxs" -%}{%- assign type_label = "Galaxy Group" -%}{%- break -%}
          {%- elsif t == "eneb" -%}{%- assign type_label = "Emission Nebula" -%}{%- break -%}
          {%- elsif t == "rneb" -%}{%- assign type_label = "Reflection Nebula" -%}{%- break -%}
          {%- elsif t == "pneb" -%}{%- assign type_label = "Planetary Nebula" -%}{%- break -%}
          {%- elsif t == "dineb" -%}{%- assign type_label = "Diffuse Nebula" -%}{%- break -%}
          {%- elsif t == "snr" -%}{%- assign type_label = "Supernova Remnant" -%}{%- break -%}
          {%- elsif t == "gcl" -%}{%- assign type_label = "Globular Cluster" -%}{%- break -%}
          {%- elsif t == "ocl" or t == "opcl" -%}{%- assign type_label = "Open Cluster" -%}{%- break -%}
          {%- elsif t == "comet" -%}{%- assign type_label = "Comet" -%}{%- break -%}
          {%- endif -%}
        {%- endfor -%}
        <div class="item item--emphasis-1">
          <div class="meta"><span class="index">{{ forloop.index }}</span></div>
          <div class="content">
            <span class="title title--small" data-clamp="1">{{ display_name }}{% if catalog_ids != "" %} · {{ catalog_ids }}{% endif %}</span>
            <div class="flex gap--xsmall">
              <span class="label label--small label--gray">{{ type_label }}</span>
              {%- if item.object.visual_mag -%}<span class="label label--small">Mag {{ item.object.visual_mag }}</span>{%- endif -%}
              {%- if item.tonight_times.rise -%}<span class="label label--small">{{ item.tonight_times.rise }} – {{ item.tonight_times.set }}</span>{%- endif -%}
            </div>
          </div>
        </div>
      {%- endfor -%}
    </div>
  </div>
</div>
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

- [ ] **Step 2: Sync and verify**

```bash
./sync-trmnlp.sh
```

Switch to the half_vertical layout in trmnlp. Confirm:
- 3 objects (not 5)
- 1 catalog ID per object (not 2)
- No constellation

- [ ] **Step 3: Commit**

```bash
git -C /Users/jpoh/Projects/trmnl-telescopius add private_plugin_227426/half_vertical.liquid
git -C /Users/jpoh/Projects/trmnl-telescopius commit -m "feat: add half_vertical layout"
```

---

## Task 4: Write `quadrant.liquid`

**Files:**
- Create: `private_plugin_227426/quadrant.liquid`

3 objects. Name + 1 catalog ID + magnitude only. No index, no type, no constellation, no times.

- [ ] **Step 1: Write the template**

Create `private_plugin_227426/quadrant.liquid`:

```liquid
<div class="layout layout--col">
  <div class="columns">
    <div class="column">
      {%- for item in page_results limit:3 -%}
        {%- assign display_name = item.object.main_name | default: item.object.main_id -%}
        {%- assign catalog_ids = "" -%}
        {%- assign id_count = 0 -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "M" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "NGC" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "C" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        {%- for id in item.object.ids -%}{%- if id_count >= 1 -%}{%- break -%}{%- endif -%}{%- assign p = id | split: " " -%}{%- if p[0] == "LBN" and id != display_name -%}{%- assign catalog_ids = id -%}{%- assign id_count = 1 -%}{%- endif -%}{%- endfor -%}
        <div class="item">
          <div class="content">
            <div class="flex gap--xsmall">
              <span class="label label--small" data-clamp="1">{{ display_name }}{% if catalog_ids != "" %} · {{ catalog_ids }}{% endif %}</span>
              {%- if item.object.visual_mag -%}<span class="label label--small label--gray">Mag {{ item.object.visual_mag }}</span>{%- endif -%}
            </div>
          </div>
        </div>
      {%- endfor -%}
    </div>
  </div>
</div>
<div class="title_bar">
  <img class="image" src="https://usetrmnl.com/images/plugins/trmnl--render.svg">
  <span class="title">{{ trmnl.plugin_settings.instance_name }}</span>
  <span class="instance">Powered by Telescopius</span>
</div>
```

- [ ] **Step 2: Sync and verify**

```bash
./sync-trmnlp.sh
```

Switch to the quadrant layout in trmnlp. Confirm:
- 3 objects, single line each
- Name + 1 catalog ID + magnitude
- No index number, no type label, no times

- [ ] **Step 3: Commit**

```bash
git -C /Users/jpoh/Projects/trmnl-telescopius add private_plugin_227426/quadrant.liquid
git -C /Users/jpoh/Projects/trmnl-telescopius commit -m "feat: add quadrant layout"
```

---

## Task 5: Update `CLAUDE.md` and final packaging

**Files:**
- Modify: `CLAUDE.md`
- Create: `private_plugin_227426.zip` (re-zip for upload)

- [ ] **Step 1: Update CLAUDE.md**

Update the Architecture and File Layout sections in `CLAUDE.md` to reflect:
- Framework v3.0.3
- Correct polling URL with query params
- Four template files (`full.liquid`, `half_horizontal.liquid`, `half_vertical.liquid`, `quadrant.liquid`)
- Data path notes: `page_results` array key, catalog ID priority logic (M → NGC → C → LBN)
- Dev workflow: `./sync-trmnlp.sh` → http://192.168.2.168:4567

- [ ] **Step 2: Re-zip the plugin**

```bash
cd /Users/jpoh/Projects/trmnl-telescopius
zip -r private_plugin_227426.zip private_plugin_227426/
```

- [ ] **Step 3: Commit**

```bash
git -C /Users/jpoh/Projects/trmnl-telescopius add CLAUDE.md private_plugin_227426.zip
git -C /Users/jpoh/Projects/trmnl-telescopius commit -m "docs: update CLAUDE.md; repackage plugin zip"
```

- [ ] **Step 4: Upload and verify on device**

1. Upload `private_plugin_227426.zip` to TRMNL dashboard
2. Trigger force refresh
3. Confirm debug log shows data in `merge_variables` (no longer empty)
4. Confirm all 4 layout types render correctly on the physical device
