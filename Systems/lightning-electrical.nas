##
# Lightning electrical system.
# From the F.6 Pilot's Notes; making educated guesses about F.1A
# Used Syd Adams' DHC2 as initial template
##

# Initialize internal values
#

var external = nil;
var battery = nil;
var alternator = nil;
var last_time = 0.0;
var vbus_volts = 0.0;
var ammeter_ave = 0.0;

##
# Initialize the electrical system
#

var init_electrical = func {
    print("Initializing Nasal Electrical System");
    external = ExternalClass.new();
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

    props.globals.getNode("systems/electrical/suppliers/rpm_source", 1).setDoubleValue(1);
    props.globals.getNode("systems/electrical/outputs/standby_instruments", 1).setDoubleValue(0);
    props.globals.getNode("systems/electrical/outputs/annunciators", 1).setDoubleValue(0);
    props.globals.getNode("controls/switches/dayNight", 1).setBoolValue(1);
    props.globals.getNode("controls/switches/changeLamps", 1).setBoolValue(0);

    setprop("controls/electric/engine/generator", "true");
    setprop("controls/switches/autopilot", "0");
    setprop("controls/switches/battery", "0");
    setprop("controls/switches/cabin_air", 0);
    setprop("controls/switches/chute_jett", "0");
    setprop("controls/switches/eng_start_master", "0");
    setprop("controls/switches/engine_start_0", 0);
    setprop("controls/switches/engine_start_1", 0);
    setprop("controls/switches/gw_fcr", 0);
    setprop("controls/switches/ignition", 0);
    setprop("controls/switches/iris", 0);
    setprop("controls/switches/instrument_master", 1);
    setprop("controls/switches/inverter_normal", 1);
    setprop("controls/switches/rain_dispersal", 0);
    setprop("controls/switches/taxi-lights", 0);
    setprop("controls/switches/nav_lights", 0);
    setprop("controls/anti-ice/pitot_heater", 0);
    setprop("controls/anti-ice/standby_pitot_heat", 0);
    setprop("controls/switches/instr-lights-port", 0);
    setprop("controls/switches/instr-lights-stbd", 0);
    setprop("controls/switches/wscreen_front", 0);
    setprop("controls/switches/wscreen_side", 0);
    setprop("systems/electrical/suppliers/gen_online", 0);
    setprop("systems/electrical/suppliers/external", 0);
    setprop("controls/electric/external-power", 1);
    setprop("sim/model/lightning/electrical-initialized", "true");

    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

var ExternalClass = {

new: func {
    var obj = { parents : [ExternalClass],
			extvolts : getprop("/systems/electrical/suppliers/external")};
    return obj;
},

get_output_volts: func {
	me.extvolts = getprop("systems/electrical/suppliers/external");
	return me.extvolts * 29;
    },
};	
var BatteryClass = {

new: func {
    var obj = { parents : [BatteryClass],
            ideal_volts : 24.0,
            ideal_amps : 30.0,
            amp_hours : 25.0,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
    },

apply_load: func( amps, dt ) {
#    print("Battery Apply Load ", me.amp_hours );
    var amphrs_used = amps * dt / 3600000.0;
    var percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    #print( "battery percent = ", me.charge_percent);
    return me.amp_hours * me.charge_percent;
    },

get_output_volts: func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor ;
    },

get_output_amps: func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
    },
};


var AlternatorClass = {

new: func {
    var obj = { parents : [AlternatorClass],
	rpm_source : "/systems/electrical/suppliers/rpm_source",
        rpm_upper_threshold : 58,
        rpm_lower_threshold : 57,
        ideal_volts : 28.0,
        ideal_amps : 200.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
},

update_source: func( dt ) {
	# Choose fastest spinning engine to supply, prefer no2	
	var rpm1 = getprop("/engines/engine[0]/n1");
	var rpm2 = getprop("/engines/engine[1]/n1");
	if (rpm1 == nil){rpm1="0"};
	if (rpm2 == nil){rpm2="0"};
	if (rpm2 < rpm1) {
		setprop("/systems/electrical/suppliers/rpm_source", rpm1);
		if (rpm1 > 58) {
			setprop("/systems/electrical/suppliers/gen_online", 1);
			} else {
				setprop("/systems/electrical/suppliers/gen_online", 0);
			}	
		}
	else {
		setprop("/systems/electrical/suppliers/rpm_source", rpm2);
		if (rpm2 > 58) {
			setprop("/systems/electrical/suppliers/gen_online", 1);
			} else {
				setprop("/systems/electrical/suppliers/gen_online", 0);
				}
		}
},

apply_load: func( amps, dt ) {
    # give full output.  This is as documented in the Pilot's Notes.
    var rpm = getprop( me.rpm_source );
 #   print("Alternator Apply Load ", me.rpm_upper_threshold );
    var factor = rpm / me.rpm_upper_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    if ( rpm < me.rpm_lower_threshold ) {
        factor = 0.000001;
    }
	# print( "alternator amps = ", me.ideal_amps * factor );
    var available_amps = me.ideal_amps * factor;
    return available_amps - amps;
},

get_output_volts: func {
    # give full output.  This is as documented in the Pilot's Notes.
    var rpm = getprop( me.rpm_source );
  #  print("Get Alternator Output Volts ", me.rpm_upper_threshold );
    var factor = rpm / me.rpm_upper_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
	if ( rpm < me.rpm_lower_threshold ) {
        factor = 0.000001;
    } 
	return me.ideal_volts * factor;
},

get_output_amps: func {
    # give full output.  
    var rpm = getprop( me.rpm_source );
#    print("Get  Alternator Output Amps ", me.rpm_upper_threshold );
    var factor = rpm / me.rpm_upper_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
	if ( rpm < me.rpm_lower_threshold ) {
        factor = 0.000001;
    } 
    return me.ideal_amps * factor;
    },
};

var update_electrical = func {
    var time = getprop("/sim/time/elapsed-sec"); ## NB this is time in miliiseconds since sim started
    var dt = time - last_time;
    last_time = time;
    update_virtual_bus( dt );
    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}

var update_virtual_bus = func( dt ) {
#    print ("update virtual bus");
    var battery_volts = battery.get_output_volts();
    var alternator_source = alternator.update_source(dt);
    var alternator_volts = alternator.get_output_volts();
    var external_volts = external.get_output_volts();
    var load = 0.0;

    # switch state
    var master_bat = getprop("/controls/switches/battery");
    var master_alt = getprop("/controls/electric/engine/generator");

    # determine power source

    var bus_volts = 0.0;
    var power_source = nil;
	if ( master_bat > 0) {
        bus_volts = battery_volts;
        power_source = "battery";
    }
    if ( master_alt and (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
    }
	if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
    }
    
    # print( "virtual bus volts = ", bus_volts );

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determins where it draws power from.)
	load += electrical_28VDC_bus();
    load += electrical_115VAC3phase_unswitched_bus();
    load += electrical_115VAC3phase_with_standby_inverter_bus();
	load += electrical_115VAC3phase_without_standby_inverter_bus();
	load += electrical_115VAC1phase_bus();
	load += electrical_28VAC1phase_bus();

    # system loads and ammeter gauge
    var ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        # normal load
        load += 15.0;

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    vbus_volts = bus_volts;

    return load;
}

var electrical_28VDC_bus = func() {
	
    var engSw = (getprop("controls/switches/eng_start_master"));
    var ignSw = (getprop("controls/switches/ignition"));
    var start = engSw * ignSw;
    if (start == nil){start="0"};
    var portlightSw = getprop("controls/switches/instr-lights-port");
    var stbdlightSw = getprop("controls/switches/instr-lights-stbd");
    if (vbus_volts == nil){vbus_volts="0"};
    var bus_volts = vbus_volts ;
    var load = 0.0;

	
	# Voltmeter	
    setprop("/systems/electrical/outputs/annunciators", bus_volts);
	# Airbrakes control and position indicator
    setprop("/systems/electrical/outputs/airbrakes", bus_volts);
    # Armament circuits
    setprop("systems/electrical/outputs/armaments", bus_volts);
    # Standby AI and Direction Indicator
    setprop("systems/electrical/outputs/standby_instruments", bus_volts);
    # Brake Chute Jettison
    setprop("systems/electrical/outputs/chute_jett", bus_volts);
    # Camera Controls
    setprop("systems/electrical/outputs/camera", bus_volts);
    # Com 1 Power
    setprop("systems/electrical/outputs/comm[0]", bus_volts);
    # Com 2 Power
    setprop("systems/electrical/outputs/comm[1]", bus_volts);
    # Controls and Trim indication
    setprop("systems/electrical/outputs/control_pos_indicator", bus_volts);
    # DME Power
    setprop("systems/electrical/outputs/dme[0]", bus_volts);
    # Engine Start and Relight
    setprop("systems/electrical/outputs/ignition[0]", bus_volts * start);
    setprop("systems/electrical/outputs/ignition[1]", bus_volts * start);
    # Flaps power and indication
    setprop("systems/electrical/outputs/flaps", bus_volts);
	# HSI Power
    setprop("systems/electrical/outputs/hsi", bus_volts);
    # Instruments Lights-Port
    setprop("systems/electrical/outputs/instr-lights-port", bus_volts * portlightSw);
    # Instruments Lights-Stbd
	setprop("systems/electrical/outputs/instr-lights-stbd", bus_volts * stbdlightSw);
    # Nav Lights
    if( getprop("controls/switches/nav_lights") != "0"){
    	setprop("systems/electrical/outputs/nav_lights", bus_volts);
		load +=1;
	}
	else {setprop("systems/electrical/outputs/nav_lights",0);}
    # Nav 1 Power
    setprop("systems/electrical/outputs/nav[0]", bus_volts);
    setprop("systems/electrical/outputs/adf", bus_volts);
    # Nav 2 Power
    setprop("systems/electrical/outputs/nav[1]", bus_volts);
    # Seat
    setprop("systems/electrical/outputs/seat", bus_volts);
    # TACAN
    setprop("systems/electrical/outputs/tacan", bus_volts);
    # Taxi Lights
    if( getprop("controls/switches/taxi-lights") != "0"){
    	setprop("systems/electrical/outputs/taxi-lights", bus_volts);
		load +=3;
	}
	else {setprop("systems/electrical/outputs/taxi-lights",0);}
    # Turn Co-ordinator
	setprop("systems/electrical/outputs/turn-coordinator[0]", bus_volts);
    # Undercarriage operation and indicators
    setprop("systems/electrical/outputs/undercarriage", bus_volts);
	

    # return cumulative load
    return load;
}

var electrical_115VAC3phase_unswitched_bus = func() {
	var gen_online = getprop("systems/electrical/suppliers/gen_online");
    var bus_volts = vbus_volts * gen_online * 4.1072;
	var load = 0.0;

    # A.I. 23B Radar
    setprop("systems/electrical/outputs/radar", bus_volts);
#######	if(bus_volts > 114){setprop("instrumentation/radar/switch","on" );} # this can crash flightgear !!!!
#######	else{setprop("instrumentation/radar/switch","off");}
    # G.W. Supply
    setprop("systems/electrical/outputs/gw", bus_volts);
    # Ventral Pack Fuel Pump
    setprop("systems/electrical/outputs/ventral_fuel_pump", bus_volts);
    # Windscreen Heaters Side and Centre
    setprop("systems/electrical/outputs/windscreen_heaters", bus_volts);
	# Anti-icing
	if ( getprop("/controls/switches/rain_dispersal") == "-1") {
		setprop("systems/electrical/outputs/de-ice", bus_volts);
		load += 3.5;
	}
	else {setprop("systems/electrical/outputs/de-ice", 0 );}

    # return cumulative load
    return load;
}

var electrical_115VAC3phase_with_standby_inverter_bus = func() {
    # Can run from either main or standby inverter
    var ins_master_switch = getprop("controls/switches/instrument_master");
    var inverter_norm_switch = getprop("controls/switches/inverter_normal");
    var inv_switch = 0;
    if (inverter_norm_switch != 0) {
	inv_switch = 1;
	}
	else { inv_switch = 0 }
    var bus_volts = vbus_volts * 4.1072 * ins_master_switch * inv_switch ;
    var load = 0.0;

    # Fuel Contents Display
    setprop("systems/electrical/outputs/fuel_contents", bus_volts);
	#Also Cockpit Temp - not implementing for now :-)

    # return cumulative load
    return load;
}

var electrical_115VAC3phase_without_standby_inverter_bus = func() {
	# Contains instruments with no standby AC power available
    var switch = getprop("controls/switches/instrument_master");
    var switch2 = getprop("controls/switches/inverter_normal");
	var gen_online = getprop("systems/electrical/suppliers/gen_online");
    var bus_volts = vbus_volts * 4.1072 * gen_online * switch * switch2;
    var load = 0.0;

    # Autopilot Power
	
	if( getprop("controls/switches/autopilot") != "0"){
		setprop("systems/electrical/outputs/autopilot", bus_volts);}
	else {setprop("systems/electrical/outputs/autopilot",0);}

    # Autothrottle Servos (Don't require main AP to be switched on)
    setprop("/systems/electrical/outputs/autothrottle", bus_volts);

    # Main AI and HSI - Automatic Failover to 28VDC on loss of AC
	#if( bus_volts < 113 )
	#if( gen_online < 1) {
	#	setprop("/systems/electrical/outputs/", vbus_volts);
	#	}
	#else {
	#	setprop("/systems/electrical/outputs/standby_instruments", bus_volts);
	#}
    
	# MRG (Master Reference Gyro) - feeds AI (and NAV display on F.6)
    setprop("/systems/electrical/outputs/MRG", bus_volts);
    setprop("/systems/electrical/outputs/DG", bus_volts);

	# JPT Control 
    setprop("/systems/electrical/outputs/JPT", bus_volts);

    # return cumulative load
    return load;
}

var electrical_115VAC1phase_bus = func() {
	var gen_online = getprop("/systems/electrical/suppliers/gen_online");
    var bus_volts = vbus_volts * 4.1072 * gen_online;
	var load = 0.0;

    # TACAN Power
    setprop("/systems/electrical/outputs/TACAN", bus_volts);
	# I.F.F
	# Spraymat Auto Temp. Control

    # return cumulative load
    return load;
}

var electrical_28VAC1phase_bus = func() {
	var gen_online = getprop("/systems/electrical/suppliers/gen_online");
    var bus_volts = vbus_volts * gen_online;
	var load = 0.0;

    # Pitot Heaters
    setprop("/systems/electrical/outputs/pitot-heat", bus_volts);
	# Services Hydraulic Pressure Gauge
    setprop("/systems/electrical/outputs/Hydraulic_services_gauge", bus_volts);

    # return cumulative load
    return load;
}
# Setup a timer based call to initialized the electrical system as
# soon as possible.
#settimer(init_electrical, 0);
setlistener("/sim/signals/fdm-initialized",init_electrical);
