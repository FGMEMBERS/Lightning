# Extraneous bits and pieces

### Reset values after crash ###

crashReset = func{
	
	Lightning.initialize();
	Lightning.init_electrical();

}

setlistener("sim/signals/reinit", crashReset);

# dialogues =======================================================
dialog = nil;

showDialog = func {
	name = "lightning-config";
	if (dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		dialog = nil;
		return;
	}
	dialog = gui.Widget.new();
	dialog.set("layout", "vbox");
	dialog.set("name", name);
	dialog.set("x", -40);
	dialog.set("y", -40);

	# "window" titlebar
	titlebar = dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Lightning configuration");
	titlebar.addChild("empty").set("stretch", 1);

	dialog.addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("Lightning.dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	checkbox = func {
		group = dialog.addChild("group");
		group.set("layout", "hbox");
		group.addChild("empty").set("pref-width", 4);
		box = group.addChild("checkbox");
		group.addChild("empty").set("stretch", 1);

		box.set("halign", "left");
		box.set("label", arg[0]);
		box;
	}

	# External Power
	w = checkbox("External Power");
	w.set("property", "systems/electrical/suppliers/external");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	# Braking Chute
	group = dialog.addChild("group");
	group.set("layout", "vbox");
	group.addChild("empty").set("pref-width", 4);

	w = group.addChild("button");
	w.set("halign", "center");
	w.set("legend", "Repack Chute");
	w.set("pref-width", 130);
	w.set("pref-height", 24);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("Lightning.chuteRepack()");

	# Fuel
	w = group.addChild("button");
	w.set("halign", "center");
	w.set("legend", "Refit ventral tank");
	w.set("pref-width", 130);
	w.set("pref-height", 24);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("Lightning.ventralRefit()");

	w = group.addChild("button");
	w.set("halign", "center");
	w.set("legend", "Refill Tanks");
	w.set("pref-width", 130);
	w.set("pref-height", 24);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("Lightning.refuel()");

	# Undercarriage reset
	w = group.addChild("button");
	w.set("halign", "center");
	w.set("legend", "Emergency u/c reset");
	w.set("pref-width", 130);
	w.set("pref-height", 24);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("Lightning.emergencyGearDown(0)");

	group = dialog.addChild("group");
	group.set("layout", "vbox");
	group.addChild("empty").set("pref-width", 4);

#	w = group.addChild("text");
#	w.set("halign", "left");
#	w.set("label", "X");
#	w.set("pref-width", 200);
#	w.set("property", "sim/model/bo105/weapons/ammunition");
#	w.set("live", 1);
#
	group.addChild("empty").set("stretch", 1);

	# finale
	dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", dialog.prop());
	gui.showDialog(name);
}
