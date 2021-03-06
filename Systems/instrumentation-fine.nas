# $Id$

# ==================================== timer stuff =========================================

# set the update period

var UPDATE_PERIOD = 0;

# set the timer for the selected function

var registerTimer = func {

	settimer(gmeterUpdate, UPDATE_PERIOD);
	settimer(setRPM, UPDATE_PERIOD);
	settimer(icewarn, UPDATE_PERIOD);
	settimer(gearLights, UPDATE_PERIOD);
	settimer(func {navdisplay("comm")}, UPDATE_PERIOD);
	settimer(func {navdisplay("nav")}, UPDATE_PERIOD);

}

# =============================== end timer stuff ===========================================

# =============================== G-Meter stuff =============================================

var gmeterUpdate = func {

	var GCurrent = props.globals.getNode("/accelerations/pilot-g[0]").getValue();
	var GMin = props.globals.getNode("/accelerations/pilot-gmin[0]").getValue();
	var GMax = props.globals.getNode("/accelerations/pilot-gmax[0]").getValue();

	if(GCurrent < 1 and GCurrent < GMin){setprop("/accelerations/pilot-gmin[0]", GCurrent);}
	else {if(GCurrent > GMax){setprop("/accelerations/pilot-gmax[0]", GCurrent);}}

registerTimer();

}

# ====================== Standby / Master AI  ===============================

var setRPM = func{
	
	var sb_volts = getprop("/systems/electrical/outputs/standby_instruments") ;
	if (sb_volts == nil ){ sb_volts = 0;}
	if (sb_volts > 22){	rpm = 2000;	} 
	else { rpm = 0; }

	setprop("/engines/engine/rpm", rpm);

} # end function

#### Ice Warning Light - values taken from RAF "Pilot's Notes General, 3rd ed. 1946" ####
#### Any suggestions for improvement welcomed! ####

var icewarn = func {

	var temp = getprop("environment/temperature-degc");
	var volts = getprop("systems/electrical/outputs/annunciators");
	var warn = 0;

	if (temp < -1 and temp > -8 and volts > 23 ) { warn = 1 }
	else {warn = 0}

	setprop("sim/model/lightning/lights/ice_warn", warn);
	
} # End func

# ==================== Undercarriage Indicator Lights =======================

var gearLights = func {

	var volts = getprop("systems/electrical/outputs/undercarriage");
	var power = 0;
	if (volts == nil) {volts = 0}
	if (volts > 1) {power = 1}
		else {power = 0}

	var dayNight = getprop("controls/switches/dayNight");
	var changeLamps = getprop("controls/switches/changeLamps");
	var port = getprop("gear/gear[0]/position-norm");
	var nose = getprop("gear/gear[1]/position-norm");
	var stbd = getprop("gear/gear[2]/position-norm");

	var brightness = power * (dayNight + 0.5);

	# Port Leg
	if (port < 1) {
		setprop("sim/model/lightning/lights/port-red",brightness);
		setprop("sim/model/lightning/lights/port-green-1",0);
		setprop("sim/model/lightning/lights/port-green-2",0);
	} elsif (changeLamps < 1){
		setprop("sim/model/lightning/lights/port-red",0);
		setprop("sim/model/lightning/lights/port-green-1",brightness);
		setprop("sim/model/lightning/lights/port-green-2",0);
	} else {
		setprop("sim/model/lightning/lights/port-red",0);
		setprop("sim/model/lightning/lights/port-green-1",0);
		setprop("sim/model/lightning/lights/port-green-2",brightness);
	}
	# Nose Leg
	if (nose < 1) {
		setprop("sim/model/lightning/lights/nose-red",brightness);
		setprop("sim/model/lightning/lights/nose-green-1",0);
		setprop("sim/model/lightning/lights/nose-green-2",0);
	} elsif (changeLamps < 1){
		setprop("sim/model/lightning/lights/nose-red",0);
		setprop("sim/model/lightning/lights/nose-green-1",brightness);
		setprop("sim/model/lightning/lights/nose-green-2",0);
	} else {
		setprop("sim/model/lightning/lights/nose-red",0);
		setprop("sim/model/lightning/lights/nose-green-1",0);
		setprop("sim/model/lightning/lights/nose-green-2",brightness);
	}
	# Starboard Leg
	if (stbd < 1) {
		setprop("sim/model/lightning/lights/stbd-red",brightness);
		setprop("sim/model/lightning/lights/stbd-green-1",0);
		setprop("sim/model/lightning/lights/stbd-green-2",0);
	} elsif (changeLamps < 1){
		setprop("sim/model/lightning/lights/stbd-red",0);
		setprop("sim/model/lightning/lights/stbd-green-1",brightness);
		setprop("sim/model/lightning/lights/stbd-green-2",0);
	} else {
		setprop("sim/model/lightning/lights/stbd-red",0);
		setprop("sim/model/lightning/lights/stbd-green-1",0);
		setprop("sim/model/lightning/lights/stbd-green-2",brightness);
	}

} # End of Function

# ==================== Nav Radio Frequency Display  =========================

var navdisplay = func(radio) {
	var total=getprop("/instrumentation/"~radio~"[0]/frequencies/selected-mhz");
	var digit1=int(total/100);
	var digit2=int((total/10)-(10*digit1));
	var digit3=int(total-(100*digit1)-(10*digit2));
	var digit4=int(10*(total-int(total)));
	var digit5=int(10*(10*(total-int(total)))-(10*digit4));
	setprop("sim/model/lightning/radios/"~radio~"[0]/digit1",digit1);
	setprop("sim/model/lightning/radios/"~radio~"[0]/digit2",digit2);
	setprop("sim/model/lightning/radios/"~radio~"[0]/digit3",digit3);
	setprop("sim/model/lightning/radios/"~radio~"[0]/digit4",digit4);
	setprop("sim/model/lightning/radios/"~radio~"[0]/digit5",digit5);
}

####################### Initialise ##############################################

var initialize = func {
        var initialized = 0;
	
	### Initialise gmeter stuff ###
	props.globals.getNode("accelerations/pilot-g[0]", 1).setDoubleValue(1.01);
	props.globals.getNode("accelerations/pilot-gmin[0]", 1).setDoubleValue(1);
	props.globals.getNode("accelerations/pilot-gmax[0]", 1).setDoubleValue(1);
	props.globals.getNode("/sim/rendering/redout/alpha", 1).setDoubleValue(0.0);
	props.globals.getNode("/sim/rendering/redout/red", 1).setDoubleValue(0.0);
	props.globals.getNode("/sim/rendering/redout/blue", 1).setDoubleValue(0.0);
	props.globals.getNode("/sim/rendering/redout/green", 1).setDoubleValue(0.0);

	### Initialise Gear ###
	props.globals.getNode("sim/lightning/controls/gear", 1).setIntValue(1);

	### Initialise fuel stuff ###
	props.globals.getNode("instrumentation/fuel/bingo[0]", 1).setIntValue(0);
	props.globals.getNode("instrumentation/fuel/bingo[1]", 1).setIntValue(0);

	### Initialise RPM (Vacuum) stuff ###
	props.globals.getNode("engines/engine[0]/rpm", 1).setIntValue(0);

	### Initialise Ice Warning stuff ###
	props.globals.getNode("sim/model/lightning/lights/ice_warn", 1).setIntValue(0);

	### Initialise Seat stuff ###
	props.globals.getNode("sim/model/lightning/controls/seat", 1).setIntValue(0);

	### Initialise Instrumentation stuff ###
	props.globals.getNode("sim/model/lightning/controls/radarview", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/syn-knob", 1).setIntValue(0);
	props.globals.getNode("instrumentation/heading-indicator/heading-source", 1).setBoolValue(0);

	### Initialise Radio stuff ###
	props.globals.getNode("sim/model/lightning/radios/nav[0]/vol", 1).setDoubleValue(0.5);
	props.globals.getNode("sim/model/lightning/radios/comm[0]/vol", 1).setDoubleValue(0.5);

	### Initialise Chute stuff ###
	props.globals.getNode("sim/model/lightning/controls/flight/chute_open", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/chute_deployed", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/chute_jettisoned", 1).setBoolValue(0);

	### Initialise Tank stuff ###
	props.globals.getNode("sim/model/lightning/controls/tank_jettisoned_lever", 1).setIntValue(0);
	
	### Initialise Gear stuff ###
	props.globals.getNode("sim/model/lightning/controls/emergency_uc_selected", 1).setBoolValue(0);
	
	### Initialise AP stuff ###
	props.globals.getNode("sim/model/lightning/controls/flight/ap_ILS", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_glide", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_pitch", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_ry", 1).setIntValue(0);
	
	### Initialise Camera stuff ###
	props.globals.getNode("sim/model/lightning/controls/camera-start-time", 1).setIntValue(0);

	### Initialise Dialogue stuff ###
	Lightning.dialog.open();

	### Initialise Steering stuff ###
	aircraft.steering.init();
		
	registerTimer();
	# Finished Initialising
	initialized = 1;

} #end func

######################### Fire it up ############################################
setlistener("/sim/model/lightning/electrical-initialized",initialize);
