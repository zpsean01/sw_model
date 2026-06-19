/**
 * GoJS公共模块 - 统一Group模型
 *
 * 核心规则：所有组件在GoJS中都是Group
 * - 后端转换器统一输出 isGroup: true
 * - 前端统一使用Group模板渲染
 * - 拖拽时无需Node→Group提升，直接设置group属性即可嵌套
 */

const GoJSCommon = {
    NODE_FILL: '#ffffff',
    NODE_STROKE: '#333333',
    NODE_STROKE_WIDTH: 2,
    GROUP_FILL: '#ffffff',
    GROUP_STROKE: '#333333',
    GROUP_STROKE_WIDTH: 2,
    GROUP_STROKE_DASH: [5, 5],
    GROUP_BASE_STROKE_WIDTH: 3,
    LINK_STROKE: '#333333',
    LINK_STROKE_WIDTH: 1.5,
    ARROW_FILL: '#333333',
    TEXT_FONT: 'bold 12px sans-serif',
    TEXT_STROKE: '#333333',
    SUBTEXT_FONT: '9px sans-serif',
    SUBTEXT_STROKE: '#7f8c8d',
    HIGHLIGHT_STROKE: '#27ae60',
    HIGHLIGHT_STROKE_WIDTH: 4,
    SELECTED_STROKE: '#e74c3c',

    createDiagram(containerId, options = {}) {
        if (typeof go === 'undefined') {
            console.error('GoJS not loaded');
            return null;
        }

        const $ = go.GraphObject.make;
        const container = document.getElementById(containerId);
        if (!container) {
            console.error('Container not found:', containerId);
            return null;
        }

        var existingDiagram = go.Diagram.fromDiv(containerId);
        if (existingDiagram) {
            existingDiagram.div = null;
        }

        container.innerHTML = '';

        const defaults = {
            undoManager: true,
            allowDrop: true,
            allowDrag: true,
            allowGroup: true,
            allowUngroup: true,
            allowDelete: true,
            allowCopy: false,
            allowMove: true,
            layout: 'ForceDirected',
            initialAutoScale: go.Diagram.Uniform,
            contentAlignment: go.Spot.Center,
            onChanged: null,
            onNodeClick: null,
            onNodeDoubleClick: null,
            onGroupClick: null,
            onGroupDoubleClick: null,
            onSelectionMoved: null,
            contextMenuHandler: null
        };

        const opts = { ...defaults, ...options };

        const diagram = $(go.Diagram, containerId, {
            'undoManager.isEnabled': opts.undoManager,
            allowDrop: opts.allowDrop,
            'draggingTool.isEnabled': opts.allowDrag,
            'draggingTool.dragsLink': false,
            allowGroup: opts.allowGroup,
            allowUngroup: opts.allowUngroup,
            'commandHandler.deletesTree': true,
            allowDelete: opts.allowDelete,
            allowCopy: opts.allowCopy,
            initialAutoScale: opts.initialAutoScale,
            contentAlignment: opts.contentAlignment,
            Changed: function(e) {
                if (e.isTransactionFinished && opts.onChanged) {
                    opts.onChanged(e);
                }
            }
        });

        this._applyLayout(diagram, opts.layout);
        this._setupGroupTemplate($, diagram, opts);
        if (opts.linkable !== false) {
            this._setupLinkTemplate($, diagram, opts);
        }

        if (opts.onSelectionMoved) {
            diagram.addDiagramListener('SelectionMoved', opts.onSelectionMoved);
        }

        return diagram;
    },

    _applyLayout(diagram, layoutType) {
        const $ = go.GraphObject.make;
        if (layoutType === 'ForceDirected') {
            diagram.layout = $(go.ForceDirectedLayout, {
                maxIterations: 150,
                defaultSpringLength: 30,
                defaultElectricalCharge: 80,
                isInitial: true,
                isOngoing: false
            });
        } else if (layoutType === 'LayeredDigraph') {
            diagram.layout = $(go.LayeredDigraphLayout, {
                direction: 90,
                layerSpacing: 40,
                columnSpacing: 30
            });
        } else if (layoutType === 'Tree') {
            diagram.layout = $(go.TreeLayout, {
                angle: 90,
                layerSpacing: 50
            });
        } else if (layoutType === 'Grid') {
            diagram.layout = $(go.GridLayout, {
                wrappingColumn: 4,
                spacing: new go.Size(10, 10)
            });
        }
    },

    _setupGroupTemplate($, diagram, opts) {
        const self = this;

        diagram.groupTemplate = $(go.Group, 'Vertical', {
            ungroupable: true,
            isSubGraphExpanded: true,
            locationObjectName: 'SHAPE',
            doubleClick: (e, group) => {
                if (opts.onGroupDoubleClick) opts.onGroupDoubleClick(group.data);
            },
            click: (e, group) => {
                if (opts.onGroupClick) opts.onGroupClick(group.data);
            },
            mouseDragEnter: function(e, group) {
                if (group) group.isHighlighted = true;
            },
            mouseDragLeave: function(e, group) {
                if (group) group.isHighlighted = false;
            },
            computesBoundsAfterDrag: true,
            handlesDragDropForMembers: true,
            mouseDrop: function(e, group) {
                var ok = group.addMembers(group.diagram.selection, true);
                if (!ok) group.diagram.currentTool.doCancel();
            },
            subGraphExpandedChanged: function(e) {
                e.subject.diagram.requestUpdate();
            },
            contextMenu: opts.contextMenuHandler ? $(go.HTMLInfo, { show: opts.contextMenuHandler }) : undefined
        },
            new go.Binding('location', 'loc', go.Point.parse).makeTwoWay(go.Point.stringify),
            $(go.Panel, 'Auto',
                $(go.Shape, 'RoundedRectangle', {
                    name: 'SHAPE',
                    fill: self.GROUP_FILL,
                    stroke: self.GROUP_STROKE,
                    strokeWidth: self.GROUP_STROKE_WIDTH,
                    portId: '',
                    fromLinkable: true,
                    toLinkable: true,
                    fromLinkableDuplicates: true,
                    toLinkableDuplicates: true,
                    cursor: 'pointer'
                },
                    new go.Binding('stroke', 'isBase', b => b ? self.GROUP_STROKE : '#95a5a6'),
                    new go.Binding('strokeWidth', 'isBase', b => b ? self.GROUP_BASE_STROKE_WIDTH : self.GROUP_STROKE_WIDTH),
                    new go.Binding('stroke', 'isHighlighted', (h, sh) => h ? self.HIGHLIGHT_STROKE : (sh.part.data.isBase ? self.GROUP_STROKE : '#95a5a6')),
                    new go.Binding('strokeWidth', 'isHighlighted', h => h ? self.HIGHLIGHT_STROKE_WIDTH : self.GROUP_STROKE_WIDTH)
                ),
                $(go.Panel, 'Vertical', { margin: 6 },
                    $(go.Panel, 'Horizontal', { margin: new go.Margin(0, 0, 3, 0) },
                        $(go.Panel, 'Auto', {
                            margin: new go.Margin(0, 4, 0, 0),
                            cursor: 'pointer',
                            click: function(e, obj) {
                                var group = obj.part;
                                if (group) {
                                    e.handled = true;
                                    group.isSubGraphExpanded = !group.isSubGraphExpanded;
                                }
                            }
                        },
                            $(go.Shape, 'Rectangle', {
                                width: 14,
                                height: 14,
                                fill: '#f5f5f5',
                                stroke: self.NODE_STROKE,
                                strokeWidth: 1
                            }),
                            $(go.TextBlock, {
                                font: 'bold 11px sans-serif',
                                stroke: self.NODE_STROKE,
                                text: '-'
                            }, new go.Binding('text', 'isSubGraphExpanded', exp => exp ? '-' : '+').ofObject())
                        ),
                        $(go.TextBlock, {
                            font: self.TEXT_FONT,
                            stroke: self.TEXT_STROKE
                        }, new go.Binding('text', 'text')),
                        $(go.TextBlock, {
                            font: self.SUBTEXT_FONT,
                            stroke: self.SUBTEXT_STROKE,
                            margin: new go.Margin(0, 0, 0, 4)
                        }, new go.Binding('text', 'groupType', c => c ? `(${c})` : '')),
                        // 测试用例数量徽标
                        $(go.Panel, 'Auto', {
                            margin: new go.Margin(0, 0, 0, 4),
                            visible: false
                        },
                            new go.Binding('visible', 'coloringCount', c => c > 0),
                            $(go.Shape, 'Circle', {
                                width: 18,
                                height: 18,
                                fill: '#e74c3c',
                                stroke: null
                            }, new go.Binding('fill', 'coloringBadgeColor', c => c || '#e74c3c')),
                            $(go.TextBlock, {
                                font: 'bold 9px sans-serif',
                                stroke: 'white',
                                margin: 1
                            }, new go.Binding('text', 'coloringCount', c => c > 99 ? '99+' : String(c)))
                        )
                    ),
                    $(go.Placeholder, { padding: 6, alignment: go.Spot.TopLeft }, new go.Binding('visible', 'isSubGraphExpanded').ofObject())
                )
            )
        );
    },

    _setupLinkTemplate($, diagram, opts) {
        const self = this;

        diagram.linkTemplate = $(go.Link, {
            routing: go.Link.Normal,
            curve: go.Link.Bezier,
            relinkableFrom: opts.undoManager,
            relinkableTo: opts.undoManager
        },
            $(go.Shape, { strokeWidth: self.LINK_STROKE_WIDTH, stroke: self.LINK_STROKE }),
            $(go.Shape, { toArrow: 'Standard', fill: self.ARROW_FILL, stroke: self.ARROW_FILL }),
            $(go.TextBlock, {
                font: self.SUBTEXT_FONT,
                stroke: self.SUBTEXT_STROKE,
                segmentOffset: new go.Point(0, -8)
            }, new go.Binding('text', 'text'))
        );
    },

    /**
     * NetworkX Graph → GoJS 格式
     * 所有节点统一为 Group
     */
    networkxToGoJS(data) {
        const nodes = data.nodes || [];
        const links = data.links || [];

        const containsMap = {};
        const childOfGroup = new Set();

        links.forEach(l => {
            const edgeType = l.attributes?.edge_type || l.attributes?.type || l.type || '';
            if (edgeType === 'contains') {
                containsMap[l.target] = l.source;
                childOfGroup.add(l.target);
            }
        });

        nodes.forEach(n => {
            const attrs = n.attributes || {};
            if (attrs.parent) {
                if (!containsMap[n.id]) {
                    containsMap[n.id] = attrs.parent;
                }
                childOfGroup.add(n.id);
            }
        });

        const safeContainsMap = {};
        Object.keys(containsMap).forEach(childId => {
            const parentId = containsMap[childId];
            safeContainsMap[childId] = parentId;

            const visited = new Set();
            let current = parentId;
            while (current) {
                if (visited.has(current)) {
                    delete safeContainsMap[childId];
                    break;
                }
                visited.add(current);
                current = safeContainsMap[current];
            }
        });

        const nodeDataArray = nodes.map(n => {
            const attrs = n.attributes || {};
            const nodeData = {
                key: n.id,
                text: attrs.label || attrs.name || n.id,
                groupType: attrs.type || attrs.category || '',
                defId: n.id,
                isGroup: true,
                isBase: attrs.is_root || false
            };

            if (safeContainsMap[n.id]) {
                nodeData.group = safeContainsMap[n.id];
            } else if (attrs.parent) {
                nodeData.group = attrs.parent;
            }

            return nodeData;
        });

        const linkDataArray = links
            .filter(l => {
                const edgeType = l.attributes?.edge_type || l.attributes?.type || l.type || '';
                return edgeType !== 'contains';
            })
            .map(l => ({
                from: l.source,
                to: l.target,
                key: l.key,
                text: l.attributes?.label || '',
                category: l.attributes?.edge_type || l.attributes?.type || 'flow'
            }));

        return { nodeDataArray, linkDataArray };
    },

    /**
     * GoJS → NetworkX Graph 格式
     */
    gojsToNetworkx(diagram) {
        if (!diagram) return null;

        const nodeDataArray = diagram.model.nodeDataArray;
        const linkDataArray = diagram.model.linkDataArray;

        const groupMap = {};
        nodeDataArray.forEach(n => {
            const nodeObj = diagram.findNodeForKey(n.key);
            if (nodeObj && nodeObj.containingGroup) {
                groupMap[n.key] = nodeObj.containingGroup.data.key;
            } else if (n.group) {
                groupMap[n.key] = n.group;
            }
        });

        const nodes = nodeDataArray.map(n => ({
            id: n.key,
            attributes: {
                is_root: n.isBase || false,
                name: n.text,
                label: n.text,
                type: n.groupType || n.category || '',
                category: n.groupType || n.category || ''
            }
        }));

        const links = [];
        let linkKey = 0;

        for (const [nodeId, parentId] of Object.entries(groupMap)) {
            links.push({
                source: parentId,
                target: nodeId,
                key: linkKey++,
                attributes: { edge_type: 'contains', label: '包含' }
            });
        }

        linkDataArray.forEach(l => {
            links.push({
                source: l.from,
                target: l.to,
                key: l.key !== undefined && l.key !== null ? l.key : linkKey++,
                attributes: {
                    edge_type: l.category || 'flow',
                    label: l.text || ''
                }
            });
        });

        return {
            directed: true,
            multigraph: true,
            graph: {},
            nodes,
            links
        };
    },

    _normalizeGroupStructure(nodeDataArray, linkDataArray) {
        if (!nodeDataArray || nodeDataArray.length === 0) {
            return { nodeDataArray: nodeDataArray || [], linkDataArray: linkDataArray || [] };
        }

        const containsEdges = [];
        const otherLinks = [];

        (linkDataArray || []).forEach(l => {
            const cat = l.category || '';
            if (cat === 'contains') {
                containsEdges.push(l);
            } else {
                otherLinks.push(l);
            }
        });

        if (containsEdges.length === 0) {
            return {
                nodeDataArray: this._breakGroupCycles(nodeDataArray),
                linkDataArray: linkDataArray || []
            };
        }

        const parentOf = {};
        containsEdges.forEach(l => {
            parentOf[l.to] = l.from;
        });

        nodeDataArray = nodeDataArray.map(n => {
            if (!parentOf[n.key]) return n;
            const node = Object.assign({}, n);
            if (!node.group) {
                node.group = parentOf[n.key];
            }
            return node;
        });

        nodeDataArray = this._breakGroupCycles(nodeDataArray);

        return { nodeDataArray, linkDataArray: otherLinks };
    },

    loadData(diagram, data) {
        if (!diagram || !data) return;

        let nodeDataArray, linkDataArray;

        if (data.nodeDataArray && data.linkDataArray) {
            const normalized = this._normalizeGroupStructure(data.nodeDataArray, data.linkDataArray);
            nodeDataArray = normalized.nodeDataArray;
            linkDataArray = normalized.linkDataArray;
        } else if (data.nodes || data.links) {
            const converted = this.networkxToGoJS(data);
            nodeDataArray = converted.nodeDataArray;
            linkDataArray = converted.linkDataArray;
        } else {
            nodeDataArray = [];
            linkDataArray = [];
        }

        const model = new go.GraphLinksModel(nodeDataArray, linkDataArray);
        model.linkKeyProperty = 'key';
        model.makeUniqueKeyFunction = function(model, data) {
            let key = data.key;
            if (key === undefined || key === null) {
                key = -1;
                while (model.findNodeDataForKey(key) || model.findLinkDataForKey(key)) {
                    key--;
                }
                data.key = key;
            }
            return key;
        };
        diagram.model = model;
        if (diagram.layout) {
            diagram.layout.invalidateLayout();
        }
        diagram.rebuildParts();
        diagram.requestUpdate();

        const nodeCount = nodeDataArray.length;
        if (nodeCount > 0) {
            const delay = nodeCount > 50 ? 800 : (nodeCount > 10 ? 400 : 200);
            setTimeout(() => {
                if (diagram && !diagram.isVirtual) {
                    diagram.zoomToFit();
                }
            }, delay);
        }
    },

    async loadFromAPI(diagram, apiUrl) {
        if (!diagram || !apiUrl) return;

        try {
            const model = window.ModelManager ? ModelManager.currentModel : 'ARM_AGI_CPU';
            const separator = apiUrl.includes('?') ? '&' : '?';
            const url = `${apiUrl}${separator}model=${encodeURIComponent(model)}`;

            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();
            this.loadData(diagram, data);
            return data;
        } catch (e) {
            console.error('Failed to load from API:', e);
            throw e;
        }
    },

    /**
     * 拖拽设置 - 统一Group模型
     * 拖入的组件直接创建为Group，无需Node→Group提升
     */
    setupDrop(diagram, containerId, options = {}) {
        if (!diagram) return;
        const dropDiv = diagram.div;
        if (!dropDiv) return;

        if (dropDiv._dropSetup) return;
        dropDiv._dropSetup = true;

        const defaults = {
            editLockGetter: () => false,
            findComponent: null,
            onDropComplete: null
        };
        const opts = { ...defaults, ...options };

        dropDiv.addEventListener('dragover', function(e) {
            e.preventDefault();
            e.stopPropagation();
            e.dataTransfer.dropEffect = 'copy';
        });

        dropDiv.addEventListener('drop', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const defId = e.dataTransfer.getData('text/plain');
            if (!defId) return;

            if (!opts.findComponent) return;

            const comp = opts.findComponent(defId);
            if (!comp) return;

            const rect = dropDiv.getBoundingClientRect();
            const viewPoint = new go.Point(e.clientX - rect.left, e.clientY - rect.top);
            const docPoint = diagram.transformViewToDoc(viewPoint);

            const existingKeys = diagram.model.nodeDataArray.map(n => n.key);
            let newKey = defId;
            let counter = 1;
            while (existingKeys.includes(newKey)) {
                newKey = `${defId}_${counter}`;
                counter++;
            }

            // 查找拖放目标（哪个Group被命中）
            let targetGroupKey = null;
            diagram.nodes.each(function(node) {
                if (node.actualBounds && node.actualBounds.containsPoint(docPoint)) {
                    if (!targetGroupKey || node.actualBounds.area < diagram.findNodeForKey(targetGroupKey).actualBounds.area) {
                        targetGroupKey = node.data.key;
                    }
                }
            });

            // 所有组件都是Group，直接创建
            const newNodeData = {
                key: newKey,
                text: comp.name || defId,
                groupType: comp.type || '',
                defId: defId,
                isGroup: true,
                isBase: false,
                loc: go.Point.stringify(docPoint)
            };

            if (targetGroupKey && targetGroupKey !== newKey) {
                newNodeData.group = targetGroupKey;
            }

            diagram.startTransaction('add node');
            diagram.model.addNodeData(newNodeData);
            diagram.commitTransaction('add node');
            diagram.requestUpdate();

            // 嵌套时确保目标Group展开显示子成员
            if (targetGroupKey && targetGroupKey !== newKey) {
                const targetNode = diagram.findNodeForKey(targetGroupKey);
                if (targetNode && !targetNode.isSubGraphExpanded) {
                    diagram.startTransaction('expand group');
                    targetNode.isSubGraphExpanded = true;
                    diagram.commitTransaction('expand group');
                }
            }

            if (opts.onDropComplete) {
                opts.onDropComplete(newNodeData, comp);
            }
        });
    },

    syncGroupMembership(diagram) {
        if (!diagram) return;

        const model = diagram.model;
        model.nodeDataArray.forEach(node => {
            const nodeObj = diagram.findNodeForKey(node.key);
            if (nodeObj && nodeObj.containingGroup) {
                const currentGroup = node.group;
                const newGroup = nodeObj.containingGroup.data.key;
                if (currentGroup !== newGroup) {
                    model.setDataProperty(node, 'group', newGroup);
                }
            }
        });
    },

    toggleEditLock(diagram, locked) {
        if (!diagram) return;
        diagram.draggingTool.isEnabled = !locked;
        diagram.allowDelete = !locked;
        diagram.allowCopy = false;
    },

    zoomToFit(diagram) {
        if (diagram) diagram.zoomToFit();
    },

    clear(diagram) {
        if (diagram) {
            diagram.div = null;
        }
    },

    showContextMenu(obj, point, menuItems) {
        const menu = document.createElement('div');
        menu.style.cssText = `position: fixed; left: ${point.x}px; top: ${point.y}px; background: white; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.2); z-index: 1001; min-width: 140px;`;

        let html = '';
        menuItems.forEach(item => {
            const style = item.danger ? 'color: #e74c3c;' : '';
            const border = item.separator ? 'border-bottom: 1px solid #eee;' : '';
            html += `<div style="padding: 8px 12px; cursor: pointer; font-size: 12px; ${border} ${style}" onclick="${item.action}; this.parentElement.remove();">${item.label}</div>`;
        });

        menu.innerHTML = html;
        document.body.appendChild(menu);

        setTimeout(() => {
            document.addEventListener('click', function close() { menu.remove(); document.removeEventListener('click', close); });
        }, 10);
    },

    groupSelected(diagram) {
        if (!diagram) return;

        const selectedParts = diagram.selection.toArray();
        if (selectedParts.length < 2) {
            alert('请选择至少2个节点进行分组');
            return;
        }

        diagram.startTransaction('group');

        const groupKey = 'group_' + Date.now();
        diagram.model.addNodeData({
            key: groupKey,
            text: '新分组',
            groupType: '',
            isGroup: true
        });

        selectedParts.forEach(part => {
            if (part instanceof go.Node) {
                diagram.model.setGroupDataForNodeData(part.data, diagram.model.findNodeDataForKey(groupKey));
            }
        });

        diagram.commitTransaction('group');
    },

    ungroupSelected(diagram) {
        if (!diagram) return;

        const selectedGroups = diagram.selection.filter(p => p instanceof go.Group);
        if (selectedGroups.count === 0) {
            alert('请选择一个分组');
            return;
        }

        diagram.startTransaction('ungroup');
        selectedGroups.each(group => {
            diagram.model.ungroupData(group.data);
        });
        diagram.commitTransaction('ungroup');
    },

    _breakGroupCycles(nodeDataArray) {
        if (!nodeDataArray || !Array.isArray(nodeDataArray)) return nodeDataArray;

        const keyMap = {};
        nodeDataArray.forEach(n => {
            if (n.key !== undefined && n.key !== null) {
                keyMap[n.key] = n;
            }
        });

        const fixed = [];
        nodeDataArray.forEach(n => {
            if (n.group === undefined || n.group === null) return;

            const visited = new Set();
            visited.add(n.key);

            let current = n.group;
            while (current !== undefined && current !== null) {
                if (visited.has(current)) {
                    delete n.group;
                    fixed.push(n.key);
                    break;
                }
                visited.add(current);
                const parent = keyMap[current];
                if (!parent) break;
                current = parent.group;
            }
        });

        if (fixed.length > 0) {
            console.warn('_breakGroupCycles: removed group property from nodes:', fixed);
        }

        return nodeDataArray;
    },

    removeNode(diagram, nodeKey) {
        if (!diagram) return;
        diagram.startTransaction('remove node');
        diagram.model.removeNodeData(diagram.model.findNodeDataForKey(nodeKey));
        diagram.commitTransaction('remove node');
    }
};

window.GoJSCommon = GoJSCommon;
