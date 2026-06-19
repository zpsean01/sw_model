/**
 * UI Components for the firmware analysis dashboard.
 */

const COMP = {};

/**
 * Render a grid of dashboard cards.
 * @param {Array<{id:string, label:string, count:number, icon:string, badge?:string}>} items
 * @returns {string} HTML string
 */
COMP.renderCards = function(items) {
  if (!items || items.length === 0) return '<p>No data available.</p>';
  const cards = items.map(item => `
    <div class="card" onclick="window.location.hash='${item.id}'" title="查看详情">
      ${item.badge ? `<span class="card-badge">${item.badge}</span>` : ''}
      <div class="card-icon">${item.icon}</div>
      <div class="card-label">${item.label}</div>
      <div class="card-count">${item.count ?? '?'}</div>
    </div>
  `).join('');
  return `<div class="cards-grid">${cards}</div>`;
};

/**
 * Render a data table.
 * @param {Array<Object>} data - Array of row objects
 * @param {Array<{key:string, label:string, format?:function}>} columns
 * @param {Object} [options]
 * @param {string} [options.emptyMsg]
 * @returns {string} HTML string
 */
COMP.renderTable = function(data, columns, options = {}) {
  if (!data || data.length === 0) {
    return `<p>${options.emptyMsg || 'No data.'}</p>`;
  }
  const thead = columns.map(c => `<th>${c.label}</th>`).join('');
  const tbody = data.map(row => {
    const cells = columns.map(c => {
      let val = row[c.key];
      if (c.format) val = c.format(val);
      if (val === null || val === undefined) val = '';
      if (typeof val === 'object') val = JSON.stringify(val);
      return `<td title="${String(val).replace(/"/g, '&quot;')}">${val}</td>`;
    }).join('');
    return `<tr>${cells}</tr>`;
  }).join('');
  return `
    <div class="table-count">共 ${data.length} 条记录</div>
    <div class="table-container"><table>
      <thead><tr>${thead}</tr></thead>
      <tbody>${tbody}</tbody>
    </table></div>
  `;
};

/**
 * Render a call graph (MultiDiGraph format with nodes/edges).
 * @param {Object} data - { nodes: [{id, attributes}], edges: [{source, target, key, attributes}] }
 * @returns {string} HTML string
 */
COMP.renderCallGraph = function(data) {
  if (!data || !data.nodes || !data.edges) {
    return '<p>No call graph data.</p>';
  }
  const nodes = data.nodes.map(n => {
    const attrs = n.attributes || {};
    const addr = attrs.address ? `0x${Number(attrs.address).toString(16)}` : '';
    return `<span class="cg-node" title="${addr}">${n.id}</span>`;
  }).join('');

  const edges = data.edges.map(e => {
    const attrs = e.attributes || {};
    const addr = attrs.at || e.key || '';
    return `<div class="cg-edge-item">
      <span class="cg-edge-caller">${e.source}</span>
      <span class="cg-edge-arrow">→</span>
      <span class="cg-edge-callee">${e.target}</span>
      <span class="cg-edge-addr">${addr}</span>
    </div>`;
  }).join('');

  return `
    <div class="call-graph-section">
      <h3>节点 (${data.nodes.length})</h3>
      <div class="cg-node-list">${nodes}</div>
    </div>
    <div class="call-graph-section">
      <h3>边 (${data.edges.length})</h3>
      <div class="cg-edge-list">${edges}</div>
    </div>
  `;
};

/**
 * Render a JSON view with syntax-like styling.
 * @param {Object} data
 * @returns {string} HTML string
 */
COMP.renderJSON = function(data) {
  const html = JSON.stringify(data, null, 2);
  return `<pre class="json-view">${html}</pre>`;
};

/**
 * Render an error message.
 * @param {string} msg
 * @returns {string}
 */
COMP.renderError = function(msg) {
  return `<div class="error-box">❌ ${msg}</div>`;
};

/**
 * Render a page header with breadcrumb.
 * @param {Array<{label:string, href?:string}>} crumbs - Breadcrumb trail
 * @returns {string} HTML
 */
COMP.renderHeader = function(title, subtitle, crumbs) {
  const bread = crumbs.map((c, i) => {
    if (c.href) return `<a href="${c.href}">${c.label}</a>`;
    return `<span class="current">${c.label}</span>`;
  }).join(' / ');
  return `
    <div class="breadcrumb">${bread}</div>
    <h2 class="page-title">${title}</h2>
    ${subtitle ? `<p class="page-subtitle">${subtitle}</p>` : ''}
  `;
};