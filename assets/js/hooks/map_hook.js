import mapboxgl from 'mapbox-gl'

/**
 * MapHook - Integrates Mapbox GL JS with Phoenix LiveView.
 *
 * Usage in HEEx:
 *   <div id="map" phx-hook="MapHook" phx-update="ignore"
 *        data-mapbox-token="pk.xxx" data-lng="0" data-lat="20" data-zoom="1.5">
 *   </div>
 *
 * Events from LiveView to Map:
 *   - fly_to: {lng, lat, zoom} - Animate to location
 *   - update_route: {geojson} - Update route layer data
 *   - add_markers: {markers} - Add markers to map
 *
 * Events from Map to LiveView:
 *   - map_clicked: {lng, lat} - User clicked on map
 *   - map_loaded: {} - Map finished loading
 */
export const MapHook = {
  mounted() {
    const token = this.el.dataset.mapboxToken
    const lng = parseFloat(this.el.dataset.lng) || 0
    const lat = parseFloat(this.el.dataset.lat) || 20
    const zoom = parseFloat(this.el.dataset.zoom) || 1.5

    if (!token) {
      console.error('MapHook: No Mapbox token provided')
      return
    }

    mapboxgl.accessToken = token

    // Wait for next frame to ensure container has dimensions
    requestAnimationFrame(() => {
      this.initMap(lng, lat, zoom)
    })
  },

  initMap(lng, lat, zoom) {
    // Initialize the map with globe projection
    this.map = new mapboxgl.Map({
      container: this.el,
      style: 'mapbox://styles/mapbox/outdoors-v12',
      center: [lng, lat],
      zoom: zoom,
      projection: 'globe',
      antialias: true
    })

    // Add atmosphere and fog for globe effect
    this.map.on('style.load', () => {
      this.map.setFog({
        color: 'rgb(186, 210, 235)',
        'high-color': 'rgb(36, 92, 223)',
        'horizon-blend': 0.02,
        'space-color': 'rgb(11, 11, 25)',
        'star-intensity': 0.6
      })

      // Add empty source for route (will be populated later)
      this.map.addSource('route', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      })

      // Route line layer
      this.map.addLayer({
        id: 'route-line',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#e74c3c',
          'line-width': 3,
          'line-opacity': 0.8
        }
      })

      // Add empty source for POI markers
      this.map.addSource('pois', {
        type: 'geojson',
        data: { type: 'FeatureCollection', features: [] }
      })

      // POI circle layer
      this.map.addLayer({
        id: 'poi-circles',
        type: 'circle',
        source: 'pois',
        paint: {
          'circle-radius': 6,
          'circle-color': '#3498db',
          'circle-stroke-width': 2,
          'circle-stroke-color': '#fff'
        }
      })
    })

    // Navigation controls
    this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')

    // Map click handler
    this.map.on('click', (e) => {
      this.pushEvent('map_clicked', {
        lng: e.lngLat.lng,
        lat: e.lngLat.lat
      })
    })

    // Notify LiveView when map is loaded
    this.map.on('load', () => {
      // Resize to ensure proper dimensions after DOM is ready
      this.map.resize()
      this.pushEvent('map_loaded', {})
    })

    // Also resize on window resize
    this.resizeHandler = () => this.map.resize()
    window.addEventListener('resize', this.resizeHandler)

    // Handle events from LiveView
    this.handleEvent('fly_to', ({ lng, lat, zoom }) => {
      this.map.flyTo({
        center: [lng, lat],
        zoom: zoom || this.map.getZoom(),
        essential: true
      })
    })

    this.handleEvent('update_route', ({ geojson }) => {
      const source = this.map.getSource('route')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('update_pois', ({ geojson }) => {
      const source = this.map.getSource('pois')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('fit_bounds', ({ bounds, padding }) => {
      this.map.fitBounds(bounds, {
        padding: padding || 50,
        essential: true
      })
    })
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
    if (this.map) {
      this.map.remove()
    }
  }
}
