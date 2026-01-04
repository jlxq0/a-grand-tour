#!/usr/bin/env node
/**
 * Build trip routes by connecting Route stops in the correct country order
 * Sights are NOT included in the route lines - they're just markers to visit
 */

const fs = require('fs');
const path = require('path');

// Trip country order - based on actual data and geographic flow
const TRIP_COUNTRY_ORDER = {
  1: ['AE', 'QA', 'BH', 'OM', 'IR', 'PK', 'IN'],
  2: ['IN', 'NP', 'BD'],
  3: ['TH', 'LA', 'KH', 'VN', 'MY'],
  4: ['ID', 'TL', 'AU'],
  5: ['NZ'],
  6: ['CL', 'AR', 'UY'],
  7: ['AR', 'PY', 'BR', 'GY', 'SR', 'GF', 'BO', 'PE'],
  8: ['PE', 'EC', 'CO', 'PA', 'CR', 'NI', 'HN', 'SV', 'GT'],
  9: ['BZ', 'MX'],
  10: ['MX', 'US'],
  11: ['US', 'CA'],
  12: ['CA', 'US'],
  13: ['GB', 'IE', 'FR', 'BE', 'NL', 'LU', 'DE', 'CH'],
  14: ['NO', 'SE', 'FI', 'EE', 'LV', 'LT', 'DK'],
  15: ['PL', 'CZ', 'SK', 'AT', 'HU', 'SI', 'HR', 'BA', 'ME'],
  16: ['XK', 'RS', 'MK', 'AL', 'BG', 'RO', 'MD', 'TR', 'GE'],
  17: ['AM', 'AZ', 'GR', 'IT', 'ES', 'GI', 'MA'],
  18: ['MA', 'EH', 'MR', 'SN', 'GM', 'GW', 'GN', 'SL', 'LR', 'CI', 'GH'],
  19: ['GH', 'TG', 'BJ', 'NG', 'CM', 'GQ', 'GA', 'CG', 'CD', 'AO', 'NA', 'BW', 'ZM', 'ZW', 'ZA'],
  20: ['ZA', 'LS', 'SZ', 'MZ', 'MW', 'TZ', 'BI', 'RW', 'UG', 'KE', 'ET'],
  21: ['ET', 'ER', 'SD', 'EG', 'JO', 'SA', 'KW', 'AE']
};

// Haversine distance in km
function haversine(lon1, lat1, lon2, lat2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

function distance(p1, p2) {
  return haversine(p1[0], p1[1], p2[0], p2[1]);
}

// Load all Route stops from country files
function loadRouteStops() {
  const countriesDir = path.join(__dirname, '../data/countries');
  const files = fs.readdirSync(countriesDir).filter(f => f.endsWith('.geojson'));

  const stops = [];
  for (const file of files) {
    const data = JSON.parse(fs.readFileSync(path.join(countriesDir, file), 'utf8'));
    for (const f of data.features) {
      if (f.properties.source === 'Route' && f.geometry?.coordinates) {
        stops.push({
          name: f.properties.name,
          country: f.properties.country,
          iso: f.properties.iso,
          trip: f.properties.trip,
          coords: f.geometry.coordinates,
          category: f.properties.category || 'Stop'
        });
      }
    }
  }
  return stops;
}

// Load all Sights from country files
function loadSights() {
  const countriesDir = path.join(__dirname, '../data/countries');
  const files = fs.readdirSync(countriesDir).filter(f => f.endsWith('.geojson'));

  const sights = [];
  for (const file of files) {
    const data = JSON.parse(fs.readFileSync(path.join(countriesDir, file), 'utf8'));
    for (const f of data.features) {
      if (f.properties.source === 'Sight' && f.geometry?.coordinates) {
        sights.push({
          name: f.properties.name,
          country: f.properties.country,
          iso: f.properties.iso,
          score: f.properties.score,
          coords: f.geometry.coordinates,
          category: f.properties.category,
          why_notable: f.properties.why_notable
        });
      }
    }
  }
  return sights;
}

// Order stops within a trip by the country sequence
function orderStopsByCountrySequence(stops, tripNum) {
  const countryOrder = TRIP_COUNTRY_ORDER[tripNum];
  if (!countryOrder) {
    console.log(`  Warning: No country order defined for trip ${tripNum}`);
    return stops;
  }

  // Group stops by country
  const byCountry = {};
  for (const stop of stops) {
    if (!byCountry[stop.iso]) byCountry[stop.iso] = [];
    byCountry[stop.iso].push(stop);
  }

  // Build ordered list following country sequence
  const ordered = [];
  let lastPoint = null;

  for (const iso of countryOrder) {
    const countryStops = byCountry[iso];
    if (!countryStops || countryStops.length === 0) continue;

    // Within a country, order stops by proximity to last point
    if (lastPoint && countryStops.length > 1) {
      // Sort by distance from last point
      countryStops.sort((a, b) =>
        distance(a.coords, lastPoint) - distance(b.coords, lastPoint)
      );
    }

    // Add all stops from this country
    for (const stop of countryStops) {
      ordered.push(stop);
      lastPoint = stop.coords;
    }
  }

  return ordered;
}

// Assign sights to trips based on which Route stop they're nearest to
function assignSightsToTrips(sights, routeStops) {
  const tripSights = {};

  for (const sight of sights) {
    // Find nearest Route stop in same country
    const sameCountryStops = routeStops.filter(s => s.iso === sight.iso);

    if (sameCountryStops.length === 0) continue;

    let nearestStop = sameCountryStops[0];
    let nearestDist = distance(sight.coords, sameCountryStops[0].coords);

    for (const stop of sameCountryStops.slice(1)) {
      const d = distance(sight.coords, stop.coords);
      if (d < nearestDist) {
        nearestDist = d;
        nearestStop = stop;
      }
    }

    const trip = nearestStop.trip;
    if (!tripSights[trip]) tripSights[trip] = [];
    tripSights[trip].push({
      ...sight,
      nearestStop: nearestStop.name,
      distanceToStop: Math.round(nearestDist)
    });
  }

  return tripSights;
}

// Calculate total route distance
function routeDistance(stops) {
  let total = 0;
  for (let i = 0; i < stops.length - 1; i++) {
    total += distance(stops[i].coords, stops[i+1].coords);
  }
  return total;
}

// Generate GeoJSON for a trip
function generateTripGeoJSON(orderedStops, sights, tripNum, totalKm) {
  const features = [];

  // Add each stop as a point
  for (let i = 0; i < orderedStops.length; i++) {
    const stop = orderedStops[i];
    features.push({
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: stop.coords
      },
      properties: {
        name: stop.name,
        country: stop.country,
        iso: stop.iso,
        category: 'Stop',
        order: i + 1,
        type: 'route-stop'
      }
    });
  }

  // Add connecting line for Route stops ONLY
  if (orderedStops.length > 1) {
    features.push({
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: orderedStops.map(s => s.coords)
      },
      properties: {
        type: 'route',
        totalKm: Math.round(totalKm),
        stopCount: orderedStops.length
      }
    });
  }

  return {
    type: 'FeatureCollection',
    properties: {
      trip: tripNum,
      totalKm: Math.round(totalKm),
      stopCount: orderedStops.length,
      sightCount: sights.length,
      estimatedDrivingDays: Math.ceil(totalKm / 300),
      countries: [...new Set(orderedStops.map(s => s.iso))]
    },
    features: features
  };
}

// Main execution
function main() {
  console.log('Loading data...');
  const routeStops = loadRouteStops();
  const sights = loadSights();

  console.log(`Loaded ${routeStops.length} route stops`);
  console.log(`Loaded ${sights.length} sights`);

  // Group Route stops by trip
  const tripStops = {};
  for (const stop of routeStops) {
    if (!tripStops[stop.trip]) tripStops[stop.trip] = [];
    tripStops[stop.trip].push(stop);
  }

  // Assign sights to trips
  const tripSights = assignSightsToTrips(sights, routeStops);

  // Ensure output directory exists
  const tripsDir = path.join(__dirname, '../data/trips');
  if (!fs.existsSync(tripsDir)) {
    fs.mkdirSync(tripsDir, { recursive: true });
  }

  const summary = {
    generated: new Date().toISOString(),
    trips: []
  };

  const tripNums = Object.keys(tripStops).map(Number).sort((a,b) => a-b);
  console.log(`\nBuilding routes for ${tripNums.length} trips...\n`);

  for (const tripNum of tripNums) {
    const stops = tripStops[tripNum];
    const sightsForTrip = tripSights[tripNum] || [];

    // Order stops by country sequence
    const orderedStops = orderStopsByCountrySequence(stops, tripNum);
    const totalKm = routeDistance(orderedStops);

    // Generate and save GeoJSON
    const geojson = generateTripGeoJSON(orderedStops, sightsForTrip, tripNum, totalKm);
    const filename = `trip-${String(tripNum).padStart(2, '0')}.geojson`;
    fs.writeFileSync(path.join(tripsDir, filename), JSON.stringify(geojson, null, 2));

    // Add to summary
    summary.trips.push({
      trip: tripNum,
      countries: geojson.properties.countries,
      stopCount: orderedStops.length,
      sightCount: sightsForTrip.length,
      totalKm: Math.round(totalKm),
      estimatedDrivingDays: Math.ceil(totalKm / 300)
    });

    console.log(`Trip ${String(tripNum).padStart(2)}: ${orderedStops.length} stops, ${sightsForTrip.length} sights, ${Math.round(totalKm)}km`);
  }

  // Save summary
  fs.writeFileSync(
    path.join(__dirname, '../data/trip-summary.json'),
    JSON.stringify(summary, null, 2)
  );

  console.log('\n=== SUMMARY ===');
  const totalStops = summary.trips.reduce((sum, t) => sum + t.stopCount, 0);
  const totalSights = summary.trips.reduce((sum, t) => sum + t.sightCount, 0);
  const totalKm = summary.trips.reduce((sum, t) => sum + t.totalKm, 0);
  console.log(`Total stops: ${totalStops}`);
  console.log(`Total sights: ${totalSights}`);
  console.log(`Total distance: ${totalKm.toLocaleString()}km`);
  console.log(`\nOutput saved to data/trips/ and data/trip-summary.json`);
}

main();
