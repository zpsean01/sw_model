/**
 * Main application — ZTreeManager tree navigation + content viewer.
 */

const APP = {};

/** Global JSONEditor instance (for regular nodes) */
APP.editor = null;

/** JSONEditor instance for the unified page third column */
APP.unifiedEditor = null;

/** GoJS diagram for the unified page */
APP.gojsDiagram = null;

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
  "modeling/unified_model":      null, // handled specially
  "sym_execution/report":        function() { return API.getSymReport(); },
  "sym_execution/paths":         function() { return API.getSymPaths(); },
};

/**
 * Handle ztree node click.
 * Special case: "modeling/unified_model" opens the 3-column page.
 * All others load data into the JSON editor.
 */
APP.onNodeClick = async function(event, treeId, treeNode) {
  if (treeNode.isParent === "true") return; // skip folder nodes

  if (treeNode.id === "modeling/unified_model") {
    await APP._showUnifiedPage();
    return;
  }

  // Normal nodes: show JSON editor, hide unified page
  APP._hideUnifiedPage();
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

// ── Unified 3-column page ──────────────────────────────────────

APP._showUnifiedPage = async function() {
  // Show unified page, hide regular JSON editor
  document.getElementById("jsoneditor").style.display = "none";
  document.getElementById("unified-page").style.display = "flex";

  // Show loading state
  document.getElementById("stats-content").innerHTML = "<p>Loading…</p>";

  try {
    // Fetch both data sources in parallel
    var [dataRes, gojsRes] = await Promise.all([
      fetch("/api/v1/sw_model/modeling/unified_model/data"),
      fetch("/api/v1/sw_model/modeling/unified_model/gojs"),
    ]);

    if (!dataRes.ok || !gojsRes.ok) {
      throw new Error("Failed to fetch data");
    }

    var data = await dataRes.json();
    var gojsData = await gojsRes.json();

    // Render statistics (column 1)
    APP._renderStats(data);

    // Render GoJS diagram (column 2)
    await APP._renderGoJS(gojsData);

    // Render JSON editor (column 3)
    APP._renderUnifiedJSON(data);
  } catch (err) {
    document.getElementById("stats-content").innerHTML =
      '<div class="error-box">' + err.message + "</div>";
  }
};

APP._hideUnifiedPage = function() {
  document.getElementById("jsoneditor").style.display = "block";
  document.getElementById("unified-page").style.display = "none";
};

APP._renderStats = function(data) {
  var nodes = data.nodes || [];
  var edges = data.edges || [];

  var funcNodes = nodes.filter(function(n) {
    return (n.attributes || {}).node_type === "function";
  });
  var regNodes = nodes.filter(function(n) {
    return (n.attributes || {}).node_type === "register";
  });

  // Count calls per function for edge analysis
  var functionCallers = {};
  edges.forEach(function(e) {
    functionCallers[e.source] = (functionCallers[e.source] || 0) + 1;
  });
  var callersWithEdges = Object.keys(functionCallers).length;

  // File distribution
  var fileMap = {};
  funcNodes.forEach(function(n) {
    var f = (n.attributes || {}).file || "unknown";
    fileMap[f] = (fileMap[f] || 0) + 1;
  });

  var fileEntries = Object.entries(fileMap).sort(function(a, b) {
    return b[1] - a[1];
  });

  var html = "";

  // Overview stats
  html += '<div class="stat-section">';
  html += "<h4>Overview</h4>";
  html += '<div class="stat-row"><span class="stat-label">Total Nodes</span><span class="stat-value">' + nodes.length + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Total Edges</span><span class="stat-value">' + edges.length + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Functions</span><span class="stat-value">' + funcNodes.length + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Registers</span><span class="stat-value">' + regNodes.length + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Functions with Calls</span><span class="stat-value">' + callersWithEdges + "</span></div>";
  html += "</div>";

  // Top files by function count
  html += '<div class="stat-section">';
  html += "<h4>Files (Top 10)</h4>";
  html += '<table class="stat-table">';
  var topFiles = fileEntries.slice(0, 10);
  topFiles.forEach(function(entry) {
    var path = entry[0].replace(/\\/g, "/").split("/").slice(-3).join("/");
    html += "<tr><td>" + path + "</td><td>" + entry[1] + "</td></tr>";
  });
  html += "</table>";
  html += "</div>";

  // Call edge summary
  html += '<div class="stat-section">';
  html += "<h4>Call Summary</h4>";
  edges.forEach(function(e) {
    html += '<div class="stat-row" style="font-size:12px">';
    html += '<span class="stat-label">' + e.source + " → " + e.target + "</span>";
    html += '<span class="stat-value">' + (e.key || "") + "</span>";
    html += "</div>";
  });
  html += "</div>";

  document.getElementById("stats-content").innerHTML = html;
};

APP._renderGoJS = function(gojsData) {
  // Create diagram if not yet created
  if (!APP.gojsDiagram) {
    APP.gojsDiagram = GoJSTopo.createDiagram("gojs-diagram", {
      layout: "ForceDirected",
      allowDrag: false,
      allowDrop: false,
      allowGroup: false,
      allowUngroup: false,
      allowDelete: false,
    });
  }
  // Load data
  GoJSTopo.loadData(gojsData);
};

APP._renderUnifiedJSON = function(data) {
  var container = document.getElementById("unified-jsoneditor");
  if (!APP.unifiedEditor) {
    APP.unifiedEditor = new JsonEditor(container, { mode: "view" });
  }
  APP.unifiedEditor.set(data);
  APP.unifiedEditor.expandAll();
};

// ── Regular JSON editor (for non-unified nodes) ────────────────

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

// ── Initialize ─────────────────────────────────────────────────

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

// ── Start on DOM ready ─────────────────────────────────────────
$(document).ready(function() {
  APP.init();
});