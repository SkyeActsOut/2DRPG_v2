extends Node

var displayIndex = 0
var startTime
var elapsedTime = 0
var cooldowns = {}
var pause = 0

var globalTextSpeed = 0.0125

var Levels;
var Introduction;
var currScriptNum = 0;
var currLevelNum = 0;
var currLevel;
var currScript;
var currLine;

onready var OptionsNode = $'../../UIContainer/HBox/Options'
onready var SanityNode = $'../../UIContainer/HBox/StatusBars/Sanity/Bar'

# A dictionary of all the individual reputations the player can have
# Your overall / general reputation is simply gen
var reputation = { 
	"gen": 50
} 

var sanDec = 0;
var globalDecSpeed = 0.25
var sanity = 100; # The players sanity

var Option = preload ("res://Scenes/Option.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	cooldowns[globalTextSpeed] = -1
	cooldowns[globalDecSpeed] = -1
	
	Levels = list_files_in_directory("res://Dialogue/")
	currLevel = list_files_in_directory(str("res://Dialogue/", Levels[currLevelNum]))
	currScript = load_script(str("res://Dialogue/", Levels[currLevelNum], "/", currLevel[currScriptNum]))
	print (currScript)
	currLine = "."
	SetOptions ()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsedTime += delta
	DrawText(currScript.get(currLine)[0])
	ModSanity()

func GetInverval (speed):
	var currTime = stepify(elapsedTime, speed)
	if (pause <= 0):
		if (currTime == cooldowns[speed]):
			return false
		else:
			cooldowns[speed] = currTime
			return true
	else:
		pause -= globalTextSpeed
		return false

# Draws Text to the screen
func DrawText (s):
	# Checks puncuation
	if (GetInverval (globalTextSpeed) && displayIndex < s.length()): # Only draws text on intervals of 0.125 seconds
		displayIndex+=1
	get_parent().get_node("GameText").set_text (s.substr(0, displayIndex))
	if (pause <= 0 && isPunctuation (s.substr(0, displayIndex), s.length())):
		pause = 0.625

func isPunctuation (s, slen):
	print (s.rfind ("!"))
	print (s.length())
	if (s.length() != slen && s.length() != 0):
		return (
				s.rfind (".") == s.length() - 1 || 
				s.rfind ("!") == s.length() - 1 || 
				s.rfind ("?") == s.length() - 1 ||
				s.rfind (",") == s.length() - 1
			)
	return false

# Decreases sanity over time if sanDec is not 0
func ModSanity():
	if (GetInverval(globalDecSpeed)):
		if (sanDec < 0):
			sanity -= 0.5
			sanDec += 0.5
			print (sanDec)
		elif (sanDec > 0):
			sanity += 1
			sanDec -= 1
			print (sanDec)
		if (sanDec != 0):
			SanityNode.value = sanity

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
			OptionsNode.add_child(option_node);
			i+=1
	else:
		var option_node = Option.instance()
		option_node.option_text = options[0]
		OptionsNode.add_child(option_node);

# Clears all the nodes in the options
func ClearOptions ():
	for node in OptionsNode.get_children():
		 OptionsNode.remove_child(node)

# Goes to the next line based of the lead
func NextLine (lead):
	if (pause <= 0):
		currLine += str(lead)
		displayIndex = 0;
#		elapsedTime = 0;
		ClearOptions()
		SetOptions()
		yield(get_tree().create_timer(1), "timeout")
		
# Jumps to a specific line
func JumpLine (jump):
	if (pause <= 0):
		currLine = jump
		displayIndex = 0;
#		elapsedTime = 0;
		ClearOptions()
		SetOptions()
		yield(get_tree().create_timer(1), "timeout")

func ChangeRep (rep, amount):
	print (str("Changing rep of type ", rep, " by ", amount))
	reputation[rep] += amount
func ChangeSan (amount):
	print (str("Changing Sanity by ", amount))
	sanDec += amount
#	SanityNode.value += amount

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
	return s.substr (s.find("."))
