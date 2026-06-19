/**
 * API client for the ARM Firmware Analysis backend.
 * All requests are proxied via run_server.py, so paths are relative.
 */

const API = {
  PREFIX: "/api/v1/sw_model",
};

/**
 * Fetch JSON from a relative API path.
 * @param {string} path - relative URL
 * @returns {Promise<any>}
 */
API.fetchJSON = async function(path) {
  const resp = await fetch(path);
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error("HTTP " + resp.status + ": " + err.slice(0, 200));
  }
  return resp.json();
};

/** Fetch a static analysis resource. */
API.getStatic = function(name) {
  return API.fetchJSON(API.PREFIX + "/static/" + name);
};

/** Fetch a binary analysis resource. */
API.getBinary = function(name) {
  return API.fetchJSON(API.PREFIX + "/binary/" + name);
};

/** Fetch a modeling resource. */
API.getModeling = function(name) {
  return API.fetchJSON(API.PREFIX + "/modeling/" + name);
};

/** Fetch symbolic execution report. */
API.getSymReport = function() {
  return API.fetchJSON(API.PREFIX + "/sym_execution/report");
};

/** Fetch symbolic execution paths list. */
API.getSymPaths = function() {
  return API.fetchJSON(API.PREFIX + "/sym_execution/paths");
};

/** Fetch ztree navigation data. */
API.getZtree = function() {
  return API.fetchJSON(API.PREFIX + "/ztree");
};