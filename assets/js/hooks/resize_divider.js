/**
 * ResizeDivider hook for resizing the split view panels.
 * Drag the divider to adjust the width of map and content panels.
 */
export const ResizeDivider = {
  mounted() {
    this.isDragging = false
    this.mapPanel = document.getElementById('map-panel')
    this.contentPanel = document.getElementById('content-panel')
    this.container = this.mapPanel?.parentElement

    if (!this.mapPanel || !this.contentPanel || !this.container) {
      console.warn('ResizeDivider: Could not find required panels')
      return
    }

    this.handleMouseDown = this.handleMouseDown.bind(this)
    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseUp = this.handleMouseUp.bind(this)

    this.el.addEventListener('mousedown', this.handleMouseDown)
    document.addEventListener('mousemove', this.handleMouseMove)
    document.addEventListener('mouseup', this.handleMouseUp)

    // Touch support
    this.el.addEventListener('touchstart', this.handleMouseDown)
    document.addEventListener('touchmove', this.handleMouseMove)
    document.addEventListener('touchend', this.handleMouseUp)
  },

  destroyed() {
    document.removeEventListener('mousemove', this.handleMouseMove)
    document.removeEventListener('mouseup', this.handleMouseUp)
    document.removeEventListener('touchmove', this.handleMouseMove)
    document.removeEventListener('touchend', this.handleMouseUp)
  },

  handleMouseDown(e) {
    e.preventDefault()
    this.isDragging = true
    this.el.classList.add('bg-primary')
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'
  },

  handleMouseMove(e) {
    if (!this.isDragging) return

    const clientX = e.touches ? e.touches[0].clientX : e.clientX
    const containerRect = this.container.getBoundingClientRect()
    const containerWidth = containerRect.width
    const offsetX = clientX - containerRect.left

    // Calculate percentage (with min/max constraints)
    let percentage = (offsetX / containerWidth) * 100
    percentage = Math.max(20, Math.min(80, percentage)) // Clamp between 20% and 80%

    // Apply the new widths
    this.mapPanel.style.width = `${percentage}%`
    this.contentPanel.style.width = `${100 - percentage}%`

    // Trigger resize event so the map can update
    window.dispatchEvent(new Event('resize'))
  },

  handleMouseUp() {
    if (!this.isDragging) return

    this.isDragging = false
    this.el.classList.remove('bg-primary')
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  }
}
