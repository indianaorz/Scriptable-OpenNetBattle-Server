local invisible = include("invisible/invisible.lua")

local DAMAGE = 0

invisible.codes = {"*"}
invisible.shortname = "Invisibl"
invisible.damage = DAMAGE
invisible.time_freeze = true
invisible.element = Element.None
invisible.description = "Invisible\nfor a\nwhile"
invisible.long_description = "Become invisible for a little while. Avoid most attacks"
invisible.can_boost = false
invisible.card_class = CardClass.Standard
invisible.limit = 3
invisible.mb = 30

function package_init(package) 
    package:declare_package_id("com.OFC.card.EXE6-179-Invisible")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes(invisible.codes)

    local props = package:get_card_props()
    props.shortname = invisible.shortname
    props.damage = invisible.damage
    props.time_freeze = invisible.time_freeze
    props.element = invisible.element
    props.description = invisible.description
    props.long_description = invisible.long_description
    props.can_boost = invisible.can_boost
	props.card_class = invisible.card_class
	props.limit = invisible.limit
end

card_create_action = invisible.card_create_action