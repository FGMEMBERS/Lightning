# $Id$

# ==================================== timer stuff =========================================

# set the update period

UPDATE_PERIOD = 0.2;

# set the timer for the selected function

registerTimer = func {

    settimer(gmeterUpdate, UPDATE_PERIOD);
    settimer(setRPM, UPDATE_PERIOD);
    settimer(icewarn, UPDATE_PERIOD);

}

# =============================== end timer stuff ===========================================

# =============================== G-Meter stuff =============================================

gmeterUpdate = func {

    if (flag and !done) {done = 1};
    #if (flag and !done) {print("gmeter_running"); done = 1};

    GCurrent = props.globals.getNode("/accelerations/pilot-g[0]").getValue();

    # Unfortunately, FDM initialization hasn't happened when we start
    # running.  Wait for the FDM to start running before we set any output
    # properties.  This also prevents us from mucking with FDMs that
    # don't support this scheme.
    if(GCurrent == 1 and !flag) {  # this relies on 'GCurrent'
        return registerTimer(); #  not being quite 0 at startup,
        }else{                  # and therefore keeps the function running,
        flag = 1;               # once it has run once.
    }

    if(!initialized) { initialize(); }

    GCurrent = props.globals.getNode("/accelerations/pilot-g[0]").getValue();
    GMin = props.globals.getNode("/accelerations/pilot-gmin[0]").getValue();
    GMax = props.globals.getNode("/accelerations/pilot-gmax[0]").getValue();

    if(GCurrent < 1 and GCurrent < GMin){setprop("/accelerations/pilot-gmin[0]", GCurrent);}
    else {if(GCurrent > GMax){setprop("/accelerations/pilot-gmax[0]", GCurrent);}}
    
    registerTimer();

}

# ====================== Standby / Master AI  ===============================

setRPM = func{
	
	sb_volts = getprop("/systems/electrical/outputs/standby_instruments") ;
	if (sb_volts == nil ){ sb_volts = 0;}
	if (sb_volts > 22){	rpm = 2000;	} 
	else { rpm = 0; }

	setprop("/engines/engine/rpm", rpm);

} # end function

#### Ice Warning Light - values taken from RAF "Pilot's Notes General, 3rd ed. 1946" ####
#### Any suggestions for improvement welcomed! ####

icewarn = func {

	temp = getprop("environment/temperature-degc");
	volts = getprop("systems/electrical/outputs/annunciators");

	if (temp < -1 and temp > -8 and volts > 23 ) { warn = 1 }
	else {warn = 0}

	setprop("sim/model/lightning/lights/ice_warn", warn);
	
} # End func


####################### Initialise ##############################################
done = 0;
flag = 0;
initialized = 0;

initialize = func {

    ### Initialise gmeter stuff ###
    props.globals.getNode("accelerations/pilot-g[0]", 1).setDoubleValue(1.01);
    props.globals.getNode("accelerations/pilot-gmin[0]", 1).setDoubleValue(1);
    props.globals.getNode("accelerations/pilot-gmax[0]", 1).setDoubleValue(1);

    ### Initialise fuel stuff ###
    props.globals.getNode("instrumentation/fuel/bingo[0]", 1).setIntValue(0);
    props.globals.getNode("instrumentation/fuel/bingo[1]", 1).setIntValue(0);
   
    ### Initialise RPM (Vacuum) stuff ###
    props.globals.getNode("engines/engine[0]/rpm", 1).setIntValue(0);

	### Initialise Ice Warning stuff ###
	props.globals.getNode("sim/model/lightning/lights/ice_warn", 1).setIntValue(0);

	### Initialise electrical stuff ###
    props.globals.getNode("systems/electrical/suppliers/rpm_source", 1).setDoubleValue(1);
    props.globals.getNode("systems/electrical/outputs/standby_instruments", 1).setDoubleValue(0);
		
	### Initialise Radar stuff ###
    props.globals.getNode("sim/model/lightning/controls/radarview", 1).setValue(0);
	default_x = props.globals.getNode("sim/view/config/x-offset-m[0]").getValue();
	default_y = props.globals.getNode("sim/view/config/y-offset-m[0]").getValue();
	default_z = props.globals.getNode("sim/view/config/z-offset-m[0]").getValue();
	default_fov = 55;
	props.globals.getNode("sim/model/lightning/views/current-x-offset", 1).setDoubleValue(default_x);
	props.globals.getNode("sim/model/lightning/views/current-y-offset", 1).setDoubleValue(default_y);
	props.globals.getNode("sim/model/lightning/views/current-z-offset", 1).setDoubleValue(default_z);
	props.globals.getNode("sim/model/lightning/views/current-fov", 1).setDoubleValue(default_fov);
    
	### Initialise Chute stuff ###
	props.globals.getNode("sim/model/lightning/controls/flight/chute_open", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/chute_deployed", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/chute_jettisoned", 1).setBoolValue(0);
	
	### Initialise Braking stuff ###
	props.globals.getNode("sim/model/lightning/controls/gear/braking", 1).setIntValue(0);
	
	### Initialise AP stuff ###
	props.globals.getNode("sim/model/lightning/controls/flight/ap_ILS", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_glide", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_pitch", 1).setIntValue(0);
	props.globals.getNode("sim/model/lightning/controls/flight/ap_ry", 1).setIntValue(0);
	
	### Initialise Camera stuff ###
	props.globals.getNode("sim/model/lightning/controls/camera-start-time", 1).setIntValue(0);

	### Initialise Dialogue stuff ###
	Lightning.showDialog();
		
	# Finished Initialising
    initialized = 1;

} #end func

######################### Fire it up ############################################

registerTimer();
