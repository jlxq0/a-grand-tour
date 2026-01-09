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
          name: "Trip 7: Santiago to Cartagena",
          part: 7,
          type: "summary",
          description: "South America (Chile → Argentina → Uruguay → Brazil → Bolivia → Peru → Ecuador → Guianas → Colombia)",
          totalDistanceKm: part7.totalDistanceKm,
          totalDurationHrs: parseFloat(part7.totalDurationHrs),
          segmentCount: part7.segments.length
        },
        geometry: {
          type: "LineString",
          coordinates: part7.totalCoords
        }
      },
      // Individual segments
      ...part1.segments,
      ...part2.segments,
      ...part3.segments,
      ...part4.segments,
      ...part5.segments,
      ...part6.segments,
      ...part7.segments
    ]
  };

  fs.writeFileSync('data/planned-route.geojson', JSON.stringify(geojson, null, 2));

  console.error(`\n=== TOTALS ===`);
  console.error(`Part 1: ${part1.totalDistanceKm} km, ${part1.totalDurationHrs} hrs driving (${part1.segments.length} segments)`);
  console.error(`Part 2: ${part2.totalDistanceKm} km, ${part2.totalDurationHrs} hrs driving (${part2.segments.length} segments)`);
  console.error(`Part 3: ${part3.totalDistanceKm} km, ${part3.totalDurationHrs} hrs driving (${part3.segments.length} segments)`);
  console.error(`Part 4: ${part4.totalDistanceKm} km, ${part4.totalDurationHrs} hrs driving (${part4.segments.length} segments)`);
  console.error(`Part 5: ${part5.totalDistanceKm} km, ${part5.totalDurationHrs} hrs driving (${part5.segments.length} segments)`);
  console.error(`Part 6: ${part6.totalDistanceKm} km, ${part6.totalDurationHrs} hrs driving (${part6.segments.length} segments)`);
  console.error(`Part 7: ${part7.totalDistanceKm} km, ${part7.totalDurationHrs} hrs driving (${part7.segments.length} segments)`);
  const totalKm = part1.totalDistanceKm + part2.totalDistanceKm + part3.totalDistanceKm + part4.totalDistanceKm + part5.totalDistanceKm + part6.totalDistanceKm + part7.totalDistanceKm;
  const totalHrs = parseFloat(part1.totalDurationHrs) + parseFloat(part2.totalDurationHrs) + parseFloat(part3.totalDurationHrs) + parseFloat(part4.totalDurationHrs) + parseFloat(part5.totalDurationHrs) + parseFloat(part6.totalDurationHrs) + parseFloat(part7.totalDurationHrs);
  console.error(`TOTAL: ${totalKm} km, ${totalHrs.toFixed(1)} hrs driving`);
  console.error(`\nWrote ${part1.totalCoords.length + part2.totalCoords.length + part3.totalCoords.length + part4.totalCoords.length + part5.totalCoords.length + part6.totalCoords.length + part7.totalCoords.length} coordinates to data/planned-route.geojson`);
}

buildRoute();
