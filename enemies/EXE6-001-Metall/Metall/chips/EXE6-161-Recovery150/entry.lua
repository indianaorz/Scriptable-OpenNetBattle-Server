local recovery = include("recovery/recovery.lua")

local DAMAGE = 0

recovery.recover_hp = 150

recovery.codes = {"J","M","T"}
recovery.shortname = "Recov"..recovery.recover_hp
recovery.damage = DAMAGE
recovery.time_freeze = false
recovery.element = Element.None
recovery.description = "Recovers\n"..recovery.recover_hp.."HP"
recovery.long_description = "Recovers "..recovery.recover_hp.." HP"
recovery.can_boost = false
recovery.card_class = CardClass.Standard
recovery.limit = 3
recovery.mb = 38

function package_init(package) 
    package:declare_package_id("com.OFC.card.EXE6-161-Recovery"..recovery.recover_hp)
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes(recovery.codes)

    local props = package:get_card_props()
    props.shortname = recovery.shortname
    props.damage = recovery.damage
    props.time_freeze = recovery.time_freeze
    props.element = recovery.element
    props.description = recovery.description
    props.long_description = recovery.long_description
    props.can_boost = recovery.can_boost
	props.card_class = recovery.card_class
	props.limit = recovery.limit
end

card_create_action = recovery.card_create_action