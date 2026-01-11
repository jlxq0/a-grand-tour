/**
 * QuickFilter Hook
 *
 * Provides instant client-side filtering of elements marked with data-filterable.
 * This gives immediate visual feedback while the server-side filter debounces.
 *
 * Usage in HEEx:
 *   <input id="filter" phx-hook="QuickFilter" phx-change="filter_items" />
 *
 * Elements to filter should have:
 *   data-filterable - marks element as filterable
 *   data-filterable-text - text content to search (optional, uses innerText if not set)
 */
export const QuickFilter = {
  mounted() {
    this.el.addEventListener("input", (e) => {
      this.filterItems(e.target.value)
    })

    // Handle initial value if any
    if (this.el.value) {
      this.filterItems(this.el.value)
    }
  },

  updated() {
    // Re-apply filter when DOM is updated (e.g., after loading more items)
    if (this.el.value) {
      this.filterItems(this.el.value)
    }
  },

  filterItems(query) {
    const searchTerm = query.toLowerCase().trim()
    const filterables = document.querySelectorAll("[data-filterable]")

    filterables.forEach((el) => {
      if (!searchTerm) {
        // Show all when query is empty
        el.style.display = ""
        return
      }

      // Get searchable text from data attribute or element content
      const text = (
        el.dataset.filterableText || el.innerText || ""
      ).toLowerCase()

      // Show/hide based on match
      if (text.includes(searchTerm)) {
        el.style.display = ""
      } else {
        el.style.display = "none"
      }
    })

    // Update visible count if there's a counter element
    this.updateVisibleCount(filterables, searchTerm)
  },

  updateVisibleCount(filterables, searchTerm) {
    const counter = document.querySelector("[data-filter-count]")
    if (!counter) return

    if (!searchTerm) {
      counter.textContent = counter.dataset.totalCount || filterables.length
    } else {
      const visible = Array.from(filterables).filter(
        (el) => el.style.display !== "none"
      ).length
      counter.textContent = visible
    }
  }
}
