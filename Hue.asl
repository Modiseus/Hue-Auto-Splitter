state("Hue") {}

startup{

	// Other levels can be added here:
	vars.levels = new [] {
		new { name = "UniversityOutside", door = 1},
		new { name = "Courtyard1", door = 0 },
		new { name = "Courtyard2", door = 0 },
		new { name = "Courtyard3", door = 0 },
		new { name = "UniRooftop", door = 0 }
	};

	vars.colourSlices = new []{
		new { id = 2, name = "Aqua" },
		new { id = 5, name = "Purple" },
		new { id = 8, name = "Orange" },
		new { id = 6, name = "Pink" },
		new { id = 7, name = "Red" },
		new { id = 3, name = "Blue" },
		new { id = 9, name = "Yellow" },
		new { id = 0, name = "Lime" }
	};		
	
	settings.Add( "colours", true, "Colour Slices" );
	settings.CurrentDefaultParent = "colours";
	foreach( var colour in vars.colourSlices ){
		settings.Add( colour.name, true, colour.name );
	}
	
	settings.CurrentDefaultParent = null;
	settings.Add( "level", true, "Levels" );
	settings.CurrentDefaultParent = "level";
	foreach( var level in vars.levels ){
		settings.Add( level.name, true, level.name );
	}
	
	settings.CurrentDefaultParent = null;
	settings.Add( "end", true, "Finish game" );
	
}

init {
	var ptr1 = IntPtr.Zero;
	var ptr2 = IntPtr.Zero;
	
	//SaveLoadManager
	var scanTarget1 = new SigScanTarget(0,
		"?? ?? ?? ??",
        "00 00 00 00",
		"9C 63 FF FF"
    );
	
	//GameManager
	var scanTarget2 = new SigScanTarget(0,
		"?? ?? ?? ??", 
		"00 00 00 00", 
		"4A 2F 00 00", 
		"?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ??",
		"01 00 00 00" 
	);
	
	

	foreach (var page in game.MemoryPages(true)) {
		var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
		if ( ptr2 == IntPtr.Zero ){
			ptr2 = scanner.Scan(scanTarget2);
		}
		if ( ptr1 == IntPtr.Zero ){
			ptr1 = scanner.Scan(scanTarget1);
		}			
	}
	
	if ( ptr1 == IntPtr.Zero || ptr2 == IntPtr.Zero ) {
       Thread.Sleep(1000);
	   throw new Exception();
    }
	
	print( "Game started." );
	
	vars.currentLevelMemory = new MemoryWatcher<int>( ptr1 + 0x14 );
    vars.door = new MemoryWatcher<int>( ptr1 + 0x34 );
	vars.coloursUnlocked = new MemoryWatcher<int>( ptr1 + 0x38 );

	vars.isInCutscene = new MemoryWatcher<bool>( ptr2 + 0x51 );
	 
    vars.watchers = new MemoryWatcherList() {
        vars.door,
		vars.currentLevelMemory,
		vars.coloursUnlocked,
		vars.isInCutscene
    };
	
	vars.prevLevel = "";
	vars.currentLevel = "";
}

update {
    vars.watchers.UpdateAll(game);

	vars.prevLevel = vars.currentLevel;
	if( vars.currentLevelMemory.Current != vars.currentLevelMemory.Old ){
	
		var ptr = new IntPtr( vars.currentLevelMemory.Current );
		var length = memory.ReadValue<byte>( ptr + 8 );
		vars.currentLevel = memory.ReadString( ptr + 12, length * 2 );
		
	}
	
}

split {
	
	// Split after collecting a colour slice:
	
	foreach( var colour in vars.colourSlices ){
		bool colourCurrent = ( ( vars.coloursUnlocked.Current & 1 << colour.id ) != 0 );
		bool colourOld = ( ( vars.coloursUnlocked.Old & 1 << colour.id ) != 0 );
		
		if( settings[ colour.name ] && colourCurrent && !colourOld ){
			return true;
		}
	}
	
	
	// Split after entering a level:
	
	if( vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old ){
		
		foreach( var level in vars.levels ){
			if( settings[ level.name ] && vars.currentLevel == level.name && vars.door.Current == level.door){
				return true;
			}
		}
		
	}
	
	// Split after finishing the game:
	
	if( settings["end"] && vars.currentLevel == "OutroDream" && vars.door.Current == -1 ){
		if( vars.isInCutscene.Current != vars.isInCutscene.Old ){
			// split when entering cutscene at the end
			return true;
		}
	}
}

start{

	if( vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old ){
		if( vars.currentLevel == "IntroDream" && vars.door.Current == -1 ){
			return true;
		}
	}
	return false;
}