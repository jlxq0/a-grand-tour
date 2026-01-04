#!/usr/bin/env node
/**
 * Screenshot all scenic routes for visual verification
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const SCENIC_ROUTES_FILE = path.join(__dirname, '../data/scenic-routes.geojson');
const OUTPUT_DIR = path.join(__dirname, '../route-screenshots');

// Calculate center and bounds of a route
function getRouteCenter(coordinates) {
  let minLon = Infinity, maxLon = -Infinity;
  let minLat = Infinity, maxLat = -Infinity;

  for (const [lon, lat] of coordinates) {
    minLon = Math.min(minLon, lon);
    maxLon = Math.max(maxLon, lon);
    minLat = Math.min(minLat, lat);
    maxLat = Math.max(maxLat, lat);
  }

  return {
    center: [(minLon + maxLon) / 2, (minLat + maxLat) / 2],
    bounds: { minLon, maxLon, minLat, maxLat }
  };
}

// Calculate appropriate zoom level based on route extent
function getZoomLevel(bounds) {
  const lonSpan = bounds.maxLon - bounds.minLon;
  const latSpan = bounds.maxLat - bounds.minLat;
  const maxSpan = Math.max(lonSpan, latSpan);

  if (maxSpan > 20) return 4;
  if (maxSpan > 10) return 5;
  if (maxSpan > 5) return 6;
  if (maxSpan > 2) return 7;
  if (maxSpan > 1) return 8;
  if (maxSpan > 0.5) return 9;
  if (maxSpan > 0.2) return 10;
  return 11;
}

async function main() {
  // Ensure output directory exists
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Load routes
  const geojson = JSON.parse(fs.readFileSync(SCENIC_ROUTES_FILE, 'utf8'));
  const routes = geojson.features;

  console.log(`Screenshotting ${routes.length} routes...`);

  // Launch browser
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1200, height: 800 } });
  const page = await context.newPage();

  // Navigate to map
  await page.goto('http://localhost:8080/map.html');
  await page.waitForTimeout(3000); // Wait for map to load

  // Turn off non-scenic layers for clarity
  await page.evaluate(() => {
    if (typeof map !== 'undefined') {
      // Hide other layers to focus on scenic routes
      try {
        map.setLayoutProperty('sights', 'visibility', 'none');
        map.setLayoutProperty('hotels', 'visibility', 'none');
        map.setLayoutProperty('food', 'visibility', 'none');
        map.setLayoutProperty('driving-routes', 'visibility', 'none');
      } catch (e) {}
    }
  });

  for (let i = 0; i < routes.length; i++) {
    const route = routes[i];
    const { center, bounds } = getRouteCenter(route.geometry.coordinates);
    const zoom = getZoomLevel(bounds);
    const name = route.properties.name;
    const id = route.properties.id;

    process.stdout.write(`[${i + 1}/${routes.length}] ${name}... `);

    // Fly to route
    await page.evaluate(({ center, zoom }) => {
      map.flyTo({ center, zoom, duration: 0 });
    }, { center, zoom });

    await page.waitForTimeout(500); // Wait for map to render

    // Take screenshot
    const filename = `${String(i + 1).padStart(3, '0')}-${id}.png`;
    await page.screenshot({ path: path.join(OUTPUT_DIR, filename) });

    console.log(`saved`);
  }

  await browser.close();

  console.log(`\nDone! Screenshots saved to ${OUTPUT_DIR}`);
  console.log(`Open the folder to visually verify all routes.`);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
