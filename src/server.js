const express = require('express');
const path = require('path');
//var serveIndex = require('serve-index')

const app = express();
const port = process.env.PORT || 8080;
app.use("/logs", express.static(__dirname + "/logs"));
// sendFile will go here
app.get('/', function(req, res) {
  res.sendFile(path.join(__dirname, '../typescript.html'));
});

//app.use('/', express.static('../src/logs'), serveIndex('../src/logs', {'icons': true}))
app.listen(port);
console.log('Server started at http://localhost:' + port);