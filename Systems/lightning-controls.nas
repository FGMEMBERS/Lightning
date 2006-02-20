# ==================================== timer stuff =========================================

# set the update period

UPDATE_PERIOD = 0.5;
UPDATE_PERIOD_FINE = 0.1;
UPDATE_PERIOD_NIL = 0.0;

# set the timer for the selected function

registerTimerControls = func {

    settimer(arg[0], UPDATE_PERIOD);
}

registerTimerControlsFine = func {

    settimer(arg[0], UPDATE_PERIOD_FINE);
}

registerTimerControlsNil = func {

    settimer(arg[0], UPDATE_PERIOD_NIL);
}
# =============================== end timer stuff ===========================================

# ================================== Flaps ==================================================

controls.flapsDown = func(down){
	
	if (down > 0) {setprop("controls/flight/flaps-lever",1);}
	elsif (down < 0) {setprop("controls/flight/flaps-lever", 0);}

	volts = getprop("systems/electrical/outputs/flaps");
	if (volts > 22) {operative = 1;}
	else {operative = 0;}

	if (down > 0 and operative == 1) {registerTimerControls(flapRaise);}	# Set the clock running on flaps lever lowered
	else {
		if(operative > 0) {setprop("controls/flight/flaps", 0);}	# Just raise the flaps
		}

} # end function

flapRaise = func{
	down = getprop("controls/flight/flaps-lever");
	airspeed = getprop("velocities/airspeed-kt");

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

# ================================== Gear ==================================================

controls.gearDown = func(down){
	power = getprop("systems/electrical/outputs/undercarriage");
    if (down < 0){
		setprop("sim/model/lightning/controls/gear-down",0);
		if (power > 22) {setprop("controls/gear/gear-down", 0);}
    }
	elsif (down > 0){
		setprop("sim/model/lightning/controls/gear-down",1);
		if (power > 22) {setprop("controls/gear/gear-down",1);}
    }
}


# ================================== Airbrakes ==================================================

airbrakes = func{
	
	out = getprop("surface-positions/speedbrake-pos-norm");
	volts = getprop("systems/electrical/outputs/airbrakes");
	if (volts > 22) {operative = 1;}
	else {operative = 0;}

	if (out < 1 and operative == 1) {
		setprop("controls/flight/speedbrake", 1);
		registerTimerControls(airbrakesIn);}	# Set the clock running on airbrakes out 
	elsif (out > 0 and operative == 1) { setprop("controls/flight/speedbrake", 0 );}	# Just retract

} # end function

airbrakesIn = func{
	airspeed = getprop("velocities/mach");

	if (airspeed > 1.3) { setprop("controls/flight/speedbrake", 0);} # Retract airbrakes
	#if (airspeed > 1.3) { Lightning.airbrakes(0);}		# Retract airbrakes
	else { return registerTimerControls(airbrakesIn);}	# Keep watching	
		
} # end function


# ================================== Property Toggle ========================================

propToggle = func {

	property = arg[0];
	currentValue = getprop( property );

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

chuteAngle = func {

	chute_open = getprop('sim/model/lightning/controls/flight/chute_open');
	
	if (chute_open != '1') {return();}

	speed = getprop('velocities/airspeed-kt');
	aircraftpitch = getprop('orientation/pitch-deg[0]');
	chutepitch = getprop("sim/model/lightning/orientation/chute_pitch");
	#aircraftyaw = getprop('orientation/yaw-rate-degps[0]');
	#chuteyaw = props.globals.getNode("sim/model/lightning/orientation/chute_yaw").getValue();

	if (speed > 210) {
		setprop("sim/model/lightning/controls/flight/chute_jettisoned", 1); # Model Shear Pin
		return();
	}

	if (aircraftpitch < -20) {aircraftpitch = -20;}
	elsif (aircraftpitch > 20) {aircraftpitch = 20;}

	chutepitch = aircraftpitch * -1;
	setprop("sim/model/lightning/orientation/chute_pitch", chutepitch);
	return registerTimerControlsNil(chuteAngle);	# Keep watching

} # end function

chuteRepack = func{

	setprop('sim/model/lightning/controls/flight/chute_open', 0);
	setprop('sim/model/lightning/controls/flight/chute_deployed', 0);
	setprop('sim/model/lightning/controls/flight/chute_jettisoned', 0);

} # end func	

# =============================== Master Camera =============================================

setMasterCamera = func {

	alreadySet =  getprop("controls/switches/camera");
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

doReplay = func{

	startTime = getprop("sim/model/lightning/controls/camera-start-time");
	stopTime = getprop("sim/time/elapsed-sec");

	if (startTime > 0 or startTime == nil) {
		duration = stopTime - startTime ;
		setprop("sim/replay/duration", duration);
	}

	fgcommand("replay", props.Node.new());
	
}

# ================================== Autopilot ==============================================


# Pitch Hold / Off

autopilot_pitch = func {

	on = getprop("sim/model/lightning/controls/flight/ap_pitch");
	aircraftpitch = getprop('orientation/pitch-deg[0]');

	if ( on != '1' ) {
		setprop("autopilot/locks/altitude[0]", "");
		setprop("autopilot/gui/alt-active[0]", "false");
		#print("turning off")
	}
	else {
		setprop("autopilot/settings/target-pitch-deg[0]", aircraftpitch);
		setprop("autopilot/locks/altitude[0]", "pitch-hold");
		setprop("autopilot/gui/alt-active[0]", "true");
		#print("turning on")
	}
} # end function

setlistener("sim/model/lightning/controls/flight/ap_pitch", autopilot_pitch);

# Roll&Yaw hold / Off
autopilot_rollyaw = func {

	aircraftheading = getprop('orientation/heading-deg[0]');

	on = getprop("sim/model/lightning/controls/flight/ap_ry");
	
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
autopilot_ILS = func {

	on = getprop("sim/model/lightning/controls/flight/ap_ILS");
	current_p_setting = getprop("sim/model/lightning/controls/flight/ap_pitch");
	current_r_setting = getprop("sim/model/lightning/controls/flight/ap_ry");
	
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
autopilot_glide = func {

	on = getprop("sim/model/lightning/controls/flight/ap_glide");
	current_p_setting = getprop("sim/model/lightning/controls/flight/ap_pitch");
	
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



	
# ================================== Radar View ==================================================

toggle_radar_view = func {

	original_view = props.globals.getNode("sim/current-view/view-number[0]").getValue();
	default_x = props.globals.getNode("sim/model/lightning/views/current-x-offset").getValue();
	default_y = props.globals.getNode("sim/model/lightning/views/current-y-offset").getValue();
	default_z = props.globals.getNode("sim/model/lightning/views/current-z-offset").getValue();
	default_fov = props.globals.getNode("sim/model/lightning/views/current-fov").getValue();
	radar_view_selected = props.globals.getNode("/sim/model/lightning/controls/radarview").getValue();
	# YASim config values
	#radar_x = 0.12;
	#radar_y = 1.77;
	#radar_z = -4.2;
	#radar_fov = 12;
	radar_x = 0.13;
	radar_y = 1.43;
	radar_z = -4.2;
	radar_fov = 12;

	if (original_view != 0) {
		setprop('sim/current-view/view-number', 0);
	}
	if (radar_view_selected > 0) {
		setprop('sim/current-view/x-offset-m', default_x);
		setprop('sim/current-view/y-offset-m', default_y);
		setprop('sim/current-view/z-offset-m', default_z);
		setprop('sim/current-view/field-of-view', default_fov);
		setprop('sim/model/lightning/controls/radarview', 0);
	}
	else {
		setprop('sim/current-view/x-offset-m', radar_x);
		setprop('sim/current-view/y-offset-m', radar_y);
		setprop('sim/current-view/z-offset-m', radar_z);
		setprop('sim/current-view/field-of-view', radar_fov);
		setprop('sim/current-view/heading-offset-deg[0]', 0);
		setprop('sim/current-view/pitch-offset-deg[0]', -15);
		setprop('sim/model/lightning/controls/radarview', 1);
	}		


} #End func

# ============================= Engine Starts  =================================================

EngineStart = func {
	
	number = arg[0];
	switchIsOn = getprop("controls/switches/engine_start_"~ number );
	volts = getprop("systems/electrical/outputs/ignition["~number~"]");
	cutoff = getprop("sim/model/lightning/controls/shut_down");

	if (switchIsOn == 0){
		setprop("controls/engines/engine["~number~"]/cutoff","false");
		setprop("controls/engines/engine["~number~"]/starter","false");
	}
	
	elsif ( volts > 27 and cutoff == "1"){
		setprop("controls/engines/engine["~number~"]/cutoff","false");
		setprop("controls/engines/engine["~number~"]/starter","true");
	}

	elsif ( volts > 27 and cutoff != "1"){
		setprop("controls/engines/engine["~number~"]/cutoff","true");
		setprop("controls/engines/engine["~number~"]/starter","true");
	}

} #End func

# ============================= Engine Stop  =================================================

EngineStop = func {
	
	no1Running = getprop("engines/engine[0]/n1");
	no2Running = getprop("engines/engine[1]/n1");
	shutoff0 = getprop("fdm/jsbsim/fcs/shutoff0");
	shutoff1 = getprop("fdm/jsbsim/fcs/shutoff1");


	if (shutoff0 == 1 and no1Running > 30){
		setprop("controls/engines/engine[0]/cutoff","true");
	}
	if (shutoff1 == 1 and no2Running > 30){
		setprop("controls/engines/engine[1]/cutoff","true");
	}
	else {settimer(EngineStop,0.1);}

} #End func


# ================================== Steering ==================================================


steering = func{

	applied = getprop("sim/model/lightning/controls/gear/braking");
	rudder_pos = getprop("controls/flight/rudder");

	if (applied == 0 ) {
		setprop('controls/gear/brake-left', 0);
		setprop('controls/gear/brake-right', 0);	# Release brakes
	}
	elsif (rudder_pos > 0.3 ) {
		setprop('controls/gear/brake-right', rudder_pos);
		setprop('controls/gear/brake-left', 0);
		return registerTimerControlsNil(steering);	# Brake right and continue watching 
	}
	elsif (rudder_pos < -0.3 ) {
		applied_left = rudder_pos * -1;
		setprop('controls/gear/brake-left', applied_left);
		setprop('controls/gear/brake-right', 0);
		return registerTimerControlsNil(steering);	# Brake left and continue watching 
	}
	else {
		setprop('controls/gear/brake-left', 1);
		setprop('controls/gear/brake-right', 1);
		return registerTimerControlsNil(steering);	# Brake centrally and continue watching 
	}	
		
} # end function
setlistener("sim/model/lightning/controls/gear/braking", steering);


