/**
 * 核心配置和初始化模块
 */

const AppConfig = {
    API_BASE: '/api/v1',
    currentRenderEngine: 'gojs',
    currentTopologyCategory: 'soc'
};

const AppData = {
    socData: null,
    riskAnalysis: null,
    gojsDataCache: null
};

async function fetchAPI(endpoint) {
    try {
        const response = await fetch(`${AppConfig.API_BASE}${endpoint}`);
        if (!response.ok) throw new Error(`HTTP error: ${response.status}`);
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        return null;
    }
}

async function loadData() {
    const model = window.ModelManager ? ModelManager.currentModel : 'ARM_AGI_CPU';
    
    try {
        AppData.gojsDataCache = await fetchAPI(`/sys_topo/graph/gojs?model=${encodeURIComponent(model)}`);
        
        if (AppData.gojsDataCache) {
            console.log('GoJS Data loaded:', AppData.gojsDataCache);
            renderStats(AppData.gojsDataCache);
            if (typeof renderTopology === 'function') {
                renderTopology();
            }
        }
    } catch (e) {
        console.error('loadData/gojs error:', e);
    }
    
    try {
        AppData.riskAnalysis = await fetchAPI(`/risks/analysis?model=${encodeURIComponent(model)}`);
        
        if (AppData.riskAnalysis) {
            renderRiskStats();
            renderRiskList();
        }
    } catch (e) {
        console.error('loadData/risks error:', e);
    }
    
    try {
        if (typeof renderInfoFlow === 'function') {
            renderInfoFlow();
        }
    } catch (e) {
        console.error('loadData/infoFlow error:', e);
    }
}

function setupRenderEngineSelector() {
    const selector = document.getElementById('renderEngine');
    if (selector) {
        selector.addEventListener('change', (e) => {
            AppConfig.currentRenderEngine = e.target.value;
            console.log('Render engine changed to:', AppConfig.currentRenderEngine);
            if (typeof renderTopology === 'function') {
                renderTopology();
            }
        });
        console.log('Render engine selector initialized');
    } else {
        console.error('Render engine selector not found');
    }
}

function renderStats(gojsData) {
    const stats = gojsData.stats;
    const html = `
        <div class="stat-card">
            <h3>${stats.total_nodes}</h3>
            <p>节点总数</p>
        </div>
        <div class="stat-card">
            <h3>${stats.total_links}</h3>
            <p>连接数量</p>
        </div>
        <div class="stat-card">
            <h3>${stats.group_nodes}</h3>
            <p>分组节点</p>
        </div>
        <div class="stat-card">
            <h3>${stats.leaf_nodes}</h3>
            <p>叶子节点</p>
        </div>
        <div class="stat-card" style="background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);">
            <h3>0</h3>
            <p>测试用例</p>
        </div>
        <div class="stat-card" style="background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);">
            <h3>0</h3>
            <p>问题单</p>
        </div>
    `;
    document.getElementById('statsGrid').innerHTML = html;
}

function showComponentDetails(componentId) {
    const component = AppData.socData.nodes.find(n => n.id === componentId);
    if (!component) return;
    
    const modal = document.createElement('div');
    modal.className = 'modal';
    modal.innerHTML = `
        <div class="modal-content">
            <h3>${component.name}</h3>
            <p><strong>类型:</strong> ${component.type}</p>
            <p><strong>供应商:</strong> ${component.vendor}</p>
            <p><strong>描述:</strong> ${component.description || '无'}</p>
            <h4>技术规格</h4>
            <pre>${JSON.stringify(component.specs, null, 2)}</pre>
            <h4>风险 (${component.risks.length})</h4>
            ${component.risks.map(r => `
                <div class="risk-item risk-${r.level}">
                    <span class="badge badge-${r.level}">${r.level.toUpperCase()}</span>
                    <span class="badge">${r.category}</span>
                    <p>${r.description}</p>
                    ${r.mitigation ? `<p><em>建议: ${r.mitigation}</em></p>` : ''}
                </div>
            `).join('')}
            <button onclick="this.parentElement.parentElement.remove()">关闭</button>
        </div>
    `;
    
    modal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 1000;
    `;
    
    modal.querySelector('.modal-content').style.cssText = `
        background: white;
        padding: 30px;
        border-radius: 10px;
        max-width: 600px;
        max-height: 80vh;
        overflow-y: auto;
    `;
    
    document.body.appendChild(modal);
    modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.remove();
    });
}

function renderComponentsList() {
    const html = `
        <table style="width:100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8f9fa;">
                    <th style="padding: 10px; text-align: left;">名称</th>
                    <th style="padding: 10px; text-align: left;">类型</th>
                    <th style="padding: 10px; text-align: left;">供应商</th>
                    <th style="padding: 10px; text-align: left;">风险数</th>
                </tr>
            </thead>
            <tbody>
                ${AppData.socData.nodes.map((n, i) => `
                    <tr style="background: ${i % 2 === 0 ? 'white' : '#f8f9fa'};">
                        <td style="padding: 10px;">${n.name}</td>
                        <td style="padding: 10px;">${n.type}</td>
                        <td style="padding: 10px;">${n.vendor}</td>
                        <td style="padding: 10px;">${n.risks.length}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('componentsList').innerHTML = html;
}

function renderConnectionsList() {
    const html = `
        <table style="width:100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8f9fa;">
                    <th style="padding: 10px; text-align: left;">源组件</th>
                    <th style="padding: 10px; text-align: left;">目标组件</th>
                    <th style="padding: 10px; text-align: left;">类型</th>
                    <th style="padding: 10px; text-align: left;">带宽(Gbps)</th>
                    <th style="padding: 10px; text-align: left;">延迟(ns)</th>
                </tr>
            </thead>
            <tbody>
                ${AppData.socData.edges.map((e, i) => {
                    const source = AppData.socData.nodes.find(n => n.id === e.from);
                    const target = AppData.socData.nodes.find(n => n.id === e.to);
                    return `
                        <tr style="background: ${i % 2 === 0 ? 'white' : '#f8f9fa'};">
                            <td style="padding: 10px;">${source ? source.name : e.from}</td>
                            <td style="padding: 10px;">${target ? target.name : e.to}</td>
                            <td style="padding: 10px;">${e.type || '-'}</td>
                            <td style="padding: 10px;">${e.bandwidth_gbps || '-'}</td>
                            <td style="padding: 10px;">${e.latency_ns || '-'}</td>
                        </tr>
                    `;
                }).join('')}
            </tbody>
        </table>
    `;
    document.getElementById('connectionsList').innerHTML = html;
}

window.AppConfig = AppConfig;
window.AppData = AppData;
window.fetchAPI = fetchAPI;
window.loadData = loadData;
window.setupRenderEngineSelector = setupRenderEngineSelector;
window.renderStats = renderStats;
window.showComponentDetails = showComponentDetails;
window.renderComponentsList = renderComponentsList;
window.renderConnectionsList = renderConnectionsList;
