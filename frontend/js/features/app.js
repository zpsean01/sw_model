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
  "modeling/protocol_conformance": null, // handled specially
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
  if (treeNode.id === "modeling/protocol_conformance") {
    await APP._showProtocolConformancePage();
    return;
  }

  // Normal nodes: show JSON editor, hide special pages
  APP._hideUnifiedPage();
  APP._hideProtocolPage();
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

// ── Protocol Conformance 3-column page ──────────────────────────

APP._hideProtocolPage = function() {
  document.getElementById("jsoneditor").style.display = "block";
  document.getElementById("protocol-page").style.display = "none";
};

APP._showProtocolConformancePage = async function() {
  document.getElementById("jsoneditor").style.display = "none";
  document.getElementById("unified-page").style.display = "none";
  document.getElementById("protocol-page").style.display = "flex";

  document.getElementById("pc-stats-content").innerHTML = "<p>Loading…</p>";
  document.getElementById("pc-detail-content").innerHTML = "";

  try {
    var [dataRes, gojsRes] = await Promise.all([
      fetch("/api/v1/sw_model/modeling/protocol_conformance/data"),
      fetch("/api/v1/sw_model/modeling/protocol_conformance/gojs"),
    ]);
    if (!dataRes.ok || !gojsRes.ok) throw new Error("Failed to fetch data");

    var findingsData = await dataRes.json();
    var gojsData = await gojsRes.json();

    APP._renderPCStats(findingsData);
    APP._renderPCGoJS(gojsData, findingsData);
    APP._renderPCDetails(findingsData);
  } catch (err) {
    document.getElementById("pc-stats-content").innerHTML =
      '<div class="error-box">' + err.message + "</div>";
  }
};

APP._renderPCStats = function(data) {
  var findings = data.findings || [];
  var total = findings.length;

  // Count by severity
  var severityCounts = {};
  var typeCounts = {};
  findings.forEach(function(f) {
    var sev = f.severity || "unknown";
    var typ = f.type || "unknown";
    severityCounts[sev] = (severityCounts[sev] || 0) + 1;
    typeCounts[typ] = (typeCounts[typ] || 0) + 1;
  });

  var html = "";

  // Overview
  html += '<div class="stat-section">';
  html += "<h4>Overview</h4>";
  html += '<div class="stat-row"><span class="stat-label">Total Findings</span><span class="stat-value">' + total + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Check Types</span><span class="stat-value">' + Object.keys(typeCounts).length + "</span></div>";
  html += '<div class="stat-row"><span class="stat-label">Protocol Version</span><span class="stat-value">JESD79-5C</span></div>';
  html += "</div>";

  // Severity distribution
  var severityOrder = ["critical", "high", "medium", "low", "info"];
  html += '<div class="stat-section">';
  html += "<h4>Severity Distribution</h4>";
  severityOrder.forEach(function(s) {
    if (severityCounts[s]) {
      var pct = Math.round(severityCounts[s] / total * 100);
      html += '<div class="stat-row">';
      html += '<span class="stat-label"><span class="pc-severity-badge pc-severity-' + s + '">' + s + "</span></span>";
      html += '<span class="stat-value">' + severityCounts[s] + " (" + pct + "%)</span>";
      html += "</div>";
    }
  });
  html += "</div>";

  // Type distribution
  html += '<div class="stat-section">';
  html += "<h4>Finding Type Distribution</h4>";
  Object.keys(typeCounts).sort().forEach(function(t) {
    var pct = Math.round(typeCounts[t] / total * 100);
    var shortType = t.split("_").slice(0, 3).join(" ");
    html += '<div class="stat-row">';
    html += '<span class="stat-label">' + shortType + "</span>";
    html += '<span class="stat-value">' + typeCounts[t] + " (" + pct + "%)</span>";
    html += "</div>";
  });
  html += "</div>";

  // Finding list compact
  html += '<div class="stat-section">';
  html += "<h4>All Findings</h4>";
  findings.forEach(function(f, i) {
    var sev = f.severity || "info";
    html += '<div class="pc-finding-card" onclick="APP._pcFindAndHighlight(\'' + (f.location ? (f.location.function || "") : "") + '\', ' + i + ')">';
    html += "<h5>";
    html += '<span class="pc-severity-badge pc-severity-' + sev + '">' + sev + "</span>";
    html += (f.location ? (f.location.function || "unknown function") : "unknown");
    html += "</h5>";
    html += '<div class="pc-finding-msg">' + (f.message || "").substring(0, 100) + "</div>";
    html += '<div class="pc-finding-meta">' + (f.spec_ref || "").substring(0, 60) + "</div>";
    html += "</div>";
  });
  html += "</div>";

  document.getElementById("pc-stats-content").innerHTML = html;
};

APP._renderPCGoJS = function(gojsData, findingsData) {
  var container = document.getElementById("pc-gojs-diagram");
  container.innerHTML = "";

  // Create dedicated diagram for protocol conformance
  APP.pcDiagram = GoJSTopo.createDiagram("pc-gojs-diagram", {
    layout: "ForceDirected",
    allowDrag: false,
    allowDrop: false,
    allowGroup: false,
    allowUngroup: false,
    allowDelete: false,
  });

  // Load data (backend already annotated nodeDataArray with 'findings' and 'color')
  GoJSTopo.loadData(gojsData);

  // Color nodes using the backend-supplied 'color' field
  if (APP.pcDiagram) {
    var nodeDataArr = gojsData.nodeDataArray || [];
    var usedColors = {};
    nodeDataArr.forEach(function(nd) {
      if (nd.color) {
        var node = APP.pcDiagram.findNodeForKey(nd.key);
        if (node) {
          var shape = node.findObject("SHAPE");
          if (shape) {
            shape.fill = nd.color;
            shape.strokeWidth = 3;
          }
        }
        usedColors[nd.color] = nd.findings ? nd.findings[0].severity : "info";
      }
    });

    // Build legend from used colors
    var legendLabels = {
      "#7f1d1d": "Critical",
      "#dc2626": "High",
      "#f59e0b": "Medium",
      "#3b82f6": "Low",
    };
    var legendHtml = '<div class="pc-color-legend">';
    Object.keys(usedColors).forEach(function(c) {
      var label = legendLabels[c] || "Info";
      legendHtml += '<span class="pc-legend-item"><span class="pc-legend-swatch" style="background:' + c + '"></span> ' + label + "</span>";
    });
    legendHtml += "</div>";

    var legendEl = document.createElement("div");
    legendEl.innerHTML = legendHtml;
    container.parentNode.insertBefore(legendEl.firstChild, container.nextSibling);
  }
};

APP._renderPCDetails = function(data) {
  var findings = data.findings || [];
  var html = "";

  findings.forEach(function(f, i) {
    var sev = f.severity || "info";
    var typ = f.type || "unknown";
    html += '<div class="pc-finding-card" onclick="APP._pcFindAndHighlight(\'' + (f.location ? (f.location.function || "") : "") + '\', ' + i + ')">';
    html += "<h5>";
    html += '<span class="pc-severity-badge pc-severity-' + sev + '">' + sev + "</span>";
    html += '<span style="font-weight:400;color:var(--text-secondary);font-size:11px">' + typ + "</span>";
    html += "</h5>";
    html += '<div class="pc-finding-msg">' + (f.message || "") + "</div>";
    if (f.spec_ref) {
      html += '<div class="pc-finding-meta"><strong>Spec:</strong> ' + f.spec_ref + "</div>";
    }
    if (f.expected) {
      html += '<div class="pc-finding-meta"><strong>Expected:</strong> ' + f.expected + "</div>";
    }
    if (f.actual) {
      html += '<div class="pc-finding-meta"><strong>Actual:</strong> ' + f.actual + "</div>";
    }
    if (f.location && f.location.function) {
      html += '<div class="pc-finding-meta"><strong>Function:</strong> ' + f.location.function + "</div>";
    }
    html += "</div>";
  });

  if (findings.length === 0) {
    html = '<div style="padding:16px;color:var(--text-secondary);font-size:13px">No findings.</div>';
  }

  document.getElementById("pc-detail-content").innerHTML = html;
};

APP._pcFindAndHighlight = function(funcName, idx) {
  if (!APP.pcDiagram || !funcName) return;
  // Try to find the node by key in the diagram
  var node = APP.pcDiagram.findNodeForKey(funcName);
  if (!node) {
    // Try with Functions/ prefix
    node = APP.pcDiagram.findNodeForKey("Functions::" + funcName);
  }
  if (!node) {
    // Search all nodes by name
    APP.pcDiagram.nodes.each(function(n) {
      var key = n.data.key || "";
      if (key.endsWith("::" + funcName) || key === funcName) {
        node = n;
        return false;
      }
    });
  }
  if (node) {
    APP.pcDiagram.clearSelection();
    APP.pcDiagram.select(node);
    APP.pcDiagram.centerRect(node.actualBounds);
  }
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