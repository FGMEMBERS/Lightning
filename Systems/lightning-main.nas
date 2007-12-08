# Extraneous bits and pieces

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
