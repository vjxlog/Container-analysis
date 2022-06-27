const shell = require('shelljs')

shell.exec("echo $SHLVL");

shell.exec("script -q");
shell.exec("echo $SHLVL");

shell.exit(1);

// const { exec } = require("child_process");
// exec("script");