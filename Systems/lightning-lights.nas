# Control Lightning Lights

# Initialise properties
setprop("sim/model/lightning/lights/nav_lights",0);

#Flasher borrowed from Concorde and heavily modified
NavLights = func {
	switch = getprop("controls/switches/nav_lights");
	light = getprop("sim/model/lightning/lights/nav_lights");
	volts = getprop("systems/electrical/outputs/nav_lights");
	
	# Off
	if (switch == "0" or switch == "nil") {
		setprop ("sim/model/lightning/lights/nav_lights",0);
	}
	# Steady
	elsif (switch == "-1" ) {
		setprop ("sim/model/lightning/lights/nav_lights",volts);
		settimer(Lightning.NavLights, 2);
	}
	# Flashing
	elsif (switch > "0") {
	   if( light == nil or light == "0") {
       light = "1";
       lightsec = 3;
	   }
	   else {
	       light = "0";
	       lightsec = 6;
	   }
	   value = volts*light;
	   setprop("sim/model/lightning/lights/nav_lights",value);

	   # re-schedule the next call
		settimer(Lightning.NavLights, lightsec);
	}

} #End Func	
setlistener("controls/switches/nav_lights", NavLights);

