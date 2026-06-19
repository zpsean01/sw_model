/**
 * GoJS拓扑图通用展示模块（基于GoJSCommon公共模块）
 * 保留向后兼容的GoJSTopo接口
 */

const GoJSTopo = {
    diagram: null,

    createDiagram(containerId, options = {}) {
        const container = document.getElementById(containerId);
        if (!container) {
            console.error('Container not found:', containerId);
            return null;
        }

        container.innerHTML = '';

        const gojsOpts = {
            undoManager: options.undoManager !== undefined ? options.undoManager : false,
            allowDrop: options.allowDrop !== undefined ? options.allowDrop : true,
            allowDrag: options.allowDrag !== undefined ? options.allowDrag : true,
            allowGroup: options.allowGroup !== undefined ? options.allowGroup : true,
            allowUngroup: options.allowUngroup !== undefined ? options.allowUngroup : true,
            layout: options.layout || 'ForceDirected',
            onNodeClick: options.onNodeClick || null,
            onGroupClick: options.onGroupClick || null
        };

        this.diagram = GoJSCommon.createDiagram(containerId, gojsOpts);

        return this.diagram;
    },

    loadData(data) {
        if (!this.diagram || !data) return;

        GoJSCommon.loadData(this.diagram, data);
    },

    highlightNodes(keys) {
        if (!this.diagram) return;

        this.diagram.clearSelection();
        keys.forEach(k => {
            const node = this.diagram.findNodeForKey(k);
            if (node) this.diagram.select(node);
        });

        if (keys.length > 0) {
            this.diagram.zoomToSelection();
        }
    },

    clear() {
        if (this.diagram) {
            GoJSCommon.clear(this.diagram);
            this.diagram = null;
        }
    }
};

window.GoJSTopo = GoJSTopo;
