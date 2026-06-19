/**
 * zTree 通用组件 —— 统一所有 zTree 的创建、数据加载
 *
 * 数据驱动：所有 zTree 数据通过统一接口获取，直接渲染，无需自定义转换。
 */

const ZTreeManager = {

    /** 从 API 获取 zTree simpleData */
    async fetchZTreeData() {
        try {
            const resp = await fetch("/api/v1/sw_model/ztree");
            if (!resp.ok) throw new Error("HTTP " + resp.status);
            return await resp.json();
        } catch (e) {
            console.error("Failed to load ztree data:", e);
            return [];
        }
    },

    /**
     * 创建 zTree
     * @param {string} containerId - DOM 元素 ID
     * @param {Array} nodes - simpleData 格式的节点数组 (id, pId, name, isParent)
     * @param {Object} [options]
     * @param {Function} [options.onClick] - 节点点击回调
     * @returns {Object|null} zTree 对象
     */
    createTree(containerId, nodes, options = {}) {
        if (!nodes || nodes.length === 0) {
            $("#" + containerId).html(
                '<div style="text-align:center;padding:20px;color:#64748b;">暂无数据</div>'
            );
            return null;
        }

        const setting = {
            view: {
                showLine: true,
                showIcon: true,
                selectedMulti: false,
            },
            data: {
                simpleData: {
                    enable: true,
                    idKey: "id",
                    pIdKey: "pId",
                    rootPId: "0",
                },
            },
            callback: {},
        };

        if (options.onClick) {
            setting.callback.onClick = options.onClick;
        }

        return $.fn.zTree.init($("#" + containerId), setting, nodes);
    },
};

window.ZTreeManager = ZTreeManager;