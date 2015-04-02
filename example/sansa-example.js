// sansa-test.js
//---------------------------------------------------------------------

// module libraries
var sansa = require("sansa");
var util = require("util");

// sansa Classes
var Arya = sansa.Arya;
var AryaMemory = sansa.AryaMemory;

// sansa objects
var arya = new Arya();
var mem = new AryaMemory();

// save an object
arya.save({ name: "bob" }, mem.output, function(err, uuid) {
    if(err != null) {
        console.log("Error! " + err);
        process.exit(-1);
    }

    // reload the object
    arya.load(uuid, mem.input, function(err, obj) {
        if(err != null) {
            console.log("Error! " + err);
            process.exit(-1);
        }

        // display the reloaded object
        console.log("The obj: " + util.inspect(obj));
    });
});

//---------------------------------------------------------------------
// end of script
