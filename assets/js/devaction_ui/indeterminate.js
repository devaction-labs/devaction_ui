/**
 * The partial state of a "select all" box. `indeterminate` is a property of the element, not an attribute, so
 * only script can set it; the server marks the box with `data-partial` and this keeps the property up with it.
 */
export default {
  mounted() {
    this.sync()
  },

  updated() {
    this.sync()
  },

  sync() {
    this.el.indeterminate = this.el.dataset.partial === "true"
  },
}
