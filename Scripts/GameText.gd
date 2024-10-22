extends Node

var textExtension = '.txt'
var audioExtension = '.wav'

var displayIndex = 0
var startTime
var elapsedTime = 0
var cooldowns = {}
var pause = 0

var globalTextSpeed = 0.025

var Levels;
var Introduction;
var currScriptNum = 1;
var currLevelNum = 0;
var currLevel;
var currScript;
var currLine;

onready var BGMStream = $"/root/Game/BGMStream"
onready var VOStream = $"/root/Game/VOStream"
onready var TextStream = $"/root/Game/TextStream"
onready var OptionsNode = $'../../UIContainer/HBox/Options'
onready var SanityNode = $'../../UIContainer/HBox/StatusBars/Sanity/Bar'

var voPath = ""
var voIndex = 0
var isVO = false

var StopAudio

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
	print (self.get_path())
	cooldowns[globalTextSpeed] = -1
	cooldowns[globalDecSpeed] = -1
	
	Levels = list_files_in_directory("res://Dialogue/")
	SetScript ()
	print (currScript)
	currLine = "."
	SetOptions ()
	RunArgs()
	
func SetScript ():
	currLevel = list_files_in_directory(str("res://Dialogue/", Levels[currLevelNum]))
	print (currLevel)
	currScript = load_script(str("res://Dialogue/", Levels[currLevelNum], "/", currLevel[currScriptNum]))

func GetScriptNum (s):
	var i = 0
	for level in currLevel:
		if (level == str(s, textExtension)):
			return i
		i+=1
	return -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	elapsedTime += delta
	DrawText(currScript.get(currLine)[0])
	if (isVO && displayIndex == voIndex):
		PlayVO(voPath)
	ModSanity()

# runs the line-specific arguments
func RunArgs():
	var args = currScript.get(currLine)[2]
	if (args.length() >= 1):
		for arg in args.split (' '):
			# The audio argument for a specific line
			if (arg.substr(0, 2) == "-a"): # -a(vo5)
				var aArgs = ""
				if (arg.split('(').size() > 1):
					aArgs = arg.split('(')[1].split(')')[0]
				var lineToPath = currLine.replace (".", "0")
				if (aArgs.length() > 0):
					# Checks to see if there is a specific VO line
					if (aArgs.split(':').size() > 1):
						var filePath = str("res://Audio/", Levels[currLevelNum], "/", currLevel[currScriptNum].split(textExtension)[0], "/", lineToPath, "_VO", audioExtension)
						var i = int(aArgs.split(':')[1]) - currLine.length()
						SetVO(filePath, i)
					# Checks to see if it should start continuous audio
					elif (aArgs.substr(0, 1) == 'c'):
						var filePath = str("res://Audio/", Levels[currLevelNum], "/", currLevel[currScriptNum].split(textExtension)[0], "/", lineToPath, audioExtension)
						PlayAudio (filePath)
						StopAudio = false
					# Checks to see if audio should be stopped upon next line or not
					elif (aArgs.substr(0,1) == 's'):
						StopAudio = true
				else:
					var filePath = str("res://Audio/", Levels[currLevelNum], "/", currLevel[currScriptNum].split(textExtension)[0], "/", lineToPath, audioExtension)
					PlayAudio (filePath)

func PlayAudio(path):
	BGMStream.set_stream(load(path))
	BGMStream.volume_db = 1
	BGMStream.pitch_scale = 1
	BGMStream.play()

func SetVO (path, i):
	voPath = path
	voIndex = int(i)
	isVO = true
	
func PlayVO(path):
	isVO = false
	print (path)
	VOStream.set_stream(load(path))
#	VOStream.volume_db = 1
#	VOStream.pitch_scale = 1
	VOStream.play()
	print ("Played!")

func TextAudio ():
	TextStream.play()

func StopAllAudio():
	if (StopAudio):
		BGMStream.stop()
		VOStream.stop()
	else:
		pass

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
	if (GetInverval (globalTextSpeed) && displayIndex < s.length()): # Only draws text on intervals of 0.125 seconds
		displayIndex+=1
		# Plays the typewriter sound effect every x indecies, or whenever there is punctuation.
		if (displayIndex % 4 == 0 ||  isPunctuation (s.substr(0, displayIndex), s.length())):
			TextAudio()
		if (s.substr(displayIndex-1, displayIndex+1) == "\n"): # If there is a line break, add one to displayIndex to not have the \ appear
			displayIndex+=1
	get_parent().get_node("GameText").set_text (tr(s.substr(0, displayIndex)).c_unescape()) # c_unescape allows linebreaks to function properly
	if (pause <= 0 && isPunctuation (s.substr(0, displayIndex), s.length())):
		pause = 0.625

func isPunctuation (s, slen):
	if (s.length() != slen && s.length() != 0):
		return (
				s.rfind (".") == s.length() - 1 || 
				s.rfind ("!") == s.length() - 1 || 
				s.rfind ("?") == s.length() - 1 ||
				s.rfind (",") == s.length() - 1 ||
				s.rfind (";") == s.length() - 1 ||
				s.rfind ('"') == s.length() - 1
			)
	return false

# Decreases sanity over time if sanDec is not 0
func ModSanity():
	if (GetInverval(globalDecSpeed)):
		if (sanDec < 0):
			sanity -= 0.5
			sanDec += 0.5
		elif (sanDec > 0):
			sanity += 1
			sanDec -= 1
		if (sanDec != 0):
			SanityNode.value = sanity

# Creates the options nodes
func SetOptions ():
	var options_text = currScript.get(currLine)[1] # the current dialogue options
	var options = options_text.split('|') # Options array for all the individual options
	var i = 1
	if (options.size() > 1): # If there is more than one option, create numbered leads for the different options
		for option in options:
			var option_node = Option.instance()
			option_node.option_text = option
			# If there is a (dl) after the option, keep the default lead, otherwise give a numbered lead
			if (option.split('(').size() > 1 && option.split('(')[1].substr(0, 2) == 'dl'):
				option_node.lead = '.'
			else:
				option_node.lead = i
			OptionsNode.add_child(option_node);
			i+=1
	else: # If only one option, keep the default lead
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
		StopAllAudio()
		yield(get_tree().create_timer(1), "timeout")
		RunArgs()
		
# Jumps to a specific line
func JumpLine (jump):
	if (pause <= 0):
		currLine = jump
		displayIndex = 0;
#		elapsedTime = 0;
		ClearOptions()
		SetOptions()
		StopAllAudio()
		yield(get_tree().create_timer(1), "timeout")
		RunArgs()

func JumpFile (jump):
	if (pause <= 0):
		currLevelNum = int(jump[0])
		currScriptNum = GetScriptNum(jump[1])
		SetScript()
		currLine = jump[2]
		displayIndex = 0;
#		elapsedTime = 0;
		ClearOptions()
		SetOptions()
		StopAllAudio()
		yield(get_tree().create_timer(1), "timeout")
		RunArgs()

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
	
	files.sort()

	return files

# Loads the script into a dictionary
func load_script(file):

	var script = {};

	var f = File.new()
	f.open(file, File.READ)
	while not f.eof_reached(): # iterate through all lines until the end of file is reached
		var line = f.get_line() # a string for the indivudual line
		if (line.substr(0, 1) == "#"): # If a # is found at the start, skip the line since its a comment line
			continue
		elif (line.rfind ('[') == -1): # Skips blank lines
			continue
		var options = line.split('[')[1].split(']')[0]
		var splitLine = StripTab(line).split(' ') # A split by ' '
		var addr = splitLine[0] # The address of the individual line of text
		var text = StripTab(line).split(' ') # The actual dialogue text to be displayed on screen
		text.remove(0) # Removes the address
		var cut = 1; # How much to cut off the end to get the line of dialogue
		var opSize = options.split(" ").size()
		if (line.rfind ("-a") != -1): # If the audio argument is found, add one to cut
			cut += 1
		for i in range (0, cut + opSize - 1):
			text.remove(text.size() - 1) # Removes the options and arguments
		text = text.join(' ') # Joins the text
		# For however many arguments exist, add them to the arguments string
		var args = ""
		if (cut != 1):
			for i in range (1, cut):
				args += splitLine[splitLine.size() - i]
		script[addr] = [text, options, args]
	f.close()
	return script

# Strips the tabs from the start of a line of dialogue
func StripTab (s):
	return s.substr (s.find("."))
