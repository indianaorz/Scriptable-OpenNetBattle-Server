local stage = include("stage/stage.lua")

local DAMAGE = 0

stage.type = 2

stage.codes = {"Z"}
stage.shortname = "Snctuary"
stage.damage = DAMAGE
stage.time_freeze = true
stage.element = Element.None
stage.description = "Turn your\npnls into\nHolyPnls!"
stage.long_description = "Turn all your panels into HolyPanels!"
stage.can_boost = false
stage.card_class = CardClass.Standard
stage.limit = 1
stage.mb = 62

function package_init(package)
    package:declare_package_id("com.OFC.card.EXE6-171-Sanctuary")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes(stage.codes)

    local props = package:get_card_props()
    props.shortname = stage.shortname
    props.damage = stage.damage
    props.time_freeze = stage.time_freeze
    props.element = stage.element
    props.description = stage.description
    props.long_description = stage.long_description
    props.can_boost = stage.can_boost
	props.card_class = stage.card_class
	props.limit = stage.limit
end

card_create_action = stage.card_create_action