local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "Nova_RadialMenu")

--RegisterServerEvent("Nova:PoliceCheck")
--AddEventHandler("Nova:PoliceCheck", function()
--    local source = source
--    local user_id = vRP.getUserId({source})
--    if vRP.hasPermission({user_id, "police.keycard"}) then
--        MetPD = true
--    else
--        MetPD = false
--    end
--    TriggerClientEvent("Nova:PoliceClockedOn", source, MetPD)
--end)

RegisterServerEvent("serverBoot")
AddEventHandler(
    "serverBoot",
    function()
        TriggerClientEvent("openBoot", source)
    end
)
