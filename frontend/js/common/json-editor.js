/**
 * JsonEditor — Ace 编辑器封装的 JSON 查看器
 *
 * API 与 jsoneditor 库兼容，方便替换：
 *   new JsonEditor(container, options)
 *   .set(data)       — 设置并格式化 JSON 数据
 *   .expandAll()     — 展开所有折叠
 *   .get()           — 获取当前文本
 *   .destroy()       — 销毁编辑器
 *
 * 数据驱动：直接传入 JS 对象，自动格式化为带缩进的 JSON。
 */

class JsonEditor {
  /**
   * @param {HTMLElement} container - 挂载 DOM 元素
   * @param {Object} [options]
   * @param {boolean} [options.readOnly=true]
   */
  constructor(container, options) {
    this._container = container;
    this._options = Object.assign({ readOnly: true }, options);
    this._init();
  }

  _init() {
    // Create Ace editor
    this._editor = ace.edit(this._container);
    this._editor.setTheme("ace/theme/chrome");

    // JSON syntax mode
    this._editor.session.setMode("ace/mode/json");

    // Read-only
    this._editor.setReadOnly(this._options.readOnly);

    // Editor options
    this._editor.setOptions({
      tabSize: 2,
      useSoftTabs: true,
      showPrintMargin: false,
      highlightActiveLine: false,
      highlightGutterLine: false,
      showLineNumbers: true,
      displayIndentGuides: true,
      animatedScroll: false,
      fontSize: 13,
      fontFamily: "'SF Mono', 'Consolas', 'Liberation Mono', monospace",
    });

    // Remove cursor blink in read-only mode
    if (this._options.readOnly) {
      this._editor.renderer.$cursorLayer.element.style.display = "none";
    }

    // Fit container height
    this._editor.setAutoScrollEditorIntoView(true);

    // Handle resize
    this._resize();
    this._observer = new ResizeObserver(() => this._resize());
    this._observer.observe(this._container);
  }

  /**
   * Set JSON data into the editor.
   * @param {*} data - Will be JSON.stringify'd with 2-space indent.
   */
  set(data) {
    const json = JSON.stringify(data, null, 2);
    this._editor.session.setValue(json);
    this._editor.gotoLine(0, 0);
    this._editor.clearSelection();
  }

  /** Expand all folds (scroll to top as Ace default). */
  expandAll() {
    this._editor.gotoLine(0, 0);
    this._editor.clearSelection();
  }

  /** Get the raw JSON text. */
  get() {
    return this._editor.session.getValue();
  }

  /** Resize editor to fill container. */
  _resize() {
    this._editor.resize();
  }

  /** Destroy the editor and clean up. */
  destroy() {
    if (this._observer) this._observer.disconnect();
    if (this._editor) this._editor.destroy();
    this._editor = null;
  }
}

window.JsonEditor = JsonEditor;