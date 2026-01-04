#!/usr/bin/env node
/**
 * Generate road-accurate scenic route geometries using OSRM routing API
 *
 * This script reads waypoints from scenic-routes-waypoints.json and generates
 * high-resolution LineStrings that follow actual roads.
 */

const fs = require('fs');
const path = require('path');

const WAYPOINTS_FILE = path.join(__dirname, '../data/scenic-routes-waypoints.json');
const OUTPUT_FILE = path.join(__dirname, '../data/scenic-routes.geojson');

// OSRM public demo server - rate limit ~1 req/sec
const OSRM_URL = 'https://router.project-osrm.org/route/v1/driving';

// Delay between requests (ms) to respect rate limits
const REQUEST_DELAY = 1200;

// Target points per km (for simplification)
const TARGET_PTS_PER_KM = 5;

/**
 * Fetch route geometry from OSRM
 * @param {Array} waypoints - Array of [lon, lat] coordinates
 * @returns {Promise<Array>} - Array of coordinates forming the route
 */
async function getRouteGeometry(waypoints) {
  // Format coordinates for OSRM: lon,lat;lon,lat;lon,lat
  const coordString = waypoints.map(w => `${w[0]},${w[1]}`).join(';');
  const url = `${OSRM_URL}/${coordString}?geometries=geojson&overview=full`;

  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`OSRM request failed: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();

  if (data.code !== 'Ok') {
    throw new Error(`OSRM error: ${data.code} - ${data.message || 'Unknown error'}`);
  }

  if (!data.routes || data.routes.length === 0) {
    throw new Error('No route found');
  }

  // Return the geometry coordinates and the actual distance
  return {
    coordinates: data.routes[0].geometry.coordinates,
    distance: Math.round(data.routes[0].distance / 1000) // Convert to km
  };
}

/**
 * Sleep for specified milliseconds
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Simplify coordinates by keeping every Nth point
 * Maintains start and end points
 */
function simplifyCoordinates(coords, targetPtsPerKm, distanceKm) {
  if (coords.length <= 2) return coords;

  const targetPoints = Math.max(10, Math.round(distanceKm * targetPtsPerKm));

  if (coords.length <= targetPoints) return coords;

  const step = Math.max(1, Math.floor(coords.length / targetPoints));
  const simplified = [];

  for (let i = 0; i < coords.length; i += step) {
    simplified.push(coords[i]);
  }

  // Always include the last point
  if (simplified[simplified.length - 1] !== coords[coords.length - 1]) {
    simplified.push(coords[coords.length - 1]);
  }

  return simplified;
}

/**
 * Main function
 */
async function main() {
  console.log('Loading waypoints...');
  const waypointsData = JSON.parse(fs.readFileSync(WAYPOINTS_FILE, 'utf8'));
  const routes = waypointsData.routes;

  console.log(`Found ${routes.length} routes to process\n`);

  const features = [];
  const errors = [];

  for (let i = 0; i < routes.length; i++) {
    const route = routes[i];
    const progress = `[${i + 1}/${routes.length}]`;

    try {
      process.stdout.write(`${progress} ${route.name}... `);

      const result = await getRouteGeometry(route.waypoints);
      const originalCount = result.coordinates.length;

      // Simplify coordinates to target density
      const simplified = simplifyCoordinates(result.coordinates, TARGET_PTS_PER_KM, result.distance);
      const pointCount = simplified.length;
      const ptsPerKm = (pointCount / result.distance).toFixed(1);

      // Create GeoJSON feature
      features.push({
        type: 'Feature',
        properties: {
          id: route.id,
          name: route.name,
          country: route.country,
          region: route.region,
          length_km: result.distance,
          rating: route.rating,
          notes: route.notes,
          trip: route.trip,
          waypoint_count: route.waypoints.length,
          point_count: pointCount
        },
        geometry: {
          type: 'LineString',
          coordinates: simplified
        }
      });

      console.log(`${originalCount} → ${pointCount} pts (${ptsPerKm}/km) [${result.distance}km]`);

      // Rate limiting
      if (i < routes.length - 1) {
        await sleep(REQUEST_DELAY);
      }

    } catch (error) {
      console.log(`ERROR: ${error.message}`);
      errors.push({ route: route.name, error: error.message });

      // Still add the route with original waypoints as fallback
      features.push({
        type: 'Feature',
        properties: {
          id: route.id,
          name: route.name,
          country: route.country,
          region: route.region,
          length_km: route.length_km,
          rating: route.rating,
          notes: route.notes,
          trip: route.trip,
          waypoint_count: route.waypoints.length,
          point_count: route.waypoints.length,
          routing_error: true
        },
        geometry: {
          type: 'LineString',
          coordinates: route.waypoints
        }
      });

      await sleep(REQUEST_DELAY);
    }
  }

  // Create output GeoJSON
  const geojson = {
    type: 'FeatureCollection',
    metadata: {
      generated: new Date().toISOString(),
      source: 'OSRM routing API',
      route_count: features.length,
      total_points: features.reduce((sum, f) => sum + f.properties.point_count, 0)
    },
    features: features
  };

  // Write output
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(geojson, null, 2));

  // Summary
  console.log('\n=== SUMMARY ===');
  console.log(`Routes processed: ${features.length}`);
  console.log(`Total points: ${geojson.metadata.total_points.toLocaleString()}`);
  console.log(`Output: ${OUTPUT_FILE}`);

  if (errors.length > 0) {
    console.log(`\nErrors (${errors.length}):`);
    errors.forEach(e => console.log(`  - ${e.route}: ${e.error}`));
  }

  // Stats
  const successfulRoutes = features.filter(f => !f.properties.routing_error);
  if (successfulRoutes.length > 0) {
    const avgPtsPerRoute = Math.round(
      successfulRoutes.reduce((sum, f) => sum + f.properties.point_count, 0) / successfulRoutes.length
    );
    const totalKm = successfulRoutes.reduce((sum, f) => sum + f.properties.length_km, 0);
    const avgPtsPerKm = (successfulRoutes.reduce((sum, f) => sum + f.properties.point_count, 0) / totalKm).toFixed(1);

    console.log(`\nAverage: ${avgPtsPerRoute} pts/route, ${avgPtsPerKm} pts/km`);
    console.log(`Total distance: ${totalKm.toLocaleString()} km`);
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
