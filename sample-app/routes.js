var app = require("./server.js");

app.get("/", function(req, res){
  var string = "A string from the server.";
  var people = [
    {name: "Adam", age: 10},
    {name: "Bob",  age: 12},
    {name: "Carl", age: 15}
  ];

  res.render("index.ejs", {
    people: people,
    string: string
  });
});

app.get("/page2", function(req, res){
  res.render("page2.ejs");
});
