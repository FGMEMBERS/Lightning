# Extraneous bits and pieces

### Set up generic tyre smoke

var run_tyresmoke0 = 0;
var run_tyresmoke1 = 0;
var run_tyresmoke2 = 0;

var tyresmoke_0 = aircraft.tyresmoke.new(0);
var tyresmoke_1 = aircraft.tyresmoke.new(1);
var tyresmoke_2 = aircraft.tyresmoke.new(2);

setlistener("gear/gear[0]/position-norm", func {
	var gear = getprop("gear/gear[0]/position-norm");
	
	if (gear == 1 ){
		run_tyresmoke0 = 1;
	}else{
		run_tyresmoke0 = 0;
	}

	},
	1,
	0);

setlistener("gear/gear[1]/position-norm", func {
	var gear = getprop("gear/gear[1]/position-norm");
	
	if (gear == 1 ){
		run_tyresmoke1 = 1;
	}else{
		run_tyresmoke1 = 0;
	}

	},
	1,
	0);

setlistener("gear/gear[2]/position-norm", func {
	var gear = getprop("gear/gear[2]/position-norm");
	
	if (gear == 1 ){
		run_tyresmoke2 = 1;
	}else{
		run_tyresmoke2 = 0;
	}

	},
	1,
	0);

### Tyre Smoke ###
	
var tyresmoke = func {

#	print ("run_tyresmoke ",run_tyresmoke0);

	if (run_tyresmoke0)
		tyresmoke_0.update();

	if (run_tyresmoke1)
		tyresmoke_1.update();

	if (run_tyresmoke2)
		tyresmoke_2.update();

	settimer(tyresmoke, 0);

}# end tyresmoke

# == fire it up ===

tyresmoke();

### Reset values after crash ###

var crashReset = func{
	
	Lightning.initialize();
	Lightning.init_electrical();

}

setlistener("sim/signals/reinit", crashReset);

var dialog = gui.Dialog.new("/sim/gui/dialogs/lightning/config/dialog",
		"Aircraft/Lightning/Dialogs/config.xml");

aircraft.livery.init("Aircraft/Lightning/Models/Liveries",
		"sim/model/livery/variant");

var idiotStart = func{

	setprop("systems/electrical/suppliers/external",1);
	setprop("sim/model/lightning/controls/shut_down",0);
	setprop("controls/switches/battery",1);
	setprop("controls/switches/ignition",1);
	setprop("controls/switches/eng_start_master",1);
	settimer(func{Lightning.AvpinPump(0);},2);
	settimer(func{Lightning.AvpinPump(1);},2);
	settimer(func{setprop("systems/electrical/suppliers/external",0);},30);

}


