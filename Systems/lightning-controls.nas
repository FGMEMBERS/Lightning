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
	aircraftyaw = getprop('orientation/side-slip-deg');
	chuteyaw = getprop("sim/model/lightning/orientation/chute_yaw");
	aircraftroll = getprop('orientation/roll-deg');
	chuteroll = getprop("sim/model/lightning/orientation/chute_roll");

	if (speed > 210) {
		setprop("sim/model/lightning/controls/flight/chute_jettisoned", 1); # Model Shear Pin
		return();
	}

	# Chute Pitch
	chutepitch = aircraftpitch * -1;
	setprop("sim/model/lightning/orientation/chute_pitch", chutepitch);

	# Damped yaw from Vivian's A4 work
	var n = 0.01;
	if (aircraftyaw == nil) {aircraftyaw = 0;}
	if (chuteyaw == nil) {chuteyaw = 0;}
	chuteyaw = ( aircraftyaw * n) + ( chuteyaw * (1 - n));	
	setprop("sim/model/lightning/orientation/chute_yaw", chuteyaw);

	# Chute Roll - no twisting for now
	chuteroll = aircraftroll;
	setprop("sim/model/lightning/orientation/chute_roll", chuteroll);

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



# ================================== Seat Height =================================================

seatRaise = func {

	switchPos = getprop("sim/model/lightning/controls/seat");
	power = getprop("systems/electrical/outputs/seat"); 
	y_offset = getprop("sim/current-view/y-offset-m");
	min = 1.35;
	max = 1.5;
	
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

toggle_radar_view = func {

	radar_x = 0.12;
	radar_y = 1.37;
	radar_z = 4.5;
	radar_fov = 12;
	radar_pitch = -16;
	radar_view_already_selected = props.globals.getNode("/sim/model/lightning/controls/radarview").getValue();

	if (radar_view_already_selected != 1) {
		current_x = props.globals.getNode("sim/current-view/x-offset-m").getValue();
		current_y = props.globals.getNode("sim/current-view/y-offset-m").getValue();
		current_z = props.globals.getNode("sim/current-view/z-offset-m").getValue();
		current_fov = props.globals.getNode("sim/current-view/field-of-view").getValue();
		current_pitch = props.globals.getNode("sim/current-view/pitch-offset-deg").getValue();

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
	}
	else {
		stored_x = props.globals.getNode("sim/model/lightning/views/stored-x-offset-m").getValue();
		stored_y = props.globals.getNode("sim/model/lightning/views/stored-y-offset-m").getValue();
		stored_z = props.globals.getNode("sim/model/lightning/views/stored-z-offset-m").getValue();
		stored_fov = props.globals.getNode("sim/model/lightning/views/stored-field-of-view").getValue();
		stored_pitch = props.globals.getNode("sim/model/lightning/views/stored-pitch").getValue();

		props.globals.getNode("sim/current-view/x-offset-m",1).setDoubleValue(stored_x);
		props.globals.getNode("sim/current-view/y-offset-m",1).setDoubleValue(stored_y);
		props.globals.getNode("sim/current-view/z-offset-m",1).setDoubleValue(stored_z);
		setprop('sim/current-view/field-of-view', stored_fov);
		setprop('sim/current-view/pitch-offset-deg', stored_pitch);
		setprop('sim/model/lightning/controls/radarview', 0);
	}		

} #End func

# ============================= Engine Starts  =================================================

AvpinPump = func(number){

	volts = getprop("systems/electrical/outputs/ignition["~number~"]");

	if ( volts > 27){
		setprop("sim/model/lightning/engines/engine["~number~"]/avpin_flowing",1);
		settimer(func{Combustion(number);},2);
	}

} # End Function

Combustion = func(number){

	setprop("sim/model/lightning/engines/engine["~number~"]/avpin_flowing",0);
	setprop("sim/model/lightning/engines/engine["~number~"]/combustion",1);
	settimer(func{EngineStart(number);},5);

} # End Function
		
EngineStart = func {
	
	number = arg[0];
	volts = getprop("systems/electrical/outputs/ignition["~number~"]");
	cutoff = getprop("sim/model/lightning/controls/shut_down");

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


# ================================== Steering =================================================

controls.applyBrakes = func(v,which=0){

	if (which == 0){setprop("sim/model/lightning/controls/gear/braking", v);}
	elsif (which < 0) {setprop("/controls/gear/brake-left", v);}
	elsif (which > 0) {setprop("/controls/gear/brake-right", v);}
 
} # end function

steering = func{

	applied = cmdarg().getValue();
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

# ========================= Ground Fuelling ====================================

refuel = func{

	brakesOn = getprop("/controls/gear/brake-parking");
	wow = getprop("/gear/gear/wow");
	fueltanks = props.globals.getNode("consumables/fuel").getChildren("tank");

	if (brakesOn and wow){
		foreach(tank; fueltanks) {
			level = tank.getNode("level-gal_us",0);
			remaining = level.getValue();
			interpolate(level,400, 30);
		}
	}
} # End function

ventralRefit = func{

	setprop('sim/model/lightning/controls/tank_jettisoned', 0);
	setprop('sim/model/lightning/controls/tank_jettisoned_lever', 0);

} # end of function

# ========================= Emergency U/C  =====================================

controls.gearDown = func(down){

	emergency = getprop("sim/model/lightning/controls/emergency_uc_selected");
	if (emergency > 0) { return () };

	power = getprop("systems/electrical/outputs/undercarriage");
	if (power < 24) { return () };

	airspeed = getprop("velocities/airspeed-kt");

	if (down < 0 and airspeed > 150) {
		setprop("controls/gear/gear-down", 0);
	} elsif (down > 0) {
		setprop("controls/gear/gear-down", 1);
	} 

} # end of function

emergencyGearDown = func(set){

	if (set < 1){
		setprop("sim/model/lightning/controls/emergency_uc_selected", 0);
	} else {
		setprop("sim/model/lightning/controls/emergency_uc_selected", 1);
		setprop("controls/gear/gear-down", 1);
	}
} # End Func
