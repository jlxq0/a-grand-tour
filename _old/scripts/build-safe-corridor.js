const https = require('https');
const fs = require('fs');

// Safe corridor waypoints: Calabar (Nigeria) → Republic of Congo
// NOTE: Does NOT avoid Anglophone zone - transits through it (Mamfe/Kumba) in ~4 hours
// Avoids: Equatorial Guinea
// Route: Calabar → (Anglophone transit) → Douala → Yaoundé → Congo border
const waypoints = [
  {
    name: "Calabar",
    coords: [8.3300, 4.9500],
    safe: true,
    description: "Nigerian port city. Entry point. Stock up on supplies, get Cameroon visa stamped. Safe."
  },
  {
    name: "Ikom",
    coords: [8.7200, 5.9600],
    safe: true,
    description: "Last major Nigerian town before border. Fill fuel tanks. Safe."
  },
  {
    name: "Ekok Border",
    coords: [8.9500, 5.7700],
    safe: "caution",
    description: "Nigeria-Cameroon border crossing. Legitimate crossing point. Have papers ready. Modest bribes possible."
  },
  {
    name: "Mamfe",
    coords: [9.3100, 5.7500],
    safe: "transit",
    description: "ANGLOPHONE ZONE - DO NOT STOP. Transit only. Military escorts sometimes available from Ekok. Drive in daylight ONLY. No photos."
  },
  {
    name: "Kumba",
    coords: [9.4500, 4.6400],
    safe: "transit",
    description: "ANGLOPHONE ZONE - Still dangerous. Continue transit to Douala. Do not stop except for checkpoints."
  },
  {
    name: "Douala",
    coords: [9.7000, 4.0500],
    safe: true,
    description: "Francophone Cameroon - SAFE. Major port city. Rest stop, resupply, safe hotels. French-speaking zone begins here."
  },
  {
    name: "Edéa",
    coords: [10.1333, 3.8000],
    safe: true,
    description: "Safe transit town on main highway N3 to Yaoundé."
  },
  {
    name: "Yaoundé",
    coords: [11.5167, 3.8667],
    safe: true,
    description: "Capital city - SAFE. Major rest stop. Embassies, good hotels, supplies. Can arrange onward travel info here."
  },
  {
    name: "Mbalmayo",
    coords: [11.5000, 3.5167],
    safe: true,
    description: "Safe town south of Yaoundé. Main route south."
  },
  {
    name: "Ebolowa",
    coords: [11.1500, 2.9000],
    safe: true,
    description: "Capital of South Region - SAFE. Good stopping point. French-speaking, peaceful area."
  },
  {
    name: "Sangmélima",
    coords: [11.9833, 2.9333],
    safe: true,
    description: "Safe town. Route continues east toward Congo border."
  },
  {
    name: "Djoum",
    coords: [12.6667, 2.6667],
    safe: true,
    description: "Small town, limited services but safe. Last significant town before border region."
  },
  {
    name: "Mintom",
    coords: [13.5167, 2.4333],
    safe: true,
    description: "Remote but safe. Near Congo border."
  },
  {
    name: "Kika Border",
    coords: [14.1833, 2.2333],
    safe: "caution",
    description: "Cameroon-Congo border crossing. Small remote post. Have all paperwork ready. May need patience."
  },
  {
    name: "Sembé",
    coords: [14.5833, 1.6500],
    safe: true,
    description: "First town in Republic of Congo. Safe. Resupply if possible."
  },
  {
    name: "Ouesso",
    coords: [16.0500, 1.6167],
    safe: true,
    description: "Major town in northern Congo - SAFE. River port on Sangha. Good stopping point. Can continue south to Brazzaville or west to Gabon."
  }
];

async function fetchRoute(coords) {
  const coordString = coords.map(c => c.join(',')).join(';');
  const url = `https://router.project-osrm.org/route/v1/driving/${coordString}?overview=full&geometries=geojson`;

  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve(json);
        } catch(e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function buildSafeCorridor() {
  const features = [];
  let allCoords = [];
  let totalDistance = 0;
  let totalDuration = 0;

  // Build route segment by segment
  for (let i = 0; i < waypoints.length - 1; i++) {
    const from = waypoints[i];
    const to = waypoints[i + 1];

    console.error(`Fetching segment ${i + 1}/${waypoints.length - 1}: ${from.name} → ${to.name}`);

    // Add small delay to be nice to OSRM
    if (i > 0) await new Promise(r => setTimeout(r, 500));

    try {
      const result = await fetchRoute([from.coords, to.coords]);
      if (result.routes && result.routes[0]) {
        const route = result.routes[0];
        const distanceKm = Math.round(route.distance / 1000);
        const durationHrs = (route.duration / 3600).toFixed(1);

        totalDistance += route.distance;
        totalDuration += route.duration;

        // Accumulate coordinates for full route
        if (allCoords.length === 0) {
          allCoords = route.geometry.coordinates;
        } else {
          allCoords = allCoords.concat(route.geometry.coordinates.slice(1));
        }

        console.error(`  ✓ ${distanceKm} km, ${durationHrs} hrs`);
      } else {
        console.error(`  ✗ No route found, using straight line`);
        if (allCoords.length === 0) {
          allCoords = [from.coords, to.coords];
        } else {
          allCoords.push(to.coords);
        }
      }
    } catch (err) {
      console.error(`  ✗ Error: ${err.message}`);
      if (allCoords.length === 0) {
        allCoords = [from.coords, to.coords];
      } else {
        allCoords.push(to.coords);
      }
    }
  }

  // Build safety summary
  const segments = [];
  for (let i = 0; i < waypoints.length - 1; i++) {
    const from = waypoints[i];
    const to = waypoints[i + 1];
    const safetyStatus = to.safe === "transit" ? "⚠️ TRANSIT ONLY" :
                         to.safe === "caution" ? "⚡ CAUTION" : "✓ Safe";
    segments.push(`${from.name} → ${to.name}: ${safetyStatus}`);
  }

  // Create main corridor LineString feature
  features.push({
    type: "Feature",
    properties: {
      name: "Calabar-Congo Safe Corridor",
      type: "safe-corridor",
      description: `Safe overland route from Nigeria to Republic of Congo, bypassing the Anglophone crisis zone in Cameroon and avoiding Equatorial Guinea entirely.

**Total Distance:** ${Math.round(totalDistance / 1000)} km
**Estimated Drive Time:** ${(totalDuration / 3600).toFixed(0)} hours

## Route Segments:
${segments.join('\n')}

## Key Safety Notes:
• **Anglophone Zone (Mamfe-Kumba):** DO NOT stop. Transit in daylight only. Military escorts sometimes available.
• **Douala onwards:** Francophone Cameroon is safe. Normal travel precautions apply.
• **Border crossings:** Have all papers ready. Expect delays but crossings are legitimate.
• **Equatorial Guinea:** Completely avoided - this route stays inland through Yaoundé.

## When to Travel:
• Dry season (Nov-Feb) preferred for road conditions
• Always travel in daylight through Anglophone zone
• Allow 4-5 days for the full crossing with rest stops`,
      totalDistanceKm: Math.round(totalDistance / 1000),
      totalDurationHrs: Math.round(totalDuration / 3600)
    },
    geometry: {
      type: "LineString",
      coordinates: allCoords
    }
  });

  // Add waypoint markers
  for (const wp of waypoints) {
    const safetyColor = wp.safe === "transit" ? "#e74c3c" :
                        wp.safe === "caution" ? "#f39c12" : "#27ae60";
    const safetyLabel = wp.safe === "transit" ? "⚠️ DANGER - Transit Only" :
                        wp.safe === "caution" ? "⚡ Exercise Caution" : "✓ Safe";

    features.push({
      type: "Feature",
      properties: {
        name: wp.name,
        type: "waypoint",
        description: wp.description,
        safe: wp.safe,
        safetyLabel: safetyLabel,
        color: safetyColor
      },
      geometry: {
        type: "Point",
        coordinates: wp.coords
      }
    });
  }

  const geojson = {
    type: "FeatureCollection",
    features: features
  };

  console.log(JSON.stringify(geojson, null, 2));
  console.error(`\n✓ Generated ${features.length} features (1 route + ${waypoints.length} waypoints)`);
  console.error(`✓ Total: ${Math.round(totalDistance / 1000)} km, ${(totalDuration / 3600).toFixed(0)} hours`);
}

buildSafeCorridor().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
