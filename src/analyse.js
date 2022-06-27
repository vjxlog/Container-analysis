const shell = require('shelljs')


const readline = require('readline');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});




if (!shell.which('docker')) {
  shell.echo('Sorry, this script requires docker');
  shell.exit(1);
}

shell.exec('docker -v');
rl.question('Enter image name ? ', function (name) {
  
  shell.exec(`docker run -itd ${name}`);
  
  //docker-bench
  console.log("Docker bench is starting to analyse");

    shell.cd('docker-bench');
    shell.exec('sh docker-bench-security.sh');
    
    // Inspec
    console.log("Inspec is starting to analyse");


    if (!shell.which('inspec')) {
      shell.echo('Sorry, this script requires inspec');
      shell.exit(1);

    }
    shell.cd("..");
    shell.cd(`Inspec`);
    shell.exec(`inspec exec cis-docker-benchmark`);

      let id = shell.exec("docker ps -aq");


      shell.exec(`inspec exec linux-baseline -t docker://${id.stdout}`);

      // trivy
      console.log("Trivy is starting to analyse");


    if (!shell.which('trivy')) {
      shell.echo('Sorry, this script requires trivy');
      shell.exit(1);

    }
    
    shell.exec(`trivy image ${name} `);
    
      //dive  
    //   console.log("Dive bench is starting to analyse");


    // if (!shell.which('dive')) {
    //     shell.echo('Sorry, this script requires dive');
    //     shell.exit(1);
    //   }
    
    
    // shell.exec(`dive ${name} --ci`);
    
    // shell.exec(`dive ${name}`);

    if (!shell.which('snyk')) {
          shell.echo('Sorry, this script requires snyk');
          shell.exit(1);
        }


    console.log("Snyk is starting to analyse");
    

    shell.exec(`snyk container test ${name}`);

    shell.exec(`sudo docker ps -aq |sudo xargs docker stop |sudo xargs docker rm`);

    shell.exit(1);

})
