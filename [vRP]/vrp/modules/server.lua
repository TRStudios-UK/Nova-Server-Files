-- A JamesUK Production. Licensed users only. Use without authorisation is illegal, and a criminal offence under UK Law.
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
local vRP = Proxy.getInterface("vRP")
local vRPclient = Tunnel.getInterface("vRP", "vRP") -- server -> client tunnel
local Inventory = module("vrp", "cfg/inventory")
local InventorySpamTrack = {} -- Stops inventory being spammed by users.
local LootBagEntities = {}
local InventoryCoolDown = {}

RegisterNetEvent("Nova:FetchPersonalInventory")
AddEventHandler(
    "Nova:FetchPersonalInventory",
    function()
        local source = source
        if not InventorySpamTrack[source] then
            InventorySpamTrack[source] = true
            local UserId = vRP.getUserId({source})
            local data = vRP.getUserDataTable({UserId})
            if data and data.inventory then
                local FormattedInventoryData = {}
                --print(json.encode(data.inventory))
                for i, v in pairs(data.inventory) do
                    FormattedInventoryData[i] = {
                        amount = v.amount,
                        ItemName = vRP.getItemName({i}),
                        Weight = vRP.getItemWeight({i})
                    }
                end
                TriggerClientEvent(
                    "Nova:FetchPersonalInventory",
                    source,
                    FormattedInventoryData,
                    vRP.computeItemsWeight({data.inventory}),
                    vRP.getInventoryMaxWeight({UserId})
                )
                InventorySpamTrack[source] = false
            else
                print(
                    "[^7JamesUKInventory]^1: An error has occured while trying to fetch inventory data from: " ..
                        UserId .. " This may be a saving / loading data error you will need to investigate this."
                )
            end
        end
    end
)

AddEventHandler(
    "Nova:RefreshInventory",
    function(source)
        local UserId = vRP.getUserId({source})
        local data = vRP.getUserDataTable({UserId})
        if data and data.inventory then
            local FormattedInventoryData = {}
            for i, v in pairs(data.inventory) do
                FormattedInventoryData[i] = {
                    amount = v.amount,
                    ItemName = vRP.getItemName({i}),
                    Weight = vRP.getItemWeight({i})
                }
            end
            TriggerClientEvent(
                "Nova:FetchPersonalInventory",
                source,
                FormattedInventoryData,
                vRP.computeItemsWeight({data.inventory}),
                vRP.getInventoryMaxWeight({UserId})
            )
        else
            print(
                "[^7JamesUKInventory]^1: An error has occured while trying to fetch inventory data from: " ..
                    UserId .. " This may be a saving / loading data error you will need to investigate this."
            )
        end
    end
)

RegisterNetEvent("Nova:GiveItem")
AddEventHandler(
    "Nova:GiveItem",
    function(itemId, itemLoc)
        local source = source
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if itemLoc == "Plr" then
            vRP.RunGiveTask({source, itemId})
        else
            vRPclient.notify(source, {"~r~You need to have this item on you to give it."})
        end
    end
)

RegisterNetEvent("Nova:TrashItem")
AddEventHandler(
    "Nova:TrashItem",
    function(itemId, itemLoc)
        local source = source
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if itemLoc == "Plr" then
            vRP.RunTrashTask({source, itemId})
        else
            vRPclient.notify(source, {"~r~You need to have this item on you to drop it."})
        end
    end
)

RegisterNetEvent("Nova:FetchTrunkInventory")
AddEventHandler(
    "Nova:FetchTrunkInventory",
    function(spawnCode)
        local source = source
        local user_id = vRP.getUserId({source})
        if InventoryCoolDown[source] then
            vRPclient.notify(source, {"~r~The server is still processing your request."})
            return
        end
        local carformat = "chest:u1veh_" .. spawnCode .. "|" .. user_id
        vRP.getSData(
            {
                carformat,
                function(cdata)
                    local processedChest = {}
                    cdata = json.decode(cdata) or {}
                    local FormattedInventoryData = {}
                    for i, v in pairs(cdata) do
                        FormattedInventoryData[i] = {
                            amount = v.amount,
                            ItemName = vRP.getItemName({i}),
                            Weight = vRP.getItemWeight({i})
                        }
                    end
                    local maxVehKg = Inventory.vehicle_chest_weights[spawnCode] or 1500
                    TriggerClientEvent(
                        "Nova:SendSecondaryInventoryData",
                        source,
                        FormattedInventoryData,
                        vRP.computeItemsWeight({cdata}),
                        maxVehKg
                    )
                end
            }
        )
    end
)

RegisterNetEvent("Nova:FetchTrunkInventory2")
AddEventHandler(
    "Nova:FetchTrunkInventory2",
    function(spawnCode)
        local source = source
        local user_id = vRP.getUserId({source})
        if InventoryCoolDown[source] then
            vRPclient.notify(source, {"~r~The server is still processing your request."})
            return
        end
        local carformat = "chest:u1veh_" .. spawnCode .. "|" .. user_id
        vRP.getSData(
            {
                carformat,
                function(cdata)
                    local processedChest = {}
                    cdata = json.decode(cdata) or {}
                    local FormattedInventoryData = {}
                    for i, v in pairs(cdata) do
                        FormattedInventoryData[i] = {
                            amount = v.amount,
                            ItemName = vRP.getItemName({i}),
                            Weight = vRP.getItemWeight({i})
                        }
                    end
                    local maxVehKg = Inventory.vehicle_chest_weights[spawnCode] or 1500
                    TriggerClientEvent(
                        "Nova:SendSecondaryInventoryData",
                        source,
                        FormattedInventoryData,
                        vRP.computeItemsWeight({cdata}),
                        1500
                    )
                end
            }
        )
    end
)

RegisterNetEvent("Nova:UseItem")
AddEventHandler(
    "Nova:UseItem",
    function(itemId, itemLoc)
        local source = source
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if itemLoc == "Plr" then
            vRP.RunInventoryTask({source, itemId})
        else
            vRPclient.notify(source, {"~r~You need to have this item on you to use it."})
        end
    end
)

RegisterNetEvent("Nova:MoveItem")
AddEventHandler(
    "Nova:MoveItem",
    function(inventoryType, itemId, inventoryInfo, Lootbag)
        local source = source
        local UserId = vRP.getUserId({source})
        local data = vRP.getUserDataTable({UserId})
        if InventoryCoolDown[source] then
            vRPclient.notify(source, {"~r~The server is still processing your request."})
            return
        end
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if data and data.inventory then
            if inventoryInfo == nil then
                return
            end
            if inventoryType == "CarBoot" then
                InventoryCoolDown[source] = true
                local Quantity = parseInt(1)
                if Quantity then
                    local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                    vRP.getSData(
                        {
                            carformat,
                            function(cdata)
                                cdata = json.decode(cdata) or {}
                                if cdata[itemId] and cdata[itemId].amount >= 1 then
                                    local weightCalculation =
                                        vRP.getInventoryWeight({UserId}) + vRP.getItemWeight({itemId})
                                    if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                                        if cdata[itemId].amount > 1 then
                                            cdata[itemId].amount = cdata[itemId].amount - 1
                                            vRP.giveInventoryItem({UserId, itemId, 1, true})
                                        else
                                            cdata[itemId] = nil
                                            vRP.giveInventoryItem({UserId, itemId, 1, true})
                                        end
                                        local FormattedInventoryData = {}
                                        for i, v in pairs(cdata) do
                                            FormattedInventoryData[i] = {
                                                amount = v.amount,
                                                ItemName = vRP.getItemName({i}),
                                                Weight = vRP.getItemWeight({i})
                                            }
                                        end
                                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                        TriggerClientEvent(
                                            "Nova:SendSecondaryInventoryData",
                                            source,
                                            FormattedInventoryData,
                                            vRP.computeItemsWeight({cdata}),
                                            maxVehKg
                                        )
                                        TriggerEvent("Nova:RefreshInventory", source)
                                        InventoryCoolDown[source] = false
                                        vRP.setSData({carformat, json.encode(cdata)})
                                    else
                                        InventoryCoolDown[source] = false
                                        vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                                    end
                                else
                                    InventoryCoolDown[source] = false
                                    print(
                                        "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                                            UserId ..
                                                " This is usually caused by cheating as the item does not exist in the car boot."
                                    )
                                end
                            end
                        }
                    )
                end
            elseif inventoryType == "LootBag" then
                if LootBagEntities[inventoryInfo].Items[itemId] then
                    local weightCalculation = vRP.getInventoryWeight({UserId}) + vRP.getItemWeight({itemId})
                    if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                        if
                            LootBagEntities[inventoryInfo].Items[itemId] and
                                LootBagEntities[inventoryInfo].Items[itemId].amount > 1
                         then
                            LootBagEntities[inventoryInfo].Items[itemId].amount =
                                LootBagEntities[inventoryInfo].Items[itemId].amount - 1
                            vRP.giveInventoryItem({UserId, itemId, 1, true})
                        else
                            LootBagEntities[inventoryInfo].Items[itemId] = nil
                            vRP.giveInventoryItem({UserId, itemId, 1, true})
                        end
                        local FormattedInventoryData = {}
                        for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                            FormattedInventoryData[i] = {
                                amount = v.amount,
                                ItemName = vRP.getItemName({i}),
                                Weight = vRP.getItemWeight({i})
                            }
                        end
                        local maxVehKg = 200
                        TriggerClientEvent(
                            "Nova:SendSecondaryInventoryData",
                            source,
                            FormattedInventoryData,
                            vRP.computeItemsWeight({LootBagEntities[inventoryInfo].Items}),
                            maxVehKg
                        )
                        TriggerEvent("Nova:RefreshInventory", source)
                    else
                        vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                    end
                end
            elseif inventoryType == "Housing" then
                -- Housing integration..
            elseif inventoryType == "Plr" then
                if not Lootbag then
                    if data.inventory[itemId] then
                        InventoryCoolDown[source] = true
                        local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                        vRP.getSData(
                            {
                                carformat,
                                function(cdata)
                                    cdata = json.decode(cdata) or {}
                                    if data.inventory[itemId] and data.inventory[itemId].amount >= 1 then
                                        local weightCalculation =
                                            vRP.computeItemsWeight({cdata}) + vRP.getItemWeight({itemId})
                                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                        if weightCalculation <= maxVehKg then
                                            if vRP.tryGetInventoryItem({UserId, itemId, 1, true}) then
                                                if cdata[itemId] then
                                                    cdata[itemId].amount = cdata[itemId].amount + 1
                                                else
                                                    cdata[itemId] = {}
                                                    cdata[itemId].amount = 1
                                                end
                                            end
                                            local FormattedInventoryData = {}
                                            for i, v in pairs(cdata) do
                                                FormattedInventoryData[i] = {
                                                    amount = v.amount,
                                                    ItemName = vRP.getItemName({i}),
                                                    Weight = vRP.getItemWeight({i})
                                                }
                                            end
                                            local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                            TriggerClientEvent(
                                                "Nova:SendSecondaryInventoryData",
                                                source,
                                                FormattedInventoryData,
                                                vRP.computeItemsWeight({cdata}),
                                                maxVehKg
                                            )
                                            TriggerEvent("Nova:RefreshInventory", source)
                                            InventoryCoolDown[source] = nil
                                            vRP.setSData({carformat, json.encode(cdata)})
                                        else
                                            InventoryCoolDown[source] = nil
                                            vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                                        end
                                    else
                                        InventoryCoolDown[source] = nil
                                        print(
                                            "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                                                UserId ..
                                                    " This is usually caused by cheating as the item does not exist in the car boot."
                                        )
                                    end
                                end
                            }
                        )
                    else
                        InventoryCoolDown[source] = nil
                        print(
                            "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                                UserId ..
                                    " This is usually caused by cheating as the item does not exist in the car boot."
                        )
                    end
                end
            end
        else
            InventoryCoolDown[source] = nil
            print(
                "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                    UserId .. " This may be a saving / loading data error you will need to investigate this."
            )
        end
    end
)

RegisterNetEvent("Nova:MoveItemX")
AddEventHandler(
    "Nova:MoveItemX",
    function(inventoryType, itemId, inventoryInfo, Lootbag)
        local source = source
        local UserId = vRP.getUserId({source})
        local data = vRP.getUserDataTable({UserId})
        if InventoryCoolDown[source] then
            vRPclient.notify(source, {"~r~The server is still processing your request."})
            return
        end
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if data and data.inventory then
            if inventoryInfo == nil then
                return
            end
            if inventoryType == "CarBoot" then
                InventoryCoolDown[source] = true
                TriggerClientEvent("Nova:ToggleNUIFocus", source, false)
                vRP.prompt(
                    {
                        source,
                        "How many " .. vRP.getItemName({itemId}) .. "s. Do you want to move?",
                        "",
                        function(player, Quantity)
                            Quantity = parseInt(Quantity)
                            TriggerClientEvent("Nova:ToggleNUIFocus", source, true)
                            if Quantity then
                                local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                                vRP.getSData(
                                    {
                                        carformat,
                                        function(cdata)
                                            cdata = json.decode(cdata) or {}
                                            if cdata[itemId] and Quantity <= cdata[itemId].amount then
                                                local weightCalculation =
                                                    vRP.getInventoryWeight({UserId}) +
                                                    (vRP.getItemWeight({itemId}) * Quantity)
                                                if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                                                    if cdata[itemId].amount > Quantity then
                                                        cdata[itemId].amount = cdata[itemId].amount - Quantity
                                                        vRP.giveInventoryItem({UserId, itemId, Quantity, true})
                                                    else
                                                        cdata[itemId] = nil
                                                        vRP.giveInventoryItem({UserId, itemId, Quantity, true})
                                                    end
                                                    local FormattedInventoryData = {}
                                                    for i, v in pairs(cdata) do
                                                        FormattedInventoryData[i] = {
                                                            amount = v.amount,
                                                            ItemName = vRP.getItemName({i}),
                                                            Weight = vRP.getItemWeight({i})
                                                        }
                                                    end
                                                    local maxVehKg =
                                                        Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                                    TriggerClientEvent(
                                                        "Nova:SendSecondaryInventoryData",
                                                        source,
                                                        FormattedInventoryData,
                                                        vRP.computeItemsWeight({cdata}),
                                                        maxVehKg
                                                    )
                                                    TriggerEvent("Nova:RefreshInventory", source)
                                                    InventoryCoolDown[source] = nil
                                                    vRP.setSData({carformat, json.encode(cdata)})
                                                else
                                                    InventoryCoolDown[source] = nil
                                                    vRPclient.notify(
                                                        source,
                                                        {"~r~You do not have enough inventory space."}
                                                    )
                                                end
                                            else
                                                InventoryCoolDown[source] = nil
                                                vRPclient.notify(
                                                    source,
                                                    {"~r~You are trying to move more then there actually is!"}
                                                )
                                            end
                                        end
                                    }
                                )
                            else
                                vRPclient.notify(source, {"~r~Invalid input!"})
                            end
                        end
                    }
                )
            elseif inventoryType == "LootBag" then
                if LootBagEntities[inventoryInfo].Items[itemId] then
                    TriggerClientEvent("Nova:ToggleNUIFocus", source, false)
                    vRP.prompt(
                        {
                            source,
                            "How many " .. vRP.getItemName({itemId}) .. "s. Do you want to move?",
                            "",
                            function(player, Quantity)
                                Quantity = parseInt(Quantity)
                                TriggerClientEvent("Nova:ToggleNUIFocus", source, true)
                                if Quantity then
                                    local weightCalculation =
                                        vRP.getInventoryWeight({UserId}) + (vRP.getItemWeight({itemId}) * Quantity)
                                    if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                                        if Quantity <= LootBagEntities[inventoryInfo].Items[itemId].amount then
                                            if
                                                LootBagEntities[inventoryInfo].Items[itemId] and
                                                    LootBagEntities[inventoryInfo].Items[itemId].amount > Quantity
                                             then
                                                LootBagEntities[inventoryInfo].Items[itemId].amount =
                                                    LootBagEntities[inventoryInfo].Items[itemId].amount - Quantity
                                                vRP.giveInventoryItem({UserId, itemId, Quantity, true})
                                            else
                                                LootBagEntities[inventoryInfo].Items[itemId] = nil
                                                vRP.giveInventoryItem({UserId, itemId, Quantity, true})
                                            end
                                            local FormattedInventoryData = {}
                                            for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                                                FormattedInventoryData[i] = {
                                                    amount = v.amount,
                                                    ItemName = vRP.getItemName({i}),
                                                    Weight = vRP.getItemWeight({i})
                                                }
                                            end
                                            local maxVehKg = 200
                                            TriggerClientEvent(
                                                "Nova:SendSecondaryInventoryData",
                                                source,
                                                FormattedInventoryData,
                                                vRP.computeItemsWeight({LootBagEntities[inventoryInfo].Items}),
                                                maxVehKg
                                            )
                                            TriggerEvent("Nova:RefreshInventory", source)
                                        else
                                            vRPclient.notify(
                                                source,
                                                {"~r~You are trying to move more then there actually is!"}
                                            )
                                        end
                                    else
                                        vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                                    end
                                else
                                    vRPclient.notify(source, {"~r~Invalid input!"})
                                end
                            end
                        }
                    )
                end
            elseif inventoryType == "Housing" then
                -- Housing integration..
            elseif inventoryType == "Plr" then
                if not Lootbag then
                    if data.inventory[itemId] then
                        InventoryCoolDown[source] = true
                        TriggerClientEvent("Nova:ToggleNUIFocus", source, false)
                        vRP.prompt(
                            {
                                source,
                                "How many " .. vRP.getItemName({itemId}) .. "s. Do you want to move?",
                                "",
                                function(player, Quantity)
                                    Quantity = parseInt(Quantity)
                                    TriggerClientEvent("Nova:ToggleNUIFocus", source, true)
                                    if Quantity then
                                        local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                                        vRP.getSData(
                                            {
                                                carformat,
                                                function(cdata)
                                                    cdata = json.decode(cdata) or {}
                                                    if
                                                        data.inventory[itemId] and
                                                            Quantity <= data.inventory[itemId].amount
                                                     then
                                                        local weightCalculation =
                                                            vRP.computeItemsWeight({cdata}) +
                                                            (vRP.getItemWeight({itemId}) * Quantity)
                                                        local maxVehKg =
                                                            Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                                        if weightCalculation <= maxVehKg then
                                                            if vRP.tryGetInventoryItem({UserId, itemId, Quantity, true}) then
                                                                if cdata[itemId] then
                                                                    cdata[itemId].amount =
                                                                        cdata[itemId].amount + Quantity
                                                                else
                                                                    cdata[itemId] = {}
                                                                    cdata[itemId].amount = Quantity
                                                                end
                                                            end
                                                            local FormattedInventoryData = {}
                                                            for i, v in pairs(cdata) do
                                                                FormattedInventoryData[i] = {
                                                                    amount = v.amount,
                                                                    ItemName = vRP.getItemName({i}),
                                                                    Weight = vRP.getItemWeight({i})
                                                                }
                                                            end
                                                            local maxVehKg =
                                                                Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                                            TriggerClientEvent(
                                                                "Nova:SendSecondaryInventoryData",
                                                                source,
                                                                FormattedInventoryData,
                                                                vRP.computeItemsWeight({cdata}),
                                                                maxVehKg
                                                            )
                                                            TriggerEvent("Nova:RefreshInventory", source)
                                                            InventoryCoolDown[source] = nil
                                                            vRP.setSData({carformat, json.encode(cdata)})
                                                        else
                                                            InventoryCoolDown[source] = nil
                                                            vRPclient.notify(
                                                                source,
                                                                {"~r~You do not have enough inventory space."}
                                                            )
                                                        end
                                                    else
                                                        InventoryCoolDown[source] = nil
                                                        vRPclient.notify(
                                                            source,
                                                            {"~r~You are trying to move more then there actually is!"}
                                                        )
                                                    end
                                                end
                                            }
                                        )
                                    else
                                        vRPclient.notify(source, {"~r~Invalid input!"})
                                    end
                                end
                            }
                        )
                    else
                        print(
                            "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                                UserId ..
                                    " This is usually caused by cheating as the item does not exist in the car boot."
                        )
                    end
                end
            end
        else
            print(
                "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                    UserId .. " This may be a saving / loading data error you will need to investigate this."
            )
        end
    end
)

RegisterNetEvent("Nova:MoveItemAll")
AddEventHandler(
    "Nova:MoveItemAll",
    function(inventoryType, itemId, inventoryInfo, Lootbag)
        local source = source
        local UserId = vRP.getUserId({source})
        local data = vRP.getUserDataTable({UserId})
        if not itemId then
            vRPclient.notify(source, {"~r~You need to select an item, first!"})
            return
        end
        if InventoryCoolDown[source] then
            vRPclient.notify(source, {"~r~The server is still processing your request."})
            return
        end
        if data and data.inventory then
            if inventoryInfo == nil then
                return
            end
            if inventoryType == "CarBoot" then
                InventoryCoolDown[source] = true
                local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                vRP.getSData(
                    {
                        carformat,
                        function(cdata)
                            cdata = json.decode(cdata) or {}
                            if cdata[itemId] and cdata[itemId].amount <= cdata[itemId].amount then
                                local weightCalculation =
                                    vRP.getInventoryWeight({UserId}) +
                                    (vRP.getItemWeight({itemId}) * cdata[itemId].amount)
                                if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                                    vRP.giveInventoryItem({UserId, itemId, cdata[itemId].amount, true})
                                    cdata[itemId] = nil
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {
                                            amount = v.amount,
                                            ItemName = vRP.getItemName({i}),
                                            Weight = vRP.getItemWeight({i})
                                        }
                                    end
                                    local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                    TriggerClientEvent(
                                        "Nova:SendSecondaryInventoryData",
                                        source,
                                        FormattedInventoryData,
                                        vRP.computeItemsWeight({cdata}),
                                        maxVehKg
                                    )
                                    TriggerEvent("Nova:RefreshInventory", source)
                                    InventoryCoolDown[source] = nil
                                    vRP.setSData({carformat, json.encode(cdata)})
                                else
                                    InventoryCoolDown[source] = nil
                                    vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                                end
                            else
                                InventoryCoolDown[source] = nil
                                vRPclient.notify(source, {"~r~You are trying to move more then there actually is!"})
                            end
                        end
                    }
                )
            elseif inventoryType == "LootBag" then
                if LootBagEntities[inventoryInfo].Items[itemId] then
                    local weightCalculation =
                        vRP.getInventoryWeight({UserId}) +
                        (vRP.getItemWeight({itemId}) * LootBagEntities[inventoryInfo].Items[itemId].amount)
                    if weightCalculation <= vRP.getInventoryMaxWeight({UserId}) then
                        if
                            LootBagEntities[inventoryInfo].Items[itemId].amount <=
                                LootBagEntities[inventoryInfo].Items[itemId].amount
                         then
                            vRP.giveInventoryItem(
                                {UserId, itemId, LootBagEntities[inventoryInfo].Items[itemId].amount, true}
                            )
                            LootBagEntities[inventoryInfo].Items[itemId] = nil
                            local FormattedInventoryData = {}
                            for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                                FormattedInventoryData[i] = {
                                    amount = v.amount,
                                    ItemName = vRP.getItemName({i}),
                                    Weight = vRP.getItemWeight({i})
                                }
                            end
                            local maxVehKg = 200
                            TriggerClientEvent(
                                "Nova:SendSecondaryInventoryData",
                                source,
                                FormattedInventoryData,
                                vRP.computeItemsWeight({LootBagEntities[inventoryInfo].Items}),
                                maxVehKg
                            )
                            TriggerEvent("Nova:RefreshInventory", source)
                        else
                            vRPclient.notify(source, {"~r~You are trying to move more then there actually is!"})
                        end
                    else
                        vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                    end
                end
            elseif inventoryType == "Housing" then
                -- Housing integration..
            elseif inventoryType == "Plr" then
                if not Lootbag then
                    if data.inventory[itemId] then
                        InventoryCoolDown[source] = true
                        local carformat = "chest:u1veh_" .. inventoryInfo .. "|" .. UserId
                        vRP.getSData(
                            {
                                carformat,
                                function(cdata)
                                    cdata = json.decode(cdata) or {}
                                    if
                                        data.inventory[itemId] and
                                            data.inventory[itemId].amount <= data.inventory[itemId].amount
                                     then
                                        local weightCalculation =
                                            vRP.computeItemsWeight({cdata}) +
                                            (vRP.getItemWeight({itemId}) * data.inventory[itemId].amount)
                                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                        if weightCalculation <= maxVehKg then
                                            if
                                                vRP.tryGetInventoryItem(
                                                    {UserId, itemId, data.inventory[itemId].amount, true}
                                                )
                                             then
                                                if cdata[itemId] then
                                                    cdata[itemId].amount =
                                                        cdata[itemId].amount + data.inventory[itemId].amount
                                                else
                                                    cdata[itemId] = {}
                                                    cdata[itemId].amount = data.inventory[itemId].amount
                                                end
                                            end
                                            local FormattedInventoryData = {}
                                            for i, v in pairs(cdata) do
                                                FormattedInventoryData[i] = {
                                                    amount = v.amount,
                                                    ItemName = vRP.getItemName({i}),
                                                    Weight = vRP.getItemWeight({i})
                                                }
                                            end
                                            local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or 1500
                                            TriggerClientEvent(
                                                "Nova:SendSecondaryInventoryData",
                                                source,
                                                FormattedInventoryData,
                                                vRP.computeItemsWeight({cdata}),
                                                maxVehKg
                                            )
                                            TriggerEvent("Nova:RefreshInventory", source)
                                            InventoryCoolDown[source] = nil
                                            vRP.setSData({carformat, json.encode(cdata)})
                                        else
                                            InventoryCoolDown[source] = nil
                                            vRPclient.notify(source, {"~r~You do not have enough inventory space."})
                                        end
                                    else
                                        InventoryCoolDown[source] = nil
                                        vRPclient.notify(
                                            source,
                                            {"~r~You are trying to move more then there actually is!"}
                                        )
                                    end
                                end
                            }
                        )
                    else
                        InventoryCoolDown[source] = nil
                        print(
                            "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                                UserId ..
                                    " This is usually caused by cheating as the item does not exist in the car boot."
                        )
                    end
                end
            end
        else
            InventoryCoolDown[source] = nil
            print(
                "[^7JamesUKInventory]^1: An error has occured while trying to move an item. Inventory data from: " ..
                    UserId .. " This may be a saving / loading data error you will need to investigate this."
            )
        end
    end
)

-- LOOTBAGS CODE BELOW HERE

RegisterNetEvent("vRP:InComa")
AddEventHandler(
    "vRP:InComa",
    function()
        local source = source
        vRPclient.isInComa(
            source,
            {},
            function(in_coma)
                if in_coma then
                    Wait(1500)
                    local user_id = vRP.getUserId({source})
                    local model = GetHashKey("xs_prop_arena_bag_01")
                    local name1 = GetPlayerName(source)
                    local lootbag =
                        CreateObjectNoOffset(model, GetEntityCoords(GetPlayerPed(source)) + 0.4, true, true, false)
                    local lootbagnetid = NetworkGetNetworkIdFromEntity(lootbag)
                    LootBagEntities[lootbagnetid] = {lootbag, lootbag, false, source}
                    LootBagEntities[lootbagnetid].Items = {}
                    LootBagEntities[lootbagnetid].name = name1
                    local ndata = vRP.getUserDataTable({user_id})
                    local stored_inventory = nil
                    if ndata ~= nil then
                        if ndata.inventory ~= nil then
                            stored_inventory = ndata.inventory
                            vRP.clearInventory({user_id})
                            for k, v in pairs(stored_inventory) do
                                LootBagEntities[lootbagnetid].Items[k] = {}
                                LootBagEntities[lootbagnetid].Items[k].amount = v.amount
                            end
                        end
                    end
                end
            end
        )
    end
)

Citizen.CreateThread(
    function()
        while true do
            Wait(250)
            for i, v in pairs(LootBagEntities) do
                if v[5] then
                    local coords = GetEntityCoords(GetPlayerPed(v[5]))
                    local objectcoords = GetEntityCoords(v[1])
                    if #(objectcoords - coords) > 2.0 then
                        CloseInv(v[5])
                        Wait(3000)
                        v[3] = false
                        v[5] = nil
                    end
                end
            end
        end
    end
)

RegisterNetEvent("Nova:CloseLootbag")
AddEventHandler(
    "Nova:CloseLootbag",
    function()
        local source = source
        for i, v in pairs(LootBagEntities) do
            if v[5] and v[5] == source then
                CloseInv(v[5])
                Wait(3000)
                v[3] = false
                v[5] = nil
            end
        end
    end
)

function CloseInv(source)
    TriggerClientEvent("Nova:InventoryOpen", source, false, false)
end

function OpenInv(source, netid, LootBagItems)
    local UserId = vRP.getUserId({source})
    local data = vRP.getUserDataTable({UserId})
    if data and data.inventory then
        local FormattedInventoryData = {}
        for i, v in pairs(data.inventory) do
            FormattedInventoryData[i] = {
                amount = v.amount,
                ItemName = vRP.getItemName({i}),
                Weight = vRP.getItemWeight({i})
            }
        end
        TriggerClientEvent(
            "Nova:FetchPersonalInventory",
            source,
            FormattedInventoryData,
            vRP.computeItemsWeight({data.inventory}),
            vRP.getInventoryMaxWeight({UserId})
        )
        InventorySpamTrack[source] = false
    else
        print(
            "[^7JamesUKInventory]^1: An error has occured while trying to fetch inventory data from: " ..
                UserId .. " This may be a saving / loading data error you will need to investigate this."
        )
    end
    TriggerClientEvent("Nova:InventoryOpen", source, true, true)
    local FormattedInventoryData = {}
    for i, v in pairs(LootBagItems) do
        FormattedInventoryData[i] = {
            amount = v.amount,
            ItemName = vRP.getItemName({i}),
            Weight = vRP.getItemWeight({i})
        }
    end
    local maxVehKg = 200
    TriggerClientEvent(
        "Nova:SendSecondaryInventoryData",
        source,
        FormattedInventoryData,
        vRP.computeItemsWeight({LootBagItems}),
        maxVehKg
    )
    print(json.encode(FormattedInventoryData))
end

-- Garabge collector for empty lootbags.
Citizen.CreateThread(
    function()
        while true do
            Wait(500)
            for i, v in pairs(LootBagEntities) do
                local itemCount = 0
                for i, v in pairs(v.Items) do
                    itemCount = itemCount + 1
                end
                if itemCount == 0 then
                    if DoesEntityExist(v[1]) then
                        DeleteEntity(v[1])
                        --print('Deleted Lootbag')
                        LootBagEntities[i] = nil
                    end
                end
            end
            --print('All Lootbag garbage collected.')
        end
    end
)
