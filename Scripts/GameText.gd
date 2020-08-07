extends Node

var displayIndex = 0
var startTime
var elapsedTime = 0

var globalTextSpeed = 0.100

var Levels;
var Introduction;
var currScriptNum = 0;
var currLevelNum = 0;
var currLevel;
var currScript;
var currLine;

var Option = preload ("res://Scenes/Option.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Levels = list_files_in_directory("res://Dialogue/")
	currLevel = list_files_in_directory(str("res://Dialogue/", Levels[currLevelNum]))
	currScript = load_script(str("res://Dialogue/", Levels[currLevelNum], "/", currLevel[currScriptNum]))
	print (currScript)
	currLine = "."
	SetOptions ()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	DrawText(currScript.get(currLine)[0], delta)

# Draws Text to the screen
func DrawText (s, delta):
	elapsedTime += delta
	if (fmod(int(elapsedTime), globalTextSpeed) == 0 && displayIndex < s.length()):
		displayIndex+=1
	get_parent().get_node("GameText").set_text (s.substr(0, displayIndex))

# Creates the options nodes
func SetOptions ():
	var options_text = currScript.get(currLine)[1]
	var options = options_text.substr(1, options_text.length()-2).split('|') # Options array for all the individual options
	var i = 1
	if (options.size() > 1):
		for option in options:
			var option_node = Option.instance()
			option_node.option_text = option
			option_node.lead = i
			$'../../OptionsContainer/VBox'.add_child(option_node);
			i+=1
	else:
		var option_node = Option.instance()
		option_node.option_text = options[0]
		$'../../OptionsContainer/VBox'.add_child(option_node);

# Clears all the nodes in the options
func ClearOptions ():
	for node in $'../../OptionsContainer/VBox'.get_children():
		 $'../../OptionsContainer/VBox'.remove_child(node)

# Goes to the next line based of the lead
func NextLine (lead):
	currLine += str(lead)
	displayIndex = 0;
	elapsedTime = 0;
	ClearOptions()
	SetOptions()
	yield(get_tree().create_timer(1), "timeout")

# Jumps to a specific line
func JumpLine (jump):
	currLine = jump
	displayIndex = 0;
	elapsedTime = 0;
	ClearOptions()
	SetOptions()
	yield(get_tree().create_timer(1), "timeout")

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
# Loads all of the dialogues in the /Dialogue folder
func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files

# Loads the script into a dictionary
func load_script(file):

	var script = {};

	var f = File.new()
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line() # a string for the indivudual line
		var splitLine = StripTab(line).split(' ')
		var addr = splitLine[0]
		var text = StripTab(line).split(' ')
		text.remove(0) # Removes the address
		text.remove(text.size() - 1) # Removes the options
		text = text.join(' ')
		var options = splitLine[splitLine.size() - 1]
		script[addr] = [text, options]
	f.close()
	return script

# Strips the tabs from the start of a line of dialogue
func StripTab (s):
#	return s
	return s.substr (s.find("."))
