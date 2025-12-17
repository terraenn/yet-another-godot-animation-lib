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
static func create_animation_helper(_def_node : CanvasItem = null) -> AnimationHelper:
	var ah : AnimationHelper = AnimationHelper.new()
	if _def_node: 
		ah.def_node = _def_node
	return ah

static func create_tween() -> Tween:
	return Engine.get_main_loop().root.create_tween()

func set_trans(value : Tween.TransitionType) -> AnimationHelper:
	def_trans = value
	return self

func set_ease(value : Tween.EaseType) -> AnimationHelper:
	def_ease = value
	return self

func set_time_multi(value : float) -> AnimationHelper:
	time_multiplier = value
	return self

#endregion

#region ANIMATIONS
## Pulses a [float] value using sine.
## [br]Put this in the _process method of a node to work.
## [br]Supports [Vector2] x and y values as well.
## To pulse those, format the property string like you would a [NodePath] - "position:x", "scale:y", etc.
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
				var value : Variant =\
				 Vector2(sin(time * speed) * multiplier + min_value, node.get(truncated_property).y)
				if truncated_property == "scale":
					value = abs(value)
				node.set(truncated_property,
				 value as Vector2 if node.get(truncated_property) is Vector2 else value as Vector2)
			elif end == ":y":
				var value : Variant =\
				 Vector2(node.get(truncated_property).x, sin(time * speed) * multiplier + min_value)
				if truncated_property == "scale":
					value = abs(value)
				node.set(truncated_property,
				 value as Vector2 if node.get(truncated_property) is Vector2 else value as Vector2)
			else:
				push_error("Property string was Vector2, but the end was neither :x or :y.")
			return
	else:
		node.set(property, sin(time * speed) * multiplier + min_value)

#func pulse_float(
	#property : String,
	#node : CanvasItem = def_node,
	#min_value : float = 0,
	#speed : float = 1,
	#multiplier : float = 1,
#) -> void:
	#pulse(property, node, min_value as float, speed as float, multiplier as float)

#func pulse_int(
	#property : String,
	#node : CanvasItem = def_node,
	#min_value : int = 0,
	#speed : float = 1,
	#multiplier : float = 1,
#) -> void:
	#pulse(property, node, min_value as int, speed as int, multiplier as int)

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
#endregion
