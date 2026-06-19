/**
 * Main application — ZTreeManager tree navigation + JSON Editor data viewer.
 */
const APP = {};

/** Global JSONEditor instance */
APP.editor = null;

/** Map ztree node id → API fetch function */
APP.API_MAP = {
  "static/functions":      function() { return API.getStatic("functions"); },
  "static/call_graph":     function() { return API.getStatic("call_graph"); },
  "static/globals":        function() { return API.getStatic("globals"); },
  "static/types":          function() { return API.getStatic("types"); },
  "static/interrupts":     function() { return API.getStatic("interrupts"); },
  "static/registers":      function() { return API.getStatic("registers"); },
  "static/state_machines": function() { return API.getStatic("state_machines"); },
  "binary/functions":      function() { return API.getBinary("functions"); },
  "binary/call_graph":     function() { return API.getBinary("call_graph"); },
  "binary/globals":        function() { return API.getBinary("globals"); },
  "binary/types":          function() { return API.getBinary("types"); },
  "modeling/event_architecture": function() { return API.getModeling("event_architecture"); },
  "modeling/security_report":    function() { return API.getModeling("security_report"); },
  "sym_execution/report":        function() { return API.getSymReport(); },
  "sym_execution/paths":         function() { return API.getSymPaths(); },
};

/**
 * Handle ztree node click — fetch data and load into JSON editor.
 */
APP.onNodeClick = async function(event, treeId, treeNode) {
  if (treeNode.isParent === "true") return; // skip folder nodes
  var fetchFn = APP.API_MAP[treeNode.id];
  if (!fetchFn) {
    APP.setEditor({ error: "No API mapping for: " + treeNode.id });
    return;
  }
  APP.setEditor({ loading: treeNode.id + " …" });
  try {
    var data = await fetchFn();
    APP.setEditor(data);
  } catch (err) {
    APP.setEditor({ error: err.message });
  }
};

/**
 * Set value into the JSON editor (or initialize it).
 */
APP.setEditor = function(data) {
  if (!APP.editor) {
    var container = document.getElementById("jsoneditor");
    APP.editor = new JsonEditor(container, {
      mode: "view",
    });
  }
  APP.editor.set(data);
  APP.editor.expandAll();
};

/**
 * Initialize — load zTree data via ZTreeManager, create tree.
 */
APP.init = async function() {
  try {
    var treeData = await ZTreeManager.fetchZTreeData();
    ZTreeManager.createTree("ztree", treeData, {
      onClick: APP.onNodeClick,
    });
    // Expand all nodes after creation
    var treeObj = $.fn.zTree.getZTreeObj("ztree");
    if (treeObj) treeObj.expandAll(true);
  } catch (err) {
    $("#ztree").html(
      '<div class="error-box">Failed to load tree: ' + err.message + "</div>"
    );
  }
};

// ── Start on DOM ready ──────────────────────────────
$(document).ready(function() {
  APP.init();
});