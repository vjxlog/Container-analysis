var run  = require("./analyse");
const shell = require('shelljs')


const readline = require('readline');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

shell.exec("script");

run.analyse();

shell.exec("exit");

shell.exit(1);

