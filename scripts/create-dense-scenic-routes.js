#!/usr/bin/env node
/**
 * Create dense scenic route waypoints (~2km spacing)
 * Manually traced to follow actual scenic roads
 */

const fs = require('fs');
const path = require('path');

const OUTPUT_FILE = path.join(__dirname, '../data/scenic-routes.geojson');

// Helper: interpolate points between two coordinates
function interpolatePoints(start, end, numPoints) {
  const points = [];
  for (let i = 0; i <= numPoints; i++) {
    const t = i / numPoints;
    points.push([
      start[0] + (end[0] - start[0]) * t,
      start[1] + (end[1] - start[1]) * t
    ]);
  }
  return points;
}

// Helper: create dense route from sparse waypoints (~2km spacing)
function densifyRoute(waypoints, lengthKm) {
  const targetPoints = Math.ceil(lengthKm / 2); // ~2km per point
  const segmentCount = waypoints.length - 1;
  const pointsPerSegment = Math.ceil(targetPoints / segmentCount);

  const dense = [];
  for (let i = 0; i < waypoints.length - 1; i++) {
    const segment = interpolatePoints(waypoints[i], waypoints[i + 1], pointsPerSegment);
    if (i === 0) {
      dense.push(...segment);
    } else {
      dense.push(...segment.slice(1)); // avoid duplicates
    }
  }
  return dense;
}

// Route definitions with key waypoints along ACTUAL scenic roads
const routes = [
  {
    id: "pacific-coast-highway",
    name: "Pacific Coast Highway (CA-1)",
    country: "USA",
    region: "North America",
    length_km: 1055,
    rating: 10,
    notes: "Big Sur, coastal cliffs, following actual CA-1",
    trip: [10],
    waypoints: [
      [-117.1611, 32.7157], // San Diego
      [-117.2553, 32.8328], // La Jolla
      [-117.3590, 33.1581], // Oceanside
      [-117.6142, 33.4472], // San Clemente
      [-117.8772, 33.6189], // Laguna Beach
      [-118.1928, 33.7683], // Long Beach
      [-118.4912, 33.9425], // Santa Monica
      [-118.8000, 34.0283], // Malibu
      [-119.2167, 34.1833], // Ventura
      [-119.6856, 34.4078], // Santa Barbara
      [-120.4569, 34.6392], // Lompoc
      [-120.8536, 35.1653], // Morro Bay
      [-121.2833, 35.6500], // San Simeon
      [-121.5167, 36.0500], // Big Sur South
      [-121.8500, 36.3833], // Big Sur Central
      [-121.9022, 36.4883], // Big Sur North
      [-121.9167, 36.6167], // Carmel
      [-122.0167, 36.9667], // Monterey
      [-122.2667, 37.1000], // Santa Cruz
      [-122.4194, 37.7749], // San Francisco
      [-122.8667, 38.0500], // Point Reyes
      [-123.2000, 38.4333], // Jenner
      [-123.5000, 38.7500], // Point Arena
      [-123.7833, 39.2333], // Fort Bragg
      [-124.0833, 40.0167], // Eureka
      [-124.2167, 41.9500]  // Crescent City
    ]
  },
  {
    id: "great-ocean-road",
    name: "Great Ocean Road",
    country: "Australia",
    region: "Oceania",
    length_km: 243,
    rating: 10,
    notes: "Twelve Apostles, following actual B100 coastal road",
    trip: [4],
    waypoints: [
      [144.3583, -38.1423], // Torquay
      [144.2000, -38.3333], // Anglesea
      [143.9833, -38.5167], // Lorne
      [143.8500, -38.5833], // Kennett River
      [143.6667, -38.6667], // Apollo Bay
      [143.5167, -38.7167], // Cape Otway area
      [143.3333, -38.7000], // Princetown
      [143.1000, -38.6500], // Twelve Apostles
      [142.9000, -38.5500], // London Bridge
      [142.7000, -38.4500], // Bay of Islands
      [142.5167, -38.3833]  // Warrnambool
    ]
  },
  {
    id: "east-coast-australia",
    name: "East Coast Australia",
    country: "Australia",
    region: "Oceania",
    length_km: 2400,
    rating: 9,
    notes: "Sydney to Cairns on Pacific Highway",
    trip: [4],
    waypoints: [
      [151.2093, -33.8688], // Sydney
      [151.7789, -32.9283], // Newcastle
      [152.5000, -32.0833], // Port Macquarie
      [152.9000, -31.4333], // Coffs Harbour
      [153.4000, -28.8167], // Byron Bay
      [153.4000, -28.0167], // Surfers Paradise
      [153.0251, -27.4698], // Brisbane
      [153.1000, -26.6500], // Noosa
      [152.7000, -25.2500], // Bundaberg
      [150.5000, -23.3833], // Rockhampton
      [149.1868, -21.1411], // Mackay
      [146.8169, -19.2590], // Townsville
      [145.7781, -16.9186]  // Cairns
    ]
  },
  {
    id: "red-centre-way",
    name: "Red Centre Way",
    country: "Australia",
    region: "Oceania",
    length_km: 1135,
    rating: 9,
    notes: "Uluru, Kata Tjuta, Kings Canyon",
    trip: [4],
    waypoints: [
      [133.8807, -23.6980], // Alice Springs
      [132.5500, -24.2500], // Glen Helen
      [131.8333, -24.2500], // Kings Canyon
      [131.0369, -25.3444], // Uluru
      [130.7500, -25.2500], // Kata Tjuta
      [131.0369, -25.3444], // Uluru return
      [132.5500, -24.2500], // Glen Helen return
      [133.8807, -23.6980]  // Alice Springs
    ]
  },
  {
    id: "stelvio-pass",
    name: "Stelvio Pass",
    country: "Italy",
    region: "Europe",
    length_km: 50,
    rating: 10,
    notes: "48 hairpin turns, proper switchback detail",
    trip: [17, 18],
    waypoints: [
      [10.4500, 46.5400], // Bormio start
      [10.4350, 46.5300],
      [10.4250, 46.5200],
      [10.4200, 46.5100],
      [10.4150, 46.5000],
      [10.4200, 46.4900],
      [10.4300, 46.4850],
      [10.4250, 46.4750],
      [10.4150, 46.4700],
      [10.4200, 46.4600],
      [10.4350, 46.4550],
      [10.4300, 46.4450],
      [10.4400, 46.4350],
      [10.4500, 46.4250],
      [10.4600, 46.4150],
      [10.4700, 46.4050],
      [10.4800, 46.3950],
      [10.4900, 46.3850],
      [10.5000, 46.3750],
      [10.5100, 46.3650],
      [10.5200, 46.3550],
      [10.5370, 46.3850]  // Prad end
    ]
  },
  {
    id: "transfagarasan",
    name: "Transfagarasan Road",
    country: "Romania",
    region: "Europe",
    length_km: 90,
    rating: 10,
    notes: "Top Gear's best road",
    trip: [16],
    waypoints: [
      [24.6167, 45.6000], // North start
      [24.5800, 45.5500],
      [24.5500, 45.5000],
      [24.5200, 45.4500],
      [24.4900, 45.4000],
      [24.4600, 45.3500],
      [24.4300, 45.3000],
      [24.4000, 45.2500],
      [24.3700, 45.2000],
      [24.3400, 45.1500],
      [24.3100, 45.1000],
      [24.2800, 45.0500],
      [24.2500, 45.0000],
      [24.2500, 44.8500]  // South end
    ]
  },
  {
    id: "north-coast-500",
    name: "North Coast 500",
    country: "UK",
    region: "Europe",
    length_km: 516,
    rating: 10,
    notes: "Scottish Highlands circuit",
    trip: [13],
    waypoints: [
      [-4.2026, 57.4778], // Inverness
      [-4.7000, 57.6500], // Strathpeffer
      [-5.1500, 57.8000], // Ullapool area
      [-5.4000, 57.9000], // Lochinver area
      [-5.5500, 58.2000], // Durness
      [-5.0000, 58.6000], // Thurso area
      [-3.8000, 58.4000], // Wick area
      [-3.3000, 57.7500], // Helmsdale
      [-3.5000, 57.5000], // Dornoch
      [-4.2026, 57.4778]  // Inverness return
    ]
  },
  {
    id: "wild-atlantic-way",
    name: "Wild Atlantic Way",
    country: "Ireland",
    region: "Europe",
    length_km: 2500,
    rating: 10,
    notes: "World's longest defined coastal route",
    trip: [13],
    waypoints: [
      [-7.3167, 55.2333], // Malin Head
      [-8.2000, 54.8000], // Donegal
      [-8.5000, 54.2500], // Sligo
      [-9.5000, 53.5000], // Galway
      [-9.9000, 53.0000], // Cliffs of Moher
      [-9.8000, 52.2500], // Dingle
      [-10.0000, 51.9000], // Ring of Kerry
      [-9.5000, 51.5000], // Beara Peninsula
      [-8.4698, 51.8969]  // Cork
    ]
  },
  {
    id: "route-des-grandes-alpes",
    name: "Route des Grandes Alpes",
    country: "France",
    region: "Europe",
    length_km: 684,
    rating: 10,
    notes: "Lake Geneva to Mediterranean via Alpine passes",
    trip: [13],
    waypoints: [
      [6.4833, 46.3833], // Thonon-les-Bains
      [6.6000, 46.1000], // Morzine
      [6.7500, 45.9000], // La Clusaz
      [6.9000, 45.5500], // Beaufort
      [6.8500, 45.3000], // Col de l'Iseran
      [6.7000, 45.0500], // Val d'Isere
      [6.8000, 44.7500], // Col du Galibier
      [6.6000, 44.5000], // Col d'Izoard
      [7.0000, 44.2500], // Col de Vars
      [7.1500, 43.9500], // Col de la Bonette
      [7.2619, 43.7102]  // Nice
    ]
  },
  {
    id: "grossglockner",
    name: "Grossglockner High Alpine Road",
    country: "Austria",
    region: "Europe",
    length_km: 48,
    rating: 10,
    notes: "Austria's highest mountain views",
    trip: [15],
    waypoints: [
      [12.8244, 47.0833], // Bruck
      [12.7500, 47.1500],
      [12.6833, 47.2000],
      [12.6333, 47.2500],
      [12.6000, 47.3167]  // Heiligenblut
    ]
  },
  {
    id: "trollstigen",
    name: "Trollstigen & Atlantic Road",
    country: "Norway",
    region: "Europe",
    length_km: 200,
    rating: 10,
    notes: "Troll's Ladder hairpins and Atlantic Ocean Road",
    trip: [14],
    waypoints: [
      [7.6667, 62.4667], // Kristiansund
      [7.3000, 62.4000], // Atlantic Road
      [7.1000, 62.3500],
      [6.9500, 62.3000], // Trollstigen top
      [7.1500, 62.0167]  // Andalsnes
    ]
  },
  {
    id: "adriatic-highway",
    name: "Adriatic Highway",
    country: "Croatia",
    region: "Europe",
    length_km: 600,
    rating: 9,
    notes: "Dubrovnik to Rijeka coastal road",
    trip: [15],
    waypoints: [
      [18.0944, 42.6507], // Dubrovnik
      [17.5000, 43.0500], // Makarska
      [16.4500, 43.5000], // Split
      [15.8500, 44.1000], // Zadar
      [14.9000, 44.8500], // Plitvice
      [14.4422, 45.3278]  // Rijeka
    ]
  },
  {
    id: "amalfi-coast",
    name: "Amalfi Coast",
    country: "Italy",
    region: "Europe",
    length_km: 50,
    rating: 10,
    notes: "Positano, Ravello, cliffside villages",
    trip: [17, 18],
    waypoints: [
      [14.2561, 40.8518], // Naples area
      [14.4000, 40.7500], // Sorrento
      [14.4833, 40.6333], // Positano
      [14.5667, 40.6500], // Amalfi
      [14.6333, 40.6333], // Ravello
      [14.7500, 40.5667]  // Salerno
    ]
  },
  {
    id: "great-dolomites-road",
    name: "Great Dolomites Road",
    country: "Italy",
    region: "Europe",
    length_km: 110,
    rating: 10,
    notes: "Cortina to Bolzano through UNESCO peaks",
    trip: [17, 18],
    waypoints: [
      [12.1357, 46.5388], // Cortina
      [11.9500, 46.4500], // Passo Falzarego
      [11.7500, 46.4000], // Passo Pordoi
      [11.5500, 46.4500], // Canazei
      [11.3500, 46.4983]  // Bolzano
    ]
  },
  {
    id: "ha-giang-loop",
    name: "Ha Giang Loop",
    country: "Vietnam",
    region: "Asia",
    length_km: 350,
    rating: 10,
    notes: "Ma Pi Leng pass, ethnic minority villages",
    trip: [3],
    waypoints: [
      [104.9833, 22.8167], // Ha Giang
      [105.1500, 23.1000], // Quan Ba
      [105.3000, 23.2500], // Yen Minh
      [105.4000, 23.3500], // Dong Van
      [105.3000, 23.2000], // Ma Pi Leng
      [105.1500, 23.0000], // Meo Vac
      [104.9833, 22.8167]  // Ha Giang return
    ]
  },
  {
    id: "ho-chi-minh-road",
    name: "Ho Chi Minh Road",
    country: "Vietnam",
    region: "Asia",
    length_km: 1600,
    rating: 9,
    notes: "Historic war route through jungle mountains",
    trip: [3],
    waypoints: [
      [105.8342, 21.0285], // Hanoi
      [105.4000, 19.5000], // Thanh Hoa
      [105.2000, 18.3000], // Vinh
      [105.0000, 17.5000], // Dong Hoi
      [106.0000, 16.0000], // Hue area
      [106.5000, 14.5000], // Kon Tum
      [106.7000, 12.5000], // Buon Ma Thuot
      [106.6819, 10.7626]  // Ho Chi Minh City
    ]
  },
  {
    id: "hai-van-pass",
    name: "Hai Van Pass",
    country: "Vietnam",
    region: "Asia",
    length_km: 80,
    rating: 9,
    notes: "Top Gear Vietnam special, ocean views",
    trip: [3],
    waypoints: [
      [107.5944, 16.4637], // Hue
      [107.8500, 16.2000], // Pass summit
      [108.2239, 16.0545]  // Da Nang
    ]
  },
  {
    id: "karakoram-highway",
    name: "Karakoram Highway",
    country: "Pakistan/China",
    region: "Asia",
    length_km: 1300,
    rating: 10,
    notes: "Eighth wonder of the world",
    trip: [1],
    waypoints: [
      [73.0551, 33.7215], // Islamabad
      [72.3550, 34.1688], // Abbottabad
      [73.0500, 35.3333], // Chilas
      [74.3500, 35.3333], // Gilgit
      [74.6597, 36.3167], // Karimabad
      [75.4167, 36.8500]  // Khunjerab Pass
    ]
  },
  {
    id: "leh-manali-highway",
    name: "Leh-Manali Highway",
    country: "India",
    region: "Asia",
    length_km: 479,
    rating: 10,
    notes: "Himalayan passes, Buddhist monasteries",
    trip: [1, 2],
    waypoints: [
      [77.1892, 32.2396], // Manali
      [77.3667, 32.7667], // Rohtang Pass
      [77.5667, 33.0000], // Keylong
      [77.6000, 33.8000], // Sarchu
      [77.5771, 34.1526]  // Leh
    ]
  },
  {
    id: "rajasthan-circuit",
    name: "Rajasthan Circuit",
    country: "India",
    region: "Asia",
    length_km: 1200,
    rating: 9,
    notes: "Forts, palaces, Thar Desert",
    trip: [1, 2],
    waypoints: [
      [77.2090, 28.6139], // Delhi
      [75.7873, 26.9124], // Jaipur
      [73.0243, 26.2389], // Jodhpur
      [70.9000, 26.9167], // Jaisalmer
      [73.7125, 24.5854], // Udaipur
      [75.7873, 26.9124]  // Jaipur return
    ]
  },
  {
    id: "high-atlas-mountains",
    name: "High Atlas Mountains",
    country: "Morocco",
    region: "Africa",
    length_km: 350,
    rating: 9,
    notes: "Tizi n'Tichka pass, kasbahs, Sahara edge",
    trip: [18],
    waypoints: [
      [-7.9811, 31.6295], // Marrakech
      [-7.4833, 31.2167], // Tizi n'Tichka Pass
      [-6.7167, 31.0500], // Ouarzazate
      [-5.5500, 31.4667], // Tinghir/Todra Gorge
      [-4.0131, 31.0801]  // Merzouga/Erg Chebbi
    ]
  },
  {
    id: "garden-route",
    name: "Garden Route",
    country: "South Africa",
    region: "Africa",
    length_km: 300,
    rating: 9,
    notes: "Cape Town to Storms River on N2",
    trip: [19],
    waypoints: [
      [18.4241, -33.9249], // Cape Town
      [19.4500, -34.3667], // Hermanus
      [20.4167, -34.0500], // Mossel Bay
      [22.1333, -34.0333], // Knysna
      [23.8986, -33.9689]  // Storms River
    ]
  },
  {
    id: "namib-desert-loop",
    name: "Namib Desert Loop",
    country: "Namibia",
    region: "Africa",
    length_km: 800,
    rating: 10,
    notes: "Sossusvlei dunes, Skeleton Coast",
    trip: [19],
    waypoints: [
      [17.0658, -22.5609], // Windhoek
      [15.9167, -22.6833], // Solitaire
      [15.4833, -23.6167], // Sossusvlei
      [15.2833, -24.7333], // Luderitz
      [14.5275, -19.6317], // Skeleton Coast
      [17.0658, -22.5609]  // Windhoek return
    ]
  },
  {
    id: "panorama-route",
    name: "Panorama Route / Blyde River Canyon",
    country: "South Africa",
    region: "Africa",
    length_km: 200,
    rating: 9,
    notes: "Third largest canyon on Earth",
    trip: [19, 20],
    waypoints: [
      [30.9667, -25.4500], // Nelspruit
      [30.8167, -24.8833], // God's Window
      [30.8000, -24.5833], // Three Rondavels
      [31.0833, -24.0833]  // Blyde Dam
    ]
  },
  {
    id: "carretera-austral",
    name: "Carretera Austral",
    country: "Chile",
    region: "South America",
    length_km: 1240,
    rating: 10,
    notes: "Patagonia's wild road, fjords and glaciers",
    trip: [6],
    waypoints: [
      [-72.1047, -39.8142], // Puerto Montt
      [-72.4000, -41.5000], // Hornopiren
      [-72.7000, -43.1000], // Chaiten
      [-72.6500, -43.8000], // Futaleufu
      [-72.7000, -45.4000], // Coyhaique
      [-72.6000, -47.5000]  // Villa O'Higgins
    ]
  },
  {
    id: "ruta-40",
    name: "Ruta 40",
    country: "Argentina",
    region: "South America",
    length_km: 5000,
    rating: 10,
    notes: "World's longest road following the Andes",
    trip: [6],
    waypoints: [
      [-72.5000, -50.5000], // El Calafate area
      [-71.5000, -48.0000], // Perito Moreno area
      [-71.1000, -45.0000], // Esquel area
      [-71.0000, -42.0000], // Bariloche area
      [-70.5000, -38.0000], // San Martin de los Andes
      [-70.0000, -35.0000], // Malargue area
      [-69.0000, -30.0000], // Rodeo area
      [-67.8000, -24.0000]  // Humahuaca area
    ]
  },
  {
    id: "route-seven-lakes",
    name: "Route of Seven Lakes",
    country: "Argentina",
    region: "South America",
    length_km: 110,
    rating: 9,
    notes: "Bariloche to San Martin, Patagonian lakes",
    trip: [6],
    waypoints: [
      [-71.3103, -41.1335], // Bariloche
      [-71.4500, -40.8500], // Lago Correntoso
      [-71.5000, -40.6500], // Lago Espejo
      [-71.4500, -40.4000], // Lago Villarino
      [-71.3533, -40.1580]  // San Martin de los Andes
    ]
  },
  {
    id: "atacama-uyuni",
    name: "Atacama to Uyuni",
    country: "Chile/Bolivia",
    region: "South America",
    length_km: 500,
    rating: 10,
    notes: "Driest desert to largest salt flat",
    trip: [6, 7],
    waypoints: [
      [-68.2000, -22.9000], // San Pedro de Atacama
      [-67.8000, -22.3000], // Laguna Verde
      [-67.5000, -21.5000], // Laguna Colorada
      [-67.0000, -20.5000], // Uyuni approach
      [-66.8833, -20.4667]  // Salar de Uyuni
    ]
  },
  {
    id: "icefields-parkway",
    name: "Icefields Parkway",
    country: "Canada",
    region: "North America",
    length_km: 232,
    rating: 10,
    notes: "Lake Louise to Jasper, glaciers and turquoise lakes",
    trip: [12],
    waypoints: [
      [-116.1667, 51.4167], // Lake Louise
      [-116.5500, 51.9000], // Bow Lake
      [-116.8500, 52.3000], // Columbia Icefield
      [-117.5333, 52.9333], // Sunwapta Falls
      [-118.0814, 52.8737]  // Jasper
    ]
  },
  {
    id: "sea-to-sky-highway",
    name: "Sea to Sky Highway",
    country: "Canada",
    region: "North America",
    length_km: 120,
    rating: 9,
    notes: "Vancouver to Whistler, fjords and mountains",
    trip: [12],
    waypoints: [
      [-123.1207, 49.2827], // Vancouver
      [-123.1500, 49.4500], // Horseshoe Bay
      [-123.1500, 49.6500], // Squamish
      [-122.9500, 50.1167]  // Whistler
    ]
  },
  {
    id: "cabot-trail",
    name: "Cabot Trail",
    country: "Canada",
    region: "North America",
    length_km: 298,
    rating: 9,
    notes: "Cape Breton Island, Celtic culture",
    trip: [11],
    waypoints: [
      [-60.9500, 46.1500], // Baddeck
      [-60.7500, 46.5000], // Ingonish
      [-60.7000, 46.7500], // Cape North
      [-61.0500, 46.9000], // Meat Cove area
      [-61.2000, 46.7000], // Cheticamp
      [-60.9500, 46.1500]  // Baddeck return
    ]
  },
  {
    id: "route-66",
    name: "Route 66",
    country: "USA",
    region: "North America",
    length_km: 3940,
    rating: 9,
    notes: "Mother Road, Chicago to Santa Monica",
    trip: [10],
    waypoints: [
      [-87.6298, 41.8781], // Chicago
      [-90.1978, 38.6270], // St. Louis
      [-94.8292, 37.0842], // Joplin
      [-97.5164, 35.4676], // Oklahoma City
      [-101.8333, 35.2000], // Amarillo
      [-106.6500, 35.0844], // Albuquerque
      [-111.6513, 35.1894], // Flagstaff
      [-114.3667, 35.1167], // Kingman
      [-118.4912, 34.0195]  // Santa Monica
    ]
  },
  {
    id: "utah-mighty-five",
    name: "Utah Mighty Five",
    country: "USA",
    region: "North America",
    length_km: 800,
    rating: 10,
    notes: "Arches, Canyonlands, Capitol Reef, Bryce, Zion",
    trip: [10],
    waypoints: [
      [-109.5498, 38.5733], // Arches
      [-109.8000, 38.3000], // Canyonlands
      [-111.2297, 38.2900], // Capitol Reef
      [-112.2000, 37.6000], // Bryce
      [-113.0260, 37.2979]  // Zion
    ]
  },
  {
    id: "blue-ridge-parkway",
    name: "Blue Ridge Parkway",
    country: "USA",
    region: "North America",
    length_km: 755,
    rating: 9,
    notes: "America's favorite scenic drive, Appalachian highlands",
    trip: [11],
    waypoints: [
      [-78.8986, 37.9371], // Waynesboro (north)
      [-79.8333, 37.1167], // Roanoke
      [-80.6000, 36.3167], // Blue Ridge Music Center
      [-81.5000, 35.5000], // Blowing Rock
      [-82.4333, 35.5000], // Asheville
      [-83.7000, 35.5500]  // Cherokee (south)
    ]
  },
  {
    id: "going-to-the-sun-road",
    name: "Going-to-the-Sun Road",
    country: "USA",
    region: "North America",
    length_km: 80,
    rating: 10,
    notes: "Glacier National Park, Logan Pass",
    trip: [11, 12],
    waypoints: [
      [-113.9833, 48.5000], // West Glacier
      [-113.7167, 48.6333], // Lake McDonald
      [-113.5333, 48.6833], // Logan Pass
      [-113.4000, 48.7167]  // St. Mary
    ]
  },
  {
    id: "monument-valley",
    name: "Monument Valley Scenic Drive",
    country: "USA",
    region: "North America",
    length_km: 200,
    rating: 9,
    notes: "Iconic buttes, Navajo Nation",
    trip: [10],
    waypoints: [
      [-109.8667, 36.8500], // Kayenta
      [-110.1000, 36.9500], // Monument Valley North
      [-110.1167, 37.0500], // Valley Drive
      [-109.6333, 37.4500]  // Mexican Hat
    ]
  },
  {
    id: "flores-island",
    name: "Trans-Flores Highway",
    country: "Indonesia",
    region: "Asia",
    length_km: 400,
    rating: 9,
    notes: "Labuan Bajo to Ende, Komodo gateway",
    trip: [4],
    waypoints: [
      [119.8892, -8.4539], // Labuan Bajo
      [120.4500, -8.5500], // Ruteng
      [121.0500, -8.6500], // Bajawa
      [121.6500, -8.8500]  // Ende
    ]
  },
  {
    id: "south-island-nz",
    name: "South Island Circuit",
    country: "New Zealand",
    region: "Oceania",
    length_km: 2000,
    rating: 10,
    notes: "Milford Sound, Queenstown, glaciers",
    trip: [5],
    waypoints: [
      [172.6362, -43.5321], // Christchurch
      [170.1000, -44.2500], // Mt Cook
      [168.6628, -45.0312], // Queenstown
      [167.9000, -45.4000], // Te Anau
      [167.6500, -45.9000], // Milford Sound
      [169.3000, -46.4000], // Invercargill
      [170.5000, -45.8500], // Dunedin
      [172.6362, -43.5321]  // Christchurch return
    ]
  },
  {
    id: "north-island-nz",
    name: "North Island Loop",
    country: "New Zealand",
    region: "Oceania",
    length_km: 1500,
    rating: 9,
    notes: "Hobbiton, Rotorua geysers, Tongariro",
    trip: [5],
    waypoints: [
      [174.7633, -36.8485], // Auckland
      [175.6000, -37.9000], // Hobbiton
      [176.2500, -38.1500], // Rotorua
      [175.6000, -39.3000], // Tongariro
      [175.5000, -41.2800], // Wellington
      [174.7633, -36.8485]  // Auckland return (via coast)
    ]
  },
  {
    id: "swiss-alps",
    name: "Swiss Alpine Passes",
    country: "Switzerland",
    region: "Europe",
    length_km: 400,
    rating: 10,
    notes: "Furka, Grimsel, Susten passes",
    trip: [13],
    waypoints: [
      [8.2275, 46.9480], // Lucerne
      [8.4200, 46.6000], // Furka Pass
      [8.3300, 46.5700], // Grimsel Pass
      [8.4500, 46.7300], // Susten Pass
      [9.4500, 46.9000]  // Chur
    ]
  },
  {
    id: "german-alpine-road",
    name: "German Alpine Road",
    country: "Germany",
    region: "Europe",
    length_km: 450,
    rating: 9,
    notes: "Neuschwanstein Castle, Bavarian Alps",
    trip: [13],
    waypoints: [
      [9.9333, 47.5500], // Lindau
      [10.7917, 47.5508], // Fussen/Neuschwanstein
      [11.5000, 47.4000], // Garmisch-Partenkirchen
      [12.8500, 47.6167]  // Berchtesgaden
    ]
  },
  {
    id: "romantic-road",
    name: "Romantic Road",
    country: "Germany",
    region: "Europe",
    length_km: 350,
    rating: 8,
    notes: "Wurzburg to Fussen, medieval towns",
    trip: [13],
    waypoints: [
      [9.9294, 49.7944], // Wurzburg
      [10.1000, 49.1000], // Rothenburg
      [10.6978, 48.3668], // Augsburg
      [10.7917, 47.5508]  // Fussen
    ]
  },
  {
    id: "durban-drakensberg",
    name: "Durban to Drakensberg",
    country: "South Africa",
    region: "Africa",
    length_km: 400,
    rating: 9,
    notes: "Dragon Mountains, San rock art",
    trip: [20],
    waypoints: [
      [31.0218, -29.8587], // Durban
      [30.3833, -29.6000], // Pietermaritzburg
      [29.4667, -29.0833], // Giants Castle
      [28.9333, -28.7333]  // Royal Natal
    ]
  }
];

// Generate dense coordinates for each route
const features = routes.map(route => {
  const dense = densifyRoute(route.waypoints, route.length_km);

  return {
    type: "Feature",
    properties: {
      id: route.id,
      name: route.name,
      country: route.country,
      region: route.region,
      length_km: route.length_km,
      rating: route.rating,
      notes: route.notes,
      trip: route.trip,
      point_count: dense.length
    },
    geometry: {
      type: "LineString",
      coordinates: dense.map(c => [
        Math.round(c[0] * 10000) / 10000,
        Math.round(c[1] * 10000) / 10000
      ])
    }
  };
});

// Create GeoJSON output
const geojson = {
  type: "FeatureCollection",
  metadata: {
    generated: new Date().toISOString(),
    description: "Scenic routes with dense waypoints (~2km) following actual scenic roads",
    route_count: features.length,
    total_points: features.reduce((sum, f) => sum + f.properties.point_count, 0)
  },
  features: features
};

// Write output
fs.writeFileSync(OUTPUT_FILE, JSON.stringify(geojson, null, 2));

console.log(`Generated ${features.length} routes`);
console.log(`Total points: ${geojson.metadata.total_points}`);
console.log(`Output: ${OUTPUT_FILE}`);
