#!/usr/bin/env python3
"""
Build high-resolution risk-regions.geojson from geoBoundaries admin-1 data.
"""

import json
import urllib.request

# GeoBoundaries download URLs for each country
SOURCES = {
    'IRQ': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/IRQ/ADM1/geoBoundaries-IRQ-ADM1.geojson',
    'PAK': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/PAK/ADM1/geoBoundaries-PAK-ADM1.geojson',
    'EGY': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/EGY/ADM1/geoBoundaries-EGY-ADM1.geojson',
    'ETH': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/ETH/ADM1/geoBoundaries-ETH-ADM1.geojson',
    'MOZ': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/MOZ/ADM1/geoBoundaries-MOZ-ADM1.geojson',
    'COD': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/COD/ADM1/geoBoundaries-COD-ADM1.geojson',
    'NGA': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/NGA/ADM1/geoBoundaries-NGA-ADM1.geojson',
    'CMR': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/CMR/ADM1/geoBoundaries-CMR-ADM1.geojson',
    'DZA': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/DZA/ADM1/geoBoundaries-DZA-ADM1.geojson',
    'LBN': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/LBN/ADM1/geoBoundaries-LBN-ADM1.geojson',
    'BEN': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/BEN/ADM1/geoBoundaries-BEN-ADM1.geojson',
    'TGO': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/TGO/ADM1/geoBoundaries-TGO-ADM1.geojson',
    # New countries for additional overlays
    'IND': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/IND/ADM1/geoBoundaries-IND-ADM1.geojson',
    'KEN': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/KEN/ADM1/geoBoundaries-KEN-ADM1.geojson',
    'UGA': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/UGA/ADM1/geoBoundaries-UGA-ADM1.geojson',
    'RWA': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/RWA/ADM1/geoBoundaries-RWA-ADM1.geojson',
    'BDI': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/BDI/ADM1/geoBoundaries-BDI-ADM1.geojson',
    'TZA': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/TZA/ADM1/geoBoundaries-TZA-ADM1.geojson',
    'COL': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/COL/ADM1/geoBoundaries-COL-ADM1.geojson',
    'MEX': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/MEX/ADM1/geoBoundaries-MEX-ADM1.geojson',
    'HND': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/HND/ADM1/geoBoundaries-HND-ADM1.geojson',
    'SEN': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/SEN/ADM1/geoBoundaries-SEN-ADM1.geojson',
    'MRT': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/MRT/ADM1/geoBoundaries-MRT-ADM1.geojson',
    'PAN': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/PAN/ADM1/geoBoundaries-PAN-ADM1.geojson',
    # ADM2 (district-level) for more precision
    'PAK_ADM2': 'https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/PAK/ADM2/geoBoundaries-PAK-ADM2.geojson',
}

# Regions to extract with risk classification
# Format: (country_iso, region_name_patterns, risk, display_name, note, exact_match)
REGIONS = [
    # Iraqi Kurdistan (orange - safer in red Iraq)
    ('IRQ', ['Erbil', 'Dohuk', 'Al-Sulaimaniyah', 'Sulaimaniyah'],
     'orange', 'Iraqi Kurdistan', 'Autonomous region - relatively safe with own security', False),

    # Southern Iraq (orange - accessible for overlanders)
    ('IRQ', ['Al-Basrah', 'Basrah', 'Basra', 'Dhi Qar'],
     'orange', 'Southern Iraq', 'Basra-Nasiriyah corridor accessible. Ur, Uruk, Eridu, Marshes. Never occupied by ISIS.', False),

    # Pakistan - Balochistan (red in orange country)
    ('PAK', ['Balochistan', 'Baluchistan'],
     'red', 'Balochistan', 'Separatist insurgency - foreigners targeted', False),

    # Egypt - Sinai (red in orange country)
    ('EGY', ['North Sinai', 'South Sinai', 'Shamal Sina', 'Janub Sina'],
     'red', 'Sinai Peninsula', 'Active insurgency - military escort required', False),

    # Ethiopia - Tigray & Amhara (red in orange country)
    ('ETH', ['Tigray', 'Amhara'],
     'red', 'Tigray & Amhara', 'Post-war devastation, Fano insurgency', True),

    # Mozambique - Cabo Delgado (red in orange country)
    ('MOZ', ['Cabo Delgado'],
     'red', 'Cabo Delgado', 'ISIS-linked insurgency - completely avoid', False),

    # DRC - Eastern provinces (red in orange country)
    ('COD', ['Nord-Kivu', 'North Kivu', 'Sud-Kivu', 'South Kivu', 'Ituri'],
     'red', 'Eastern DRC', 'M23, ADF armed groups - never go here', True),

    # Nigeria - Northern states (red in orange country)
    ('NGA', ['Borno', 'Yobe', 'Adamawa', 'Zamfara', 'Kaduna', 'Katsina', 'Sokoto', 'Niger', 'Plateau', 'Taraba', 'Bauchi', 'Gombe', 'Jigawa', 'Kano', 'Kebbi'],
     'red', 'Northern Nigeria', 'Boko Haram, banditry, kidnappings - avoid entirely', True),

    # Cameroon - Anglophone regions (red - both NW and SW are dangerous)
    # Only the main N3 highway through SW is passable - shown as green safe corridor
    ('CMR', ['North-West', 'Nord-Ouest', 'South-West', 'Sud-Ouest'],
     'red', 'Anglophone Cameroon', 'Armed separatist conflict since 2017. ONLY the main N3 highway (Mamfe-Kumba-Douala) is passable with military escorts. DO NOT deviate from highway.', True),

    # Cameroon - Far North (red in orange country)
    ('CMR', ['Far North', 'Extrême-Nord', 'Extreme-Nord'],
     'red', 'Far North Cameroon', 'Boko Haram activity', True),

    # Algeria - Southern wilayas (red in orange country)
    ('DZA', ['Tamanrasset', 'Adrar', 'Illizi', 'Tindouf', 'Bechar', 'Ghardaia', 'Ouargla', 'El Oued', 'Laghouat', 'Djelfa', 'Biskra'],
     'red', 'Southern Algeria', 'Sahara - jihadist presence, kidnapping risk', True),

    # Lebanon - Southern governorates (red in orange country)
    ('LBN', ['Liban-Sud', 'Nabatîyé', 'Nabatiye'],
     'red', 'Southern Lebanon', 'Israel-Hezbollah conflict zone', False),

    # Benin - Northern departments (red in orange country)
    ('BEN', ['Alibori', 'Atakora'],
     'red', 'Northern Benin', 'Sahel terrorism spillover', True),

    # Togo - Savanes region (red in orange country)
    ('TGO', ['Savanes', 'Kara'],
     'red', 'Northern Togo', 'Sahel terrorism spillover', True),

    # === NEW REGIONS ===

    # Pakistan - Former FATA tribal districts (red - Taliban active)
    # Using ADM2 for precision - KKH corridor (Abbottabad, Mansehra, Gilgit-Baltistan) is SAFE
    ('PAK_ADM2', ['Bajaur', 'Mohmand', 'Khyber', 'Orakzai', 'Kurram', 'North Waziristan', 'South Waziristan', 'Tank', 'Bannu', 'Lakki Marwat', 'Dera Ismail Khan'],
     'red', 'Tribal Areas (former FATA)', 'Taliban/TTP active, kidnapping, terrorism - Do Not Travel. KKH corridor is safe.', True),

    # India - Kashmir (red - active conflict)
    ('IND', ['Jammu and Kashmīr', 'Jammu and Kashmir', 'Kashmir'],
     'red', 'Kashmir', 'Active India-Pakistan conflict zone - Do Not Travel', False),

    # India - Manipur (red - ethnic violence)
    ('IND', ['Manipur'],
     'red', 'Manipur', 'Ethnic violence since 2023, 250+ killed - Do Not Travel', True),

    # Kenya - Somalia border region (red)
    ('KEN', ['Mandera', 'Wajir', 'Garissa'],
     'red', 'Kenya-Somalia Border', 'Al-Shabaab terrorism, kidnapping - Do Not Travel', True),

    # Kenya - Lamu (red)
    ('KEN', ['Lamu'],
     'red', 'Lamu County', 'Al-Shabaab attacks, terrorism - Do Not Travel', True),

    # Uganda - Northern Region (contains Karamoja - red)
    ('UGA', ['Northern Region', 'Northern'],
     'red', 'Northern Uganda', 'Karamoja violence, banditry, landmines - Avoid', False),

    # Uganda - Western DRC border (red)
    ('UGA', ['Western Region', 'Western'],
     'red', 'Western Uganda', 'ADF attacks from DRC, border violence', False),

    # Rwanda - Western Province (DRC border - red)
    ('RWA', ['Western Province', 'Western'],
     'red', 'Rwanda DRC Border', 'M23 conflict spillover, Do Not Travel within 10km of border', False),

    # Burundi - Western provinces (red)
    ('BDI', ['Cibitoke', 'Bubanza'],
     'red', 'Western Burundi', 'Armed violence from DRC, Kibira Park off-limits', True),

    # Tanzania - Mtwara (Mozambique border)
    ('TZA', ['Mtwara'],
     'red', 'Tanzania-Mozambique Border', 'Cabo Delgado insurgency spillover', True),

    # Colombia - Arauca (red)
    ('COL', ['Arauca'],
     'red', 'Arauca', 'Armed groups, Venezuela border violence - Do Not Travel', True),

    # Colombia - Cauca (red)
    ('COL', ['Cauca'],
     'red', 'Cauca', 'FARC dissidents, active conflict - Do Not Travel', True),

    # Colombia - Norte de Santander (red)
    ('COL', ['Norte de Santander'],
     'red', 'Norte de Santander', 'Catatumbo conflict zone - Do Not Travel', True),

    # Colombia - Choco (red - Darien corridor)
    ('COL', ['Chocó', 'Choco'],
     'red', 'Chocó & Darién', 'Darien Gap, armed groups, migration crisis - impassable', False),

    # Panama - Darien (red)
    ('PAN', ['Darién', 'Darien'],
     'red', 'Darién Gap', 'Impassable jungle, armed groups, migration crisis', False),

    # Mexico - Colima (red)
    ('MEX', ['Colima'],
     'red', 'Colima', 'Cartel violence - Do Not Travel', True),

    # Mexico - Guerrero (red)
    ('MEX', ['Guerrero'],
     'red', 'Guerrero', 'Cartel violence, includes Acapulco - Do Not Travel', True),

    # Mexico - Michoacán (red)
    ('MEX', ['MichoacÃ¡n de Ocampo', 'Michoacán de Ocampo', 'Michoacán', 'Michoacan'],
     'red', 'Michoacán', 'Cartel violence - Do Not Travel', False),

    # Mexico - Sinaloa (red)
    ('MEX', ['Sinaloa'],
     'red', 'Sinaloa', 'Cartel war, extreme violence - Do Not Travel', True),

    # Mexico - Tamaulipas (red)
    ('MEX', ['Tamaulipas'],
     'red', 'Tamaulipas', 'Cartel violence, border region - Do Not Travel', True),

    # Mexico - Zacatecas (red)
    ('MEX', ['Zacatecas'],
     'red', 'Zacatecas', 'Cartel violence - Do Not Travel', True),

    # Honduras - Gracias a Dios (red)
    ('HND', ['Gracias a Dios'],
     'red', 'Gracias a Dios', 'Narcotics trafficking, no government presence - Do Not Travel', True),

    # Senegal - Casamance (orange - landmines)
    ('SEN', ['Ziguinchor', 'Sédhiou', 'Kolda'],
     'orange', 'Casamance', 'Landmines from prior conflict, avoid rural/border areas', False),

    # Mauritania - Eastern border (red)
    ('MRT', ['Hodh Ech Chargui', 'Hodh El Gharbi', 'Assaba', 'Guidimaka', 'Tagant', 'Adrar', 'Tiris Zemmour'],
     'red', 'Eastern Mauritania', 'Mali insurgency spillover, No Movement Zones', False),
]

# Gaza Strip - manual polygon (too small for admin-1)
GAZA = {
    "type": "Feature",
    "properties": {"name": "Gaza Strip", "risk": "red", "note": "Active war zone - completely inaccessible"},
    "geometry": {
        "type": "Polygon",
        "coordinates": [[[34.22, 31.59], [34.56, 31.59], [34.56, 31.22], [34.22, 31.22], [34.22, 31.59]]]
    }
}

def download_geojson(url):
    """Download GeoJSON from URL."""
    print(f"  Downloading: {url[:80]}...")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.loads(response.read().decode('utf-8'))

def normalize_name(name):
    """Normalize region name for matching."""
    if not name:
        return ''
    return name.lower().replace('-', ' ').replace('_', ' ').strip()

def find_matching_features(geojson, patterns, exact=False):
    """Find features matching any of the name patterns."""
    matches = []
    normalized_patterns = [normalize_name(p) for p in patterns]

    for feature in geojson.get('features', []):
        props = feature.get('properties', {})
        # Check various name fields
        for key in ['shapeName', 'shapeISO', 'NAME', 'name', 'NAME_1', 'ADM1_EN', 'ADM1_AR']:
            name = props.get(key, '')
            if not name:
                continue
            norm_name = normalize_name(name)
            for pattern in normalized_patterns:
                # For exact matching, check if the pattern matches the start of the name
                # or if the name exactly equals the pattern
                if exact:
                    if norm_name == pattern or norm_name.startswith(pattern + ' '):
                        matches.append(feature)
                        print(f"    Found: {name}")
                        break
                else:
                    if pattern in norm_name or norm_name in pattern:
                        matches.append(feature)
                        print(f"    Found: {name}")
                        break
            else:
                continue
            break

    return matches

def merge_geometries(features):
    """Merge multiple features into a single MultiPolygon geometry."""
    if not features:
        return None

    all_coords = []
    for f in features:
        geom = f.get('geometry', {})
        geom_type = geom.get('type', '')
        coords = geom.get('coordinates', [])

        if geom_type == 'Polygon':
            all_coords.append(coords)
        elif geom_type == 'MultiPolygon':
            all_coords.extend(coords)

    if len(all_coords) == 1:
        return {"type": "Polygon", "coordinates": all_coords[0]}
    else:
        return {"type": "MultiPolygon", "coordinates": all_coords}

def main():
    print("Building high-resolution risk-regions.geojson...\n")

    # Download all country data
    country_data = {}
    for iso, url in SOURCES.items():
        print(f"Fetching {iso}...")
        try:
            country_data[iso] = download_geojson(url)
        except Exception as e:
            print(f"  Error: {e}")
            country_data[iso] = {"features": []}

    print("\nExtracting regions...")
    output_features = []

    for country_iso, patterns, risk, name, note, exact in REGIONS:
        print(f"\n{name} ({country_iso}):")
        if country_iso not in country_data:
            print("  Skipped - no data")
            continue

        matches = find_matching_features(country_data[country_iso], patterns, exact=exact)
        if not matches:
            print("  No matches found")
            continue

        geometry = merge_geometries(matches)
        if geometry:
            output_features.append({
                "type": "Feature",
                "properties": {"name": name, "risk": risk, "note": note},
                "geometry": geometry
            })
            print(f"  Added with {len(matches)} region(s)")

    # Add Gaza
    output_features.append(GAZA)
    print("\nAdded Gaza Strip (manual polygon)")

    # Write output
    output = {
        "type": "FeatureCollection",
        "features": output_features
    }

    output_path = 'data/risk-regions.geojson'
    with open(output_path, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"\nWrote {len(output_features)} regions to {output_path}")

if __name__ == '__main__':
    main()
