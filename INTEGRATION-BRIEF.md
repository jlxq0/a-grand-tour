# A Grand Tour — Integration Brief for Kampong Social Club

## Executive Summary

"A Grand Tour" is a trip planning dataset and prototype web application for a 13-year around-the-world overland expedition (2027–2039). The goal is to integrate this as a component within the Kampong Social Club web application — essentially a "Trip Planning" or "Adventure" module.

**Repository:** https://github.com/jlxq0/a-grand-tour

---

## What This Project Contains

### 1. Trip Data (25 trips across 100+ countries)

| Data Type | Location | Format | Description |
|-----------|----------|--------|-------------|
| **Routes** | `data/routes/trip-{01-25}.geojson` | GeoJSON LineString | Detailed driving routes with segment-by-segment waypoints, distances, and durations |
| **POIs** | `data/pois/{country-code}.geojson` | GeoJSON Point | ~1,000+ points of interest organized by country (landmarks, nature, culture, etc.) |
| **POI Images** | `data/pois/images/{country-code}/` | WebP | Downloaded images for POIs (~670 MB total) |
| **Scenic Routes** | `data/scenic-routes/*.geojson` | GeoJSON LineString | 118 world-famous scenic drives with ratings |
| **Scenic Images** | `data/scenic-routes/images/` | WebP + Attribution | Photos for scenic routes |
| **Ferries** | `data/ferries/*.geojson` | GeoJSON LineString | Ferry crossings (e.g., Dover-Calais) |
| **Shipping** | `data/shipping/*.geojson` | GeoJSON LineString | Car shipping routes (8 ocean crossings) |
| **Risk Regions** | `data/risk-regions.geojson` | GeoJSON Polygon | "Impossible" (red) and "Problematic" (orange) zones |
| **Safe Corridors** | `data/safe-corridors/*.geojson` | GeoJSON LineString | Pre-planned routes through higher-risk areas |

### 2. Documentation (Markdown)

| File | Purpose |
|------|---------|
| `README.md` | Master planning document — route, schedule, budget, vehicle specs |
| `CARNET.md` | Customs documentation guide for vehicle import |
| `TRIP{01-12}.md` | Detailed day-by-day itineraries for trips 1-12 |

### 3. Prototype Web Application

| File | Description |
|------|-------------|
| `index.html` | Single-page app with Mapbox GL JS globe visualization |
| `map.html` | Alternative simpler map view |

**Current Features:**
- Interactive 3D globe with all 25 trip routes
- POI markers with popups (name, description, images)
- Scenic routes overlay
- Risk zone visualization (red/orange overlays)
- Ferry and shipping route display
- Markdown content rendering for trip details
- Timeline view showing all trips
- Dark/light mode toggle
- Trip filtering by number

---

## Data Schemas

### Route GeoJSON (`data/routes/trip-XX.geojson`)

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Trip 25: Al-Ula to Dubai",
        "part": 25,
        "type": "summary",
        "totalDistanceKm": 3627,
        "totalDurationHrs": 44.6,
        "segmentCount": 10
      },
      "geometry": { "type": "LineString", "coordinates": [[lon, lat], ...] }
    },
    {
      "type": "Feature",
      "properties": {
        "part": 25,
        "segmentIndex": 0,
        "from": "Al-Ula",
        "to": "Wadi Al-Disah",
        "distanceKm": 272,
        "durationHrs": 5.0,
        "label": "Al-Ula → Wadi Al-Disah"
      },
      "geometry": { "type": "LineString", "coordinates": [...] }
    }
  ]
}
```

### POI GeoJSON (`data/pois/{country}.geojson`)

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Petra",
        "country": "Jordan",
        "countryCode": "JO",
        "category": "landmark",  // landmark, natural, cultural, extreme, etc.
        "rating": 5,             // 1-5 stars
        "description": "Rose-red city half-carved into rock...",
        "images": ["petra-1.webp", "petra-2.webp"]  // optional
      },
      "geometry": { "type": "Point", "coordinates": [35.4444, 30.3285] }
    }
  ]
}
```

### Scenic Route GeoJSON (`data/scenic-routes/*.geojson`)

```json
{
  "type": "Feature",
  "properties": {
    "name": "Great Ocean Road",
    "countryCode": "AU",
    "country": "Australia",
    "rating": 5,
    "description": "242 km - Twelve Apostles, Loch Ard Gorge."
  },
  "geometry": { "type": "LineString", "coordinates": [...] }
}
```

### Risk Region GeoJSON (`data/risk-regions.geojson`)

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Tigray & Amhara (Ethiopia)",
        "risk": "impossible",  // "impossible" or "problematic"
        "reason": "Ongoing civil conflict"
      },
      "geometry": { "type": "Polygon", "coordinates": [...] }
    }
  ]
}
```

---

## Trip Schedule Overview

**Phase A (2027–2033):** 13 trips, ~3-4 months each, pre-school years
**Phase B (2034–2039):** 12 trips during school holidays (Easter/Summer/Christmas)

| Trip | Dates | Route | Distance |
|------|-------|-------|----------|
| 1 | Feb–May 2027 | Dubai → Iran → Pakistan → India | 10,780 km |
| 2 | Aug–Nov 2027 | India → Nepal → Bangladesh | 17,460 km |
| 3 | Jan–Apr 2028 | Thailand → Vietnam → Malaysia | 9,200 km |
| 4 | Aug–Nov 2028 | Indonesia → Timor-Leste → Australia | 22,000 km |
| 5 | Feb–Apr 2029 | New Zealand | 6,500 km |
| 6 | Aug–Nov 2029 | Chile → Argentina → Colombia | 25,000 km |
| 7 | Feb–May 2030 | Panama → Mexico → LA | 14,500 km |
| 8 | Sep–Dec 2030 | LA → Alaska → Seattle | 15,000 km |
| 9 | Feb–May 2031 | Seattle → Texas | 15,000 km |
| 10 | Aug–Nov 2031 | Texas → Toronto → Jacksonville | 13,000 km |
| 11 | Feb–May 2032 | Dublin → Helsinki | 7,000 km |
| 12 | Aug–Oct 2032 | Helsinki → Vienna | 6,000 km |
| 13 | Feb–May 2033 | Vienna → Athens | 5,500 km |
| 14–25 | 2034–2039 | Europe → Africa → Dubai | ~50,000 km |

**Total:** ~200,000 km over 25 trips

---

## Integration Recommendations

### Option A: Standalone Page/Section
Add "A Grand Tour" as a dedicated section in Kampong Social Club, similar to how other projects are showcased.

### Option B: Trip Planning Module
Extract the mapping and data visualization components into a reusable trip planning module that could be used for other adventures.

### Key Components to Integrate

1. **Map Component**
   - Mapbox GL JS globe with custom styling
   - Route rendering (LineString)
   - POI markers with clustering
   - Risk zone overlays
   - Interactive popups

2. **Data Layer**
   - GeoJSON loading and parsing
   - Trip filtering by number/date
   - POI search/filter by category/country

3. **Content Layer**
   - Markdown rendering for trip details
   - Timeline visualization
   - Budget/stats display

4. **Assets**
   - POI images (~670 MB, could be served from CDN)
   - Scenic route images (~53 MB)

---

## Technical Notes

### Current Dependencies
- **Mapbox GL JS v3.0.1** — Interactive maps
- **marked.js** — Markdown parsing
- No build system (vanilla HTML/CSS/JS)

### Data Size
```
Routes:     347 MB (can be lazy-loaded per trip)
POIs:       254 MB (includes images)
Scenic:      53 MB
Other:       16 MB
Total:     ~670 MB
```

### Build Scripts
- `scripts/build-planned-route.js` — Generates route GeoJSONs from waypoints using OSRM
- `scripts/download-poi-images.js` — Downloads POI images from various sources

---

## What the Development Team Needs

1. **Access to this repository** — https://github.com/jlxq0/a-grand-tour

2. **Design direction** — How should this integrate with Kampong Social Club's existing design system?

3. **Data hosting strategy** — Where to host the large GeoJSON and image files (CDN? Lazy loading?)

4. **Feature scope** — Full interactive trip planner vs. read-only showcase?

5. **Authentication** — Should trip data be public or require login?

---

## Questions for Planning

1. Should users be able to edit/customize trips, or is this read-only?
2. Should this be a separate route (`/grand-tour`) or integrated into existing navigation?
3. Do we want to preserve the globe visualization or use a different map style?
4. Should the detailed markdown content (TRIP01.md, etc.) be converted to a CMS?
5. Mobile experience — responsive web or native app considerations?

---

## Files to Review First

1. `README.md` — Full project overview
2. `index.html` — Current prototype (run locally with `python -m http.server`)
3. `CARNET.md` — Example of detailed documentation
4. `data/routes/trip-01.geojson` — Route data structure
5. `data/pois/jo.geojson` — POI data structure

---

*Generated: January 2025*
