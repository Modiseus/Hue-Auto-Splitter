state("Hue") {}

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
	
	while( ptr1 == IntPtr.Zero || ptr2 == IntPtr.Zero ){
	
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
			print("Waiting for game to boot...");
			Thread.Sleep(1000);
		}
	}
	
	print("Game started.");
	
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
		
		//print( "level: " + vars.currentLevel );
		
	}
	
}

split {
	if( vars.coloursUnlocked.Current != vars.coloursUnlocked.Old ){
		// split after collecting the colour.
		//print( vars.coloursUnlocked.Current.ToString() );
		return true;
	}
	
	if( vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old ){
		// split after entering the level
		
		//print(vars.currentLevel + ":" + vars.door.Current );
		
		if(vars.currentLevel == "UniversityOutside" && vars.door.Current == 1){
			return true;
		}
		
		if(vars.currentLevel == "Courtyard1" && vars.door.Current == 0){
			return true;
		}
		
		if(vars.currentLevel == "Courtyard2" && vars.door.Current == 0){
			return true;
		}
		
		if(vars.currentLevel == "Courtyard3" && vars.door.Current == 0){
			return true;
		}
		
		if(vars.currentLevel == "UniRooftop" && vars.door.Current == 0){
			return true;
		}
		
	}
	
	if(vars.currentLevel == "OutroDream" && vars.door.Current == -1){
		if(vars.isInCutscene.Current != vars.isInCutscene.Old){
			// split when entering cutscene at the end
			return true;
		}
	}
}

start{
	if(vars.currentLevel != vars.prevLevel || vars.door.Current != vars.door.Old){
		
		if(vars.currentLevel == "IntroDream" && vars.door.Current == -1){
			return true;
		}
		
	}
	return false;
}