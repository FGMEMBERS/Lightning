# Extraneous bits and pieces

### Reset values after crash ###

crashReset = func{
	
	Lightning.initialize();
	Lightning.init_electrical();

}

setlistener("sim/signals/reinit", crashReset);

var dialog = gui.Dialog.new("/sim/gui/dialogs/lightning/config/dialog",
		"Aircraft/Lightning/Dialogs/config.xml");

