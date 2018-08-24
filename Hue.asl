state("Hue") {}

startup{

	// Other levels can be added here: (levelname, door, enabled)
	vars.levels = new Tuple<string,int, bool>[] {
		new Tuple<string,int, bool>( "UniversityOutside", 1, true ),
		new Tuple<string,int, bool>( "Courtyard1", 0, true ),
		new Tuple<string,int, bool>( "Courtyard2", 0, true ),
		new Tuple<string,int, bool>( "Courtyard3", 0, true ),
		new Tuple<string,int, bool>( "UniRooftop", 0, true ),
		new Tuple<string,int, bool>( "Village", 0, false )
	};

	vars.colourSlices = new Tuple<int,String>[]{
		new Tuple<int,string>( 2, "Aqua" ),
		new Tuple<int,string>( 5, "Purple" ),
		new Tuple<int,string>( 8, "Orange" ),
		new Tuple<int,string>( 6, "Pink" ),
		new Tuple<int,string>( 7, "Red" ),
		new Tuple<int,string>( 3, "Blue" ),
		new Tuple<int,string>( 9, "Yellow" ),
		new Tuple<int,string>( 0, "Lime" )
	};		
	
	settings.Add( "colours", true, "Colour Slices" );
	settings.CurrentDefaultParent = "colours";
	foreach( var colour in vars.colourSlices ){
		settings.Add( colour.Item2, true, colour.Item2 );
	}
	
	settings.CurrentDefaultParent = null;
	settings.Add( "level", true, "Levels" );
	settings.CurrentDefaultParent = "level";
	foreach( var level in vars.levels ){
		settings.Add( level.Item1, level.Item3, level.Item1 );
	}
	
	settings.CurrentDefaultParent = null;
	settings.Add( "end", true, "Finish game" );
	
	
	//SaveLoadManager
	vars.targetSaveLoadManager = new SigScanTarget(0,
		"?? ?? ?? ??",
        "00 00 00 00",
		"9C 63 FF FF"
    );
	
	//GameManager
	vars.targetGameManager = new SigScanTarget(0,
		"?? ?? ?? ??", 
		"00 00 00 00", 
		"4A 2F 00 00", 
		"?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ??",
		"01 00 00 00" 
	);
}

init {
	
	ThreadStart startScan = new ThreadStart(()=>{
		print("Scan started");
		var ptr1 = IntPtr.Zero;
		var ptr2 = IntPtr.Zero;
	
		while( ptr1 == IntPtr.Zero || ptr2 == IntPtr.Zero ){
			foreach (var page in game.MemoryPages(true)) {
				var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
				if ( ptr2 == IntPtr.Zero ){
					ptr2 = scanner.Scan(vars.targetGameManager);
				}
				if ( ptr1 == IntPtr.Zero ){
					ptr1 = scanner.Scan(vars.targetSaveLoadManager);
				}	
			}
			if( ptr1 == IntPtr.Zero || ptr2 == IntPtr.Zero ){
				print("Not found yet.");
				Thread.Sleep(1000);
			}
		}
		
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
	
		print("Scan finished");
	});
	
	Thread thread = new Thread(startScan);
	thread.Start();
	
	vars.watchers = null;
	vars.prevLevel = "";
	vars.currentLevel = "";
}

update {
	//Wait for Scan to finish:
	if(vars.watchers == null){
		return false;
	}

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
	
		bool colourCurrent = ( ( vars.coloursUnlocked.Current & 1 << colour.Item1 ) != 0 );
		bool colourOld = ( ( vars.coloursUnlocked.Old & 1 << colour.Item1 ) != 0 );
		
		if( settings[ colour.Item2 ] && colourCurrent && !colourOld ){
			return true;
		}
	}
	
	
	// Split after entering a level:
	
	if( vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old ){
		
		foreach( var level in vars.levels ){
			if( settings[ level.Item1 ] && vars.currentLevel == level.Item1 && vars.door.Current == level.Item2){
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
	
	return false;
}

start{

	if( vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old ){
		if( vars.currentLevel == "IntroDream" && vars.door.Current == -1 ){
			return true;
		}
	}
	return false;
}