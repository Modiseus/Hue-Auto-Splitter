state("Hue"){
	//SaveLoadManager
	string255 currentLevel : "Hue.exe", 0x00F57860, 0x1C, 0x14, 0x14, 0xC;
	int currentLevel_address : "Hue.exe", 0x00F57860, 0x1C, 0x14, 0x14;
	int lastDoor : "Hue.exe", 0x00F57860, 0x1C, 0x14, 0x34;	
	int coloursUnlocked : "Hue.exe", 0x00F57860, 0x1C, 0x14, 0x38;
	int collectiblesUnlocked : "Hue.exe", 0x00F57860, 0x1C, 0x14, 0x3c;
	//GameManager
	bool isInCutscene : "Hue.exe", 0x00F0799C, 0x8, 0x0, 0x10, 0x4, 0x4C, 0x38, 0x51;
	string255 currentLevelName: "Hue.exe", 0x00F0799C, 0x8, 0x0, 0x10, 0x4, 0x4C, 0x38, 0x44, 0xC;
	//isLoading Info
	int loadingEnum : "Hue.exe", 0x00F0456C, 0xF0, 0x384, 0x8, 0x50, 0x204, 0x10, 0x18, 0x8, 0x18;
}

startup{
	// Other levels can be added here: (levelname, door, enabled)
	vars.levels = new Tuple<string,int, bool>[]{
		new Tuple<string,int, bool>( "Village", 0, true),
		new Tuple<string,int, bool>( "Courtyard1", 0, true),
		new Tuple<string,int, bool>( "Courtyard2", 0, true),
		new Tuple<string,int, bool>( "Courtyard3", 0, true),
		new Tuple<string,int, bool>( "UniRooftop", 0, true),
		new Tuple<string,int, bool>( "UniversityOutside", 1, true)
	};

	//Tuples for colour slices
	vars.colourSlices = new Tuple<int,String>[]{
		new Tuple<int,string>( 2, "Aqua"),
		new Tuple<int,string>( 5, "Purple"),
		new Tuple<int,string>( 8, "Orange"),
		new Tuple<int,string>( 6, "Pink"),
		new Tuple<int,string>( 7, "Red"),
		new Tuple<int,string>( 3, "Blue"),
		new Tuple<int,string>( 9, "Yellow"),
		new Tuple<int,string>( 0, "Lime")
	};
	settings.Add("colours", true, "Colour Slices");
	settings.CurrentDefaultParent = "colours";
	foreach(var colour in vars.colourSlices){
		settings.Add(colour.Item2, true, colour.Item2);
	}
	
	settings.CurrentDefaultParent = null;
	settings.Add("level", true, "Levels");
	settings.CurrentDefaultParent = "level";
	settings.Add("IntroDream", true, "IntroDream");
	foreach(var level in vars.levels){
		settings.Add( level.Item1, level.Item3, level.Item1 );
	}
	settings.CurrentDefaultParent = null;
	settings.Add("beaker", false, "Beaker pickups");
	settings.Add("end", true, "Finish game");
	settings.CurrentDefaultParent = "level";
	settings.CurrentDefaultParent = null;
	
	vars.lastColourSplit = 0;
}

start{
	if( current.currentLevel_address != old.currentLevel_address || current.lastDoor != old.lastDoor ){
		if( current.currentLevel == "IntroDream" && current.lastDoor == -1 ){
			return true;
		}
	}
	return false;
}

onStart{
	vars.lastColourSplit = 0;
}

split{
	// Split after collecting a colour slice
	foreach( var colour in vars.colourSlices){
		if(settings[colour.Item2]){
			int mask = 1 << colour.Item1;
			bool currentUnlocked = Convert.ToBoolean(current.coloursUnlocked & mask);
			bool oldUnlocked = Convert.ToBoolean((vars.lastColourSplit | old.coloursUnlocked) & mask);

			if(currentUnlocked && !oldUnlocked){
				vars.lastColourSplit = current.coloursUnlocked;
				return true;
			}
		}
	}

	// Split after entering a level
	if(current.currentLevel != old.currentLevel || current.lastDoor != old.lastDoor){
		foreach(var level in vars.levels){
			if(settings[level.Item1] && current.currentLevel == level.Item1 && current.lastDoor == level.Item2){
				return true;
			}
		}
	}

	//Split after completing IntroDream
	if(settings["IntroDream"] && current.isInCutscene && !old.isInCutscene && current.currentLevelName == "IntroDream"){
		return true;
	}
	
	// Split after finishing the game
	if( settings["end"] && current.currentLevel == "OutroDream" && current.lastDoor == -1 ){
		if( current.isInCutscene != old.isInCutscene ){
			// split when entering cutscene at the end
			return true;
		}
	}
	//Split on beakers
	if (settings["beaker"] && old.collectiblesUnlocked != current.collectiblesUnlocked){
		return true;
	}
	return false;
}

reset{
	if( current.currentLevel_address != old.currentLevel_address || current.lastDoor != old.lastDoor ){
		if( current.currentLevel == "IntroDream" && current.lastDoor == -1 ){
			return true;
		}
	}
	return false;
}

isLoading{
    return current.loadingEnum == 1;
}
