var path = "Aircraft/Lightning/Models/Liveries/";
var xmldialog = "Aircraft/Lightning/Dialogs/livery.xml";
var variant = props.globals.getNode("sim/model/livery/variant", 1);
var dialog = gui.Dialog.new("/sim/gui/dialogs/livery/dialog", xmldialog);


# build hash with name->data-hash pairs
var data = {};
foreach (var file; directory(getprop("/sim/fg-root") ~ "/" ~ path)) {
	if (substr(file, -4) != ".xml")
		continue;

	var n = props.Node.new({ "filename" : path ~ file });
	fgcommand("loadxml", n);
	n = n.getNode("data");
	var name = n.getNode("sim/model/livery/variant", 1).getValue();
	data[name] = n.getValues();
}


var select = func(name) {
	props.globals.setValues(data[name]);
}


# initialize variant
aircraft.data.add(variant);
select(variant.getValue());

