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

// Trip 3: Southeast Asia (car arrives in Laem Chabang/Bangkok from Chittagong)
const waypointsPart3 = [
  // Start in Thailand - car pickup
  { name: "Bangkok", coords: [100.5018, 13.7563] },
  { name: "Ayutthaya", coords: [100.5877, 14.3532] },
  { name: "Sukhothai Historical Park", coords: [99.7031, 17.0170] },
  // Northern Thailand
  { name: "Chiang Mai", coords: [98.9853, 18.7883] },
  { name: "Pai", coords: [98.4400, 19.3597] },
  { name: "Mae Hong Son", coords: [97.9654, 19.2990] },
  { name: "Mae Sariang", coords: [97.9333, 18.1667] },
  { name: "Chiang Mai (loop return)", coords: [98.9853, 18.7883] },
  { name: "Chiang Rai (White Temple)", coords: [99.8325, 19.8244] },
  // Cross to Laos
  { name: "Huay Xai (border)", coords: [100.4167, 20.2833] },
  { name: "Luang Prabang", coords: [102.1347, 19.8856] },
  { name: "Vang Vieng", coords: [102.4510, 18.9220] },
  { name: "Vientiane", coords: [102.6331, 17.9757] },
  { name: "Phonsavan (Plain of Jars)", coords: [103.1833, 19.4500] },
  // Cross to Vietnam (north)
  { name: "Dien Bien Phu", coords: [103.0167, 21.3833] },
  { name: "Sapa", coords: [103.8440, 22.3364] },
  { name: "Hanoi", coords: [105.8542, 21.0285] },
  { name: "Halong Bay", coords: [107.0448, 20.9101] },
  { name: "Ninh Binh", coords: [105.9750, 20.2506] },
  { name: "Phong Nha Caves", coords: [106.1348, 17.5915] },
  { name: "Hue (Imperial City)", coords: [107.5847, 16.4637] },
  { name: "Hai Van Pass", coords: [108.1167, 16.1833] },
  { name: "Da Nang", coords: [108.2022, 16.0544] },
  { name: "Hoi An", coords: [108.3380, 15.8801] },
  // Cross back to Laos
  { name: "Lao Bao (border)", coords: [106.6000, 16.6167] },
  { name: "Savannakhet", coords: [104.7500, 16.5500] },
  { name: "Pakse", coords: [105.7833, 15.1167] },
  { name: "Wat Phu", coords: [105.8167, 14.8500] },
  { name: "4000 Islands (Don Det)", coords: [105.9167, 14.1167] },
  // Cross to Cambodia
  { name: "Stung Treng", coords: [105.9667, 13.5333] },
  { name: "Siem Reap (Angkor)", coords: [103.8600, 13.3622] },
  { name: "Tonle Sap Lake", coords: [104.0000, 12.9000] },
  // Back to Thailand
  { name: "Poipet (border)", coords: [102.5667, 13.6500] },
  { name: "Bangkok (return)", coords: [100.5018, 13.7563] },
  // Kanchanaburi detour
  { name: "Kanchanaburi (River Kwai)", coords: [99.5328, 14.0228] },
  { name: "Erawan Falls", coords: [99.1419, 14.3744] },
  // South Thailand
  { name: "Hua Hin", coords: [99.9587, 12.5684] },
  { name: "Khao Sok National Park", coords: [98.5269, 8.9167] },
  { name: "Phuket", coords: [98.3923, 7.8804] },
  { name: "Krabi", coords: [99.0403, 8.0863] },
  // Cross to Malaysia
  { name: "Langkawi (ferry)", coords: [99.7253, 6.3500] },
  { name: "Georgetown (Penang)", coords: [100.3327, 5.4164] },
  { name: "Cameron Highlands", coords: [101.3833, 4.4833] },
  { name: "Kuala Lumpur", coords: [101.6869, 3.1390] },
  { name: "Malacca", coords: [102.2500, 2.1896] },
  { name: "Johor Bahru (store car)", coords: [103.7500, 1.4655] }
  // END - Store car in JB, visit Singapore
];

// Trip 4: Indonesia + Timor-Leste (car pickup from JB storage, ship to Darwin at end)
const waypointsPart4 = [
  // JB to Jakarta via ferries (ferry segments - straight lines)
  { name: "Johor Bahru (pickup)", coords: [103.7500, 1.4655] },
  // Sumatra Loop - UP via East Route (Jalintim)
  { name: "Jakarta", coords: [106.8456, -6.2088] },
  { name: "Merak Ferry", coords: [105.9833, -6.0333] },
  { name: "Bakauheni", coords: [105.7333, -5.8500] },
  { name: "Bandar Lampung", coords: [105.2611, -5.4294] },
  { name: "Palembang", coords: [104.7458, -2.9761] },
  { name: "Jambi", coords: [103.6131, -1.6101] },
  { name: "Pekanbaru", coords: [101.4500, 0.5071] },
  { name: "Parapat (Lake Toba)", coords: [98.9333, 2.6667] },
  { name: "Samosir Island", coords: [98.8500, 2.6167] },
  { name: "Berastagi", coords: [98.5092, 3.1941] },
  { name: "Medan", coords: [98.6722, 3.5952] },
  // Return south - DOWN via West Route (Jalinbar) - different scenic route
  { name: "Berastagi (return)", coords: [98.5092, 3.1941] },
  { name: "Bukittinggi", coords: [100.3691, -0.3055] },
  { name: "Padang", coords: [100.3543, -0.9471] },
  { name: "Bengkulu", coords: [102.2655, -3.8004] },
  { name: "Bandar Lampung (return)", coords: [105.2611, -5.4294] },
  { name: "Merak Ferry (return)", coords: [105.9833, -6.0333] },
  { name: "Jakarta (return)", coords: [106.8456, -6.2088] },
  // Java
  { name: "Yogyakarta", coords: [110.3606, -7.7872] },
  { name: "Borobudur Temple", coords: [110.2036, -7.6079] },
  { name: "Prambanan Temple", coords: [110.4914, -7.7520] },
  { name: "Mount Bromo", coords: [112.9500, -7.9425] },
  { name: "Banyuwangi", coords: [114.3575, -8.2194] },
  // Bali - North Coast Route (avoiding tourist traps)
  { name: "Gilimanuk (ferry)", coords: [114.4389, -8.1622] },
  { name: "Pemuteran", coords: [114.6453, -8.1286] },
  { name: "Lovina", coords: [115.0253, -8.1519] },
  { name: "Singaraja", coords: [115.0892, -8.1161] },
  { name: "Munduk", coords: [115.0833, -8.2667] },
  { name: "MM Villa Canggu", coords: [115.1480737, -8.6263497] },
  { name: "Amed", coords: [115.6500, -8.3500] },
  { name: "Padang Bai", coords: [115.5083, -8.5333] },
  // Island Hopping
  { name: "Lombok (Lembar)", coords: [116.0667, -8.7333] },
  { name: "Senggigi", coords: [116.0500, -8.4667] },
  { name: "Sumbawa Besar", coords: [117.4167, -8.4833] },
  { name: "Bima", coords: [118.7167, -8.4667] },
  { name: "Labuan Bajo", coords: [119.8833, -8.4833] },
  { name: "Ruteng", coords: [120.4667, -8.6167] },
  { name: "Bajawa", coords: [120.9667, -8.7833] },
  { name: "Moni (Kelimutu)", coords: [121.7833, -8.7667] },
  { name: "Maumere", coords: [122.2167, -8.6167] },
  { name: "Larantuka", coords: [123.0000, -8.3500] },
  { name: "Kupang", coords: [123.5833, -10.1667] },
  // Timor-Leste
  { name: "Dili", coords: [125.5736, -8.5586] },
  { name: "Mount Ramelau", coords: [125.5167, -8.8667] },
  { name: "Dili (shipping)", coords: [125.5736, -8.5586] }
];

// Trip 5: Australia (fly to Darwin, pick up shipped car, ship to Auckland at end)
const waypointsPart5 = [
  // Top End
  { name: "Darwin", coords: [130.8456, -12.4634] },
  { name: "Kakadu", coords: [132.9167, -13.0000] },
  { name: "Katherine", coords: [132.2710, -14.4521] },
  { name: "Kununurra", coords: [128.7378, -15.7747] },
  { name: "Bungle Bungles", coords: [128.4000, -17.5333] },
  { name: "Halls Creek", coords: [127.6703, -18.2281] },
  { name: "Fitzroy Crossing", coords: [125.5667, -18.1833] },
  { name: "Broome", coords: [122.2358, -17.9614] },
  // West Coast
  { name: "Port Hedland", coords: [118.5750, -20.3103] },
  { name: "Karijini", coords: [118.5000, -22.6667] },
  { name: "Exmouth (Ningaloo)", coords: [114.1244, -21.9306] },
  { name: "Coral Bay", coords: [113.7667, -23.1500] },
  { name: "Carnarvon", coords: [113.6594, -24.8842] },
  { name: "Geraldton", coords: [114.6144, -28.7781] },
  { name: "Pinnacles", coords: [115.1667, -30.6000] },
  { name: "Perth", coords: [115.8605, -31.9505] },
  { name: "Margaret River", coords: [115.0411, -33.9536] },
  { name: "Albany", coords: [117.8836, -35.0228] },
  { name: "Esperance", coords: [121.8913, -33.8611] },
  // Nullarbor
  { name: "Nullarbor (Eucla)", coords: [128.8833, -31.6833] },
  { name: "Ceduna", coords: [133.6767, -32.1300] },
  { name: "Port Augusta", coords: [137.7833, -32.4922] },
  // Red Centre
  { name: "Coober Pedy", coords: [134.7550, -29.0135] },
  { name: "Uluru", coords: [131.0369, -25.3444] },
  { name: "Kata Tjuta", coords: [130.7389, -25.3056] },
  { name: "Alice Springs", coords: [133.8807, -23.6980] },
  { name: "Port Augusta (return)", coords: [137.7833, -32.4922] },
  // South coast
  { name: "Adelaide", coords: [138.6007, -34.9285] },
  { name: "Great Ocean Road Start", coords: [143.5236, -38.6833] },
  { name: "Twelve Apostles", coords: [143.1050, -38.6656] },
  { name: "Geelong", coords: [144.3500, -38.1500] },
  { name: "Melbourne", coords: [144.9631, -37.8136] },
  // Tasmania
  { name: "Devonport", coords: [146.3667, -41.1833] },
  { name: "Cradle Mountain", coords: [145.9510, -41.6840] },
  { name: "Hobart", coords: [147.3272, -42.8821] },
  { name: "Port Arthur", coords: [147.8500, -43.1500] },
  { name: "Freycinet", coords: [148.2500, -42.1667] },
  { name: "Devonport (return)", coords: [146.3667, -41.1833] },
  // East Coast
  { name: "Geelong (return)", coords: [144.3500, -38.1500] },
  { name: "Melbourne (return)", coords: [144.9631, -37.8136] },
  { name: "Canberra", coords: [149.1300, -35.2809] },
  { name: "Sydney", coords: [151.2093, -33.8688] },
  { name: "Byron Bay", coords: [153.6167, -28.6500] },
  { name: "Brisbane", coords: [153.0251, -27.4698] },
  // Queensland East Coast
  { name: "Rainbow Beach (K'gari)", coords: [153.0833, -25.9000] },
  { name: "Hervey Bay", coords: [152.8483, -25.2881] },
  { name: "Town of 1770", coords: [151.8803, -24.1567] },
  { name: "Agnes Water", coords: [151.9031, -24.2111] },
  { name: "Rockhampton", coords: [150.5089, -23.3792] },
  { name: "Mackay", coords: [149.1868, -21.1411] },
  { name: "Airlie Beach (Whitsundays)", coords: [148.7167, -20.2667] },
  { name: "Bowen", coords: [148.2333, -20.0167] },
  { name: "Townsville", coords: [146.8169, -19.2590] },
  { name: "Mission Beach", coords: [146.1000, -17.8667] },
  { name: "Cairns", coords: [145.7781, -16.9186] },
  // Tropical North Queensland
  { name: "Port Douglas", coords: [145.4655, -16.4836] },
  { name: "Daintree Ferry", coords: [145.4161, -16.2694] },
  { name: "Cape Tribulation", coords: [145.4667, -16.1667] },
  { name: "Daintree (return)", coords: [145.4161, -16.2694] },
  { name: "Cairns (return)", coords: [145.7781, -16.9186] },
  // Ship from Townsville to Auckland
  { name: "Townsville (shipping)", coords: [146.8169, -19.2590] }
];

// Trip 7: South America Epic (Valparaíso to Cartagena, 100 days)
const waypointsPart7 = [
  // Part 1: Valparaíso to Mendoza via Paso de los Caracoles
  { name: "Valparaíso", coords: [-71.6273, -33.0472] },
  { name: "Santiago", coords: [-70.6483, -33.4489] },
  { name: "Paso de los Caracoles", coords: [-70.0667, -32.8333] },
  { name: "Mendoza", coords: [-68.8272, -32.8908] },
  // Ruta 40 South
  { name: "San Rafael", coords: [-68.3354, -34.6176] },
  { name: "Malargüe", coords: [-69.5833, -35.4667] },
  { name: "Bardas Blancas", coords: [-69.8000, -35.8667] },
  { name: "Chos Malal", coords: [-70.2667, -37.3833] },
  { name: "Zapala", coords: [-70.0667, -38.9000] },
  { name: "Junín de los Andes", coords: [-71.0667, -39.9500] },
  // Seven Lakes Route
  { name: "San Martín de los Andes", coords: [-71.3519, -40.1575] },
  { name: "Bariloche", coords: [-71.3082, -41.1335] },
  // Cross to Chile - Chiloé & Carretera Austral
  { name: "Osorno", coords: [-73.1500, -40.5667] },
  { name: "Puerto Montt", coords: [-72.9369, -41.4693] },
  { name: "Castro (Chiloé)", coords: [-73.7667, -42.4667] },
  { name: "Puerto Montt (return)", coords: [-72.9369, -41.4693] },
  // Carretera Austral
  { name: "Hornopirén", coords: [-72.4333, -41.9500] },
  { name: "Chaitén", coords: [-72.7167, -42.9167] },
  { name: "La Junta", coords: [-72.4000, -43.9167] },
  { name: "Coyhaique", coords: [-72.0667, -45.5667] },
  { name: "Cochrane", coords: [-72.5667, -47.2500] },
  { name: "Villa O'Higgins", coords: [-72.5667, -48.4667] },
  // Cross to Argentina - Southern Patagonia
  { name: "El Chaltén", coords: [-72.8861, -49.3311] },
  { name: "El Calafate", coords: [-72.2761, -50.3378] },
  { name: "Ushuaia", coords: [-68.3029, -54.8019] },
  { name: "El Calafate (return)", coords: [-72.2761, -50.3378] },
  // Ruta 40 North to Atlantic
  { name: "Perito Moreno (town)", coords: [-70.9333, -46.5167] },
  { name: "Puerto Madryn", coords: [-65.0364, -42.7683] },
  // Atlantic Coast
  { name: "Buenos Aires", coords: [-58.3816, -34.6037] },
  // Uruguay
  { name: "Colonia del Sacramento", coords: [-57.8400, -34.4626] },
  { name: "Montevideo", coords: [-56.1645, -34.9011] },
  { name: "Punta del Este", coords: [-54.9333, -34.9667] },
  // Brazil
  { name: "Porto Alegre", coords: [-51.2177, -30.0346] },
  { name: "Florianópolis", coords: [-48.5477, -27.5969] },
  { name: "Rio de Janeiro", coords: [-43.1729, -22.9068] },
  { name: "Ouro Preto", coords: [-43.5046, -20.3855] },
  { name: "Foz do Iguaçu", coords: [-54.5854, -25.5163] },
  // Northwest Argentina with Calchaquí Valleys
  { name: "Salta", coords: [-65.4117, -24.7821] },
  { name: "Cachi", coords: [-66.1667, -25.1167] },
  { name: "Molinos", coords: [-66.3000, -25.4500] },
  { name: "Cafayate", coords: [-65.9764, -26.0728] },
  { name: "Salta (return)", coords: [-65.4117, -24.7821] },
  // Chile - Atacama
  { name: "San Pedro de Atacama", coords: [-68.1997, -22.9087] },
  // Bolivia - Scenic High Plateau Route
  { name: "Laguna Verde", coords: [-67.8167, -22.7833] },
  { name: "Laguna Colorada", coords: [-67.7833, -22.2000] },
  { name: "Sol de Mañana Geysers", coords: [-67.7500, -22.4333] },
  { name: "Uyuni", coords: [-66.8250, -20.4600] },
  { name: "Sucre", coords: [-65.2550, -19.0196] },
  { name: "La Paz", coords: [-68.1193, -16.4897] },
  { name: "Copacabana (Lake Titicaca)", coords: [-69.0864, -16.1661] },
  // Peru
  { name: "Puno", coords: [-70.0219, -15.8402] },
  { name: "Cusco", coords: [-71.9675, -13.5319] },
  { name: "Ollantaytambo", coords: [-72.2631, -13.2575] },
  { name: "Cusco (return)", coords: [-71.9675, -13.5319] },
  { name: "Nazca", coords: [-75.0000, -14.8333] },
  { name: "Huacachina", coords: [-75.7639, -14.0875] },
  { name: "Lima", coords: [-77.0428, -12.0464] },
  { name: "Huaraz", coords: [-77.5278, -9.5300] },
  // Ecuador
  { name: "Cuenca", coords: [-79.0053, -2.9001] },
  { name: "Quito", coords: [-78.4678, -0.1807] },
  { name: "Baños", coords: [-78.4247, -1.3928] },
  { name: "Coca (Yasuní)", coords: [-76.9833, -0.4667] },
  { name: "Quito (return)", coords: [-78.4678, -0.1807] },
  // Colombia via Ipiales border
  { name: "Ipiales (border)", coords: [-77.6419, 0.8281] },
  { name: "Popayán", coords: [-76.6064, 2.4419] },
  { name: "Bogotá", coords: [-74.0721, 4.7110] },
  { name: "Tatacoa Desert", coords: [-75.1667, 3.2333] },
  { name: "Salento", coords: [-75.5667, 4.6333] },
  { name: "Medellín", coords: [-75.5636, 6.2518] },
  { name: "Guatapé", coords: [-75.1564, 6.2325] },
  { name: "Santa Marta", coords: [-74.1990, 11.2408] },
  { name: "Cartagena", coords: [-75.5144, 10.3910] }
];

// Trip 6: New Zealand (Townsville ship to Auckland, 10-week round trip)
const waypointsPart6 = [
  // North Island - Far North
  { name: "Auckland", coords: [174.7633, -36.8485] },
  { name: "Whangarei", coords: [174.3239, -35.7253] },
  { name: "Bay of Islands (Paihia)", coords: [174.0908, -35.2838] },
  { name: "Kaitaia", coords: [173.2639, -35.1128] },
  { name: "Cape Reinga", coords: [172.6806, -34.4278] },
  { name: "Opononi (Hokianga)", coords: [173.3833, -35.5167] },
  { name: "Waipoua Forest", coords: [173.5500, -35.6333] },
  { name: "Dargaville", coords: [173.8758, -35.9361] },
  { name: "Auckland (return)", coords: [174.7633, -36.8485] },
  // North Island - Coromandel & East Cape
  { name: "Coromandel (Whitianga)", coords: [175.7000, -36.8333] },
  { name: "Mount Maunganui", coords: [176.1721, -37.6349] },
  { name: "Whakatane", coords: [176.9940, -37.9533] },
  { name: "Opotiki", coords: [177.2867, -38.0117] },
  { name: "Te Araroa (East Cape)", coords: [178.0694, -37.6347] },
  { name: "Gisborne", coords: [178.0178, -38.6629] },
  // North Island - Hawke's Bay & Central
  { name: "Napier", coords: [176.9120, -39.4902] },
  { name: "Taupo", coords: [176.0702, -38.6857] },
  { name: "Rotorua", coords: [176.2500, -38.1378] },
  { name: "Tongariro", coords: [175.6461, -39.1333] },
  // North Island - Taranaki & Wellington
  { name: "New Plymouth", coords: [174.0752, -39.0556] },
  { name: "Whanganui", coords: [175.0479, -39.9301] },
  { name: "Palmerston North", coords: [175.6082, -40.3523] },
  { name: "Martinborough", coords: [175.4597, -41.2194] },
  { name: "Cape Palliser", coords: [175.2906, -41.6103] },
  { name: "Wellington", coords: [174.7762, -41.2865] },
  // South Island - Marlborough & Kaikoura
  { name: "Picton", coords: [174.0011, -41.2906] },
  { name: "Blenheim", coords: [173.9610, -41.5138] },
  { name: "Kaikoura", coords: [173.6810, -42.4010] },
  // South Island - Canterbury & East Coast
  { name: "Christchurch", coords: [172.6362, -43.5321] },
  { name: "Akaroa", coords: [172.9681, -43.8033] },
  { name: "Oamaru", coords: [170.9714, -45.0970] },
  { name: "Dunedin", coords: [170.5006, -45.8788] },
  // South Island - Catlins & Deep South
  { name: "Nugget Point", coords: [169.8114, -46.4489] },
  { name: "Curio Bay", coords: [169.0906, -46.6558] },
  { name: "Slope Point", coords: [168.8608, -46.6764] },
  { name: "Invercargill", coords: [168.3538, -46.4132] },
  // South Island - Fiordland
  { name: "Te Anau", coords: [167.7180, -45.4140] },
  { name: "Milford Sound", coords: [167.9256, -44.6341] },
  { name: "Te Anau (return)", coords: [167.7180, -45.4140] },
  // South Island - Central Otago
  { name: "Queenstown", coords: [168.6626, -45.0312] },
  { name: "Glenorchy", coords: [168.3820, -44.8510] },
  { name: "Queenstown (return)", coords: [168.6626, -45.0312] },
  { name: "Wanaka", coords: [169.1500, -44.6833] },
  // South Island - West Coast
  { name: "Haast", coords: [169.0428, -43.8814] },
  { name: "Fox Glacier", coords: [170.0178, -43.4642] },
  { name: "Franz Josef Glacier", coords: [170.1833, -43.4833] },
  { name: "Hokitika", coords: [170.9678, -42.7175] },
  { name: "Punakaiki", coords: [171.3360, -42.1080] },
  // South Island - Nelson & Top of South
  { name: "Nelson", coords: [173.2840, -41.2706] },
  { name: "Abel Tasman (Marahau)", coords: [173.0114, -40.9939] },
  { name: "Takaka (Golden Bay)", coords: [172.8078, -40.8553] },
  { name: "Farewell Spit", coords: [172.8689, -40.5447] },
  { name: "Nelson (return)", coords: [173.2840, -41.2706] },
  { name: "Picton (return)", coords: [174.0011, -41.2906] },
  { name: "Christchurch (end)", coords: [172.6362, -43.5321] }
];

// Trip 8: Panama to Oaxaca (Central America & Southern Mexico, 105 days)
const waypointsPart8 = [
  // Panama
  { name: "Panama City", coords: [-79.5197, 8.9824] },
  { name: "Miraflores Locks", coords: [-79.5467, 9.0153] },
  { name: "Boquete", coords: [-82.4408, 8.7792] },
  { name: "Bocas del Toro (Almirante)", coords: [-82.3500, 9.3000] },
  // Costa Rica - Caribbean
  { name: "Puerto Viejo", coords: [-82.7536, 9.6565] },
  { name: "Cahuita", coords: [-82.8381, 9.7378] },
  // Costa Rica - Central
  { name: "La Fortuna (Arenal)", coords: [-84.6428, 10.4678] },
  { name: "Monteverde", coords: [-84.8252, 10.3102] },
  // Costa Rica - Pacific
  { name: "Manuel Antonio", coords: [-84.1561, 9.3925] },
  { name: "Puerto Jiménez (Osa)", coords: [-83.2994, 8.5261] },
  // Nicaragua
  { name: "Granada", coords: [-85.9560, 11.9292] },
  { name: "San Jorge (Ometepe ferry)", coords: [-85.8033, 11.4536] },
  { name: "Granada (return)", coords: [-85.9560, 11.9292] },
  { name: "Masaya Volcano", coords: [-86.1613, 11.9842] },
  { name: "León", coords: [-86.8780, 12.4379] },
  // Honduras
  { name: "Copán Ruinas", coords: [-89.1417, 14.8500] },
  { name: "Lake Yojoa", coords: [-87.9833, 14.8500] },
  { name: "La Ceiba", coords: [-86.7919, 15.7631] },
  // El Salvador
  { name: "Santa Ana", coords: [-89.5597, 13.9928] },
  { name: "Ruta de las Flores (Juayúa)", coords: [-89.7444, 13.8419] },
  { name: "El Tunco", coords: [-89.3833, 13.4933] },
  // Guatemala
  { name: "Antigua", coords: [-90.7292, 14.5586] },
  { name: "Lake Atitlán (Panajachel)", coords: [-91.1597, 14.7411] },
  { name: "Chichicastenango", coords: [-91.1117, 14.9433] },
  { name: "Semuc Champey (Lanquín)", coords: [-89.9667, 15.5333] },
  { name: "Flores (Tikal)", coords: [-89.8833, 16.9300] },
  { name: "Tikal", coords: [-89.6256, 17.2220] },
  { name: "Flores (return)", coords: [-89.8833, 16.9300] },
  // Belize
  { name: "San Ignacio", coords: [-89.0694, 17.1589] },
  { name: "Belize City", coords: [-88.1975, 17.5046] },
  { name: "Placencia", coords: [-88.3667, 16.5167] },
  { name: "Belize City (return)", coords: [-88.1975, 17.5046] },
  // Mexico - Yucatán
  { name: "Chetumal", coords: [-88.2961, 18.5001] },
  { name: "Bacalar", coords: [-88.3942, 18.6756] },
  { name: "Tulum", coords: [-87.4650, 20.2114] },
  { name: "Valladolid", coords: [-88.2022, 20.6897] },
  { name: "Chichén Itzá", coords: [-88.5686, 20.6843] },
  { name: "Mérida", coords: [-89.5926, 20.9674] },
  { name: "Celestún", coords: [-90.4033, 20.8600] },
  { name: "Mérida (return)", coords: [-89.5926, 20.9674] },
  { name: "Campeche", coords: [-90.5349, 19.8301] },
  // Mexico - Chiapas
  { name: "Palenque", coords: [-91.9822, 17.4838] },
  { name: "San Cristóbal de las Casas", coords: [-92.6376, 16.7370] },
  // Mexico - Oaxaca (scenic coastal route via Highway 175)
  { name: "Santo Domingo Tehuantepec", coords: [-95.2392, 16.3239] },
  { name: "Huatulco (Barra de Copalita)", coords: [-96.1344, 15.7833] },
  { name: "Pochutla", coords: [-96.4667, 15.7500] },
  { name: "Santa Catarina Juquila", coords: [-97.2917, 16.2372] },
  { name: "Pochutla (return)", coords: [-96.4667, 15.7500] },
  { name: "Miahuatlán (Highway 175)", coords: [-96.5931, 16.3278] },
  { name: "Oaxaca City", coords: [-96.7266, 17.0732] }
];

// Trip 9: Oaxaca to Los Angeles (Mexico Pacific Coast, Copper Canyon, Baja, ~63 days)
const waypointsPart9 = [
  // Central Mexico
  { name: "Oaxaca City (departure)", coords: [-96.7266, 17.0732] },
  { name: "Tehuacán", coords: [-97.3928, 18.4617] },
  { name: "Puebla", coords: [-98.2063, 19.0414] },
  { name: "Cholula", coords: [-98.3033, 19.0633] },
  { name: "Mexico City", coords: [-99.1332, 19.4326] },
  { name: "Teotihuacan", coords: [-98.8433, 19.6925] },
  { name: "Mexico City (return)", coords: [-99.1332, 19.4326] },
  // Pacific Coast - Highway 200
  { name: "Acapulco", coords: [-99.8901, 16.8531] },
  { name: "Zihuatanejo", coords: [-101.5514, 17.6425] },
  { name: "Lázaro Cárdenas", coords: [-102.2003, 17.9578] },
  { name: "Manzanillo", coords: [-104.3386, 19.0522] },
  { name: "Barra de Navidad", coords: [-104.6833, 19.2000] },
  { name: "Puerto Vallarta", coords: [-105.2253, 20.6534] },
  { name: "Sayulita", coords: [-105.4369, 20.8694] },
  { name: "Puerto Vallarta (return)", coords: [-105.2253, 20.6534] },
  { name: "Mazatlán", coords: [-106.4111, 23.2494] },
  // Devil's Backbone & Copper Canyon
  { name: "Devil's Backbone (Espinazo)", coords: [-105.8667, 23.7667] },
  { name: "Durango", coords: [-104.6572, 24.0277] },
  { name: "Creel", coords: [-107.6350, 27.7506] },
  { name: "Divisadero", coords: [-107.7667, 27.5167] },
  { name: "Urique", coords: [-107.9167, 27.2167] },
  { name: "Divisadero (return)", coords: [-107.7667, 27.5167] },
  { name: "El Fuerte", coords: [-108.6200, 26.4217] },
  { name: "Los Mochis", coords: [-108.9939, 25.7903] },
  { name: "Topolobampo (ferry)", coords: [-109.0500, 25.6000] },
  // Baja California
  { name: "La Paz", coords: [-110.3128, 24.1426] },
  { name: "Balandra Beach", coords: [-110.3167, 24.3167] },
  { name: "La Paz (return)", coords: [-110.3128, 24.1426] },
  { name: "Loreto", coords: [-111.3433, 26.0128] },
  { name: "San Javier", coords: [-111.5167, 25.8667] },
  { name: "Loreto (return)", coords: [-111.3433, 26.0128] },
  { name: "Mulegé", coords: [-111.9833, 26.8833] },
  { name: "Santa Rosalía", coords: [-112.2667, 27.3333] },
  { name: "San Ignacio", coords: [-112.8972, 27.2881] },
  { name: "Guerrero Negro", coords: [-114.0614, 27.9681] },
  { name: "Catavina", coords: [-114.7167, 29.7333] },
  { name: "San Quintín", coords: [-115.9333, 30.4833] },
  { name: "Ensenada", coords: [-116.5964, 31.8667] },
  { name: "Valle de Guadalupe", coords: [-116.5500, 32.0500] },
  { name: "Ensenada (return)", coords: [-116.5964, 31.8667] },
  { name: "Tijuana", coords: [-117.0382, 32.5149] },
  // California
  { name: "San Diego", coords: [-117.1611, 32.7157] },
  { name: "La Jolla", coords: [-117.2712, 32.8328] },
  { name: "San Diego (return)", coords: [-117.1611, 32.7157] },
  { name: "Los Angeles", coords: [-118.2437, 34.0522] }
];

// Trip 10: Los Angeles to Seattle via Alaska (Pacific Coast, Alaska in fall, ~100 days)
const waypointsPart10 = [
  // California Coast North
  { name: "Los Angeles", coords: [-118.2437, 34.0522] },
  { name: "Santa Barbara", coords: [-119.6982, 34.4208] },
  { name: "Big Sur (Bixby Bridge)", coords: [-121.9017, 36.3714] },
  { name: "San Francisco", coords: [-122.4194, 37.7749] },
  { name: "Point Reyes", coords: [-122.8782, 38.0682] },
  { name: "Mendocino", coords: [-123.7990, 39.3077] },
  { name: "Redwood NP", coords: [-124.0046, 41.2132] },
  // Pacific Northwest
  { name: "Crater Lake", coords: [-122.1684, 42.9446] },
  { name: "Portland", coords: [-122.6765, 45.5152] },
  { name: "Seattle", coords: [-122.3321, 47.6062] },
  { name: "Olympic NP (Hoh)", coords: [-123.9346, 47.8607] },
  { name: "Vancouver", coords: [-123.1207, 49.2827] },
  { name: "Whistler", coords: [-122.9574, 50.1163] },
  // Canadian Rockies
  { name: "Calgary", coords: [-114.0719, 51.0447] },
  { name: "Banff", coords: [-115.5708, 51.1784] },
  { name: "Lake Louise", coords: [-116.2156, 51.4254] },
  { name: "Yoho NP (Field)", coords: [-116.4875, 51.3980] },
  { name: "Icefields Parkway", coords: [-117.2269, 52.2191] },
  { name: "Jasper", coords: [-118.0814, 52.8737] },
  // Alaska Highway North
  { name: "Prince George", coords: [-122.7497, 53.9171] },
  { name: "Dawson Creek (Mile Zero)", coords: [-120.2377, 55.7596] },
  { name: "Watson Lake", coords: [-128.7097, 60.0631] },
  { name: "Whitehorse", coords: [-135.0568, 60.7212] },
  { name: "Dawson City", coords: [-139.4320, 64.0601] },
  // Alaska
  { name: "Tok", coords: [-142.9856, 63.3367] },
  { name: "Fairbanks", coords: [-147.7164, 64.8378] },
  { name: "Denali NP", coords: [-150.5039, 63.1148] },
  { name: "Anchorage", coords: [-149.9003, 61.2181] },
  { name: "Seward (Kenai Fjords)", coords: [-149.4421, 60.1042] },
  // Return via Alaska Highway to Seattle
  { name: "Anchorage (return)", coords: [-149.9003, 61.2181] },
  { name: "Tok (return)", coords: [-142.9856, 63.3367] },
  { name: "Whitehorse (return)", coords: [-135.0568, 60.7212] },
  { name: "Dawson Creek (return)", coords: [-120.2377, 55.7596] },
  { name: "Prince George (return)", coords: [-122.7497, 53.9171] },
  { name: "Vancouver (return)", coords: [-123.1207, 49.2827] },
  { name: "Seattle (end)", coords: [-122.3321, 47.6062] }
];

// Trip 11: Seattle to Texas (Rockies, Southwest, winter/spring drive south, ~115 days)
const waypointsPart11 = [
  // From Seattle head east
  { name: "Seattle (departure)", coords: [-122.3321, 47.6062] },
  { name: "Spokane", coords: [-117.4260, 47.6588] },
  { name: "Glacier NP (Logan Pass)", coords: [-113.7870, 48.6967] },
  { name: "Beartooth Highway", coords: [-109.4378, 45.0156] },
  { name: "Yellowstone (Old Faithful)", coords: [-110.8281, 44.4605] },
  { name: "Grand Teton (Jackson)", coords: [-110.7624, 43.4799] },
  // Utah Parks
  { name: "Salt Lake City", coords: [-111.8910, 40.7608] },
  { name: "Moab (Arches)", coords: [-109.5498, 38.5733] },
  { name: "Capitol Reef", coords: [-111.1617, 38.2972] },
  { name: "Bryce Canyon", coords: [-112.1871, 37.5930] },
  { name: "Zion (Springdale)", coords: [-112.9988, 37.1889] },
  { name: "Page (Horseshoe Bend)", coords: [-111.5085, 36.8753] },
  { name: "Monument Valley", coords: [-110.0985, 36.9980] },
  { name: "Grand Canyon (South Rim)", coords: [-112.1401, 36.0544] },
  // Arizona & New Mexico
  { name: "Flagstaff", coords: [-111.6513, 35.1983] },
  { name: "Sedona", coords: [-111.7610, 34.8697] },
  { name: "Phoenix", coords: [-112.0740, 33.4484] },
  { name: "Saguaro NP", coords: [-110.5885, 32.2967] },
  { name: "White Sands", coords: [-106.1712, 32.7872] },
  { name: "Carlsbad Caverns", coords: [-104.5567, 32.1479] },
  // Colorado
  { name: "Mesa Verde", coords: [-108.4618, 37.1838] },
  { name: "Silverton", coords: [-107.6642, 37.8117] },
  { name: "Million Dollar Highway (Ouray)", coords: [-107.6714, 38.0228] },
  { name: "Telluride", coords: [-107.8123, 37.9375] },
  { name: "Durango", coords: [-107.8801, 37.2753] },
  { name: "Santa Fe", coords: [-105.9378, 35.6870] },
  { name: "Albuquerque", coords: [-106.6504, 35.0844] },
  // Texas
  { name: "Big Bend (Terlingua)", coords: [-103.6168, 29.3197] },
  { name: "Marfa", coords: [-104.0214, 30.3087] },
  { name: "Guadalupe Mountains", coords: [-104.8606, 31.8912] },
  { name: "Austin", coords: [-97.7431, 30.2672] },
  { name: "San Antonio", coords: [-98.4936, 29.4241] },
  { name: "Houston", coords: [-95.3698, 29.7604] }
];

// Trip 12: Texas to Toronto to Jacksonville (Great Plains, Trans-Canada, Atlantic Canada, East Coast, ~118 days)
const waypointsPart12 = [
  // From Houston north through Great Plains
  { name: "Houston (departure)", coords: [-95.3698, 29.7604] },
  { name: "Dallas", coords: [-96.7970, 32.7767] },
  { name: "Amarillo (Cadillac Ranch)", coords: [-101.8313, 35.2220] },
  { name: "Oklahoma City", coords: [-97.5164, 35.4676] },
  { name: "Kansas City", coords: [-94.5786, 39.0997] },
  { name: "Omaha", coords: [-95.9345, 41.2565] },
  { name: "Sioux Falls", coords: [-96.7311, 43.5446] },
  { name: "Badlands NP", coords: [-102.3397, 43.8554] },
  { name: "Mount Rushmore", coords: [-103.4591, 43.8791] },
  { name: "Devils Tower", coords: [-104.7145, 44.5902] },
  // North to Canada
  { name: "Bismarck", coords: [-100.7837, 46.8083] },
  { name: "Winnipeg", coords: [-97.1384, 49.8951] },
  { name: "Thunder Bay", coords: [-89.2477, 48.3809] },
  { name: "Sault Ste. Marie", coords: [-84.3358, 46.5219] },
  { name: "Sudbury", coords: [-81.0112, 46.4917] },
  { name: "Muskoka", coords: [-79.3878, 45.0032] },
  { name: "Toronto", coords: [-79.3832, 43.6532] },
  // Eastern Canada
  { name: "Montreal", coords: [-73.5673, 45.5017] },
  { name: "Quebec City", coords: [-71.2080, 46.8139] },
  { name: "Percé (Gaspé)", coords: [-64.2165, 48.5234] },
  { name: "Moncton (Fundy)", coords: [-64.7782, 46.0878] },
  { name: "Charlottetown (PEI)", coords: [-63.1311, 46.2382] },
  { name: "Halifax", coords: [-63.5752, 44.6488] },
  { name: "Cape Breton (Cabot Trail)", coords: [-60.7500, 46.8167] },
  // Newfoundland
  { name: "Port aux Basques (ferry)", coords: [-59.1361, 47.5719] },
  { name: "Gros Morne NP", coords: [-57.8097, 49.5980] },
  { name: "St. John's", coords: [-52.7126, 47.5615] },
  // Return and US Northeast
  { name: "Port aux Basques (return ferry)", coords: [-59.1361, 47.5719] },
  { name: "Bar Harbor (Acadia)", coords: [-68.2039, 44.3876] },
  { name: "Portland (Maine)", coords: [-70.2553, 43.6591] },
  { name: "Boston", coords: [-71.0589, 42.3601] },
  { name: "Cape Cod (Provincetown)", coords: [-70.1787, 42.0629] },
  { name: "New York City", coords: [-74.0060, 40.7128] },
  { name: "Philadelphia", coords: [-75.1652, 39.9526] },
  { name: "Washington DC", coords: [-77.0369, 38.9072] },
  { name: "Shenandoah NP", coords: [-78.4679, 38.4755] },
  // Blue Ridge & South
  { name: "Blue Ridge Parkway (Roanoke)", coords: [-79.9414, 37.2710] },
  { name: "Asheville", coords: [-82.5515, 35.5951] },
  { name: "Great Smoky Mountains", coords: [-83.5070, 35.6532] },
  { name: "Savannah", coords: [-81.0998, 32.0809] },
  { name: "St. Augustine", coords: [-81.3124, 29.9012] },
  { name: "Jacksonville", coords: [-81.6557, 30.3322] }
];

// Trip 13: Vienna to Athens (Feb-May 2033, ~90 days)
const waypointsPart13 = [
  { name: "Vienna (departure)", coords: [16.3738, 48.2082] },
  { name: "Bratislava", coords: [17.1077, 48.1486] },
  { name: "Budapest", coords: [19.0402, 47.4979] },
  { name: "Belgrade", coords: [20.4489, 44.7866] },
  { name: "Niš", coords: [21.8958, 43.3209] },
  { name: "Sofia", coords: [23.3219, 42.6977] },
  { name: "Plovdiv", coords: [24.7528, 42.1354] },
  { name: "Thessaloniki", coords: [22.9444, 40.6401] },
  { name: "Meteora", coords: [21.6309, 39.7217] },
  { name: "Delphi", coords: [22.5011, 38.4824] },
  { name: "Athens", coords: [23.7275, 37.9838] }
];

// Trip 14: Athens to Milan (Easter 2034, ~2.5 weeks) - Mediterranean spring
const waypointsPart14 = [
  { name: "Athens (departure)", coords: [23.7275, 37.9838] },
  { name: "Patras (ferry)", coords: [21.7346, 38.2466] },
  { name: "Bari (ferry arrival)", coords: [16.8719, 41.1171] },
  { name: "Matera", coords: [16.6043, 40.6664] },
  { name: "Amalfi Coast", coords: [14.6027, 40.6340] },
  { name: "Pompeii", coords: [14.4849, 40.7462] },
  { name: "Rome", coords: [12.4964, 41.9028] },
  { name: "Florence", coords: [11.2558, 43.7696] },
  { name: "Bologna", coords: [11.3426, 44.4949] },
  { name: "Milan", coords: [9.1900, 45.4642] }
];

// Trip 15: Milan to Marrakech (Summer 2034, ~7 weeks) - coastal route via France & Spain
const waypointsPart15 = [
  { name: "Milan (departure)", coords: [9.1900, 45.4642] },
  { name: "Genoa", coords: [8.9463, 44.4056] },
  { name: "Monaco", coords: [7.4246, 43.7384] },
  { name: "Nice", coords: [7.2620, 43.7102] },
  { name: "Marseille", coords: [5.3698, 43.2965] },
  { name: "Montpellier", coords: [3.8767, 43.6108] },
  { name: "Barcelona", coords: [2.1734, 41.3851] },
  { name: "Valencia", coords: [-0.3763, 39.4699] },
  { name: "Granada (Alhambra)", coords: [-3.5986, 37.1773] },
  { name: "Seville", coords: [-5.9845, 37.3891] },
  { name: "Cadiz", coords: [-6.2926, 36.5271] },
  { name: "Gibraltar", coords: [-5.3536, 36.1408] },
  { name: "Tangier (ferry)", coords: [-5.8128, 35.7595] },
  { name: "Chefchaouen", coords: [-5.2636, 35.1688] },
  { name: "Fes", coords: [-5.0078, 34.0181] },
  { name: "Marrakech", coords: [-7.9811, 31.6295] }
];

// Trip 16: Marrakech to Dakar (Christmas 2034-35, ~3 weeks) - SAHARA IN WINTER!
const waypointsPart16 = [
  { name: "Marrakech (departure)", coords: [-7.9811, 31.6295] },
  { name: "Ouarzazate", coords: [-6.9063, 30.9335] },
  { name: "Merzouga (Sahara dunes)", coords: [-4.0103, 31.0801] },
  { name: "Laayoune", coords: [-13.2000, 27.1253] },
  { name: "Dakhla", coords: [-15.9320, 23.6848] },
  { name: "Nouadhibou", coords: [-17.0347, 20.9311] },
  { name: "Nouakchott", coords: [-15.9785, 18.0735] },
  { name: "Saint-Louis", coords: [-16.4897, 16.0179] },
  { name: "Dakar", coords: [-17.4677, 14.7167] }
];

// Trip 17: Dakar to Accra (Summer 2035, ~7 weeks) - West Africa coastal route
const waypointsPart17 = [
  { name: "Dakar (departure)", coords: [-17.4677, 14.7167] },
  { name: "Banjul (Gambia)", coords: [-16.5885, 13.4549] },
  { name: "Ziguinchor", coords: [-16.2719, 12.5681] },
  { name: "Bissau", coords: [-15.5977, 11.8636] },
  { name: "Conakry", coords: [-13.6773, 9.6412] },
  { name: "Freetown", coords: [-13.2317, 8.4657] },
  { name: "Monrovia", coords: [-10.8047, 6.3156] },
  { name: "Abidjan", coords: [-4.0083, 5.3600] },
  { name: "Cape Coast (Ghana)", coords: [-1.2466, 5.1053] },
  { name: "Accra", coords: [-0.1870, 5.6037] }
];

// Trip 18: Accra to Libreville (Christmas 2035-36, ~3 weeks) - Gulf of Guinea
const waypointsPart18 = [
  { name: "Accra (departure)", coords: [-0.1870, 5.6037] },
  { name: "Lomé (Togo)", coords: [1.2227, 6.1375] },
  { name: "Cotonou (Benin)", coords: [2.3912, 6.3703] },
  { name: "Lagos", coords: [3.3792, 6.5244] },
  { name: "Calabar", coords: [8.3417, 4.9517] },
  { name: "Douala", coords: [9.7043, 4.0511] },
  { name: "Kribi", coords: [9.9137, 2.9373] },
  { name: "Bata (Eq. Guinea)", coords: [9.7659, 1.8628] },
  { name: "Libreville", coords: [9.4536, 0.4162] }
];

// Trip 19: Libreville to Windhoek (Summer 2036, ~7 weeks) - Central/Southern Africa
const waypointsPart19 = [
  { name: "Libreville (departure)", coords: [9.4536, 0.4162] },
  { name: "Franceville", coords: [13.5833, -1.6333] },
  { name: "Brazzaville", coords: [15.2663, -4.2634] },
  { name: "Kinshasa", coords: [15.2663, -4.4419] },
  { name: "Luanda", coords: [13.2343, -8.8390] },
  { name: "Benguela", coords: [13.4055, -12.5763] },
  { name: "Lubango", coords: [13.4894, -14.9186] },
  { name: "Ruacana Falls", coords: [14.2167, -17.4000] },
  { name: "Etosha NP", coords: [16.0000, -18.8556] },
  { name: "Windhoek", coords: [17.0658, -22.5609] }
];

// Trip 20: Windhoek to Cape Town (Christmas 2036-37, ~3 weeks) - Cape summer!
const waypointsPart20 = [
  { name: "Windhoek (departure)", coords: [17.0658, -22.5609] },
  { name: "Sossusvlei", coords: [15.2928, -24.7275] },
  { name: "Lüderitz", coords: [15.1591, -26.6481] },
  { name: "Fish River Canyon", coords: [17.5833, -27.5833] },
  { name: "Orange River", coords: [18.0000, -28.7500] },
  { name: "Cederberg", coords: [19.0833, -32.5000] },
  { name: "Cape Town", coords: [18.4241, -33.9249] }
];

// Trip 21: Cape Town to Durban (Easter 2037, ~2.5 weeks) - Garden Route autumn
const waypointsPart21 = [
  { name: "Cape Town (departure)", coords: [18.4241, -33.9249] },
  { name: "Hermanus (whale watching)", coords: [19.2333, -34.4167] },
  { name: "Mossel Bay", coords: [22.1333, -34.1833] },
  { name: "Knysna", coords: [23.0486, -34.0363] },
  { name: "Tsitsikamma NP", coords: [23.8833, -33.9667] },
  { name: "Addo Elephant NP", coords: [26.1833, -33.4500] },
  { name: "Port Elizabeth", coords: [25.6022, -33.9608] },
  { name: "East London", coords: [27.9116, -33.0153] },
  { name: "Coffee Bay (Wild Coast)", coords: [29.1500, -31.9833] },
  { name: "Durban", coords: [31.0218, -29.8587] }
];

// Trip 22: Durban to Dar es Salaam (Summer 2038, ~7 weeks) - safari dry season
const waypointsPart22 = [
  { name: "Durban (departure)", coords: [31.0218, -29.8587] },
  { name: "Hluhluwe-iMfolozi", coords: [32.0667, -28.0167] },
  { name: "Eswatini (Swaziland)", coords: [31.4659, -26.5225] },
  { name: "Kruger NP", coords: [31.4892, -24.0117] },
  { name: "Johannesburg", coords: [28.0473, -26.2041] },
  { name: "Pretoria", coords: [28.1881, -25.7461] },
  { name: "Maun (Okavango)", coords: [23.4167, -19.9833] },
  { name: "Victoria Falls", coords: [25.8572, -17.9243] },
  { name: "Lusaka", coords: [28.2871, -15.3875] },
  { name: "South Luangwa NP", coords: [31.7833, -13.0833] },
  { name: "Lilongwe", coords: [33.7873, -13.9626] },
  { name: "Lake Malawi", coords: [34.5000, -12.0000] },
  { name: "Mbeya", coords: [33.4500, -8.9000] },
  { name: "Iringa", coords: [35.7000, -7.7667] },
  { name: "Dar es Salaam", coords: [39.2083, -6.7924] }
];

// Trip 23: Dar es Salaam to Nairobi (Christmas 2038-39, ~3 weeks) - East Africa
const waypointsPart23 = [
  { name: "Dar es Salaam (departure)", coords: [39.2083, -6.7924] },
  { name: "Zanzibar", coords: [39.1989, -6.1659] },
  { name: "Bagamoyo", coords: [38.9000, -6.4333] },
  { name: "Arusha", coords: [36.6830, -3.3869] },
  { name: "Ngorongoro Crater", coords: [35.5878, -3.1736] },
  { name: "Serengeti NP", coords: [34.8333, -2.3333] },
  { name: "Lake Victoria (Mwanza)", coords: [32.9000, -2.5167] },
  { name: "Masai Mara", coords: [35.1429, -1.4069] },
  { name: "Nairobi", coords: [36.8219, -1.2921] }
];

// Trip 24: Nairobi to Djibouti (Easter 2039, ~2.5 weeks) - Horn of Africa
const waypointsPart24 = [
  { name: "Nairobi (departure)", coords: [36.8219, -1.2921] },
  { name: "Mount Kenya", coords: [37.3061, -0.1521] },
  { name: "Samburu NP", coords: [37.5333, 0.6167] },
  { name: "Lake Turkana", coords: [36.0833, 3.5833] },
  { name: "Moyale (Ethiopia border)", coords: [39.0500, 3.5167] },
  { name: "Addis Ababa", coords: [38.7578, 9.0320] },
  { name: "Harar", coords: [42.1199, 9.3114] },
  { name: "Dire Dawa", coords: [42.4500, 9.6000] },
  { name: "Djibouti City", coords: [43.1456, 11.5721] }
];

// Trip 25: Djibouti to Dubai (Summer 2039) - ship car home
const waypointsPart25 = [
  { name: "Djibouti City", coords: [43.1456, 11.5721] },
  // Car shipped from Djibouti to Dubai
  { name: "Dubai (arrival)", coords: [55.2708, 25.2048] }
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

  console.error('\n=== Building Part 3: Bangkok to Johor Bahru (Southeast Asia) ===\n');
  const part3 = await buildRouteWithSegments(waypointsPart3, 'Part3', 3);

  console.error('\n=== Building Part 4: JB to Dili (Indonesia, Timor-Leste) ===\n');
  const part4 = await buildRouteWithSegments(waypointsPart4, 'Part4', 4);

  console.error('\n=== Building Part 5: Darwin to Townsville (Australia) ===\n');
  const part5 = await buildRouteWithSegments(waypointsPart5, 'Part5', 5);

  console.error('\n=== Building Part 6: Auckland to Christchurch (New Zealand) ===\n');
  const part6 = await buildRouteWithSegments(waypointsPart6, 'Part6', 6);

  console.error('\n=== Building Part 7: Santiago to Cartagena (South America) ===\n');
  const part7 = await buildRouteWithSegments(waypointsPart7, 'Part7', 7);

  console.error('\n=== Building Part 8: Panama to Oaxaca (Central America & Mexico) ===\n');
  const part8 = await buildRouteWithSegments(waypointsPart8, 'Part8', 8);

  console.error('\n=== Building Part 9: Oaxaca to Los Angeles (Pacific Coast, Copper Canyon, Baja) ===\n');
  const part9 = await buildRouteWithSegments(waypointsPart9, 'Part9', 9);

  console.error('\n=== Building Part 10: Los Angeles to Houston (California, Southwest, Texas) ===\n');
  const part10 = await buildRouteWithSegments(waypointsPart10, 'Part10', 10);

  console.error('\n=== Building Part 11: Houston to Toronto (Rockies, Alaska, Trans-Canada) ===\n');
  const part11 = await buildRouteWithSegments(waypointsPart11, 'Part11', 11);

  console.error('\n=== Building Part 12: Toronto to Jacksonville (Atlantic Canada, East Coast, Florida) ===\n');
  const part12 = await buildRouteWithSegments(waypointsPart12, 'Part12', 12);

  console.error('\n=== Building Part 13: Vienna to Athens (Balkans) ===\n');
  const part13 = await buildRouteWithSegments(waypointsPart13, 'Part13', 13);

  console.error('\n=== Building Part 14: Athens to Milan (Easter 2034) ===\n');
  const part14 = await buildRouteWithSegments(waypointsPart14, 'Part14', 14);

  console.error('\n=== Building Part 15: Milan to Marrakech (Summer 2034) ===\n');
  const part15 = await buildRouteWithSegments(waypointsPart15, 'Part15', 15);

  console.error('\n=== Building Part 16: Marrakech to Dakar (Christmas 2034-35, SAHARA) ===\n');
  const part16 = await buildRouteWithSegments(waypointsPart16, 'Part16', 16);

  console.error('\n=== Building Part 17: Dakar to Accra (Summer 2035) ===\n');
  const part17 = await buildRouteWithSegments(waypointsPart17, 'Part17', 17);

  console.error('\n=== Building Part 18: Accra to Libreville (Christmas 2035-36) ===\n');
  const part18 = await buildRouteWithSegments(waypointsPart18, 'Part18', 18);

  console.error('\n=== Building Part 19: Libreville to Windhoek (Summer 2036) ===\n');
  const part19 = await buildRouteWithSegments(waypointsPart19, 'Part19', 19);

  console.error('\n=== Building Part 20: Windhoek to Cape Town (Christmas 2036-37) ===\n');
  const part20 = await buildRouteWithSegments(waypointsPart20, 'Part20', 20);

  console.error('\n=== Building Part 21: Cape Town to Durban (Easter 2037) ===\n');
  const part21 = await buildRouteWithSegments(waypointsPart21, 'Part21', 21);

  console.error('\n=== Building Part 22: Durban to Dar es Salaam (Summer 2038) ===\n');
  const part22 = await buildRouteWithSegments(waypointsPart22, 'Part22', 22);

  console.error('\n=== Building Part 23: Dar es Salaam to Nairobi (Christmas 2038-39) ===\n');
  const part23 = await buildRouteWithSegments(waypointsPart23, 'Part23', 23);

  console.error('\n=== Building Part 24: Nairobi to Djibouti (Easter 2039) ===\n');
  const part24 = await buildRouteWithSegments(waypointsPart24, 'Part24', 24);

  console.error('\n=== Building Part 25: Djibouti to Dubai (Summer 2039, ship) ===\n');
  const part25 = await buildRouteWithSegments(waypointsPart25, 'Part25', 25);

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
      // Summary line for Part 3
      {
        type: "Feature",
        properties: {
          name: "Trip 3: Bangkok to Johor Bahru",
          part: 3,
          type: "summary",
          description: "Thailand → Laos → Vietnam → Cambodia → Thailand → Malaysia (store car in JB)",
          totalDistanceKm: part3.totalDistanceKm,
          totalDurationHrs: parseFloat(part3.totalDurationHrs),
          segmentCount: part3.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part3.totalCoords
        }
      },
      // Summary line for Part 4
      {
        type: "Feature",
        properties: {
          name: "Trip 4: JB to Dili",
          part: 4,
          type: "summary",
          description: "Indonesia (Sumatra, Java, Bali, Flores) → Timor-Leste (ship car to Darwin)",
          totalDistanceKm: part4.totalDistanceKm,
          totalDurationHrs: parseFloat(part4.totalDurationHrs),
          segmentCount: part4.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part4.totalCoords
        }
      },
      // Summary line for Part 5
      {
        type: "Feature",
        properties: {
          name: "Trip 5: Darwin to Townsville",
          part: 5,
          type: "summary",
          description: "Australia (Top End → Kimberley → West Coast → Red Centre → Tasmania → East Coast)",
          totalDistanceKm: part5.totalDistanceKm,
          totalDurationHrs: parseFloat(part5.totalDurationHrs),
          segmentCount: part5.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part5.totalCoords
        }
      },
      // Summary line for Part 6
      {
        type: "Feature",
        properties: {
          name: "Trip 6: Auckland to Christchurch",
          part: 6,
          type: "summary",
          description: "New Zealand (North Island → South Island)",
          totalDistanceKm: part6.totalDistanceKm,
          totalDurationHrs: parseFloat(part6.totalDurationHrs),
          segmentCount: part6.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part6.totalCoords
        }
      },
      // Summary line for Part 7
      {
        type: "Feature",
        properties: {
          name: "Trip 7: Valparaíso to Cartagena",
          part: 7,
          type: "summary",
          description: "South America (Chile → Argentina → Uruguay → Brazil → Bolivia → Peru → Ecuador → Colombia)",
          totalDistanceKm: part7.totalDistanceKm,
          totalDurationHrs: parseFloat(part7.totalDurationHrs),
          segmentCount: part7.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part7.totalCoords
        }
      },
      // Summary line for Part 8
      {
        type: "Feature",
        properties: {
          name: "Trip 8: Panama to Oaxaca",
          part: 8,
          type: "summary",
          description: "Central America & Mexico (Panama → Costa Rica → Nicaragua → Honduras → El Salvador → Guatemala → Belize → Mexico)",
          totalDistanceKm: part8.totalDistanceKm,
          totalDurationHrs: parseFloat(part8.totalDurationHrs),
          segmentCount: part8.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part8.totalCoords
        }
      },
      // Summary line for Part 9
      {
        type: "Feature",
        properties: {
          name: "Trip 9: Oaxaca to Los Angeles",
          part: 9,
          type: "summary",
          description: "Mexico Pacific Coast, Copper Canyon & Baja California to California",
          totalDistanceKm: part9.totalDistanceKm,
          totalDurationHrs: parseFloat(part9.totalDurationHrs),
          segmentCount: part9.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part9.totalCoords
        }
      },
      // Summary line for Part 10
      {
        type: "Feature",
        properties: {
          name: "Trip 10: LA to Alaska to Seattle",
          part: 10,
          type: "summary",
          description: "Pacific Coast, Canadian Rockies, Alaska Highway, Alaska (fall)",
          totalDistanceKm: part10.totalDistanceKm,
          totalDurationHrs: parseFloat(part10.totalDurationHrs),
          segmentCount: part10.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part10.totalCoords
        }
      },
      // Summary line for Part 11
      {
        type: "Feature",
        properties: {
          name: "Trip 11: Seattle to Texas",
          part: 11,
          type: "summary",
          description: "Rocky Mountains, Utah Parks, American Southwest, Texas (winter/spring)",
          totalDistanceKm: part11.totalDistanceKm,
          totalDurationHrs: parseFloat(part11.totalDurationHrs),
          segmentCount: part11.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part11.totalCoords
        }
      },
      // Summary line for Part 12
      {
        type: "Feature",
        properties: {
          name: "Trip 12: Texas to Toronto to Jacksonville",
          part: 12,
          type: "summary",
          description: "Eastern Canada, Newfoundland, US East Coast, Blue Ridge Parkway, Florida Keys",
          totalDistanceKm: part12.totalDistanceKm,
          totalDurationHrs: parseFloat(part12.totalDurationHrs),
          segmentCount: part12.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part12.totalCoords
        }
      },
      // Summary line for Part 13
      {
        type: "Feature",
        properties: {
          name: "Trip 13: Vienna to Athens",
          part: 13,
          type: "summary",
          description: "Balkans route (Feb-May 2033)",
          totalDistanceKm: part13.totalDistanceKm,
          totalDurationHrs: parseFloat(part13.totalDurationHrs),
          segmentCount: part13.segments.length
        },
        geometry: { type: "LineString", coordinates: part13.totalCoords }
      },
      // Summary line for Part 14
      {
        type: "Feature",
        properties: {
          name: "Trip 14: Athens to Milan",
          part: 14,
          type: "summary",
          description: "Mediterranean spring (Easter 2034)",
          totalDistanceKm: part14.totalDistanceKm,
          totalDurationHrs: parseFloat(part14.totalDurationHrs),
          segmentCount: part14.segments.length
        },
        geometry: { type: "LineString", coordinates: part14.totalCoords }
      },
      // Summary line for Part 15
      {
        type: "Feature",
        properties: {
          name: "Trip 15: Milan to Marrakech",
          part: 15,
          type: "summary",
          description: "Riviera, Spain, Morocco (Summer 2034)",
          totalDistanceKm: part15.totalDistanceKm,
          totalDurationHrs: parseFloat(part15.totalDurationHrs),
          segmentCount: part15.segments.length
        },
        geometry: { type: "LineString", coordinates: part15.totalCoords }
      },
      // Summary line for Part 16
      {
        type: "Feature",
        properties: {
          name: "Trip 16: Marrakech to Dakar",
          part: 16,
          type: "summary",
          description: "SAHARA IN WINTER (Christmas 2034-35)",
          totalDistanceKm: part16.totalDistanceKm,
          totalDurationHrs: parseFloat(part16.totalDurationHrs),
          segmentCount: part16.segments.length
        },
        geometry: { type: "LineString", coordinates: part16.totalCoords }
      },
      // Summary line for Part 17
      {
        type: "Feature",
        properties: {
          name: "Trip 17: Dakar to Accra",
          part: 17,
          type: "summary",
          description: "West Africa coastal (Summer 2035)",
          totalDistanceKm: part17.totalDistanceKm,
          totalDurationHrs: parseFloat(part17.totalDurationHrs),
          segmentCount: part17.segments.length
        },
        geometry: { type: "LineString", coordinates: part17.totalCoords }
      },
      // Summary line for Part 18
      {
        type: "Feature",
        properties: {
          name: "Trip 18: Accra to Libreville",
          part: 18,
          type: "summary",
          description: "Gulf of Guinea (Christmas 2035-36)",
          totalDistanceKm: part18.totalDistanceKm,
          totalDurationHrs: parseFloat(part18.totalDurationHrs),
          segmentCount: part18.segments.length
        },
        geometry: { type: "LineString", coordinates: part18.totalCoords }
      },
      // Summary line for Part 19
      {
        type: "Feature",
        properties: {
          name: "Trip 19: Libreville to Windhoek",
          part: 19,
          type: "summary",
          description: "Central/Southern Africa (Summer 2036)",
          totalDistanceKm: part19.totalDistanceKm,
          totalDurationHrs: parseFloat(part19.totalDurationHrs),
          segmentCount: part19.segments.length
        },
        geometry: { type: "LineString", coordinates: part19.totalCoords }
      },
      // Summary line for Part 20
      {
        type: "Feature",
        properties: {
          name: "Trip 20: Windhoek to Cape Town",
          part: 20,
          type: "summary",
          description: "Namibia to Cape, Cape summer (Christmas 2036-37)",
          totalDistanceKm: part20.totalDistanceKm,
          totalDurationHrs: parseFloat(part20.totalDurationHrs),
          segmentCount: part20.segments.length
        },
        geometry: { type: "LineString", coordinates: part20.totalCoords }
      },
      // Summary line for Part 21
      {
        type: "Feature",
        properties: {
          name: "Trip 21: Cape Town to Durban",
          part: 21,
          type: "summary",
          description: "Garden Route autumn (Easter 2037)",
          totalDistanceKm: part21.totalDistanceKm,
          totalDurationHrs: parseFloat(part21.totalDurationHrs),
          segmentCount: part21.segments.length
        },
        geometry: { type: "LineString", coordinates: part21.totalCoords }
      },
      // Summary line for Part 22
      {
        type: "Feature",
        properties: {
          name: "Trip 22: Durban to Dar es Salaam",
          part: 22,
          type: "summary",
          description: "Safari dry season (Summer 2038)",
          totalDistanceKm: part22.totalDistanceKm,
          totalDurationHrs: parseFloat(part22.totalDurationHrs),
          segmentCount: part22.segments.length
        },
        geometry: { type: "LineString", coordinates: part22.totalCoords }
      },
      // Summary line for Part 23
      {
        type: "Feature",
        properties: {
          name: "Trip 23: Dar es Salaam to Nairobi",
          part: 23,
          type: "summary",
          description: "East Africa (Christmas 2038-39)",
          totalDistanceKm: part23.totalDistanceKm,
          totalDurationHrs: parseFloat(part23.totalDurationHrs),
          segmentCount: part23.segments.length
        },
        geometry: { type: "LineString", coordinates: part23.totalCoords }
      },
      // Summary line for Part 24
      {
        type: "Feature",
        properties: {
          name: "Trip 24: Nairobi to Djibouti",
          part: 24,
          type: "summary",
          description: "Horn of Africa (Easter 2039)",
          totalDistanceKm: part24.totalDistanceKm,
          totalDurationHrs: parseFloat(part24.totalDurationHrs),
          segmentCount: part24.segments.length
        },
        geometry: { type: "LineString", coordinates: part24.totalCoords }
      },
      // Summary line for Part 25
      {
        type: "Feature",
        properties: {
          name: "Trip 25: Djibouti to Dubai",
          part: 25,
          type: "summary",
          description: "Ship car home (Summer 2039)",
          totalDistanceKm: part25.totalDistanceKm,
          totalDurationHrs: parseFloat(part25.totalDurationHrs),
          segmentCount: part25.segments.length
        },
        geometry: { type: "LineString", coordinates: part25.totalCoords }
      },
      // Individual segments
      ...part1.segments,
      ...part2.segments,
      ...part3.segments,
      ...part4.segments,
      ...part5.segments,
      ...part6.segments,
      ...part7.segments,
      ...part8.segments,
      ...part9.segments,
      ...part10.segments,
      ...part11.segments,
      ...part12.segments,
      ...part13.segments,
      ...part14.segments,
      ...part15.segments,
      ...part16.segments,
      ...part17.segments,
      ...part18.segments,
      ...part19.segments,
      ...part20.segments,
      ...part21.segments,
      ...part22.segments,
      ...part23.segments,
      ...part24.segments,
      ...part25.segments
    ]
  };

  // Reduce coordinate precision to shrink file size (4 decimals = ~11m accuracy)
  function roundCoords(coords, precision = 4) {
    return [
      Math.round(coords[0] * Math.pow(10, precision)) / Math.pow(10, precision),
      Math.round(coords[1] * Math.pow(10, precision)) / Math.pow(10, precision)
    ];
  }

  function reduceGeojsonPrecision(geojson) {
    return {
      ...geojson,
      features: geojson.features.map(feature => ({
        ...feature,
        geometry: {
          ...feature.geometry,
          coordinates: feature.geometry.coordinates.map(coord => roundCoords(coord))
        }
      }))
    };
  }

  // Write individual trip files
  const tripParts = [
    { part: part1, num: 1, name: "Trip 1a: Dubai to Bandar Abbas", desc: "Dubai → Oman → Saudi → Qatar → Bahrain → Kuwait → Iraq → Iran" },
    { part: part2, num: 2, name: "Trip 1b: Karachi to Chittagong", desc: "Pakistan → India → Nepal → Bangladesh" },
    { part: part3, num: 3, name: "Trip 3: Bangkok to Johor Bahru", desc: "Thailand → Laos → Vietnam → Cambodia → Malaysia" },
    { part: part4, num: 4, name: "Trip 4: JB to Dili", desc: "Indonesia → Timor-Leste" },
    { part: part5, num: 5, name: "Trip 5: Darwin to Townsville", desc: "Australia" },
    { part: part6, num: 6, name: "Trip 6: Auckland to Christchurch", desc: "New Zealand" },
    { part: part7, num: 7, name: "Trip 7: Valparaíso to Cartagena", desc: "South America" },
    { part: part8, num: 8, name: "Trip 8: Panama to Oaxaca", desc: "Central America & Mexico" },
    { part: part9, num: 9, name: "Trip 9: Oaxaca to Los Angeles", desc: "Mexico Pacific Coast & Baja" },
    { part: part10, num: 10, name: "Trip 10: LA to Alaska to Seattle", desc: "Pacific Coast, Alaska (fall)" },
    { part: part11, num: 11, name: "Trip 11: Seattle to Texas", desc: "Rockies, Southwest, Texas" },
    { part: part12, num: 12, name: "Trip 12: Texas to Toronto to Jacksonville", desc: "Great Plains, Atlantic Canada, East Coast" },
    { part: part13, num: 13, name: "Trip 13: Vienna to Athens", desc: "Balkans (Feb-May 2033)" },
    { part: part14, num: 14, name: "Trip 14: Athens to Milan", desc: "Mediterranean spring (Easter 2034)" },
    { part: part15, num: 15, name: "Trip 15: Milan to Marrakech", desc: "Riviera, Spain, Morocco (Summer 2034)" },
    { part: part16, num: 16, name: "Trip 16: Marrakech to Dakar", desc: "SAHARA IN WINTER (Christmas 2034-35)" },
    { part: part17, num: 17, name: "Trip 17: Dakar to Accra", desc: "West Africa coastal (Summer 2035)" },
    { part: part18, num: 18, name: "Trip 18: Accra to Libreville", desc: "Gulf of Guinea (Christmas 2035-36)" },
    { part: part19, num: 19, name: "Trip 19: Libreville to Windhoek", desc: "Central/Southern Africa (Summer 2036)" },
    { part: part20, num: 20, name: "Trip 20: Windhoek to Cape Town", desc: "Cape summer (Christmas 2036-37)" },
    { part: part21, num: 21, name: "Trip 21: Cape Town to Durban", desc: "Garden Route (Easter 2037)" },
    { part: part22, num: 22, name: "Trip 22: Durban to Dar es Salaam", desc: "Safari dry season (Summer 2038)" },
    { part: part23, num: 23, name: "Trip 23: Dar es Salaam to Nairobi", desc: "East Africa (Christmas 2038-39)" },
    { part: part24, num: 24, name: "Trip 24: Nairobi to Djibouti", desc: "Horn of Africa (Easter 2039)" },
    { part: part25, num: 25, name: "Trip 25: Djibouti to Dubai", desc: "Ship car home (Summer 2039)" }
  ];

  // Create routes directory if it doesn't exist
  if (!fs.existsSync('data/routes')) {
    fs.mkdirSync('data/routes', { recursive: true });
  }

  for (const trip of tripParts) {
    const tripGeojson = {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          properties: {
            name: trip.name,
            part: trip.num,
            type: "summary",
            description: trip.desc,
            totalDistanceKm: trip.part.totalDistanceKm,
            totalDurationHrs: parseFloat(trip.part.totalDurationHrs),
            segmentCount: trip.part.segments.length
          },
          geometry: {
            type: "LineString",
            coordinates: trip.part.totalCoords
          }
        },
        ...trip.part.segments
      ]
    };
    const reduced = reduceGeojsonPrecision(tripGeojson);
    const filename = `data/routes/trip-${String(trip.num).padStart(2, '0')}.geojson`;
    fs.writeFileSync(filename, JSON.stringify(reduced, null, 2));
    console.error(`Wrote ${filename} (${trip.part.totalCoords.length} coords)`);
  }

  // Also write combined file for backwards compatibility (but smaller - summary only)
  console.error(`\n=== TOTALS ===`);
  const allParts = [part1, part2, part3, part4, part5, part6, part7, part8, part9, part10, part11, part12, part13, part14, part15, part16, part17, part18, part19, part20, part21, part22, part23, part24, part25];
  allParts.forEach((p, i) => {
    console.error(`Part ${i+1}: ${p.totalDistanceKm} km, ${p.totalDurationHrs} hrs driving (${p.segments.length} segments)`);
  });
  const totalKm = allParts.reduce((sum, p) => sum + p.totalDistanceKm, 0);
  const totalHrs = allParts.reduce((sum, p) => sum + parseFloat(p.totalDurationHrs), 0);
  const totalCoords = allParts.reduce((sum, p) => sum + p.totalCoords.length, 0);
  console.error(`TOTAL: ${totalKm} km, ${totalHrs.toFixed(1)} hrs driving, ${totalCoords} coordinates`);
}

buildRoute();
