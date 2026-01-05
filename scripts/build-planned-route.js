const https = require('https');
const fs = require('fs');

// Waypoints for Trip 1: Gulf & Iran
const waypoints = [
  { name: "Dubai (Burj Khalifa)", coords: [55.2744, 25.1972] },
  { name: "Khor Fakkan (scenic route start)", coords: [56.3481, 25.3411] },
  { name: "Musandam Fjords", coords: [56.2667, 26.2000] },
  { name: "Wadi Shab", coords: [59.1833, 22.8333] },
  { name: "Muscat (Sultan Qaboos Mosque)", coords: [58.4056, 23.5953] },
  { name: "Nizwa Fort", coords: [57.5300, 22.9333] },
  { name: "Jebel Akhdar", coords: [57.5827, 23.0847] },
  { name: "Wadi Bani Awf", coords: [57.4035, 23.3072] },
  { name: "Jebel Shams", coords: [57.2667, 23.2333] },
  { name: "Salalah", coords: [54.0331, 17.0151] },
  { name: "Empty Quarter", coords: [54.0000, 22.5000] },
  { name: "Jebel Hafeet", coords: [55.7726, 24.1052] },
  { name: "Abu Dhabi", coords: [54.4711, 24.4128] },
  { name: "Inland Sea Qatar", coords: [51.3333, 24.6500] },
  { name: "Doha", coords: [51.5310, 25.2867] },
  { name: "Qal'at al-Bahrain", coords: [50.5203, 26.2333] },
  { name: "Dammam", coords: [50.1033, 26.4347] },
  { name: "Riyadh", coords: [46.6753, 24.7136] },
  { name: "Edge of the World", coords: [46.6750, 24.8256] },
  { name: "Diriyah At-Turaif", coords: [46.5744, 24.7344] },
  { name: "Kuwait City", coords: [47.9783, 29.3797] },
  { name: "Basra", coords: [47.7833, 30.5000] },
  { name: "Ziggurat of Ur", coords: [46.1053, 30.9628] },
  { name: "Khorramshahr (Iran)", coords: [48.1667, 30.4333] },
  { name: "Ahvaz", coords: [48.6842, 31.3183] },
  { name: "Isfahan (Naqsh-e Jahan Square)", coords: [51.6778, 32.6569] },
  { name: "Tehran (Golestan Palace)", coords: [51.4214, 35.6836] },
  // Extended: Iran POIs, Pakistan, India, Nepal
  { name: "Yazd Old Town", coords: [54.3544, 31.8974] },
  { name: "Shiraz (Nasir al-Mulk Mosque)", coords: [52.5483, 29.6081] },
  { name: "Persepolis", coords: [52.8892, 29.9347] },
  { name: "Hormuz Island", coords: [56.4611, 27.0619] },
  { name: "Chabahar", coords: [60.6432, 25.2919] },
  // Pakistan
  { name: "Gwadar", coords: [62.3254, 25.1264] },
  { name: "Karachi", coords: [67.0011, 24.8607] },
  { name: "Multan", coords: [71.5249, 30.1575] },
  { name: "Lahore", coords: [74.3587, 31.5204] },
  { name: "Islamabad", coords: [73.0551, 33.7295] },
  // Karakoram Highway (out and back - can't cross to China)
  { name: "Gilgit", coords: [74.3145, 35.9208] },
  { name: "Hunza Valley (Karimabad)", coords: [74.6597, 36.3186] },
  { name: "Attabad Lake", coords: [74.8500, 36.3333] },
  { name: "Khunjerab Pass", coords: [75.4167, 36.8500] },
  // Return from KKH
  { name: "Gilgit (return)", coords: [74.3145, 35.9208] },
  { name: "Islamabad (return)", coords: [73.0551, 33.7295] },
  { name: "Lahore (return)", coords: [74.3587, 31.5204] },
  // India
  { name: "Amritsar (Golden Temple)", coords: [74.8765, 31.6200] },
  { name: "Srinagar", coords: [74.7973, 34.0837] },
  { name: "Kargil", coords: [76.1349, 34.5539] },
  { name: "Leh", coords: [77.5771, 34.1526] },
  { name: "Manali", coords: [77.1887, 32.2396] },
  { name: "Spiti Valley (Kaza)", coords: [78.0722, 32.2278] },
  { name: "Shimla", coords: [77.1734, 31.1048] },
  { name: "Delhi", coords: [77.2090, 28.6139] },
  // Nepal
  { name: "Kathmandu", coords: [85.3240, 27.7172] }
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

async function buildRoute() {
  // Build route in segments (OSRM has limits)
  const segments = [];
  const segmentSize = 6;

  for (let i = 0; i < waypoints.length - 1; i += segmentSize - 1) {
    const segment = waypoints.slice(i, Math.min(i + segmentSize, waypoints.length));
    const coords = segment.map(w => w.coords);

    console.error(`Fetching segment ${i} to ${i + segment.length - 1}: ${segment.map(s => s.name).join(' -> ')}`);

    try {
      const result = await fetchRoute(coords);
      if (result.routes && result.routes[0]) {
        segments.push(result.routes[0].geometry.coordinates);
        console.error(`  Got ${result.routes[0].geometry.coordinates.length} points`);
      } else {
        console.error(`  No route found, using straight line`);
        segments.push(coords);
      }
    } catch(e) {
      console.error('  Error:', e.message);
      segments.push(coords);
    }

    // Rate limit
    await new Promise(r => setTimeout(r, 1500));
  }

  // Combine all segments
  let allCoords = [];
  segments.forEach((seg, idx) => {
    if (idx === 0) {
      allCoords = seg;
    } else {
      allCoords = allCoords.concat(seg.slice(1));
    }
  });

  const geojson = {
    type: "FeatureCollection",
    features: [{
      type: "Feature",
      properties: {
        name: "Trip 1: Gulf to Nepal",
        segment: 1,
        description: "Dubai → Oman → Saudi → Qatar → Bahrain → Kuwait → Iraq → Iran → Pakistan → India → Nepal"
      },
      geometry: {
        type: "LineString",
        coordinates: allCoords
      }
    }]
  };

  fs.writeFileSync('data/planned-route.geojson', JSON.stringify(geojson, null, 2));
  console.error(`\nWrote ${allCoords.length} total coordinates to data/planned-route.geojson`);
}

buildRoute();
