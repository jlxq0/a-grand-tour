#!/usr/bin/env node
/**
 * Analyzes proximity of sights to scenic routes
 * Identifies which sights are detours vs on-route
 */

const fs = require('fs');
const path = require('path');

// Haversine distance in km
function haversine(lon1, lat1, lon2, lat2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Distance from point to line segment
function pointToSegmentDistance(px, py, x1, y1, x2, y2) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  if (dx === 0 && dy === 0) {
    return haversine(px, py, x1, y1);
  }

  let t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);
  t = Math.max(0, Math.min(1, t));

  const nearestX = x1 + t * dx;
  const nearestY = y1 + t * dy;

  return haversine(px, py, nearestX, nearestY);
}

// Distance from point to LineString
function pointToLineDistance(point, lineCoords) {
  let minDist = Infinity;
  for (let i = 0; i < lineCoords.length - 1; i++) {
    const dist = pointToSegmentDistance(
      point[0], point[1],
      lineCoords[i][0], lineCoords[i][1],
      lineCoords[i+1][0], lineCoords[i+1][1]
    );
    minDist = Math.min(minDist, dist);
  }
  return minDist;
}

// Load scenic routes
const routesPath = path.join(__dirname, '../data/scenic-routes.geojson');
const routes = JSON.parse(fs.readFileSync(routesPath, 'utf8')).features;

console.log(`Loaded ${routes.length} scenic routes`);

// Load all sights from country files
const countriesDir = path.join(__dirname, '../data/countries');
const countryFiles = fs.readdirSync(countriesDir).filter(f => f.endsWith('.geojson'));

const sights = [];
for (const file of countryFiles) {
  const data = JSON.parse(fs.readFileSync(path.join(countriesDir, file), 'utf8'));
  for (const feature of data.features) {
    if (feature.properties.source === 'Sight' && feature.geometry?.coordinates) {
      sights.push({
        name: feature.properties.name,
        country: feature.properties.country,
        iso: feature.properties.iso,
        score: feature.properties.score,
        coords: feature.geometry.coordinates,
        category: feature.properties.category
      });
    }
  }
}

console.log(`Loaded ${sights.length} sights with coordinates`);

// Analyze each sight
const results = [];
for (const sight of sights) {
  let nearestRoute = null;
  let nearestDist = Infinity;

  for (const route of routes) {
    if (!route.geometry?.coordinates) continue;
    const dist = pointToLineDistance(sight.coords, route.geometry.coordinates);
    if (dist < nearestDist) {
      nearestDist = dist;
      nearestRoute = route.properties.name;
    }
  }

  results.push({
    ...sight,
    nearestRoute,
    distanceKm: Math.round(nearestDist)
  });
}

// Sort by distance (farthest first)
results.sort((a, b) => b.distanceKm - a.distanceKm);

// Summary stats
const THRESHOLD = 100; // km from route to be considered a detour
const detours = results.filter(r => r.distanceKm > THRESHOLD);
const onRoute = results.filter(r => r.distanceKm <= THRESHOLD);

console.log('\n=== SUMMARY ===');
console.log(`Sights within ${THRESHOLD}km of scenic route: ${onRoute.length}`);
console.log(`Sights more than ${THRESHOLD}km from route (detours): ${detours.length}`);

console.log('\n=== POTENTIAL DETOURS (>100km from any scenic route) ===');
console.log('Score | Distance | Country | Name | Nearest Route');
console.log('-'.repeat(80));

for (const sight of detours) {
  console.log(`  ${sight.score}   |  ${String(sight.distanceKm).padStart(4)}km  | ${sight.country.padEnd(15)} | ${sight.name.substring(0, 30).padEnd(30)} | ${sight.nearestRoute}`);
}

console.log('\n=== SCORE-8 DETOURS (candidates for removal) ===');
const score8Detours = detours.filter(d => d.score === 8);
console.log(`Found ${score8Detours.length} score-8 sights that are significant detours:`);
for (const sight of score8Detours) {
  console.log(`  - ${sight.name} (${sight.country}): ${sight.distanceKm}km from ${sight.nearestRoute}`);
}

console.log('\n=== SIGHTS BY REGION COVERAGE ===');
const byCountry = {};
for (const sight of results) {
  if (!byCountry[sight.country]) byCountry[sight.country] = [];
  byCountry[sight.country].push(sight);
}

for (const [country, countrySights] of Object.entries(byCountry).sort((a,b) => a[0].localeCompare(b[0]))) {
  const avgDist = Math.round(countrySights.reduce((sum, s) => sum + s.distanceKm, 0) / countrySights.length);
  const maxDist = Math.max(...countrySights.map(s => s.distanceKm));
  console.log(`${country.padEnd(20)}: ${countrySights.length} sights, avg ${avgDist}km, max ${maxDist}km from routes`);
}

// Output JSON for further analysis
const outputPath = path.join(__dirname, '../data/sight-route-analysis.json');
fs.writeFileSync(outputPath, JSON.stringify({
  summary: {
    totalSights: sights.length,
    onRouteSights: onRoute.length,
    detourSights: detours.length,
    thresholdKm: THRESHOLD
  },
  detours: detours,
  onRoute: onRoute.slice(0, 50) // First 50 closest
}, null, 2));

console.log(`\nDetailed analysis saved to ${outputPath}`);
