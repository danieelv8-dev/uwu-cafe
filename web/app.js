const app = document.getElementById('app');
const navigation = document.getElementById('navigation');
const content = document.getElementById('content');
const pageTitle = document.getElementById('pageTitle');
const profileName = document.getElementById('profileName');
const profileRole = document.getElementById('profileRole');
const sidebarModeLabel = document.getElementById('sidebarModeLabel');
const toastElement = document.getElementById('toast');

const state = { mode: 'customer', tab: 'menu', data: {}, cart: {}, scroll: {} };

// Local inline SVG icon set. The NUI does not depend on a CDN or emoji fonts.
const ICONS = {
    cat: '<path d="M5 8.5 3.5 4 8 6.2a8.2 8.2 0 0 1 8 0L20.5 4 19 8.5a8 8 0 1 1-14 0Z"/><path d="M8.5 13h.01M15.5 13h.01"/><path d="M10 16c1.2.8 2.8.8 4 0"/>',
    coffee: '<path d="M4 8h11v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5Z"/><path d="M15 10h2a3 3 0 0 1 0 6h-2"/><path d="M6 2v3M10 2v3M14 2v3"/><path d="M3 22h15"/>',
    receipt: '<path d="M6 2h12v20l-3-2-3 2-3-2-3 2Z"/><path d="M9 7h6M9 11h6M9 15h4"/>',
    chefHat: '<path d="M7 10.5a4 4 0 0 1 .5-7.9A5.5 5.5 0 0 1 18 5a3.5 3.5 0 0 1-.5 7H7Z"/><path d="M7 13v7h10v-7M10 13v4M14 13v4"/>',
    bike: '<circle cx="5.5" cy="17.5" r="3.5"/><circle cx="18.5" cy="17.5" r="3.5"/><path d="m8 17.5 3-7h4l3.5 7M9.5 14h6M8 7h3l1 3.5M15 7h3"/>',
    truck: '<path d="M3 6h11v11H3Z"/><path d="M14 10h4l3 3v4h-7Z"/><circle cx="7" cy="19" r="2"/><circle cx="18" cy="19" r="2"/>',
    package: '<path d="m12 2 9 5-9 5-9-5Z"/><path d="m3 7 9 5 9-5v10l-9 5-9-5Z"/><path d="M12 12v10M7.5 4.5l9 5"/>',
    chartBar: '<path d="M4 20V10h4v10M10 20V4h4v16M16 20v-7h4v7M2 20h20"/>',
    star: '<path d="m12 2.8 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2L3 9.4l6.2-.9Z"/>',
    chartLine: '<path d="M3 3v18h18"/><path d="m6 16 4-5 4 3 5-7"/><path d="M19 7h-4M19 7v4"/>',
    wrench: '<path d="M14.5 6.5a4 4 0 0 0-5-5l2.2 2.2-2.8 2.8-2.2-2.2a4 4 0 0 0 5 5L19 16.6a2.1 2.1 0 1 1-3 3l-7.3-7.3a4 4 0 0 0 5.8-5.8Z"/>',
    tag: '<path d="M20 13 13 20l-9-9V4h7Z"/><circle cx="8.5" cy="8.5" r="1.2"/>',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
    burger: '<path d="M4 11a8 6 0 0 1 16 0Z"/><path d="M3 11h18v3H3Z"/><path d="m4 14 2 2 2-2 2 2 2-2 2 2 2-2 2 2 2-2"/><path d="M4 17h16v1a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3Z"/>',
    cake: '<path d="M4 10h16v10H4Z"/><path d="M4 14c2 2 4-2 6 0s4-2 6 0 4-2 4-2"/><path d="M8 10V7M12 10V6M16 10V7"/><path d="M8 5h.01M12 4h.01M16 5h.01"/>',
    paw: '<circle cx="7" cy="8" r="2"/><circle cx="17" cy="8" r="2"/><circle cx="4.5" cy="13" r="2"/><circle cx="19.5" cy="13" r="2"/><path d="M8 18c0-3 1.8-5 4-5s4 2 4 5c0 2-1.5 3-4 3s-4-1-4-3Z"/>',
    refresh: '<path d="M20 11a8 8 0 1 0 2 5"/><path d="M20 4v7h-7"/>',
    close: '<path d="M18 6 6 18M6 6l12 12"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>'
};
const iconMap = { Food:'burger', Desserts:'cake', Drinks:'coffee' };
const icon = (name, className='ui-icon') => `<svg class="${className}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${ICONS[name] || ICONS.paw}</svg>`;

const nui = async (event, data = {}) => {
    const response = await fetch(`https://${GetParentResourceName()}/${event}`, { method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data) });
    return response.json();
};
const esc = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const money = value => `$${Number(value || 0).toLocaleString()}`;
const titleCase = value => String(value || '').replace(/_/g,' ').replace(/\b\w/g, c => c.toUpperCase());
const dateText = value => value ? String(value).replace('T',' ').slice(0,16) : '—';
function toast(message, type='success'){ toastElement.textContent=message||'Done.'; toastElement.className=`toast show ${type}`; clearTimeout(toast.timer); toast.timer=setTimeout(()=>toastElement.className='toast',2600); }

const customerTabs = [ ['menu','coffee','Menu'], ['myOrders','receipt','My Orders'] ];
const employeeTabDefinitions = [
    ['orders','chefHat','Kitchen Orders'],
    ['deliveries','bike','Deliveries'],
    ['register','receipt','Register'],
    ['catering','truck','Catering'],
    ['supplies','package','Supply Runs'],
    ['stock','chartBar','Stock'],
    ['profile','star','My Progress'],
    ['business','chartLine','Business'],
    ['equipment','wrench','Equipment'],
    ['promotions','tag','Promotions'],
    ['staff','users','Staff']
];
function canPage(page){ return state.mode!=='employee' || state.data.permissions?.pages?.[page]===true; }
function canAction(action){ return state.mode==='employee' && state.data.permissions?.actions?.[action]===true; }
function employeeTabs(){ return employeeTabDefinitions.filter(([id])=>canPage(id)); }
function firstAllowedEmployeeTab(){
    const preferred=state.data.defaultTab;
    if(preferred&&canPage(preferred))return preferred;
    return employeeTabs()[0]?.[0]||null;
}
function ensureAllowedTab(){
    if(state.mode!=='employee')return true;
    if(canPage(state.tab))return true;
    state.tab=firstAllowedEmployeeTab();
    return Boolean(state.tab);
}
function renderNav(){
    const tabs=state.mode==='employee'?employeeTabs():customerTabs;
    navigation.innerHTML=tabs.map(([id,iconName,label])=>`<button class="nav-button ${state.tab===id?'active':''}" data-tab="${id}"><span class="nav-icon">${icon(iconName,'ui-icon nav-svg')}</span><span>${label}</span></button>`).join('');
    navigation.querySelectorAll('[data-tab]').forEach(btn=>btn.onclick=()=>{state.scroll[state.tab]=content.scrollTop;state.tab=btn.dataset.tab;render();});
}

function productCard(product){
    const qty=state.cart[product.item]||0;
    const price=product.discount>0?`<span class="old-price">${money(product.originalPrice)}</span><span class="price">${money(product.price)}</span>`:`<span class="price">${money(product.price)}</span>`;
    return `<article class="card product-card ${product.locked?'locked':''}"><div class="product-image">${icon(iconMap[product.category]||'paw','ui-icon product-svg')}</div><h4>${esc(product.label)}</h4><p>${esc(product.description)}</p>${product.locked?`<div class="badge cancelled">Requires ${product.minimumReputation} reputation</div>`:''}<div class="product-footer"><div>${price}${product.discount>0?`<div class="discount">-${product.discount}% ${esc(product.promotionName||'')}</div>`:''}</div><div class="qty"><button data-dec="${esc(product.item)}" aria-label="Decrease ${esc(product.label)} quantity" title="Decrease quantity" ${product.locked?'disabled':''}>${icon('minus','ui-icon qty-icon')}</button><span>${qty}</span><button data-inc="${esc(product.item)}" aria-label="Increase ${esc(product.label)} quantity" title="Increase quantity" ${product.locked?'disabled':''}>${icon('plus','ui-icon qty-icon')}</button></div></div></article>`;
}
function cartTotals(){
    const products=state.data.products||[];let subtotal=0;
    products.forEach(p=>subtotal+=(state.cart[p.item]||0)*Number(p.price||0));
    const type=state.data.context?.orderType||'terminal';const fee=Number(state.data.context?.fees?.[type]||0);return{subtotal,fee,total:subtotal+fee};
}
function renderProducts(register=false){
    const previousScroll=content.scrollTop;
    const products=state.data.products||[];const totals=cartTotals();const type=state.data.context?.orderType||'terminal';
    const registerAllowed=!register||canAction('createRegisterOrder');
    content.innerHTML=`<div class="hero"><div><h3>${register?'Create customer bill':'Freshly prepared menu'}</h3><p>${register?(registerAllowed?'The customer must approve the bill before payment.':'Your grade can view the register but cannot create bills.'):type==='delivery'?'Delivery order — your current position becomes the destination.':type==='table'?`Table ${state.data.context?.tableNumber} service order.`:'Order at the cafe terminal.'}</p></div></div><div class="menu-layout"><div class="grid">${products.map(productCard).join('')}</div><aside class="card cart"><h3>${register?'Register bill':'Your order'}</h3><div id="cartRows">${products.filter(p=>state.cart[p.item]).map(p=>`<div class="cart-row"><div><strong>${state.cart[p.item]}x ${esc(p.label)}</strong><small>${money(p.price)} each</small></div><strong>${money(state.cart[p.item]*p.price)}</strong></div>`).join('')||'<p class="muted small">Your cart is empty.</p>'}</div><div class="summary-line"><span>Subtotal</span><span>${money(totals.subtotal)}</span></div>${totals.fee?`<div class="summary-line"><span>Service fee</span><span>${money(totals.fee)}</span></div>`:''}<div class="cart-total"><span>Total</span><span>${money(totals.total)}</span></div><div class="form-stack">${register?'<input id="targetId" class="form-control" type="number" placeholder="Customer server ID">':''}<input id="tip" class="form-control" type="number" min="0" placeholder="Optional tip amount"><select id="paymentMethod" class="form-control"><option value="bank">Bank</option><option value="cash">Cash</option></select><textarea id="orderNotes" class="form-control" maxlength="250" placeholder="Order notes"></textarea><button id="submitOrder" class="primary" ${totals.subtotal<=0||!registerAllowed?'disabled':''}>${register?'Request Payment':'Place Order'}</button></div></aside></div>`;
    content.querySelectorAll('[data-inc]').forEach(b=>b.onclick=()=>{state.cart[b.dataset.inc]=Math.min(10,(state.cart[b.dataset.inc]||0)+1);renderProducts(register);});
    content.querySelectorAll('[data-dec]').forEach(b=>b.onclick=()=>{state.cart[b.dataset.dec]=Math.max(0,(state.cart[b.dataset.dec]||0)-1);if(!state.cart[b.dataset.dec])delete state.cart[b.dataset.dec];renderProducts(register);});
    requestAnimationFrame(()=>{content.scrollTop=previousScroll;});
    document.getElementById('submitOrder').onclick=async()=>{
        if(register&&!canAction('createRegisterOrder'))return toast('Your grade cannot create register bills.','error');
        const payload={cart:state.cart,paymentMethod:document.getElementById('paymentMethod').value,notes:document.getElementById('orderNotes').value,tip:Number(document.getElementById('tip').value||0)};
        if(register)payload.targetId=Number(document.getElementById('targetId').value);
        const response=await nui(register?'createRegisterOrder':'placeOrder',payload);toast(response.message,response.success?'success':'error');
        if(response.success){state.cart={};await refresh();render();}
    };
}
function orderItems(order){return (order.items||[]).map(i=>`<span>${i.quantity}x ${esc(i.label)}</span>`).join('');}
function orderActions(order,myOrders=false){
    if(myOrders)return order.status==='pending'?`<button class="danger small-btn" data-cancel-order="${order.id}">Cancel & Refund</button>`:'';
    let actions='';
    if(canAction('updateOrder')){
        if(order.status==='pending')actions+=`<button class="status-btn" data-order="${order.id}" data-status="accepted">Accept</button>`;
        if(order.status==='accepted')actions+=`<button class="status-btn" data-order="${order.id}" data-status="preparing">Start Preparing</button>`;
        if(order.status==='preparing')actions+=`<button class="primary small-btn" data-order="${order.id}" data-status="ready">Use Products & Mark Ready</button>`;
        if(['pending','accepted','preparing'].includes(order.status))actions+=`<button class="danger small-btn" data-order="${order.id}" data-status="cancelled">Cancel</button>`;
        if(order.status==='ready'&&canAction('cancelReadyOrder'))actions+=`<button class="danger small-btn" data-order="${order.id}" data-status="cancelled">Cancel Ready Order</button>`;
    }
    if(order.order_type==='delivery'&&order.status==='ready'&&order.delivery_status==='ready_for_driver'&&canAction('acceptDelivery'))actions+=`<button class="primary small-btn" data-accept-delivery="${order.id}">Accept Delivery</button>`;
    return actions;
}
function renderOrders(myOrders=false,deliveryOnly=false){
    let orders=state.data.orders||[];
    if(deliveryOnly)orders=orders.filter(o=>o.order_type==='delivery'&&o.status==='ready');
    const title=deliveryOnly?'Ready customer deliveries':myOrders?'Your recent orders':'Live kitchen queue';
    content.innerHTML=`<div class="hero"><div><h3>${title}</h3><p>${deliveryOnly?'Accept a ready order and deliver it to the saved customer location.':myOrders?'Collect ready pickup orders at the cafe counter.':'Prepared items are removed from the employee inventory when an order is marked ready.'}</p></div></div><div class="order-list">${orders.map(o=>`<article class="order-card"><div class="order-head"><div><h4>#${o.id} • ${esc(o.customer_name)}</h4><div class="order-meta">${titleCase(o.order_type)}${o.table_number?` • Table ${o.table_number}`:''} • ${money(o.total)} • ${dateText(o.created_at)}</div></div><span class="badge ${o.status}">${esc(o.status)}</span></div><div class="order-items">${orderItems(o)}</div>${o.notes?`<p class="muted small">Note: ${esc(o.notes)}</p>`:''}${o.quality_score?`<p class="small">Fulfilment quality: <strong>${o.quality_score}/100</strong></p>`:''}<div class="order-actions">${orderActions(o,myOrders)}</div></article>`).join('')||'<div class="empty">No orders to show.</div>'}</div>`;
    content.querySelectorAll('[data-order]').forEach(b=>b.onclick=async()=>{const r=await nui('updateOrder',{orderId:Number(b.dataset.order),status:b.dataset.status});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
    content.querySelectorAll('[data-cancel-order]').forEach(b=>b.onclick=async()=>{const r=await nui('cancelMyOrder',{orderId:Number(b.dataset.cancelOrder)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
    content.querySelectorAll('[data-accept-delivery]').forEach(b=>b.onclick=async()=>{const r=await nui('acceptDelivery',{orderId:Number(b.dataset.acceptDelivery)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
}

function renderSupplies(){
    const packs=Object.entries(state.data.supplyPacks||{});const allowed=canAction('startSupplyRun');
    content.innerHTML=`<div class="hero"><div><h3>Supplier runs</h3><p>${allowed?'Supply costs are charged before the run begins. Lost or cancelled runs are not automatically refunded.':'Your grade can view supplier packs but cannot start a supply run.'}</p></div></div><div class="grid">${packs.map(([id,p])=>`<article class="card"><h3>${esc(p.label)}</h3><p class="muted small">${esc(p.description)}</p><div class="list-row"><span>Cost</span><strong>${money(p.cost)}</strong></div><div class="list-row"><span>Minimum grade</span><strong>${p.minimumGrade}</strong></div><div class="list-row"><span>Reputation</span><strong>${p.minimumReputation||0}</strong></div><button class="primary" data-pack="${id}" ${!allowed?'disabled':''}>Start Run</button></article>`).join('')}</div>`;
    content.querySelectorAll('[data-pack]').forEach(b=>b.onclick=async()=>{if(!canAction('startSupplyRun'))return toast('Your grade cannot start supply runs.','error');const r=await nui('startSupply',{packId:b.dataset.pack});toast(r.message,r.success?'success':'error');});
}
function renderStock(){
    const rows=state.data.dashboard?.lowStock||[];
    content.innerHTML=`<div class="hero"><div><h3>Ingredient stock</h3><p>Low-stock warnings are calculated from the shared ox_inventory stash.</p></div></div><div class="card table-wrap"><table class="table"><thead><tr><th>Ingredient</th><th>Current</th><th>Warning level</th><th>Status</th></tr></thead><tbody>${rows.map(r=>`<tr><td><strong>${esc(r.label)}</strong></td><td>${r.count}</td><td>${r.threshold}</td><td><span class="badge ${r.low?'low':'ready'}">${r.low?'Low':'Healthy'}</span></td></tr>`).join('')}</tbody></table></div>`;
}
function renderCatering(){
    const rows=state.data.catering||[];const canAccept=canAction('acceptCatering');const canStart=canAction('startCateringDelivery');
    content.innerHTML=`<div class="hero"><div><h3>Catering contracts</h3><p>Accept a contract, prepare every listed item, then load it at the packaging counter.</p></div></div><div class="grid two">${rows.map(c=>`<article class="card"><div class="order-head"><div><h3>${esc(c.label)}</h3><p class="muted small">${esc(c.destination_label)}</p></div><span class="badge ${c.status==='available'?'pending':'ready'}">${esc(c.status)}</span></div><div class="order-items">${Object.entries(c.items||{}).map(([item,q])=>`<span>${q}x ${esc(item)}</span>`).join('')}</div><div class="list-row"><span>Business reward</span><strong>${money(c.reward)}</strong></div><div class="list-row"><span>Required reputation</span><strong>${c.minimum_reputation}</strong></div><div class="action-row">${c.status==='available'?`<button class="primary small-btn" data-accept-contract="${c.id}" ${!canAccept?'disabled':''}>Accept</button>`:`<button class="primary small-btn" data-start-contract="${c.id}" ${!canStart?'disabled':''}>Load & Deliver</button>`}</div></article>`).join('')||'<div class="empty">No contracts available.</div>'}</div>`;
    content.querySelectorAll('[data-accept-contract]').forEach(b=>b.onclick=async()=>{if(!canAction('acceptCatering'))return toast('Your grade cannot accept catering contracts.','error');const r=await nui('acceptCatering',{contractId:Number(b.dataset.acceptContract)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
    content.querySelectorAll('[data-start-contract]').forEach(b=>b.onclick=async()=>{if(!canAction('startCateringDelivery'))return toast('Your grade cannot start catering deliveries.','error');const r=await nui('startCateringDelivery',{contractId:Number(b.dataset.startContract)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
}
function renderBusiness(){
    const d=state.data.dashboard||{};const canDeposit=canAction('depositBusiness');const canWithdraw=canAction('withdrawBusiness');const canUpgrade=canAction('buyBusinessUpgrade');
    content.innerHTML=`<div class="stats"><div class="stat-card"><span>Balance</span><strong>${money(d.balance)}</strong></div><div class="stat-card"><span>Today income</span><strong>${money(d.todayIncome)}</strong></div><div class="stat-card"><span>Today expenses</span><strong>${money(d.todayExpenses)}</strong></div><div class="stat-card"><span>Reputation</span><strong>${d.reputation||0}</strong></div><div class="stat-card"><span>Rating</span><strong>${d.averageRating||0}/5</strong></div></div><div class="grid two"><div class="card"><h3>Operations health</h3><div class="meter-row"><span>Cleanliness</span><div class="progress"><div style="width:${Math.max(0,Math.min(100,d.cleanliness||0))}%"></div></div><strong>${d.cleanliness||0}%</strong></div><div class="meter-row"><span>Reputation tier</span><div class="progress"><div style="width:${Math.min(100,(d.reputation||0)/7)}%"></div></div><strong>${esc(d.reputationLevel?.name||'Local')}</strong></div>${canDeposit||canWithdraw?`<div class="inline-form"><div class="field"><label>Amount</label><input id="businessAmount" class="form-control" type="number" min="1"></div>${canDeposit?'<button id="depositButton" class="secondary">Deposit</button>':''}${canWithdraw?'<button id="withdrawButton" class="danger">Withdraw</button>':''}</div>`:'<p class="muted small">Your grade has read-only access to business finances.</p>'}</div><div class="card"><h3>Best sellers — 7 days</h3><div class="list">${(d.bestSellers||[]).map(r=>`<div class="list-row"><span>${esc(r.label)}</span><strong>${r.quantity} • ${money(r.revenue)}</strong></div>`).join('')||'<p class="muted small">No completed sales yet.</p>'}</div></div></div><div class="grid two" style="margin-top:14px"><div class="card"><h3>Business upgrades</h3>${(d.upgrades||[]).map(u=>`<div class="list-row"><div><strong>${esc(u.label)}</strong><div class="muted tiny">${esc(u.description)}</div></div><div class="action-row"><span class="badge ready">Lv ${u.level}/${u.maxLevel}</span>${canUpgrade&&u.nextCost?`<button class="primary small-btn" data-upgrade="${u.key}">${money(u.nextCost)}</button>`:''}</div></div>`).join('')}</div><div class="card"><h3>Recent transactions</h3>${(d.recentTransactions||[]).map(t=>`<div class="list-row"><div><strong>${esc(t.reason)}</strong><div class="muted tiny">${dateText(t.created_at)}</div></div><strong style="color:${Number(t.amount)>=0?'var(--green)':'var(--red)'}">${Number(t.amount)>=0?'+':''}${money(t.amount)}</strong></div>`).join('')}</div></div>`;
    if(canDeposit)document.getElementById('depositButton').onclick=()=>businessMoney('depositBusiness');if(canWithdraw)document.getElementById('withdrawButton').onclick=()=>businessMoney('withdrawBusiness');
    content.querySelectorAll('[data-upgrade]').forEach(b=>b.onclick=async()=>{if(!canAction('buyBusinessUpgrade'))return toast('Your grade cannot purchase business upgrades.','error');const r=await nui('buyUpgrade',{key:b.dataset.upgrade});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
}
async function businessMoney(action){const amount=Number(document.getElementById('businessAmount').value);const r=await nui(action,{amount});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}}
function renderEquipment(){
    const rows=state.data.equipment||[];const canRepair=canAction('repairEquipment');const canUpgrade=canAction('upgradeEquipment');
    content.innerHTML=`<div class="hero"><div><h3>Kitchen equipment</h3><p>Damaged equipment slows production and lowers quality. Your grade controls which maintenance actions are available.</p></div></div><div class="grid two">${rows.map(e=>`<article class="card"><div class="order-head"><div><h3>${esc(e.label)}</h3><p class="muted small">Level ${e.level}/${4}</p></div><span class="badge ${e.condition_value<20?'cancelled':e.condition_value<50?'pending':'ready'}">${e.condition_value}%</span></div><div class="progress"><div style="width:${e.condition_value}%"></div></div><div class="action-row"><button class="secondary small-btn" data-equip-action="repair" data-station="${esc(e.station_id)}" ${e.repairCost<=0||!canRepair?'disabled':''}>Repair ${money(e.repairCost)}</button><button class="primary small-btn" data-equip-action="upgrade" data-station="${esc(e.station_id)}" ${!e.upgradeCost||!canUpgrade?'disabled':''}>${e.upgradeCost?`Upgrade ${money(e.upgradeCost)}`:'Max Level'}</button></div></article>`).join('')}</div>`;
    content.querySelectorAll('[data-equip-action]').forEach(b=>b.onclick=async()=>{const required=b.dataset.equipAction==='upgrade'?'upgradeEquipment':'repairEquipment';if(!canAction(required))return toast('Your grade cannot perform this equipment action.','error');const r=await nui('equipmentAction',{action:b.dataset.equipAction,stationId:b.dataset.station});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
}
function renderPromotions(){
    const rows=state.data.dashboard?.promotions||[];const products=state.data.products||[];const categories=[...new Set(products.map(p=>p.category))];const canCreate=canAction('createPromotion');const canDisable=canAction('disablePromotion');
    content.innerHTML=`${canCreate?`<div class="card"><h3>Create promotion</h3><div class="inline-form"><div class="field"><label>Name</label><input id="promoName" class="form-control" placeholder="Happy Hour"></div><div class="field"><label>Scope</label><select id="promoScope" class="form-control"><option value="all">All products</option><option value="category">Category</option><option value="product">Product</option></select></div><div class="field"><label>Target</label><input id="promoTarget" class="form-control" placeholder="Food or uwu_burger"></div><div class="field"><label>Discount %</label><input id="promoDiscount" class="form-control" type="number" min="1" max="40"></div><div class="field"><label>Hours</label><input id="promoHours" class="form-control" type="number" min="1" max="72"></div><button id="createPromo" class="primary">Create</button></div><p class="muted tiny">Categories: ${categories.map(esc).join(', ')}. Product target uses the item name.</p></div>`:'<div class="card"><h3>Promotions</h3><p class="muted small">Your grade has read-only promotion access.</p></div>'}<div class="card" style="margin-top:14px"><h3>Active promotions</h3>${rows.map(p=>`<div class="list-row"><div><strong>${esc(p.name)}</strong><div class="muted tiny">${esc(p.scope)} ${esc(p.target||'')} • ends ${dateText(p.ends_at)}</div></div><div class="action-row"><span class="badge ready">-${p.discount_percent}%</span>${canDisable?`<button class="danger small-btn" data-disable-promo="${p.id}">Disable</button>`:''}</div></div>`).join('')||'<p class="muted small">No active promotions.</p>'}</div>`;
    if(canCreate)document.getElementById('createPromo').onclick=async()=>{const r=await nui('createPromotion',{name:document.getElementById('promoName').value,scope:document.getElementById('promoScope').value,target:document.getElementById('promoTarget').value,discount:Number(document.getElementById('promoDiscount').value),durationHours:Number(document.getElementById('promoHours').value)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}};
    content.querySelectorAll('[data-disable-promo]').forEach(b=>b.onclick=async()=>{if(!canAction('disablePromotion'))return toast('Your grade cannot disable promotions.','error');const r=await nui('disablePromotion',{promotionId:Number(b.dataset.disablePromo)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
}
function renderStaff(){
    const employees=state.data.employees||[];const allowed=canAction('employeeAction');
    content.innerHTML=`<div class="card"><div class="hero"><div><h3>Employee management</h3><p>${allowed?'Online and offline employees are loaded from the ESX users table.':'Your grade has read-only staff access.'}</p></div></div><div class="table-wrap"><table class="table"><thead><tr><th>Employee</th><th>Grade</th><th>Status</th>${allowed?'<th>Actions</th>':''}</tr></thead><tbody>${employees.map(e=>`<tr><td><strong>${esc(e.name)}</strong><div class="muted tiny">${esc(e.identifier)}</div></td><td>${esc(e.gradeLabel)} (${e.grade})</td><td><span class="badge ${e.onDuty?'ready':e.online?'pending':''}">${e.onDuty?'On duty':e.online?'Online':'Offline'}</span></td>${allowed?`<td><div class="action-row"><button class="secondary small-btn" data-staff="setGrade" data-id="${encodeURIComponent(e.identifier)}" data-grade="${e.grade+1}">Promote</button><button class="secondary small-btn" data-staff="setGrade" data-id="${encodeURIComponent(e.identifier)}" data-grade="${Math.max(0,e.grade-1)}">Demote</button>${e.online?`<button class="secondary small-btn" data-staff="bonus" data-id="${encodeURIComponent(e.identifier)}" data-source="${e.source}">Bonus</button>`:''}<button class="danger small-btn" data-staff="fire" data-id="${encodeURIComponent(e.identifier)}">Fire</button></div></td>`:''}</tr>`).join('')}</tbody></table></div></div>${allowed?'<div class="card" style="margin-top:14px"><h3>Hire nearby player</h3><div class="inline-form"><input id="hireId" class="form-control" style="max-width:250px" type="number" placeholder="Player server ID"><button id="hireButton" class="primary">Hire as Trainee</button></div></div>':''}`;
    content.querySelectorAll('[data-staff]').forEach(b=>b.onclick=async()=>{if(!canAction('employeeAction'))return toast('Your grade cannot manage employees.','error');const action=b.dataset.staff;const payload={action,identifier:decodeURIComponent(b.dataset.id),targetId:Number(b.dataset.source||0),grade:Number(b.dataset.grade)};if(action==='bonus'){const amount=Number(prompt('Bonus amount')||0);if(!amount)return;payload.amount=amount;}const r=await nui('employeeAction',payload);toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}});
    if(allowed)document.getElementById('hireButton').onclick=async()=>{const r=await nui('employeeAction',{action:'hire',targetId:Number(document.getElementById('hireId').value)});toast(r.message,r.success?'success':'error');if(r.success){await refresh();render();}};
}
function renderProfile(){
    const p=state.data.profile||{};const current=Number(p.currentLevelXp||0),next=Number(p.nextLevelXp||100),xp=Number(p.xp||0),percent=Math.max(0,Math.min(100,(xp-current)/Math.max(1,next-current)*100));
    content.innerHTML=`<div class="stats"><div class="stat-card"><span>Level</span><strong>${p.level||1}</strong></div><div class="stat-card"><span>Experience</span><strong>${xp}</strong></div><div class="stat-card"><span>Duty hours</span><strong>${(Number(p.total_minutes||0)/60).toFixed(1)}</strong></div><div class="stat-card"><span>Orders</span><strong>${p.orders_completed||0}</strong></div><div class="stat-card"><span>Deliveries</span><strong>${Number(p.customer_deliveries||0)+Number(p.supply_deliveries||0)}</strong></div></div><div class="card"><h3>Overall level progress</h3><p class="muted small">${xp} / ${next} XP</p><div class="progress"><div style="width:${percent}%"></div></div></div><div class="grid" style="margin-top:14px">${Object.entries(p.skills||{}).map(([name,s])=>{const pc=Math.max(0,Math.min(100,(s.xp-s.currentLevelXp)/Math.max(1,s.nextLevelXp-s.currentLevelXp)*100));return`<div class="card"><h3>${titleCase(name)}</h3><strong>Level ${s.level}</strong><p class="muted small">${s.xp} XP</p><div class="progress"><div style="width:${pc}%"></div></div></div>`}).join('')}</div>`;
}

function render(){
    if(!ensureAllowedTab()){navigation.innerHTML='';pageTitle.textContent='No Access';content.innerHTML='<div class="empty">Your grade has no tablet pages configured.</div>';return;}
    renderNav();const labels={menu:'Menu',myOrders:'My Orders',orders:'Kitchen Orders',deliveries:'Customer Deliveries',register:'Register',catering:'Catering',supplies:'Supply Runs',stock:'Stock',business:'Business Dashboard',equipment:'Equipment',promotions:'Promotions',staff:'Employee Management',profile:'My Progress'};pageTitle.textContent=labels[state.tab]||titleCase(state.tab);profileName.textContent=state.data.player?.name||'Guest';profileRole.textContent=state.mode==='employee'?(state.data.player?.gradeLabel||'Employee'):'Customer';sidebarModeLabel.textContent=state.mode==='employee'?'Employee operations':'Customer portal';document.querySelector('.avatar').textContent=(state.data.player?.name||'U').charAt(0).toUpperCase();
    if(state.tab==='menu')renderProducts(false);else if(state.tab==='register')renderProducts(true);else if(state.tab==='orders')renderOrders(false,false);else if(state.tab==='deliveries')renderOrders(false,true);else if(state.tab==='myOrders')renderOrders(true,false);else if(state.tab==='supplies')renderSupplies();else if(state.tab==='stock')renderStock();else if(state.tab==='catering')renderCatering();else if(state.tab==='business')renderBusiness();else if(state.tab==='equipment')renderEquipment();else if(state.tab==='promotions')renderPromotions();else if(state.tab==='staff')renderStaff();else if(state.tab==='profile')renderProfile();
    requestAnimationFrame(()=>{content.scrollTop=state.scroll[state.tab]||0;});
}
async function refresh(){const response=await nui('refresh');if(!response?.error)state.data=response;}
content.addEventListener('scroll',()=>{state.scroll[state.tab]=content.scrollTop;},{passive:true});
document.getElementById('tabletHomeButton').onclick=()=>nui('close');document.addEventListener('keydown',e=>{if(e.key==='Escape')nui('close');});
window.addEventListener('message',event=>{const m=event.data;if(m.action==='open'){state.mode=m.mode;state.tab=m.selectedTab||(m.mode==='employee'?'orders':'menu');state.data=m.payload||{};state.cart={};state.scroll={};app.classList.remove('hidden');render();}else if(m.action==='data'){state.data=m.payload||state.data;render();}else if(m.action==='close'){app.classList.add('hidden');}});
