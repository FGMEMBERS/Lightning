Lightning F.1A Model for FlightGear (www.flightgear.org)
By AJ MacLeod (aj-lists adeptopensource.co uk)

This model is released under the terms of the GPL version 2.

PLEASE: If you can improve any part of this model, do so!  Get in touch with
me or submit your improvements to one of the flightgear email lists.  My
modelling skills are distinctly limited as can be seen, so I have no artistic
pride to swallow :-) 

Requests (in addition to the general one above)

Pilot's Notes - I have the F.6 Notes and FRCs.  Notes for the F.1 or F.1A
would be wonderful...

We really need better sounds.  Any genuine Lightning sound recordings would
be good - particularly engine startup, various cockpit warnings etc.  There
are still several around in at least ground running condition so this 
shouldn't be impossible to get.

Wind Tunnel Data!  Anyone who can lay hands on wind tunnel data for any mark
of Lightning is hereby pleaded with to send me a copy, or better still add
it to the JSBSim FDM config :-) I already have Cl,Cd,Cm vs Alpha for 0 and 
full flap deflection, but need much more data.

If anyone with flying hours on any Lightning mark has any observations on
the in-flight behaviour of this model and how it differs from their memory
of reality, I would be thrilled to hear - I'm not expecting the news to be
good, just want to hear how it can be made better.

Not immediately obvious features:

All production Lightning variants had proportional braking controlled not by
toe brakes, but by the stick mounted brake lever and rudder pedal position.
This has been implemented in this model, but because fgfs currently lacks a
sane way to easily map aircraft-specific controls to joysticks, you will need
to modify your own joystick XML configuration file something like this:

    <button n="0">
        <desc>Brakes</desc>
        <binding>
            <command>property-assign</command>
                <property>sim/model/lightning/controls/gear/braking</property>
                <repeatable type="bool">true</repeatable>
                <value type="int">1</value>
        </binding>
        <mod-up>
            <binding>
                <command>property-assign</command>
                <property>sim/model/lightning/controls/gear/braking</property>
                <value type="int">0</value>
            </binding>
        </mod-up>

    </button>



Credits:

Although this is currently nearly all my own work, I have used bits and pieces
from many other FG models as a starting point.  Credit belongs to at least the
following:

Vivian Meazza	- The Hunter was the main inspiration for this model, and
				nearly all the instruments were initially (and in one case
				currently) based on their Hunter counterparts.  Also some of
				the Nasal functions began life in the Spitfire and Hurricane.

Syd Adams		- The electrical system was modified from the Beaver model,
				and	probably other parts or methods borrowed from some of his
				cockpits.

Thanks to Vivian, Melchoir Franz and Andy Ross (and others) for their
assistance via IRC on various items over a considerable period of time.

