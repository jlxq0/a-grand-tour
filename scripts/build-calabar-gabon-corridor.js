const https = require('https');

// Safe corridor: Calabar (Nigeria) → Otsala Kokowa NP (Gabon)
// Avoids: Equatorial Guinea entirely
// Minimizes: Time in Anglophone Cameroon crisis zone
// Route: Calabar → Ekok → (transit Mamfe/Kumba) → Douala → Yaoundé → Ambam → Bitam → Otsala Kokowa area
const waypoints = [
  {
    name: "Calabar",
    coords: [8.3300, 4.9500],
    country: "NG",
    safe: true,
    description: "Nigerian port city. Entry point. Stock up on supplies, get Cameroon visa stamped. Safe."
  },
  {
    name: "Ikom",
    coords: [8.7200, 5.9600],
    country: "NG",
    safe: true,
    description: "Last major Nigerian town before border. Fill fuel tanks. Safe."
  },
  {
    name: "Ekok Border",
    coords: [8.9500, 5.7700],
    country: "CM",
    safe: "caution",
    description: "Nigeria-Cameroon border crossing. Legitimate crossing point. Have papers ready."
  },
  {
    name: "Mamfe",
    coords: [9.3100, 5.7500],
    country: "CM",
    safe: "transit",
    description: "⚠️ ANGLOPHONE ZONE - DO NOT STOP. Transit only. Drive in daylight ONLY."
  },
  {
    name: "Kumba",
    coords: [9.4500, 4.6400],
    country: "CM",
    safe: "transit",
    description: "⚠️ ANGLOPHONE ZONE - Still dangerous. Continue to Douala. Do not stop except checkpoints."
  },
  {
    name: "Douala",
    coords: [9.7000, 4.0500],
    country: "CM",
    safe: true,
    description: "Francophone Cameroon - SAFE. Major city. Rest, resupply. French-speaking zone."
  },
  {
    name: "Edéa",
    coords: [10.1333, 3.8000],
    country: "CM",
    safe: true,
    description: "Safe transit town on main highway N3 to Yaoundé."
  },
  {
    name: "Yaoundé",
    coords: [11.5167, 3.8667],
    country: "CM",
    safe: true,
    description: "Capital - SAFE. Good rest stop. Embassies, hotels, supplies."
  },
  {
    name: "Mbalmayo",
    coords: [11.5000, 3.5167],
    country: "CM",
    safe: true,
    description: "Safe town south of Yaoundé on main route south."
  },
  {
    name: "Ebolowa",
    coords: [11.1500, 2.9000],
    country: "CM",
    safe: true,
    description: "Capital of South Region - SAFE. Good stopping point."
  },
  {
    name: "Ambam",
    coords: [11.2833, 2.3833],
    country: "CM",
    safe: true,
    description: "Border town. Last major Cameroonian town before Gabon."
  },
  {
    name: "Kye-Ossi",
    coords: [11.3167, 2.1833],
    country: "CM",
    safe: "caution",
    description: "Cameroon-Gabon-Equatorial Guinea tripoint border. Take GABON crossing, NOT EQ Guinea."
  },
  {
    name: "Bitam",
    coords: [11.4833, 2.0833],
    country: "GA",
    safe: true,
    description: "First town in Gabon - SAFE. Resupply point. Welcome to Gabon!"
  },
  {
    name: "Minvoul",
    coords: [12.1333, 2.1500],
    country: "GA",
    safe: true,
    description: "Gateway to Minkébé National Park region. Safe town."
  },
  {
    name: "Otsala Kokowa NP Area",
    coords: [11.8500, 1.7500],
    country: "GA",
    safe: true,
    description: "Destination: Otsala Kokowa National Park area in northern Gabon. Remote but safe."
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
  let cameroonDistance = 0;
  let cameroonDuration = 0;

  // Build route segment by segment
  for (let i = 0; i < waypoints.length - 1; i++) {
    const from = waypoints[i];
    const to = waypoints[i + 1];

    console.error(`Fetching segment ${i + 1}/${waypoints.length - 1}: ${from.name} → ${to.name}`);

    if (i > 0) await new Promise(r => setTimeout(r, 500));

    try {
      const result = await fetchRoute([from.coords, to.coords]);
      if (result.routes && result.routes[0]) {
        const route = result.routes[0];
        const distanceKm = Math.round(route.distance / 1000);
        const durationHrs = (route.duration / 3600).toFixed(1);

        totalDistance += route.distance;
        totalDuration += route.duration;

        // Track Cameroon distance/time
        if (to.country === "CM") {
          cameroonDistance += route.distance;
          cameroonDuration += route.duration;
        }

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

  features.push({
    type: "Feature",
    properties: {
      name: "Calabar-Gabon Safe Corridor",
      type: "safe-corridor",
      description: `Safe overland route from Calabar (Nigeria) to Otsala Kokowa National Park (Gabon).
Bypasses Equatorial Guinea entirely. Minimizes Anglophone Cameroon crisis zone.

**Total Distance:** ${Math.round(totalDistance / 1000)} km
**Estimated Drive Time:** ${(totalDuration / 3600).toFixed(0)} hours

**Cameroon Transit:** ${Math.round(cameroonDistance / 1000)} km, ~${(cameroonDuration / 3600).toFixed(0)} hours

## Route Segments:
${segments.join('\n')}

## Key Safety Notes:
• **Anglophone Zone (Mamfe-Kumba):** DO NOT stop. Transit in daylight only.
• **Douala onwards:** Francophone Cameroon is safe.
• **Kye-Ossi:** Tripoint border - take the GABON crossing, not EQ Guinea.
• **Equatorial Guinea:** Completely avoided.

## When to Travel:
• Dry season (Nov-Feb) preferred
• Always travel in daylight through Anglophone zone
• Allow 3-4 days for the full crossing with rest stops`,
      totalDistanceKm: Math.round(totalDistance / 1000),
      totalDurationHrs: Math.round(totalDuration / 3600),
      cameroonDistanceKm: Math.round(cameroonDistance / 1000),
      cameroonDurationHrs: Math.round(cameroonDuration / 3600)
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
        country: wp.country,
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
  console.error(`\n✓ Generated ${features.length} features`);
  console.error(`✓ Total: ${Math.round(totalDistance / 1000)} km, ${(totalDuration / 3600).toFixed(0)} hours`);
  console.error(`✓ Cameroon: ${Math.round(cameroonDistance / 1000)} km, ${(cameroonDuration / 3600).toFixed(0)} hours`);
}

buildSafeCorridor().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
