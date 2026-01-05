const https = require('https');
const fs = require('fs');

// Trip 1 Part 1: Dubai to Iran (ends at Bandar Abbas - ship car to Karachi)
const waypointsPart1 = [
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
  // Iraq - 520km loop to visit Ziggurat of Ur (4000-year-old Sumerian temple, UNESCO site)
  { name: "Basra", coords: [47.7833, 30.5000] },
  { name: "Ziggurat of Ur", coords: [46.1053, 30.9628] },
  // Back east to Iran border
  { name: "Khorramshahr (Iran)", coords: [48.1667, 30.4333] },
  { name: "Ahvaz", coords: [48.6842, 31.3183] },
  // Iran - logical geographic order
  { name: "Kermanshah", coords: [47.0650, 34.3142] },
  { name: "Tehran (Golestan Palace)", coords: [51.4214, 35.6836] },
  { name: "Isfahan (Naqsh-e Jahan Square)", coords: [51.6778, 32.6569] },
  { name: "Yazd Old Town", coords: [54.3544, 31.8974] },
  { name: "Shiraz (Nasir al-Mulk Mosque)", coords: [52.5483, 29.6081] },
  { name: "Persepolis", coords: [52.8892, 29.9347] },
  { name: "Bandar Abbas", coords: [56.2833, 27.1833] }
  // END - Ship car to Karachi, fly family (skip Balochistan)
  // Hormuz Island (Rainbow Valley) - via ferry from Bandar Abbas
];

// Trip 1 Part 2: Pakistan onwards (after shipping from Bandar Abbas)
const waypointsPart2 = [
  { name: "Karachi", coords: [67.0011, 24.8607] },
  { name: "Multan", coords: [71.5249, 30.1575] },
  { name: "Lahore", coords: [74.3587, 31.5204] },
  { name: "Islamabad", coords: [73.0551, 33.7295] },
  // Karakoram Highway (out and back - can't cross to China)
  { name: "Abbottabad", coords: [73.2215, 34.1688] },
  { name: "Besham", coords: [72.8756, 34.9267] },
  { name: "Chilas", coords: [74.1000, 35.4167] },
  { name: "Gilgit", coords: [74.3145, 35.9208] },
  { name: "Hunza Valley (Karimabad)", coords: [74.6597, 36.3186] },
  { name: "Attabad Lake", coords: [74.8500, 36.3333] },
  { name: "Khunjerab Pass", coords: [75.4167, 36.8500] },
  // Return from KKH (same route back)
  { name: "Gilgit (return)", coords: [74.3145, 35.9208] },
  { name: "Chilas (return)", coords: [74.1000, 35.4167] },
  { name: "Besham (return)", coords: [72.8756, 34.9267] },
  { name: "Islamabad (return)", coords: [73.0551, 33.7295] },
  { name: "Lahore (return)", coords: [74.3587, 31.5204] },
  // India - Himalayan section (via Manali-Leh, avoids Kashmir conflict zone)
  { name: "Amritsar (Golden Temple)", coords: [74.8765, 31.6200] },
  { name: "Chandigarh", coords: [76.7794, 30.7333] },
  { name: "Manali", coords: [77.1887, 32.2396] },
  { name: "Leh", coords: [77.5771, 34.1526] },
  { name: "Manali (return)", coords: [77.1887, 32.2396] },
  { name: "Spiti Valley (Kaza)", coords: [78.0722, 32.2278] },
  { name: "Shimla", coords: [77.1734, 31.1048] },
  { name: "Delhi", coords: [77.2090, 28.6139] },
  // India - Grand Loop (clockwise from Delhi)
  { name: "Agra (Taj Mahal)", coords: [78.0421, 27.1751] },
  { name: "Jaipur (Hawa Mahal)", coords: [75.7873, 26.9239] },
  { name: "Jodhpur (Mehrangarh Fort)", coords: [73.0243, 26.2968] },
  { name: "Jaisalmer Fort", coords: [70.9083, 26.9157] },
  { name: "Udaipur (City Palace)", coords: [73.6833, 24.5854] },
  { name: "Rann of Kutch", coords: [69.8597, 23.7337] },
  { name: "Ahmedabad", coords: [72.5714, 23.0225] },
  { name: "Mumbai", coords: [72.8777, 19.0760] },
  { name: "Goa (Baga Beach)", coords: [73.7515, 15.5553] },
  { name: "Hampi Ruins", coords: [76.4600, 15.3350] },
  { name: "Bangalore", coords: [77.5946, 12.9716] },
  { name: "Kochi", coords: [76.2673, 9.9312] },
  { name: "Munnar", coords: [77.0595, 10.0889] },
  { name: "Alleppey (Kerala Backwaters)", coords: [76.3388, 9.4981] },
  // Back up east coast
  { name: "Madurai (Meenakshi Temple)", coords: [78.1198, 9.9252] },
  { name: "Pondicherry", coords: [79.8083, 11.9416] },
  { name: "Chennai", coords: [80.2707, 13.0827] },
  { name: "Nellore", coords: [79.9865, 14.4426] },
  { name: "Vijayawada", coords: [80.6480, 16.5062] },
  { name: "Visakhapatnam", coords: [83.2185, 17.6868] },
  { name: "Kolkata", coords: [88.3639, 22.5726] },
  { name: "Varanasi", coords: [82.9913, 25.3176] },
  // Nepal
  { name: "Kathmandu (Durbar Square)", coords: [85.3240, 27.7172] },
  { name: "Bhaktapur", coords: [85.4280, 27.6710] },
  { name: "Nagarkot (Himalayan viewpoint)", coords: [85.5200, 27.7172] },
  { name: "Pokhara (Phewa Lake)", coords: [83.9856, 28.2096] },
  { name: "Lumbini (Buddha birthplace)", coords: [83.2763, 27.4833] },
  { name: "Chitwan National Park", coords: [84.3542, 27.5291] },
  // Bangladesh
  { name: "Paharpur Buddhist Vihara", coords: [88.9764, 25.0303] },
  { name: "Dhaka", coords: [90.4125, 23.8103] },
  { name: "Sundarbans", coords: [89.1833, 21.9497] },
  { name: "Khulna", coords: [89.5403, 22.8456] },
  { name: "Dhaka (return)", coords: [90.4125, 23.8103] },
  { name: "Cox's Bazar Beach", coords: [91.9847, 21.4272] },
  { name: "Chittagong (ship car)", coords: [91.8123, 22.3569] }
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

// Build route with segment-by-segment stats
async function buildRouteWithSegments(waypoints, partName, partNumber) {
  const segmentFeatures = [];
  let totalDistance = 0;
  let totalDuration = 0;
  let allCoords = [];

  // Process waypoint pairs
  for (let i = 0; i < waypoints.length - 1; i++) {
    const from = waypoints[i];
    const to = waypoints[i + 1];

    console.error(`Fetching ${partName} segment ${i + 1}/${waypoints.length - 1}: ${from.name} → ${to.name}`);

    try {
      const result = await fetchRoute([from.coords, to.coords]);
      if (result.routes && result.routes[0]) {
        const route = result.routes[0];
        const distanceKm = Math.round(route.distance / 1000);
        const durationHrs = (route.duration / 3600).toFixed(1);

        totalDistance += route.distance;
        totalDuration += route.duration;

        // Add segment feature
        segmentFeatures.push({
          type: "Feature",
          properties: {
            part: partNumber,
            segmentIndex: i,
            from: from.name,
            to: to.name,
            distanceKm: distanceKm,
            durationHrs: parseFloat(durationHrs),
            label: `${from.name.split('(')[0].trim()} → ${to.name.split('(')[0].trim()}`
          },
          geometry: route.geometry
        });

        // Accumulate coordinates
        if (allCoords.length === 0) {
          allCoords = route.geometry.coordinates;
        } else {
          allCoords = allCoords.concat(route.geometry.coordinates.slice(1));
        }

        console.error(`  ${distanceKm} km, ${durationHrs} hrs (${route.geometry.coordinates.length} points)`);
      } else {
        console.error(`  No route found, using straight line`);
        // Fallback to straight line
        segmentFeatures.push({
          type: "Feature",
          properties: {
            part: partNumber,
            segmentIndex: i,
            from: from.name,
            to: to.name,
            distanceKm: 0,
            durationHrs: 0,
            label: `${from.name.split('(')[0].trim()} → ${to.name.split('(')[0].trim()}`,
            noRoute: true
          },
          geometry: {
            type: "LineString",
            coordinates: [from.coords, to.coords]
          }
        });
        if (allCoords.length === 0) {
          allCoords = [from.coords, to.coords];
        } else {
          allCoords.push(to.coords);
        }
      }
    } catch(e) {
      console.error('  Error:', e.message);
      // Fallback
      if (allCoords.length === 0) {
        allCoords = [from.coords, to.coords];
      } else {
        allCoords.push(to.coords);
      }
    }

    // Rate limit
    await new Promise(r => setTimeout(r, 500));
  }

  return {
    segments: segmentFeatures,
    totalCoords: allCoords,
    totalDistanceKm: Math.round(totalDistance / 1000),
    totalDurationHrs: (totalDuration / 3600).toFixed(1)
  };
}

async function buildRoute() {
  console.error('=== Building Part 1: Dubai to Bandar Abbas ===\n');
  const part1 = await buildRouteWithSegments(waypointsPart1, 'Part1', 1);

  console.error('\n=== Building Part 2: Karachi to Chittagong ===\n');
  const part2 = await buildRouteWithSegments(waypointsPart2, 'Part2', 2);

  // Create GeoJSON with both summary lines and individual segments
  const geojson = {
    type: "FeatureCollection",
    features: [
      // Summary line for Part 1
      {
        type: "Feature",
        properties: {
          name: "Trip 1a: Dubai to Bandar Abbas",
          part: 1,
          type: "summary",
          description: "Dubai → Oman → Saudi → Qatar → Bahrain → Kuwait → Iraq → Iran (ship car to Karachi)",
          totalDistanceKm: part1.totalDistanceKm,
          totalDurationHrs: parseFloat(part1.totalDurationHrs),
          segmentCount: part1.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part1.totalCoords
        }
      },
      // Summary line for Part 2
      {
        type: "Feature",
        properties: {
          name: "Trip 1b: Karachi to Chittagong",
          part: 2,
          type: "summary",
          description: "Pakistan → India → Nepal → Bangladesh (ship car from Chittagong)",
          totalDistanceKm: part2.totalDistanceKm,
          totalDurationHrs: parseFloat(part2.totalDurationHrs),
          segmentCount: part2.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part2.totalCoords
        }
      },
      // Individual segments
      ...part1.segments,
      ...part2.segments
    ]
  };

  fs.writeFileSync('data/planned-route.geojson', JSON.stringify(geojson, null, 2));

  console.error(`\n=== TOTALS ===`);
  console.error(`Part 1: ${part1.totalDistanceKm} km, ${part1.totalDurationHrs} hrs driving (${part1.segments.length} segments)`);
  console.error(`Part 2: ${part2.totalDistanceKm} km, ${part2.totalDurationHrs} hrs driving (${part2.segments.length} segments)`);
  console.error(`TOTAL: ${part1.totalDistanceKm + part2.totalDistanceKm} km, ${(parseFloat(part1.totalDurationHrs) + parseFloat(part2.totalDurationHrs)).toFixed(1)} hrs driving`);
  console.error(`\nWrote ${part1.totalCoords.length + part2.totalCoords.length} coordinates to data/planned-route.geojson`);
}

buildRoute();
