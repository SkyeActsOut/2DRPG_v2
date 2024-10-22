extends MarginContainer

var option_text = ""
var text_args = ""
var lead = "."
var jump = ""
var repType = "none"
var repMod = 0
var sanityMod = 0
var soundFile = "none"
var clicked = false
var fileJump = []

onready var GameTextNode = $"../../../../GameTextContainer/GameText"

# Called when the node enters the scene tree for the first time.
# Based on the text inputted, the options of the text are set
func _ready():
	var text = option_text.split ("(")
	get_child(0).set_text (text[0])
	
	# If only text is available, then this does not run, therefore making it just a text leading to the next dialogue
	# Otherwise this code runs, which sets the arguments for jumps, reputation, and sanity
	if (text.size() > 1):
		var args = text[1].substr(0, text[1].length()-1).split(",")
		for arg in args:
			# Sets the jump if there is one
			if (arg.substr (0, 1) == '.'):
				jump = arg
			# Checks specifically for sanity changes
			elif (arg.substr (0, 3) == "san"):
				var sanArgs = arg.split ("-")
				var mod = -1
				if (sanArgs.size() <= 1):
					sanArgs = arg.split("+")
					mod = 1
				sanityMod = int(sanArgs[1]) * mod
			# Checks for reputation changes
			elif (arg.find ("-") != -1 || arg.find ("+") != -1):
				var repArgs = arg.split ("-")
				var mod = -1
				if (repArgs.size() <= 1):
					repArgs = arg.split("+")
					mod = 1
				repType = repArgs[0]
				repMod = int(repArgs[1])
			elif (arg.substr (0, 3) == "jmp"):
				var jmpArgs = arg.split ('>')[1].split('/')
				fileJump = jmpArgs

# Runs when the player left clicks on the option
func _on_Container_gui_input(event):
	if (Input.is_action_just_pressed("left click")):
		if (repMod != 0):
			GameTextNode.ChangeRep (repType, repMod)
		if (sanityMod != 0):
			GameTextNode.ChangeSan (sanityMod)
		if (jump.length() > 0):
			GameTextNode.JumpLine(jump)
		if (fileJump.size() != 0):
			GameTextNode.JumpFile (fileJump) 
		else:
			GameTextNode.NextLine(lead)
