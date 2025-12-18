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
func _init() -> void:
	var process_tween := create_tween()
	process_tween.set_loops()
	process_tween.tween_callback(_we_have_process_at_home).set_delay(0.01 / Engine.get_frames_per_second() * 2)
#endregion

#region CLASS
## Create a new AnimationHelper, optionally with a default node for it to do stuff on.
static func create_animation_helper(_def_node : CanvasItem = null) -> AnimationHelper:
	var ah : AnimationHelper = AnimationHelper.new()
	if _def_node: 
		ah.def_node = _def_node
	return ah

## Helper function, creates a new [Tween].
## As this is a [RefCounted] and it doesn't have access the [SceneTree]
## directly (can't do [method Node.get_tree]),
## it uses [method Engine.get_main_loop] to try and access it.
static func create_tween() -> Tween:
	return Engine.get_main_loop().root.create_tween()

## Called every frame.
## [br]...If it feels like working correctly.
## It's really fast the at the start of the project, then it kinda evens out at 60 fps.
func _we_have_process_at_home() -> void:
	var fps := Engine.get_frames_per_second()
	@warning_ignore("unused_variable")
	var delta := 1.0 / fps
	prints("delta at home:", delta, "fps:", fps)
	def_node.position.x += delta
	pass

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
## [br]Put this in the [b]_process[/b] method of a node to work.
## [br]Supports [Vector2] x and y values as well.
## To pulse those, format the property string like you would a [NodePath] - "position:x", "scale:y", etc.
## You can pulse x and y at the same time:
## [codeblock] 
##func _process(_delta: float) -> void:
##	anim_helper.pulse("scale:x", $Sprite2D)
##	anim_helper.pulse("scale:y", $Sprite2D)[/codeblock]
## [br][b]NOTE[/b]: only accessing [member Vector2.x] and [member Vector2.y]
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

## Wrapper for [method pulse].
## Makes the node go from a Vector2 scale value to another Vector2 scale value smoothly.
## [br]Set the vector args to uniform vectors if you just want a regular pulse animation
## without stretching the sprite:
##[codeblock]
##ah.pulse_scale(Vector2(2, 2), Vector2.ONE)
##[/codeblock]
##[br]You can get some funky effects if you don't, though:
##[codeblock]
##ah.pulse_scale(Vector2(5, 1.25), Vector2.ONE, Vector2(0.3, 4.5))
##[/codeblock]
## Will make the y scale quickly bounce and slowly increase and decrease the x scale, for example.
func pulse_scale(
	to : Vector2, 
	from : Vector2,
	speed : Vector2 = Vector2.ONE,
	node : CanvasItem = def_node,
) -> void:
	pulse("scale:x", node,
	 from.x, speed.x, to.x / from.x - from.x)
	pulse("scale:y", node,
	 from.y, speed.y, to.y / from.y - from.y)

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

## Flashes to a color, then goes back to the previous modulate value.
func flash_color(
	color : Color,
	node : CanvasItem = def_node,
	duration : float = 0.3,
	trans : Tween.TransitionType = def_trans,
	use_self_modulate : bool = false,
) -> void:
	flash("modulate" if not use_self_modulate else "self_modulate", color, node, duration, trans)
#endregion
