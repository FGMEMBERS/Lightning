# ==================================== timer stuff =========================================

# set the update period

var UPDATE_PERIOD = 0.5;
var UPDATE_PERIOD_FINE = 0.1;
var UPDATE_PERIOD_NIL = 0.0;

# set the timer for the selected function

var registerTimerControls = func {

    settimer(arg[0], UPDATE_PERIOD);
}

var registerTimerControlsFine = func {

    settimer(arg[0], UPDATE_PERIOD_FINE);
}

var registerTimerControlsNil = func {

    settimer(arg[0], UPDATE_PERIOD_NIL);
}
# =============================== end timer stuff ===========================================

# ================================== Flaps ==================================================

controls.flapsDown = func(down){
	
	if (down > 0) {setprop("controls/flight/flaps-lever",1);}
	elsif (down < 0) {setprop("controls/flight/flaps-lever", 0);}
	
	var operative = 0;
	var volts = getprop("systems/electrical/outputs/flaps");
	if (volts > 22) {operative = 1;}
	else {operative = 0;}

	if (down > 0 and operative == 1) {registerTimerControls(flapRaise);}	# Set the clock running on flaps lever lowered
	else {
		if(operative > 0) {setprop("controls/flight/flaps", 0);}	# Just raise the flaps
		}

} # end function

var flapRaise = func{
	var down = getprop("controls/flight/flaps-lever");
	var airspeed = getprop("velocities/airspeed-kt");

	if (down == 1 and airspeed < 250) {
		setprop("controls/flight/flaps", 1);
		return registerTimerControls(flapRaise);		# Lower flaps and keep the timer going
	}
	elsif (down == 1 and airspeed > 250) {
		setprop("controls/flight/flaps", 0);
		return registerTimerControls(flapRaise);		# Raise flaps automatically, keep watching	
	}
	else {
		setprop("controls/flight/flaps", 0);
	}
		
} # end function

# ================================== Airbrakes ==================================================

var airbrakes = func{
	
	var out = getprop("surface-positions/speedbrake-pos-norm");
	var volts = getprop("systems/electrical/outputs/airbrakes");
        var operative = 0;
	if (volts > 22) {operative = 1;}
	else {operative = 0;}

	if (out < 1 and operative == 1) {
		setprop("controls/flight/speedbrake", 1);
		registerTimerControls(airbrakesIn);}	# Set the clock running on airbrakes out 
	elsif (out > 0 and operative == 1) { setprop("controls/flight/speedbrake", 0 );}	# Just retract

} # end function

var airbrakesIn = func{
	var airspeed = getprop("velocities/mach");

	if (airspeed > 1.3) { setprop("controls/flight/speedbrake", 0);} # Retract airbrakes
	#if (airspeed > 1.3) { Lightning.airbrakes(0);}		# Retract airbrakes
	else { return registerTimerControls(airbrakesIn);}	# Keep watching	
		
} # end function


# ================================== Property Toggle ========================================

var propToggle = func {

	var property = arg[0];
	var currentValue = getprop( property );
	var newValue = "0";

 	if ((currentValue))  {
		newValue = "0";
		setprop( property , newValue);
	}
	else {
		newValue = "1";
		setprop( property , newValue);
	}

} # end function
# ================================== Chute ==================================================

controls.deployChute = func(v){

	# Deploy
	if (v > 0){
		setprop("sim/model/lightning/controls/flight/chute_deployed",1);
		setprop("sim/model/lightning/controls/flight/chute_open",1);
		chuteAngle();
	}
	# Jettison
	if (v < 0){ 
		var voltage = getprop("systems/electrical/outputs/chute_jett");
		if (voltage > 20) {
			setprop("sim/model/lightning/controls/flight/chute_jettisoned",1);
			setprop("sim/model/lightning/controls/flight/chute_open",0);
		}
	}
}


var chuteAngle = func {

	var chute_open = getprop('sim/model/lightning/controls/flight/chute_open');
	
	if (chute_open != '1') {return();}

	var speed = getprop('velocities/airspeed-kt');
	var aircraftpitch = getprop('orientation/pitch-deg[0]');
	var aircraftyaw = getprop('orientation/side-slip-deg');
	var chuteyaw = getprop("sim/model/lightning/orientation/chute_yaw");
	var aircraftroll = getprop('orientation/roll-deg');

	if (speed > 210) {
		setprop("sim/model/lightning/controls/flight/chute_jettisoned", 1); # Model Shear Pin
		return();
	}

	# Chute Pitch
	var chutepitch = aircraftpitch * -1;
	setprop("sim/model/lightning/orientation/chute_pitch", chutepitch);

	# Damped yaw from Vivian's A4 work
	var n = 0.01;
	if (aircraftyaw == nil) {aircraftyaw = 0;}
	if (chuteyaw == nil) {chuteyaw = 0;}
	var chuteyaw = ( aircraftyaw * n) + ( chuteyaw * (1 - n));	
	setprop("sim/model/lightning/orientation/chute_yaw", chuteyaw);

	# Chute Roll - no twisting for now
	var chuteroll = aircraftroll;
	setprop("sim/model/lightning/orientation/chute_roll", chuteroll*rand()*-1 );

	return registerTimerControlsNil(chuteAngle);	# Keep watching

} # end function

var chuteRepack = func{

	setprop('sim/model/lightning/controls/flight/chute_open', 0);
	setprop('sim/model/lightning/controls/flight/chute_deployed', 0);
	setprop('sim/model/lightning/controls/flight/chute_jettisoned', 0);

} # end func	

# =============================== Master Camera =============================================

var setMasterCamera = func {

	var alreadySet =  getprop("controls/switches/camera");
	if (alreadySet == nil){return();}
	elsif (alreadySet == 1 ){
		initialTime = getprop("sim/time/elapsed-sec");
		setprop("sim/model/lightning/controls/camera-start-time", initialTime);
	}
	else {
		setprop("sim/model/lightning/controls/camera-start-time", 0);
		setprop("sim/replay/duration", 90);
	}

} # end function

setlistener("controls/switches/camera", setMasterCamera);

var doReplay = func{

	var startTime = getprop("sim/model/lightning/controls/camera-start-time");
	var stopTime = getprop("sim/time/elapsed-sec");

	if (startTime > 0 or startTime == nil) {
		var duration = stopTime - startTime ;
		setprop("sim/replay/duration", duration);
	}

	fgcommand("replay", props.Node.new());
	
}

# ================================== Autopilot ==============================================

# Autothrottle Engage

var autothrottleWatch = func{

	var lever = getprop("controls/switches/autothrottle");
	var power = getprop("systems/electrical/outputs/autothrottle");
	var airspeed = getprop("velocities/airspeed-kt");

	if ( power > 100 and lever and airspeed > 162 and airspeed < 275) {
		setprop("autopilot/settings/target-speed-kt", 180);
		setprop("autopilot/locks/speed","speed-with-throttle");
		return registerTimerControls(autothrottleWatch);
	}
	else { setprop("autopilot/locks/speed", " ");
		setprop("controls/switches/autothrottle",0);
	}
}

setlistener("controls/switches/autothrottle", autothrottleWatch);

# Pitch Hold / Off

var autopilot_pitch = func {

	var on = getprop("sim/model/lightning/controls/flight/ap_pitch");
	var aircraftpitch = getprop('orientation/pitch-deg[0]');

	if ( on != '1' ) {
		setprop("autopilot/locks/altitude[0]", 0);
		setprop("autopilot/gui/alt-active[0]", 0);
	}
	else {
		setprop("autopilot/settings/target-pitch-deg[0]", aircraftpitch);
		setprop("autopilot/locks/altitude[0]", "pitch-hold");
		setprop("autopilot/gui/alt-active[0]", 1);
	}
} # end function

setlistener("sim/model/lightning/controls/flight/ap_pitch", autopilot_pitch);

# Roll&Yaw hold / Off
var autopilot_rollyaw = func {

	var aircraftheading = getprop('orientation/heading-deg[0]');

	var on = getprop("sim/model/lightning/controls/flight/ap_ry");
	
	if ( on != '1' ) {
		setprop("autopilot/locks/heading[0]", "");
		setprop("sim/model/lightning/controls/flight/ap_ry", 0);
	}
	else {
		setprop("sim/model/lightning/controls/flight/ap_ry", 1);
		setprop("autopilot/settings/target-heading-deg[0]", aircraftheading);
		setprop("autopilot/locks/heading[0]", "true-heading-hold");
	}
} # end function
setlistener("sim/model/lightning/controls/flight/ap_pitch", autopilot_rollyaw);

# ILS / attitude hold
var autopilot_ILS = func {

	var on = getprop("sim/model/lightning/controls/flight/ap_ILS");
	var current_p_setting = getprop("sim/model/lightning/controls/flight/ap_pitch");
	var current_r_setting = getprop("sim/model/lightning/controls/flight/ap_ry");
	
	if ( on != '1' ) {

		if ( current_p_setting == 1 ) {
				setprop("sim/model/lightning/controls/flight/ap_pitch", 1);
		}
		if ( current_r_setting == 1 ) {
				setprop("sim/model/lightning/controls/flight/ap_ry", 1);
		}
	}

	else {
		setprop("autopilot/locks/heading[0]", "nav1-hold");
	}
} # end function
setlistener("sim/model/lightning/controls/flight/ap_ILS", autopilot_ILS);

# Glide / Off 
var autopilot_glide = func {

	var on = getprop("sim/model/lightning/controls/flight/ap_glide");
	var current_p_setting = getprop("sim/model/lightning/controls/flight/ap_pitch");
	
	if ( on != '1' ) {
		setprop("autopilot/locks/altitude[0]", "");
		if ( current_p_setting == 1 ) {
				setprop("sim/model/lightning/controls/flight/ap_pitch", 1);
		}
	}

	else {
		setprop("autopilot/locks/altitude[0]", "gs1-hold");
	}
} # end function
setlistener("sim/model/lightning/controls/flight/ap_glide", autopilot_glide);



# ================================== Seat Height =================================================

var seatRaise = func {

	var switchPos = getprop("sim/model/lightning/controls/seat");
	var power = getprop("systems/electrical/outputs/seat"); 
	var y_offset = getprop("sim/current-view/y-offset-m");
	var min = 1.35;
	var max = 1.5;
	
	while(switchPos!=0) {
		y_offset = y_offset + ((power * 0.00000417)*switchPos);
		if(y_offset > max){y_offset=max};
		if(y_offset < min){y_offset=min};

		setprop('sim/current-view/y-offset-m', y_offset);
		setprop('controls/seat/vertical-adjust', 1); # trigger for sound
		return registerTimerControlsNil(seatRaise);	# continue watching 
	}

	setprop('controls/seat/vertical-adjust', 0); # reset sound

} # end function
setlistener("sim/model/lightning/controls/seat", seatRaise);

# ================================== Radar View ==================================================

var toggle_radar_view = func {

	var radar_x = 0.12;
	var radar_y = 1.37;
	var radar_z = 4.5;
	var radar_fov = 12;
	var radar_pitch = -16;
	var radar_view_already_selected = props.globals.getNode("/sim/model/lightning/controls/radarview").getValue();

	if (radar_view_already_selected != 1) {
		var current_x = props.globals.getNode("sim/current-view/x-offset-m").getValue();
		var current_y = props.globals.getNode("sim/current-view/y-offset-m").getValue();
		var current_z = props.globals.getNode("sim/current-view/z-offset-m").getValue();
		var current_fov = props.globals.getNode("sim/current-view/field-of-view").getValue();
		var current_pitch = props.globals.getNode("sim/current-view/pitch-offset-deg").getValue();

		props.globals.getNode("sim/model/lightning/views/stored-x-offset-m",1).setDoubleValue(current_x);
		props.globals.getNode("sim/model/lightning/views/stored-y-offset-m",1).setDoubleValue(current_y);
		props.globals.getNode("sim/model/lightning/views/stored-z-offset-m",1).setDoubleValue(current_z);
		props.globals.getNode("sim/model/lightning/views/stored-field-of-view",1).setValue(current_fov);
		props.globals.getNode("sim/model/lightning/views/stored-pitch",1).setValue(current_pitch);

		setprop('sim/current-view/x-offset-m', radar_x);
		setprop('sim/current-view/y-offset-m', radar_y);
		setprop('sim/current-view/z-offset-m', radar_z);
		setprop('sim/current-view/field-of-view', radar_fov);
		setprop('sim/current-view/heading-offset-deg[0]', 0);
		setprop('sim/current-view/pitch-offset-deg[0]', -15.5);
		setprop('sim/model/lightning/controls/radarview', 1);
		setprop('instrumentation/radar/minimized', 1);
	}
	else {
		var stored_x = props.globals.getNode("sim/model/lightning/views/stored-x-offset-m").getValue();
		var stored_y = props.globals.getNode("sim/model/lightning/views/stored-y-offset-m").getValue();
		var stored_z = props.globals.getNode("sim/model/lightning/views/stored-z-offset-m").getValue();
		var stored_fov = props.globals.getNode("sim/model/lightning/views/stored-field-of-view").getValue();
		var stored_pitch = props.globals.getNode("sim/model/lightning/views/stored-pitch").getValue();

		props.globals.getNode("sim/current-view/x-offset-m",1).setDoubleValue(stored_x);
		props.globals.getNode("sim/current-view/y-offset-m",1).setDoubleValue(stored_y);
		props.globals.getNode("sim/current-view/z-offset-m",1).setDoubleValue(stored_z);
		setprop('sim/current-view/field-of-view', stored_fov);
		setprop('sim/current-view/pitch-offset-deg', stored_pitch);
		setprop('sim/model/lightning/controls/radarview', 0);
		setprop('instrumentation/radar/minimized', 0);
	}		

} #End func

# ============================= Engine Starts  =================================================

var AvpinPump = func(number){

        var volts = getprop("systems/electrical/outputs/ignition["~number~"]");
#       var volts = 28.0;
	if ( volts > 27){
		setprop("sim/model/lightning/engines/engine["~number~"]/avpin_flowing",1);
		settimer(func{Combustion(number);},2);
	}

} # End Function

var Combustion = func(number){

	setprop("sim/model/lightning/engines/engine["~number~"]/avpin_flowing",0);
	setprop("sim/model/lightning/engines/engine["~number~"]/combustion",1);
	settimer(func{EngineStart(number);},5);

} # End Function
		
var EngineStart = func {
	
	var number = arg[0];
	var volts = getprop("systems/electrical/outputs/ignition["~number~"]");
	var cutoff = getprop("sim/model/lightning/controls/shut_down");

	setprop("sim/model/lightning/engines/engine["~number~"]/combustion",0);

	if ( volts > 27 and cutoff == "1"){
		setprop("controls/engines/engine["~number~"]/cutoff","false");
		setprop("controls/engines/engine["~number~"]/starter","true");
	}

	elsif ( volts > 27 and cutoff != "1"){
		setprop("controls/engines/engine["~number~"]/cutoff","true");
		setprop("controls/engines/engine["~number~"]/starter","true");
		setprop("sim/model/lightning/engines/engine["~number~"]/starting",1);
		settimer(func{
			setprop("controls/engines/engine["~number~"]/cutoff","false");
		},1);
	}

} #End func

# ============================= Engine Stop  =================================================

var EngineStop = func {
	
	var no1Running = getprop("engines/engine[0]/n1");
	var no2Running = getprop("engines/engine[1]/n1");
	var shutoff0 = getprop("fdm/jsbsim/fcs/shutoff0");
	var shutoff1 = getprop("fdm/jsbsim/fcs/shutoff1");


	if (shutoff0 == 1 and no1Running > 30){
		setprop("controls/engines/engine[0]/cutoff","true");
	}
	if (shutoff1 == 1 and no2Running > 30){
		setprop("controls/engines/engine[1]/cutoff","true");
	}
	else {settimer(EngineStop,0.1);}

} #End func

# ========================= Ground Fuelling ====================================

var refuel = func{

	var brakesOn = getprop("/controls/gear/brake-parking");
	var wow = getprop("/gear/gear/wow");
	var fueltanks = props.globals.getNode("consumables/fuel").getChildren("tank");

	if (brakesOn and wow){
		foreach(tank; fueltanks) {
			level = tank.getNode("level-gal_us",0);
			remaining = level.getValue();
			interpolate(level,400, 30);
		}
	}
} # End function

var ventralJettison = func(jettison){

	setprop("/sim/model/lightning/controls/tank_jettisoned", jettison);
	setprop("/sim/model/lightning/controls/tank_jettisoned_lever", jettison);

	if(jettison > 0){
		setprop("consumables/fuel/tank[0]/level-gal_us", 0);
		}
	else{setprop("consumables/fuel/tank[0]/level-gal_us", 265);}

} # End function

var ventralRefit = func{

	setprop('sim/model/lightning/controls/tank_jettisoned', 0);
	setprop('sim/model/lightning/controls/tank_jettisoned_lever', 0);

} # end of function


# ========================= Emergency U/C  =====================================

controls.gearDown = func(down){

	var emergency = getprop("sim/model/lightning/controls/emergency_uc_selected");
	if (emergency > 0) { return () };

	var power = getprop("systems/electrical/outputs/undercarriage");
	if (power < 24) { return () };

	var airspeed = getprop("velocities/airspeed-kt");

	if (down < 0 and airspeed > 150) {
		setprop("controls/gear/gear-down", 0);
	} elsif (down > 0) {
		setprop("controls/gear/gear-down", 1);
	} 

} # end of function

var emergencyGearDown = func(set){

	if (set < 1){
		setprop("sim/model/lightning/controls/emergency_uc_selected", 0);
	} else {
		setprop("sim/model/lightning/controls/emergency_uc_selected", 1);
		setprop("controls/gear/gear-down", 1);
	}
} # End Func

# ========================= Rudder Trim  =====================================
controls.rudderTrim = func(direction){
	var volts = getprop("systems/electrical/outputs/control_pos_indicator");
	setprop("sim/model/lightning/controls/flight/rudder-trim", direction);
	controls.slewProp("controls/flight/rudder-trim", direction * 0.6 * (volts/28));
} # end 
