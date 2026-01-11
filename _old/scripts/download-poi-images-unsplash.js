#!/usr/bin/env node

/**
 * POI Image Downloader using Unsplash API
 *
 * Usage:
 *   node scripts/download-poi-images-unsplash.js [country-code]
 *
 * Run in background:
 *   nohup node scripts/download-poi-images-unsplash.js > poi-images.log 2>&1 &
 *
 * Environment:
 *   UNSPLASH_ACCESS_KEY - Your Unsplash API access key (required)
 *
 * Get a free API key at: https://unsplash.com/developers
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

// Configuration
const POIS_DIR = path.join(__dirname, '..', 'data', 'pois');
const IMAGES_DIR = path.join(POIS_DIR, 'images');
const PROGRESS_FILE = path.join(IMAGES_DIR, '.download-progress.json');
const MAX_IMAGES_PER_POI = 2;
const IMAGE_WIDTH = 1200;
const RATE_LIMIT_DELAY = 1000; // 1 second between requests (Unsplash allows 50/hour for demo)

// Unsplash API
const UNSPLASH_ACCESS_KEY = process.env.UNSPLASH_ACCESS_KEY;
const USER_AGENT = 'AGrandTour/1.0 (travel planning project)';

// Progress tracking
let progress = { completed: {}, failed: {}, lastCountry: null };

function loadProgress() {
  try {
    if (fs.existsSync(PROGRESS_FILE)) {
      progress = JSON.parse(fs.readFileSync(PROGRESS_FILE, 'utf8'));
    }
  } catch (e) {
    console.log('Starting fresh (no progress file)');
  }
}

function saveProgress() {
  fs.writeFileSync(PROGRESS_FILE, JSON.stringify(progress, null, 2));
}

// HTTPS helper
function httpsGet(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      headers: { 'User-Agent': USER_AGENT, ...headers }
    };

    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({
        data,
        statusCode: res.statusCode,
        headers: res.headers
      }));
    }).on('error', reject);
  });
}

// Search Unsplash for images
async function searchUnsplash(query) {
  if (!UNSPLASH_ACCESS_KEY) {
    return [];
  }

  const searchUrl = `https://api.unsplash.com/search/photos?query=${encodeURIComponent(query)}&per_page=${MAX_IMAGES_PER_POI}&orientation=landscape`;

  try {
    const { data, statusCode, headers } = await httpsGet(searchUrl, {
      'Authorization': `Client-ID ${UNSPLASH_ACCESS_KEY}`
    });

    if (statusCode === 403) {
      console.log('    [Rate limited by Unsplash]');
      return [];
    }

    if (statusCode !== 200) {
      return [];
    }

    const json = JSON.parse(data);
    return (json.results || []).map(photo => ({
      id: photo.id,
      url: photo.urls.regular, // 1080px wide
      downloadUrl: photo.links.download_location, // For attribution tracking
      photographer: photo.user.name,
      photographerUrl: photo.user.links.html
    }));
  } catch (e) {
    return [];
  }
}

// Search Wikimedia Commons as fallback
async function searchWikimedia(query) {
  const searchUrl = `https://commons.wikimedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&srnamespace=6&srlimit=${MAX_IMAGES_PER_POI * 2}&format=json`;

  try {
    const { data } = await httpsGet(searchUrl);
    const json = JSON.parse(data);
    const results = json.query?.search || [];

    const imageFiles = results
      .filter(r => /\.(jpg|jpeg|png)$/i.test(r.title))
      .slice(0, MAX_IMAGES_PER_POI);

    // Get URLs for each image
    const images = [];
    for (const file of imageFiles) {
      const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&titles=${encodeURIComponent(file.title)}&prop=imageinfo&iiprop=url&iiurlwidth=${IMAGE_WIDTH}&format=json`;
      const { data: urlData } = await httpsGet(apiUrl);
      const urlJson = JSON.parse(urlData);
      const pages = urlJson.query?.pages || {};
      const page = Object.values(pages)[0];
      const imageinfo = page?.imageinfo?.[0];
      const url = imageinfo?.thumburl || imageinfo?.url;

      if (url) {
        images.push({ url, source: 'wikimedia' });
      }

      await delay(500); // Rate limit for Wikimedia
    }

    return images;
  } catch (e) {
    return [];
  }
}

// Download image
async function downloadImage(url, filepath, retries = 3) {
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      return await new Promise((resolve, reject) => {
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
            downloadImage(res.headers.location, filepath, retries - attempt)
              .then(resolve).catch(reject);
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
    } catch (e) {
      if (e.message === 'RATE_LIMITED' && attempt < retries - 1) {
        await delay(5000 * (attempt + 1));
        continue;
      }
      throw e;
    }
  }
}

// Convert to WebP
function convertToWebP(inputPath, outputPath) {
  try {
    execSync(`cwebp -q 80 "${inputPath}" -o "${outputPath}" 2>/dev/null`, { stdio: 'pipe' });
    return true;
  } catch {
    try {
      execSync(`convert "${inputPath}" -quality 80 "${outputPath}" 2>/dev/null`, { stdio: 'pipe' });
      return true;
    } catch {
      // Copy as-is if conversion fails
      if (inputPath !== outputPath) {
        fs.copyFileSync(inputPath, outputPath.replace('.webp', '.jpg'));
      }
      return false;
    }
  }
}

// Delay helper
function delay(ms) {
  return new Promise(r => setTimeout(r, ms));
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
  const poiKey = `${countryCode}:${poiName}`;
  const safeName = sanitizeFilename(poiName);
  const country = poi.properties.country;

  // Skip if already completed
  if (progress.completed[poiKey]) {
    process.stdout.write(`  ${poiName}: cached\n`);
    return progress.completed[poiKey];
  }

  process.stdout.write(`  ${poiName}: `);

  // Check if images already exist
  const existingImages = fs.readdirSync(countryDir)
    .filter(f => f.startsWith(safeName) && f.endsWith('.webp'));

  if (existingImages.length >= MAX_IMAGES_PER_POI) {
    progress.completed[poiKey] = existingImages.length;
    saveProgress();
    console.log(`${existingImages.length} (existing)`);
    return existingImages.length;
  }

  // Search for images (Unsplash first, then Wikimedia)
  let images = [];

  if (UNSPLASH_ACCESS_KEY) {
    images = await searchUnsplash(`${poiName} ${country}`);
    await delay(RATE_LIMIT_DELAY);
  }

  if (images.length === 0) {
    images = await searchWikimedia(`${poiName} ${country}`);
  }

  if (images.length === 0) {
    console.log('no images found');
    progress.failed[poiKey] = 'no images';
    saveProgress();
    return 0;
  }

  let downloaded = existingImages.length;

  for (let i = downloaded; i < Math.min(images.length + downloaded, MAX_IMAGES_PER_POI); i++) {
    const image = images[i - downloaded];
    const tempPath = path.join(countryDir, `${safeName}-${i + 1}.tmp`);
    const finalPath = path.join(countryDir, `${safeName}-${i + 1}.webp`);

    if (fs.existsSync(finalPath)) {
      downloaded++;
      continue;
    }

    try {
      await downloadImage(image.url, tempPath);

      if (convertToWebP(tempPath, finalPath)) {
        downloaded++;
      }

      if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
    } catch (e) {
      if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath);
    }

    await delay(RATE_LIMIT_DELAY);
  }

  console.log(`${downloaded} images`);
  progress.completed[poiKey] = downloaded;
  saveProgress();

  return downloaded;
}

// Process a country
async function processCountry(countryCode) {
  const geojsonPath = path.join(POIS_DIR, `${countryCode}.geojson`);
  const countryDir = path.join(IMAGES_DIR, countryCode);

  if (!fs.existsSync(geojsonPath)) {
    console.log(`No GeoJSON for ${countryCode}`);
    return 0;
  }

  const data = JSON.parse(fs.readFileSync(geojsonPath, 'utf8'));
  const pois = data.features || [];

  console.log(`\n[${new Date().toISOString()}] Processing ${countryCode.toUpperCase()} (${pois.length} POIs)`);

  if (!fs.existsSync(countryDir)) {
    fs.mkdirSync(countryDir, { recursive: true });
  }

  let totalImages = 0;
  for (const poi of pois) {
    const count = await processPOI(poi, countryCode, countryDir);
    totalImages += count;
  }

  console.log(`  Total: ${totalImages} images for ${countryCode.toUpperCase()}`);
  progress.lastCountry = countryCode;
  saveProgress();

  return totalImages;
}

// Main
async function main() {
  console.log('='.repeat(60));
  console.log('POI Image Downloader');
  console.log('='.repeat(60));
  console.log(`Started: ${new Date().toISOString()}`);
  console.log(`Images dir: ${IMAGES_DIR}`);
  console.log(`API: ${UNSPLASH_ACCESS_KEY ? 'Unsplash + Wikimedia' : 'Wikimedia only'}`);
  console.log('='.repeat(60));

  if (!UNSPLASH_ACCESS_KEY) {
    console.log('\nNote: Set UNSPLASH_ACCESS_KEY for better results');
    console.log('Get a free key at: https://unsplash.com/developers\n');
  }

  loadProgress();

  const args = process.argv.slice(2);
  let totalImages = 0;

  if (args.length > 0) {
    // Process specific countries
    for (const code of args) {
      totalImages += await processCountry(code.toLowerCase());
    }
  } else {
    // Process all countries
    const files = fs.readdirSync(POIS_DIR)
      .filter(f => f.endsWith('.geojson'))
      .sort();

    for (const file of files) {
      const countryCode = file.replace('.geojson', '');
      totalImages += await processCountry(countryCode);
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log(`Completed: ${new Date().toISOString()}`);
  console.log(`Total images: ${totalImages}`);
  console.log('='.repeat(60));
}

main().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
