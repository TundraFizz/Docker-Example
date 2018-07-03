var express    = require("express");         // Define the web framework
var app        = module.exports = express(); // Define the application
app.set("views", ".");                       // Define the views directory
app.use(express.static("."));                // Define the static directory
require("./routes.js");                      // Include web routes third
app.listen(80);                              // Start the server
