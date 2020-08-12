customElements.define(
  "block-content",
  class extends HTMLElement {
    constructor() {
      super();
    }

    set blocks(blocks) {
      this.setHTMLContent(blocks);
    }

    setHTMLContent(blocks) {
      if (blocks) {
        const rootNode = blocksToHyperScript({ blocks });
        this.innerHTML = rootNode.outerHTML || rootNode;
      }
    }
  }
);
