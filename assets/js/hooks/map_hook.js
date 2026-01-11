import mapboxgl from 'mapbox-gl'

/**
 * MapHook - Integrates Mapbox GL JS with Phoenix LiveView.
 * Displays all tour datasets on a globe with an interactive legend.
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

    // Layer visibility state
    this.layerVisibility = {
      'pois': true,
      'scenic-routes': true,
      'ferries': true,
      'shipping': true,
      'risk-regions': true,
      'safe-corridors': true,
      'route': true
    }

    // Wait for next frame to ensure container has dimensions
    requestAnimationFrame(() => {
      this.initMap(lng, lat, zoom)
    })

    // Expose map for debugging
    this.el._mapHook = this
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
      this.updateFog()
      this.setupThemeObserver()
      this.initializeLayers()
      this.createLegend()
    })

    // Navigation controls
    this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')

    // Map click handler
    this.map.on('click', (e) => {
      // Check if we clicked on a POI
      const features = this.map.queryRenderedFeatures(e.point, { layers: ['pois-circle'] })
      if (features.length > 0) {
        const props = features[0].properties
        this.pushEvent('poi_clicked', {
          id: props.id,
          name: props.name
        })
        return
      }

      this.pushEvent('map_clicked', {
        lng: e.lngLat.lng,
        lat: e.lngLat.lat
      })
    })

    // Notify LiveView when map is loaded
    this.map.on('load', () => {
      this.map.resize()
      this.pushEvent('map_loaded', {})
    })

    // Also resize on window resize
    this.resizeHandler = () => this.map.resize()
    window.addEventListener('resize', this.resizeHandler)

    // Handle events from LiveView
    this.setupEventHandlers()
  },

  initializeLayers() {
    // Add empty sources for all datasets
    const emptyGeoJSON = { type: 'FeatureCollection', features: [] }

    // Risk regions (polygons) - add first so they're below everything
    // Note: data uses 'risk' property with values like 'red', 'yellow'
    this.map.addSource('risk-regions', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'risk-regions-fill',
      type: 'fill',
      source: 'risk-regions',
      paint: {
        'fill-color': [
          'match', ['get', 'risk'],
          'red', 'rgba(231, 76, 60, 0.35)',
          'yellow', 'rgba(241, 196, 15, 0.25)',
          'rgba(231, 76, 60, 0.25)'
        ],
        'fill-opacity': 0.8
      }
    })
    this.map.addLayer({
      id: 'risk-regions-outline',
      type: 'line',
      source: 'risk-regions',
      paint: {
        'line-color': [
          'match', ['get', 'risk'],
          'red', '#c0392b',
          'yellow', '#d4ac0d',
          '#c0392b'
        ],
        'line-width': 1.5,
        'line-opacity': 0.7
      }
    })

    // Safe corridors (dashed green lines)
    this.map.addSource('safe-corridors', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'safe-corridors-line',
      type: 'line',
      source: 'safe-corridors',
      filter: ['==', ['geometry-type'], 'LineString'],
      paint: {
        'line-color': '#27ae60',
        'line-width': [
          'interpolate', ['linear'], ['zoom'],
          1, 1.5,
          3, 2,
          6, 3,
          10, 4
        ],
        'line-opacity': 0.8,
        'line-dasharray': [3, 2]
      }
    })

    // Shipping routes (dashed light blue)
    this.map.addSource('shipping', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'shipping-line',
      type: 'line',
      source: 'shipping',
      filter: ['==', ['geometry-type'], 'LineString'],
      paint: {
        'line-color': '#85c1e9',
        'line-width': [
          'interpolate', ['linear'], ['zoom'],
          1, 1.5,
          3, 2,
          6, 2.5,
          10, 3
        ],
        'line-dasharray': [4, 3],
        'line-opacity': 0.8
      }
    })

    // Ferries (dashed dark blue)
    this.map.addSource('ferries', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'ferries-line',
      type: 'line',
      source: 'ferries',
      paint: {
        'line-color': '#1a5276',
        'line-width': [
          'interpolate', ['linear'], ['zoom'],
          1, 1.5,
          3, 2,
          6, 2.5,
          10, 3
        ],
        'line-dasharray': [2, 2],
        'line-opacity': 0.9
      }
    })

    // Scenic routes (orange) - thicker at low zoom for globe visibility
    this.map.addSource('scenic-routes', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'scenic-routes-line',
      type: 'line',
      source: 'scenic-routes',
      layout: {
        'line-join': 'round',
        'line-cap': 'round'
      },
      paint: {
        'line-color': '#e67e22',
        'line-width': [
          'interpolate', ['linear'], ['zoom'],
          1, 1.5,
          3, 2,
          6, 3,
          10, 4
        ],
        'line-opacity': 0.9
      }
    })

    // Planned route (blue line)
    this.map.addSource('route', { type: 'geojson', data: emptyGeoJSON })
    this.map.addLayer({
      id: 'route-line',
      type: 'line',
      source: 'route',
      layout: {
        'line-join': 'round',
        'line-cap': 'round'
      },
      paint: {
        'line-color': '#3498db',
        'line-width': 4,
        'line-opacity': 0.8
      }
    })

    // POIs (circles colored by rating) - no clustering by default
    this.poisClustering = false
    this.poisData = emptyGeoJSON
    this.map.addSource('pois', {
      type: 'geojson',
      data: emptyGeoJSON
    })

    // Individual POIs
    this.map.addLayer({
      id: 'pois-circle',
      type: 'circle',
      source: 'pois',
      paint: {
        'circle-color': [
          'match', ['get', 'rating'],
          5, '#e74c3c',
          4, '#e67e22',
          3, '#f39c12',
          2, '#f1c40f',
          1, '#f1c40f',
          '#888888'
        ],
        'circle-radius': [
          'interpolate', ['linear'], ['zoom'],
          1, 3,
          5, 5,
          10, 8
        ],
        'circle-stroke-color': '#fff',
        'circle-stroke-width': [
          'interpolate', ['linear'], ['zoom'],
          1, 0.5,
          5, 1,
          10, 2
        ],
        'circle-opacity': 0.9
      }
    })

    // Cursor changes for POIs
    this.map.on('mouseenter', 'pois-circle', () => {
      this.map.getCanvas().style.cursor = 'pointer'
    })
    this.map.on('mouseleave', 'pois-circle', () => {
      this.map.getCanvas().style.cursor = ''
    })

    // POI hover popup
    this.popup = new mapboxgl.Popup({
      closeButton: false,
      closeOnClick: false,
      offset: 10
    })

    this.map.on('mouseenter', 'pois-circle', (e) => {
      const props = e.features[0].properties
      const coords = e.features[0].geometry.coordinates.slice()

      const html = `
        <div style="font-family: system-ui; font-size: 12px;">
          <strong>${props.name}</strong>
          ${props.rating ? `<div style="color: #e67e22;">${'★'.repeat(props.rating)}${'☆'.repeat(5-props.rating)}</div>` : ''}
        </div>
      `

      this.popup.setLngLat(coords).setHTML(html).addTo(this.map)
    })

    this.map.on('mouseleave', 'pois-circle', () => {
      this.popup.remove()
    })
  },

  createLegend() {
    // Create legend container
    const legend = document.createElement('div')
    legend.className = 'map-legend'
    legend.innerHTML = `
      <h4>Layers</h4>
      <div class="legend-item" data-layer="pois">
        <div class="legend-icon"><div class="legend-dot" style="background: #e74c3c;"></div></div>
        <span>Points of Interest</span>
      </div>
      <div class="legend-item" data-layer="scenic-routes">
        <div class="legend-icon"><div class="legend-line" style="background: #e67e22;"></div></div>
        <span>Scenic Routes</span>
      </div>
      <div class="legend-item" data-layer="ferries">
        <div class="legend-icon"><div class="legend-line" style="background: #1a5276;"></div></div>
        <span>Ferries</span>
      </div>
      <div class="legend-item" data-layer="shipping">
        <div class="legend-icon"><div class="legend-line" style="background: #85c1e9;"></div></div>
        <span>Shipping</span>
      </div>
      <div class="legend-item" data-layer="safe-corridors">
        <div class="legend-icon"><div class="legend-line legend-dashed" style="color: #27ae60;"></div></div>
        <span>Safe Corridors</span>
      </div>
      <div class="legend-item" data-layer="risk-regions">
        <div class="legend-icon"><div class="legend-box" style="background: rgba(231, 76, 60, 0.35); border: 1px solid #c0392b;"></div></div>
        <span>Risk Regions</span>
      </div>
      <div class="legend-item" data-layer="route">
        <div class="legend-icon"><div class="legend-line" style="background: #3498db;"></div></div>
        <span>Planned Route</span>
      </div>
    `

    // Add click handlers for toggleable layers
    const toggleItems = legend.querySelectorAll('.legend-item[data-layer]')
    toggleItems.forEach(item => {
      item.style.cursor = 'pointer'
      item.addEventListener('click', () => {
        const layerKey = item.dataset.layer
        this.toggleLayer(layerKey)

        // Update visual state
        if (this.layerVisibility[layerKey]) {
          item.classList.remove('legend-item-disabled')
        } else {
          item.classList.add('legend-item-disabled')
        }
      })
    })

    // Add to map container
    this.el.appendChild(legend)
    this.legend = legend
  },

  toggleClustering(enabled) {
    this.poisClustering = enabled

    // Remove old source and layers
    if (this.map.getLayer('pois-circle')) this.map.removeLayer('pois-circle')
    if (this.map.getLayer('pois-clusters')) this.map.removeLayer('pois-clusters')
    if (this.map.getLayer('pois-cluster-count')) this.map.removeLayer('pois-cluster-count')
    if (this.map.getSource('pois')) this.map.removeSource('pois')

    // Re-add source with/without clustering
    if (enabled) {
      this.map.addSource('pois', {
        type: 'geojson',
        data: this.poisData,
        cluster: true,
        clusterMaxZoom: 8,
        clusterRadius: 50
      })

      // Add cluster circles
      this.map.addLayer({
        id: 'pois-clusters',
        type: 'circle',
        source: 'pois',
        filter: ['has', 'point_count'],
        paint: {
          'circle-color': ['step', ['get', 'point_count'], '#e67e22', 10, '#e74c3c', 30, '#c0392b'],
          'circle-radius': ['step', ['get', 'point_count'], 15, 10, 20, 30, 25],
          'circle-stroke-width': 2,
          'circle-stroke-color': '#fff'
        }
      })

      // Add cluster count labels
      this.map.addLayer({
        id: 'pois-cluster-count',
        type: 'symbol',
        source: 'pois',
        filter: ['has', 'point_count'],
        layout: {
          'text-field': '{point_count_abbreviated}',
          'text-font': ['DIN Pro Medium', 'Arial Unicode MS Bold'],
          'text-size': 12
        },
        paint: { 'text-color': '#ffffff' }
      })

      // Add individual POIs (unclustered)
      this.map.addLayer({
        id: 'pois-circle',
        type: 'circle',
        source: 'pois',
        filter: ['!', ['has', 'point_count']],
        paint: {
          'circle-color': ['match', ['get', 'rating'], 5, '#e74c3c', 4, '#e67e22', 3, '#f39c12', 2, '#f1c40f', 1, '#f1c40f', '#888888'],
          'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 3, 5, 5, 10, 8],
          'circle-stroke-color': '#fff',
          'circle-stroke-width': ['interpolate', ['linear'], ['zoom'], 1, 0.5, 5, 1, 10, 2],
          'circle-opacity': 0.9
        }
      })
    } else {
      this.map.addSource('pois', {
        type: 'geojson',
        data: this.poisData
      })

      this.map.addLayer({
        id: 'pois-circle',
        type: 'circle',
        source: 'pois',
        paint: {
          'circle-color': ['match', ['get', 'rating'], 5, '#e74c3c', 4, '#e67e22', 3, '#f39c12', 2, '#f1c40f', 1, '#f1c40f', '#888888'],
          'circle-radius': ['interpolate', ['linear'], ['zoom'], 1, 3, 5, 5, 10, 8],
          'circle-stroke-color': '#fff',
          'circle-stroke-width': ['interpolate', ['linear'], ['zoom'], 1, 0.5, 5, 1, 10, 2],
          'circle-opacity': 0.9
        }
      })
    }
  },

  toggleLayer(layerKey) {
    this.layerVisibility[layerKey] = !this.layerVisibility[layerKey]
    const visibility = this.layerVisibility[layerKey] ? 'visible' : 'none'

    // Map layer key to actual layer IDs
    let layers = []
    if (layerKey === 'pois') {
      // Include cluster layers if clustering is enabled
      layers = this.poisClustering
        ? ['pois-circle', 'pois-clusters', 'pois-cluster-count']
        : ['pois-circle']
    } else {
      const layerMap = {
        'scenic-routes': ['scenic-routes-line'],
        'ferries': ['ferries-line'],
        'shipping': ['shipping-line'],
        'safe-corridors': ['safe-corridors-line'],
        'risk-regions': ['risk-regions-fill', 'risk-regions-outline'],
        'route': ['route-line']
      }
      layers = layerMap[layerKey] || []
    }

    layers.forEach(layerId => {
      if (this.map.getLayer(layerId)) {
        this.map.setLayoutProperty(layerId, 'visibility', visibility)
      }
    })
  },

  setupEventHandlers() {
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

    this.handleEvent('update_scenic_routes', ({ geojson }) => {
      const source = this.map.getSource('scenic-routes')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('update_ferries', ({ geojson }) => {
      const source = this.map.getSource('ferries')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('update_shipping', ({ geojson }) => {
      const source = this.map.getSource('shipping')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('update_risk_regions', ({ geojson }) => {
      const source = this.map.getSource('risk-regions')
      if (source) {
        source.setData(geojson)
      }
    })

    this.handleEvent('update_safe_corridors', ({ geojson }) => {
      const source = this.map.getSource('safe-corridors')
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

    // Batch update all layers at once
    this.handleEvent('update_all_layers', (data) => {
      if (data.pois) {
        this.poisData = data.pois  // Store for clustering toggle
        const source = this.map.getSource('pois')
        if (source) source.setData(data.pois)
      }
      if (data.scenic_routes) {
        const source = this.map.getSource('scenic-routes')
        if (source) source.setData(data.scenic_routes)
      }
      if (data.ferries) {
        const source = this.map.getSource('ferries')
        if (source) source.setData(data.ferries)
      }
      if (data.shipping) {
        const source = this.map.getSource('shipping')
        if (source) source.setData(data.shipping)
      }
      if (data.risk_regions) {
        const source = this.map.getSource('risk-regions')
        if (source) source.setData(data.risk_regions)
      }
      if (data.safe_corridors) {
        const source = this.map.getSource('safe-corridors')
        if (source) source.setData(data.safe_corridors)
      }
    })
  },

  destroyed() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
    if (this.themeObserver) {
      this.themeObserver.disconnect()
    }
    if (this.legend) {
      this.legend.remove()
    }
    if (this.popup) {
      this.popup.remove()
    }
    if (this.map) {
      this.map.remove()
    }
  },

  getTheme() {
    return document.documentElement.getAttribute('data-theme') || 'light'
  },

  updateFog() {
    if (!this.map) return

    const isDark = this.getTheme() === 'dark'

    if (isDark) {
      // Night sky with stars
      this.map.setFog({
        color: 'rgb(186, 210, 235)',
        'high-color': 'rgb(36, 92, 223)',
        'horizon-blend': 0.02,
        'space-color': 'rgb(11, 11, 25)',
        'star-intensity': 0.6
      })
    } else {
      // Daytime sky - no stars, light blue space
      this.map.setFog({
        color: 'rgb(220, 235, 255)',
        'high-color': 'rgb(135, 206, 235)',
        'horizon-blend': 0.02,
        'space-color': 'rgb(200, 225, 255)',
        'star-intensity': 0
      })
    }
  },

  setupThemeObserver() {
    // Watch for theme changes on the html element
    this.themeObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.attributeName === 'data-theme') {
          this.updateFog()
        }
      }
    })

    this.themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme']
    })
  }
}
