local activePromotionCache = { expires = 0, rows = {} }

function UwU.GetBusiness()
    local row = MySQL.single.await('SELECT * FROM z_uwucafe_business WHERE id = 1')
    if not row then
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_business
                (id, balance, cleanliness, reputation, rating_total, rating_count)
            VALUES (1, 0, 100, 0, 0, 0)
        ]])
        row = { balance = 0, cleanliness = 100, reputation = 0, rating_total = 0, rating_count = 0 }
    end
    for _, column in ipairs({ 'balance', 'cleanliness', 'reputation', 'rating_total', 'rating_count' }) do
        row[column] = tonumber(row[column]) or 0
    end
    row.averageRating = row.rating_count > 0 and UwU.Round(row.rating_total / row.rating_count, 1) or 0
    return row
end

function UwU.AddTransaction(amount, reason, actorIdentifier, metadata)
    MySQL.insert.await([[
        INSERT INTO z_uwucafe_transactions (amount, reason, actor_identifier, metadata)
        VALUES (?, ?, NULLIF(?, ''), ?)
    ]], { math.floor(amount), UwU.SanitizeText(reason or 'Unknown', 160), actorIdentifier or '', json.encode(metadata or {}) })
end

function UwU.AddBusinessMoney(amount, reason, actorIdentifier, metadata)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false end
    MySQL.update.await('UPDATE z_uwucafe_business SET balance = GREATEST(0, balance + ?) WHERE id = 1', { amount })
    UwU.AddTransaction(amount, reason, actorIdentifier, metadata)
    return true
end

function UwU.RemoveBusinessMoney(amount, reason, actorIdentifier, metadata)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local changed = MySQL.update.await('UPDATE z_uwucafe_business SET balance = balance - ? WHERE id = 1 AND balance >= ?', { amount, amount })
    if not changed or changed < 1 then return false end
    UwU.AddTransaction(-amount, reason, actorIdentifier, metadata)
    return true
end

function UwU.ChangeCleanliness(amount)
    MySQL.update.await('UPDATE z_uwucafe_business SET cleanliness = LEAST(?, GREATEST(?, cleanliness + ?)) WHERE id = 1', {
        Config.Business.maxCleanliness,
        Config.Business.minCleanliness,
        math.floor(tonumber(amount) or 0)
    })
end

function UwU.ChangeReputation(amount)
    MySQL.update.await('UPDATE z_uwucafe_business SET reputation = GREATEST(0, reputation + ?) WHERE id = 1', { math.floor(tonumber(amount) or 0) })
end

function UwU.AddRating(rating)
    rating = UwU.Clamp(math.floor(tonumber(rating) or 0), 1, 5)
    MySQL.update.await('UPDATE z_uwucafe_business SET rating_total = rating_total + ?, rating_count = rating_count + 1 WHERE id = 1', { rating })
end

function UwU.GetReputationLevel(reputation)
    reputation = tonumber(reputation) or UwU.GetBusiness().reputation
    local selected = Config.ReputationLevels[1]
    for _, level in ipairs(Config.ReputationLevels) do
        if reputation >= level.required then selected = level else break end
    end
    return selected
end

function UwU.GetActivePromotions(force)
    local now = os.time()
    if not force and activePromotionCache.expires > now then return activePromotionCache.rows end
    local rows = MySQL.query.await([[
        SELECT * FROM z_uwucafe_promotions
        WHERE active = 1 AND starts_at <= NOW() AND ends_at > NOW()
        ORDER BY discount_percent DESC, id DESC
    ]]) or {}
    activePromotionCache = { expires = now + 15, rows = rows }
    return rows
end

function UwU.InvalidatePromotionCache()
    activePromotionCache.expires = 0
end

function UwU.GetProductPricing(itemName)
    local product = Config.Products[itemName]
    if not product then return nil end
    local business = UwU.GetBusiness()
    if business.reputation < (product.minimumReputation or 0) then return nil end

    local reputationLevel = UwU.GetReputationLevel(business.reputation)
    local basePrice = math.max(1, math.floor(product.price * (reputationLevel.priceMultiplier or 1.0)))
    local discount = 0
    local promotionName
    for _, promotion in ipairs(UwU.GetActivePromotions()) do
        local applies = promotion.scope == 'all'
            or (promotion.scope == 'category' and promotion.target == product.category)
            or (promotion.scope == 'product' and promotion.target == itemName)
        if applies and tonumber(promotion.discount_percent) > discount then
            discount = tonumber(promotion.discount_percent)
            promotionName = promotion.name
        end
    end
    discount = UwU.Clamp(discount, 0, Config.Promotions.maximumDiscountPercent)
    local finalPrice = math.max(1, math.floor(basePrice * (1 - discount / 100)))
    return {
        basePrice = basePrice,
        price = finalPrice,
        discount = discount,
        promotionName = promotionName
    }
end

function UwU.GetProductsForUi()
    local products = {}
    local business = UwU.GetBusiness()
    for itemName, product in pairs(Config.Products) do
        local pricing = UwU.GetProductPricing(itemName)
        products[#products + 1] = {
            item = itemName,
            label = product.label,
            category = product.category,
            price = pricing and pricing.price or product.price,
            originalPrice = pricing and pricing.basePrice or product.price,
            discount = pricing and pricing.discount or 0,
            promotionName = pricing and pricing.promotionName or nil,
            description = product.description,
            image = product.image,
            minimumReputation = product.minimumReputation or 0,
            locked = business.reputation < (product.minimumReputation or 0)
        }
    end
    table.sort(products, function(a, b)
        if a.category == b.category then return a.label < b.label end
        return a.category < b.category
    end)
    return products
end

function UwU.GetStockSnapshot()
    UwU.EnsureStashLoaded(Config.Stock.stashId)
    local rows = {}
    for itemName, threshold in pairs(Config.Stock.lowStock) do
        local itemData = exports.ox_inventory:Items(itemName)
        local count = UwU.GetInventoryItemCount(Config.Stock.stashId, itemName)
        rows[#rows + 1] = {
            item = itemName,
            label = itemData and itemData.label or itemName,
            count = count,
            threshold = threshold,
            low = count <= threshold
        }
    end
    table.sort(rows, function(a, b)
        if a.low ~= b.low then return a.low end
        return a.label < b.label
    end)
    return rows
end

function UwU.GetBusinessUpgrades()
    local rows = MySQL.query.await('SELECT upgrade_key, level FROM z_uwucafe_upgrades') or {}
    local levels = {}
    for _, row in ipairs(rows) do levels[row.upgrade_key] = tonumber(row.level) or 0 end
    local result = {}
    for key, config in pairs(Config.BusinessUpgrades) do
        result[#result + 1] = {
            key = key,
            label = config.label,
            description = config.description,
            level = levels[key] or 0,
            maxLevel = config.maxLevel,
            nextCost = config.costs[(levels[key] or 0) + 1]
        }
    end
    table.sort(result, function(a, b) return a.label < b.label end)
    return result, levels
end

function UwU.GetDashboard()
    local business = UwU.GetBusiness()
    local reputationLevel = UwU.GetReputationLevel(business.reputation)
    local today = MySQL.single.await([[
        SELECT
            COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) AS income,
            COALESCE(ABS(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END)), 0) AS expenses
        FROM z_uwucafe_transactions WHERE created_at >= CURDATE()
    ]]) or {}
    local orderStats = MySQL.single.await([[
        SELECT COUNT(*) AS orders,
               COALESCE(SUM(CASE WHEN paid_to_business = 1 THEN total ELSE 0 END), 0) AS revenue,
               COALESCE(AVG(CASE WHEN rating > 0 THEN rating END), 0) AS rating
        FROM z_uwucafe_orders WHERE created_at >= CURDATE()
    ]]) or {}
    local bestSellers = MySQL.query.await([[
        SELECT oi.item_label AS label, SUM(oi.quantity) AS quantity, SUM(oi.quantity * oi.unit_price) AS revenue
        FROM z_uwucafe_order_items oi
        INNER JOIN z_uwucafe_orders o ON o.id = oi.order_id
        WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) AND o.status = 'completed'
        GROUP BY oi.item_name, oi.item_label ORDER BY quantity DESC LIMIT 8
    ]]) or {}
    local recentTransactions = MySQL.query.await([[
        SELECT amount, reason, created_at FROM z_uwucafe_transactions ORDER BY id DESC LIMIT 15
    ]]) or {}
    local upgrades = UwU.GetBusinessUpgrades()
    return {
        balance = business.balance,
        cleanliness = business.cleanliness,
        reputation = business.reputation,
        reputationLevel = reputationLevel,
        averageRating = business.averageRating,
        todayIncome = tonumber(today.income) or 0,
        todayExpenses = tonumber(today.expenses) or 0,
        todayOrders = tonumber(orderStats.orders) or 0,
        todayRevenue = tonumber(orderStats.revenue) or 0,
        todayRating = UwU.Round(tonumber(orderStats.rating) or 0, 1),
        recentTransactions = recentTransactions,
        bestSellers = bestSellers,
        lowStock = UwU.GetStockSnapshot(),
        promotions = UwU.GetActivePromotions(),
        upgrades = upgrades,
        equipment = UwU.GetAllEquipment and UwU.GetAllEquipment() or {}
    }
end
