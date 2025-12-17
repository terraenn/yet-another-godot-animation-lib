## Animation library
##
## This is a collection of various helpful [Tween]/sine wrapper functions for 2D animations.
## [br]Methods that are just [code]verb(...) -> void[/code] work for all kinds of properties.
## Methods that are [code]verb_property(...) -> void[/code] are just wrappers for their respective method.
class_name AnimationHelper extends RefCounted

#region VARIABLES

# STATIC ----------------
## Time elapsed since the game started in seconds.
static var global_time : float = 0:
	get:
		return Time.get_ticks_msec() / 1000.0
# -----------------------

# DYNAMIC (GENERAL) ------
## How many seconds passed from the start to the project to the instantiation of this [RefCounted].
var init_time : float = global_time
## Time elapsed in seconds since this [RefCounted] was instantiated.
var time : float = 0:
	get:
		return (global_time - init_time) * time_multiplier
# -----------------------

# DYNAMIC (ANIMATION) ----
## [member time] is multiplied by this in its getter.
var time_multiplier : float = 1
## The default ease used for animations that use tweens.
var def_ease : Tween.EaseType = Tween.EaseType.EASE_IN_OUT
## The default trans type used for animation that use tweens.
var def_trans : Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
## The default [Node2D]/[Control] node this AnimationHelper operates on.
var def_node : CanvasItem
# ------------------------

#endregion

#region BUILT-IN
#endregion

#region CLASS
## Create a new AnimationHelper, optionally with a default node for it to do stuff on.
static func create_animation_helper(_def_node : CanvasItem = null) -> AnimationHelper:
	var ah : AnimationHelper = AnimationHelper.new()
	if _def_node: 
		ah.def_node = _def_node
	return ah

## Helper function, makes a new [Tween].
static func create_tween() -> Tween:
	return Engine.get_main_loop().root.create_tween()

## Set [member def_trans]
func set_trans(value : Tween.TransitionType) -> AnimationHelper:
	def_trans = value
	return self

## Set [member def_ease]
func set_ease(value : Tween.EaseType) -> AnimationHelper:
	def_ease = value
	return self

## Set [member time_multiplier]
func set_time_multi(value : float) -> AnimationHelper:
	time_multiplier = value
	return self

#endregion

#region ANIMATIONS
## Pulses a [float] value using sine.
## [br]Put this in the _process method of a node to work.
## [br]Supports [Vector2] x and y values as well.
## To pulse those, format the property string like you would a [NodePath] - "position:x", "scale:y", etc.
## You can pulse x and y at the same time:
## [codeblock] 
##func _process(_delta: float) -> void:
##	anim_helper.pulse("scale:x", $Sprite2D)
##	anim_helper.pulse("scale:y", $Sprite2D)[/codeblock]
## [br][b]NOTE[/b]: only accessing [member Vector2i.x] and [member Vector2i.y]
## values like that is supported. [Vector2i] isn't supported either.
func pulse(
	property : String,
	node : CanvasItem = def_node,
	min_value : float = 0,
	speed : float = 1,
	multiplier : float = 1,
) -> void:
	# this is a mess
	if property[-1] == "x" and property[-2] == ":" or property[-1] == "y" and property[-2] == ":":
		var truncated_property : StringName = property.left(property.length() - 2)
		var end : String = property[-2] + property[-1]
		if node.get(truncated_property) is Vector2:
			if end == ":x":
				var value := Vector2(sin(time * speed), node.get(truncated_property).y)
				if truncated_property == "scale":
					value.x = abs(value.x)
				value.x = value.x * multiplier + min_value
				node.set(truncated_property, value)
			elif end == ":y":
				var value := Vector2(node.get(truncated_property).x, sin(time * speed))
				if truncated_property == "scale":
					value.y = abs(value.y)
				value.y = value.y * multiplier + min_value
				node.set(truncated_property, value)
			else:
				push_error("Property string was Vector2, but the end was neither :x or :y.")
			return
	else:
		node.set(property, sin(time * speed) * multiplier + min_value)

## "Flashes" a property to a value and back.
func flash(
	property : NodePath,
	value : Variant,
	node : CanvasItem = def_node,
	duration : float = 0.3,
	trans : Tween.TransitionType = def_trans
) -> void:
	var tween := create_tween()
	var old_val : Variant = node.get(str(property))
	tween.tween_property(node, property, value, duration).set_ease(Tween.EASE_IN).set_trans(trans)
	tween.tween_property(node, property, old_val, duration).set_ease(Tween.EASE_OUT).set_trans(trans)

func flash_color(
	color : Color,
	node : CanvasItem = def_node,
	duration : float = 0.3,
	trans : Tween.TransitionType = def_trans
) -> void:
	flash("modulate", color, node, duration, trans)
#endregion
