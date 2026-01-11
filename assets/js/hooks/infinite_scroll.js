/**
 * InfiniteScroll Hook
 *
 * Triggers a "load_more" event when the element becomes visible in the viewport.
 * Used to implement infinite scrolling/lazy loading for large lists.
 *
 * Usage in HEEx:
 *   <div id="load-trigger" phx-hook="InfiniteScroll"></div>
 */
export const InfiniteScroll = {
  mounted() {
    this.pending = false

    this.observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (entry.isIntersecting && !this.pending) {
          this.pending = true
          this.pushEvent("load_more", {}, () => {
            // Allow next load after server responds
            this.pending = false
          })
        }
      },
      {
        root: null,
        rootMargin: "200px", // Trigger 200px before element is visible
        threshold: 0
      }
    )

    this.observer.observe(this.el)
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
