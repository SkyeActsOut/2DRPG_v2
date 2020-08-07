extends MarginContainer

var option_text = ""
var lead = "."
var jump = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	var args = option_text.split ("(")
	get_child(0).set_text (args[0])
	if (args.size() > 1):
		jump = args[1].substr(0, args[1].length()-2)
	print (str (option_text, " | ", lead))

func _on_Container_gui_input(event):
	if (Input.is_action_just_pressed("left click")):
		if (jump.length() > 0):
			$"../../../GameTextContainer/GameText".JumpLine(jump)
		else:
			$"../../../GameTextContainer/GameText".NextLine(lead)
