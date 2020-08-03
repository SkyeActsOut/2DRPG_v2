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

# Called when the node enters the scene tree for the first time.
func _ready():
	Levels = list_files_in_directory("res://Dialogue/")
	currLevel = list_files_in_directory(str("res://Dialogue/", Levels[currLevelNum]))
	currScript = load_script(str("res://Dialogue/", Levels[currLevelNum], "/", currLevel[currScriptNum]))
	print (currScript)
	currLine = "."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	DrawText(currScript.get(currLine)[0], delta)

# Draws Text to the screen
func DrawText (s, delta):
	elapsedTime += delta
	if (fmod(int(elapsedTime), globalTextSpeed) == 0 && displayIndex < s.length()):
		displayIndex+=1
	get_parent().get_node("GameText").set_text (s.substr(0, displayIndex))
	
	# GET RID OF LATER; JUST AUTOSCROLLS UNTIL IT BREAKS
	if (displayIndex + 1 == s.length()):
		NextLine()

func NextLine ():
	yield(get_tree().create_timer(1.625), "timeout")
	currLine += "."
	displayIndex = 0;
	elapsedTime = 0;

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
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
		var splitLine = line.split(' ') 
		var addr = splitLine[0]
		var text = line.split(' ')
		text.remove(0) # Removes the address
		text.remove(text.size() - 1) # Removes the options
		text = text.join(' ')
		var options = splitLine[splitLine.size() - 1]
		script[addr] = [text, options]
	f.close()
	return script
