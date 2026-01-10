const https = require('https');

// TRULY SAFE corridor: Calabar (Nigeria) → Gabon
// ACTUALLY avoids: Anglophone Cameroon crisis zone (NW/SW) via Gembu-Banyo crossing
// Avoids: Equatorial Guinea entirely
// Trade-off: Longer route through Nigeria, rough Mambilla Plateau roads
const waypoints = [
  {
    name: "Calabar",
    coords: [8.3300, 4.9500],
    country: "NG",
    safe: true,
    description: "Starting point. Nigerian port city."
  },
  {
    name: "Ikom",
    coords: [8.7200, 5.9600],
    country: "NG",
    safe: true,
    description: "Head north through Nigeria instead of crossing into Cameroon here."
  },
  {
    name: "Ogoja",
    coords: [8.8000, 6.6500],
    country: "NG",
    safe: true,
    description: "Continue north on Nigerian roads."
  },
  {
    name: "Wukari",
    coords: [9.7833, 7.8500],
    country: "NG",
    safe: true,
    description: "Taraba State. Route continues toward Mambilla Plateau."
  },
  {
    name: "Jalingo",
    coords: [11.3667, 8.9000],
    country: "NG",
    safe: true,
    description: "Capital of Taraba State. Last major city before Mambilla Plateau. Resupply here."
  },
  {
    name: "Serti",
    coords: [11.2333, 7.5000],
    country: "NG",
    safe: true,
    description: "Gateway to Mambilla Plateau. Road gets rougher from here."
  },
  {
    name: "Gembu",
    coords: [11.2500, 6.7167],
    country: "NG",
    safe: true,
    description: "Mambilla Plateau - highest point in Nigeria (~1800m). Cool climate. Border crossing ahead."
  },
  {
    name: "Mayo Darlé Border",
    coords: [11.3000, 6.5500],
    country: "CM",
    safe: "caution",
    description: "Nigeria-Cameroon border. Small crossing. Have all papers ready. Remote but legitimate."
  },
  {
    name: "Banyo",
    coords: [11.8167, 6.7500],
    country: "CM",
    safe: true,
    description: "First major town in Cameroon - ADAMAWA REGION (Francophone). SAFE. Not part of Anglophone crisis."
  },
  {
    name: "Tibati",
    coords: [12.6167, 6.4667],
    country: "CM",
    safe: true,
    description: "Safe transit town. Adamawa Region."
  },
  {
    name: "Ngaoundéré",
    coords: [13.5833, 7.3167],
    country: "CM",
    safe: true,
    description: "Major city - SAFE. Railway terminus. Good resupply point."
  },
  {
    name: "Meiganga",
    coords: [14.2833, 6.5167],
    country: "CM",
    safe: true,
    description: "Safe transit. Adamawa Region."
  },
  {
    name: "Garoua-Boulaï",
    coords: [14.5333, 5.9000],
    country: "CM",
    safe: true,
    description: "Border town with CAR (not crossing). Continue south."
  },
  {
    name: "Bertoua",
    coords: [13.6833, 4.5833],
    country: "CM",
    safe: true,
    description: "Capital of East Region - SAFE. Major stop."
  },
  {
    name: "Ayos",
    coords: [12.5167, 3.9000],
    country: "CM",
    safe: true,
    description: "Safe transit on route to Yaoundé."
  },
  {
    name: "Yaoundé",
    coords: [11.5167, 3.8667],
    country: "CM",
    safe: true,
    description: "Capital - SAFE. Rest, resupply, embassies."
  },
  {
    name: "Mbalmayo",
    coords: [11.5000, 3.5167],
    country: "CM",
    safe: true,
    description: "South of Yaoundé. Main route south."
  },
  {
    name: "Ebolowa",
    coords: [11.1500, 2.9000],
    country: "CM",
    safe: true,
    description: "Capital of South Region - SAFE."
  },
  {
    name: "Ambam",
    coords: [11.2833, 2.3833],
    country: "CM",
    safe: true,
    description: "Last Cameroonian town before Gabon border."
  },
  {
    name: "Kye-Ossi",
    coords: [11.3167, 2.1833],
    country: "CM",
    safe: "caution",
    description: "Tripoint border. Take GABON crossing (toward Bitam), NOT Equatorial Guinea."
  },
  {
    name: "Bitam",
    coords: [11.4833, 2.0833],
    country: "GA",
    safe: true,
    description: "Welcome to Gabon - SAFE."
  },
  {
    name: "Oyem",
    coords: [11.5833, 1.6000],
    country: "GA",
    safe: true,
    description: "Capital of Woleu-Ntem Province. Good resupply."
  },
  {
    name: "Mitzic",
    coords: [11.5500, 0.7833],
    country: "GA",
    safe: true,
    description: "Continue south toward Libreville or east toward parks."
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
  let nigeriaDistance = 0;
  let cameroonDistance = 0;

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

        if (to.country === "NG") nigeriaDistance += route.distance;
        if (to.country === "CM") cameroonDistance += route.distance;

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
      name: "Calabar-Gabon SAFE Corridor (via Gembu-Banyo)",
      type: "safe-corridor",
      description: `TRULY SAFE overland route from Calabar (Nigeria) to Gabon.
**ACTUALLY avoids Anglophone crisis zone** by using Gembu-Banyo crossing.
Enters Cameroon in Adamawa Region (Francophone, safe).

**Total Distance:** ${Math.round(totalDistance / 1000)} km
**Estimated Drive Time:** ${(totalDuration / 3600).toFixed(0)} hours

**Nigeria segment:** ${Math.round(nigeriaDistance / 1000)} km
**Cameroon segment:** ${Math.round(cameroonDistance / 1000)} km (all in safe Francophone regions)

## Route Segments:
${segments.join('\n')}

## Why This Route:
• **Gembu-Banyo crossing** enters Adamawa Region (Francophone)
• **Zero transit** through Anglophone NW/SW crisis zones
• **Equatorial Guinea** completely avoided

## Trade-offs:
• **Longer route** - goes north through Nigeria first
• **Mambilla Plateau** - rough roads, 4x4 essential, dry season only
• **More Nigeria driving** but on safer roads

## When to Travel:
• **Dry season (Nov-Feb)** essential for Mambilla Plateau
• Road can be impassable in rainy season (Mar-Oct)`,
      totalDistanceKm: Math.round(totalDistance / 1000),
      totalDurationHrs: Math.round(totalDuration / 3600),
      nigeriaDistanceKm: Math.round(nigeriaDistance / 1000),
      cameroonDistanceKm: Math.round(cameroonDistance / 1000),
      avoidsAnglophoneZone: true
    },
    geometry: {
      type: "LineString",
      coordinates: allCoords
    }
  });

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
  console.error(`✓ Nigeria: ${Math.round(nigeriaDistance / 1000)} km`);
  console.error(`✓ Cameroon: ${Math.round(cameroonDistance / 1000)} km (Francophone regions only)`);
}

buildSafeCorridor().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
