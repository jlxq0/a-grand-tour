#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const POIS_DIR = path.join(__dirname, '..', 'data', 'pois');
const IMAGES_DIR = path.join(POIS_DIR, 'images');
const MAX_IMAGES_PER_POI = 2;
const IMAGE_WIDTH = 1200;
const USER_AGENT = 'AGrandTour/1.0 (https://github.com/a-grand-tour; travel planning project)';

// Helper for HTTPS GET with User-Agent
function httpsGet(url) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      headers: { 'User-Agent': USER_AGENT }
    };
    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ data, statusCode: res.statusCode, headers: res.headers }));
    }).on('error', reject);
  });
}

// Wikimedia Commons API
async function searchWikimediaImages(query, limit = MAX_IMAGES_PER_POI) {
  const searchUrl = `https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&srnamespace=6&srlimit=${limit * 2}&format=json`;

  try {
    const { data } = await httpsGet(searchUrl);
    const json = JSON.parse(data);
    const results = json.query?.search || [];
    return results
      .filter(r => /\.(jpg|jpeg|png|webp)$/i.test(r.title))
      .slice(0, limit)
      .map(r => r.title);
  } catch (e) {
    return [];
  }
}

// Get direct image URL from Wikimedia
async function getImageUrl(filename) {
  const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&titles=${encodeURIComponent(filename)}&prop=imageinfo&iiprop=url&iiurlwidth=${IMAGE_WIDTH}&format=json`;

  try {
    const { data } = await httpsGet(apiUrl);
    const json = JSON.parse(data);
    const pages = json.query?.pages || {};
    const page = Object.values(pages)[0];
    const imageinfo = page?.imageinfo?.[0];
    return imageinfo?.thumburl || imageinfo?.url || null;
  } catch (e) {
    return null;
  }
}

// Download image to file with retry for rate limiting
async function downloadImage(url, filepath, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      const success = await new Promise((resolve, reject) => {
        const file = fs.createWriteStream(filepath);
        const urlObj = new URL(url);
        const options = {
          hostname: urlObj.hostname,
          path: urlObj.pathname + urlObj.search,
          headers: { 'User-Agent': USER_AGENT }
        };
        https.get(options, (res) => {
          if (res.statusCode === 301 || res.statusCode === 302) {
            file.close();
            downloadImage(res.headers.location, filepath, retries - attempt).then(resolve).catch(reject);
            return;
          }
          if (res.statusCode === 429) {
            file.close();
            fs.unlink(filepath, () => {});
            reject(new Error('RATE_LIMITED'));
            return;
          }
          if (res.statusCode !== 200) {
            file.close();
            fs.unlink(filepath, () => {});
            reject(new Error(`HTTP ${res.statusCode}`));
            return;
          }
          res.pipe(file);
          file.on('finish', () => {
            file.close();
            resolve(true);
          });
        }).on('error', (e) => {
          fs.unlink(filepath, () => {});
          reject(e);
        });
      });
      return success;
    } catch (e) {
      if (e.message === 'RATE_LIMITED' && attempt < retries - 1) {
        // Exponential backoff: 2s, 4s, 8s
        await new Promise(r => setTimeout(r, 2000 * Math.pow(2, attempt)));
        continue;
      }
      throw e;
    }
  }
}

// Convert to WebP using cwebp, ImageMagick, or sips
function convertToWebP(inputPath, outputPath) {
  try {
    // Try cwebp first (from webp package)
    execSync(`cwebp -q 80 "${inputPath}" -o "${outputPath}" 2>/dev/null`, { stdio: 'pipe' });
    return true;
  } catch {
    try {
      // Fallback to ImageMagick
      execSync(`convert "${inputPath}" -quality 80 "${outputPath}" 2>/dev/null`, { stdio: 'pipe' });
      return true;
    } catch {
      try {
        // Try sips (macOS, may not support webp on all versions)
        execSync(`sips -s format webp -s formatOptions 80 "${inputPath}" --out "${outputPath}" 2>/dev/null`, { stdio: 'pipe' });
        return true;
      } catch {
        // Last resort: just copy if it's already webp
        if (inputPath.endsWith('.webp')) {
          fs.copyFileSync(inputPath, outputPath);
          return true;
        }
        return false;
      }
    }
  }
}

// Sanitize filename
function sanitizeFilename(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50);
}

// Process a single POI
async function processPOI(poi, countryCode, countryDir) {
  const poiName = poi.properties.name;
  const safeName = sanitizeFilename(poiName);
  const country = poi.properties.country;

  process.stdout.write(`  ${poiName}: `);

  // Search queries to try
  const queries = [
    `${poiName}`,
    `${poiName} ${country}`,
    `${poiName} landmark`,
  ];

  let allImages = [];
  for (const query of queries) {
    if (allImages.length >= MAX_IMAGES_PER_POI) break;
    const images = await searchWikimediaImages(query, MAX_IMAGES_PER_POI - allImages.length);
    for (const img of images) {
      if (!allImages.includes(img)) allImages.push(img);
    }
  }

  if (allImages.length === 0) {
    console.log(`no images found`);
    return 0;
  }

  let downloaded = 0;
  for (let i = 0; i < Math.min(allImages.length, MAX_IMAGES_PER_POI); i++) {
    const imageTitle = allImages[i];
    const imageUrl = await getImageUrl(imageTitle);

    if (!imageUrl) continue;

    const tempPath = path.join(countryDir, `${safeName}-${i + 1}.tmp`);
    const finalPath = path.join(countryDir, `${safeName}-${i + 1}.webp`);

    // Skip if already exists
    if (fs.existsSync(finalPath)) {
      downloaded++;
      continue;
    }

    try {
      await downloadImage(imageUrl, tempPath);

      // Convert to WebP
      if (convertToWebP(tempPath, finalPath)) {
        downloaded++;
      }

      // Clean up temp file
      if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
    } catch (e) {
      if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
    }

    // Rate limiting - 3 seconds between downloads to avoid 429 errors
    await new Promise(r => setTimeout(r, 3000));
  }

  console.log(`${downloaded} images`);
  return downloaded;
}

// Process a single country
async function processCountry(countryCode) {
  const geojsonPath = path.join(POIS_DIR, `${countryCode}.geojson`);
  const countryDir = path.join(IMAGES_DIR, countryCode);

  if (!fs.existsSync(geojsonPath)) {
    console.log(`No GeoJSON for ${countryCode}`);
    return;
  }

  const data = JSON.parse(fs.readFileSync(geojsonPath, 'utf8'));
  const pois = data.features || [];

  console.log(`\nProcessing ${countryCode.toUpperCase()} (${pois.length} POIs)`);

  // Ensure directory exists
  if (!fs.existsSync(countryDir)) {
    fs.mkdirSync(countryDir, { recursive: true });
  }

  let totalImages = 0;
  for (const poi of pois) {
    const count = await processPOI(poi, countryCode, countryDir);
    totalImages += count;
  }

  console.log(`  Total: ${totalImages} images for ${countryCode.toUpperCase()}`);
  return totalImages;
}

// Main
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    // Process all countries
    const files = fs.readdirSync(POIS_DIR).filter(f => f.endsWith('.geojson'));
    for (const file of files) {
      const countryCode = file.replace('.geojson', '');
      await processCountry(countryCode);
    }
  } else {
    // Process specific countries
    for (const code of args) {
      await processCountry(code.toLowerCase());
    }
  }
}

main().catch(console.error);
