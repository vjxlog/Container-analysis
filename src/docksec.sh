#!/bin/bash

rm -rf logs

# ------------------------------------------------------------------------------
# Simple Docker Security
# -- extracting security-relevant information from Docker environments
#
#
# 
# ------------------------------------------------------------------------------

version="1.0"

printf "## Simple Docker Security" 

# ------------------------------------------------------------------------------
# STARTUP

required_programs="docker grep ps"

for program in $required_programs; do
  command -v "$program" >/dev/null 2>&1 || { printf "[ERROR] Required program not found: %s \n" "$program"; exit 1; }
done


if ! docker ps -q >/dev/null 2>&1; then
  printf "[ERROR] Cannot connect to the Docker daemon\n"
  exit 1
fi

# Warn if not root 
ID=$(id -u)
if [ "x$ID" != "x0" ]; then
  printf "[!] User is not root, some tests might not run"
  sleep 3
fi

# Create Output Directory
output_dir="logs"
mkdir $output_dir
cd $output_dir

# ------------------------------------------------------------------------------
# MAIN SYSTEM

echo "[*] Main System" '\n'
echo "Logging the main system information" '\n'

docker version > docker-version.txt
docker system info > docker-system-info.txt
docker image ls > docker-image-ls.txt
docker container ls --no-trunc > docker-container-ls.txt
docker ps --no-trunc > docker-ps.txt
ps -efww | grep dockerd > ps-dockerd.txt
cat /etc/docker/daemon.json > docker-daemon-json.txt
ls -la /var/run/docker.sock > docker-sock.txt
grep '^docker' /etc/group > docker-group.txt

## Misc Information
apparmor_status > apparmor.txt
sestatus > selinux.txt
grep CONFIG_SECCOMP= /boot/config-$(uname -r) > seccomp.txt
env > env.txt
ifconfig > ifconfig.txt

# ------------------------------------------------------------------------------
# IMAGES

echo "[*] Images" '\n'
echo "Logging the image based information" '\n'

mkdir images
cd images

images="$(docker images -q)"

printf "Image ID;Image Name and Tag;Creation Date;Container User;Exposed Ports;Environmental Variables\n" >> images.csv

for image in $images; do

  image_id="$image"
  image_repotags="$(docker image inspect "$image" -f='{{.RepoTags}}')"
  image_created="$(docker image inspect "$image" -f='{{.Created}}')"
  image_config_exposedports="$(docker image inspect "$image" -f='{{.Config.ExposedPorts}}')"
  image_config_env="$(docker image inspect "$image" -f='{{.Config.Env}}')"

  image_containerconfig_user="$(docker image inspect "$image" -f='{{.ContainerConfig.User}}')"

  printf "$image_id;$image_repotags;$image_created;$image_containerconfig_user;$image_config_exposedports;$image_config_env\n" >> images.csv

  docker image inspect "$image" > "$image_id"-inspect.txt
  docker image history --no-trunc "$image" > "$image_id"-history.txt

done

cd ..

# ------------------------------------------------------------------------------
# CONTAINERS

echo "[*] Containers" '\n'
echo "Logging the container based information" '\n'

mkdir containers
cd containers

containers="$(docker container ls -q)"

printf "Container ID;Container Name;Original Image;AppArmor Profile;CapAdd;CapDrop;IPC;PID Mode;PIDs Limit;Privileged;Read Only;Security Options;User NS;Logging;Config User;whoami;Network Mode;Networks;Ports;Host Binds\n" >> containers.csv

for container in $containers; do

  container_id="$container"
  container_name="$(docker inspect "$container" -f='{{.Name}}')"
  container_config_image="$(docker inspect "$container" -f='{{.Config.Image}}')"
  container_apparmorprofile="$(docker inspect "$container" -f='{{.AppArmorProfile}}')"

  container_hostconfig_capadd="$(docker inspect "$container" -f='{{.HostConfig.CapAdd}}')"
  container_hostconfig_capdrop="$(docker inspect "$container" -f='{{.HostConfig.CapDrop}}')"
  container_hostconfig_ipcmode="$(docker inspect "$container" -f='{{.HostConfig.IpcMode}}')"
  container_hostconfig_pidmode="$(docker inspect "$container" -f='{{.HostConfig.PidMode}}')"
  container_hostconfig_pidslimit="$(docker inspect "$container" -f='{{.HostConfig.PidsLimit}}')"
  container_hostconfig_privileged="$(docker inspect "$container" -f='{{.HostConfig.Privileged}}')"
  container_hostconfig_readonlyfs="$(docker inspect "$container" -f='{{.HostConfig.ReadonlyRootfs}}')"
  container_hostconfig_securityopt="$(docker inspect "$container" -f='{{.HostConfig.SecurityOpt}}')"
  container_hostconfig_usernsmode="$(docker inspect "$container" -f='{{.HostConfig.UsernsMode}}')"

  container_hostconfig_logconfig_type="$(docker inspect "$container" -f='{{.HostConfig.LogConfig.Type}}')"

  container_config_exposedports="$(docker inspect "$container" -f='{{.Config.ExposedPorts}}')"
  container_hostconfig_binds="$(docker inspect "$container" -f='{{.HostConfig.Binds}}')"

  container_config_user="$(docker inspect "$container" -f='{{.Config.User}}')"
  container_whoami="$(docker exec -ti "$container" bash -c 'whoami')"
  container_whoami_clean="$(echo "$container_whoami" | tr -d '\r')"

  container_hostconfig_networkmode="$(docker inspect "$container" -f='{{.HostConfig.NetworkMode}}')"
  container_networksettings_networks="$(docker inspect "$container" -f='{{.NetworkSettings.Networks}}')"

  printf "$container_id;$container_name;$container_config_image;$container_apparmorprofile;$container_hostconfig_capadd;$container_hostconfig_capdrop;$container_hostconfig_ipcmode;$container_hostconfig_pidmode;$container_hostconfig_pidslimit;$container_hostconfig_privileged;$container_hostconfig_readonlyfs;$container_hostconfig_securityopt;$container_hostconfig_usernsmode;$container_hostconfig_logconfig_type;$container_config_user;$container_whoami_clean;$container_hostconfig_networkmode;$container_networksettings_networks;$container_config_exposedports;$container_hostconfig_binds\n" >> containers.csv

  docker inspect "$container" > "$container_id"-inspect.txt

  # DIRECT COMMANDS
  container_osrelease="$(docker exec -ti "$container" cat /etc/os-release)"
  container_user_info="$(docker exec -ti "$container" bash -c 'whoami; id; sudo -v')"
  container_ps_ef="$(docker exec -ti "$container" ps -efww)"

  echo "# OS Release\n" >> "$container_id"-info.txt
  echo "$container_osrelease" >> "$container_id"-info.txt
  echo "\n\n# User Information\n" >> "$container_id"-info.txt
  echo "$container_user_info" >> "$container_id"-info.txt
  echo "\n\n# ps -ef Output\n" >> "$container_id"-info.txt
  echo "$container_ps_ef" >> "$container_id"-info.txt

done

cd ..

# ------------------------------------------------------------------------------
# NETWORK

echo "[*] Networks" '\n'
echo "Logging the Network based information" '\n'

mkdir network
cd network

networks=$(docker network ls -q)

for network in $networks; do
  docker network inspect "$network"       > "$network"-inspect.txt
  docker ps --filter network="$network"   > "$network"-ps.txt
done







#Remediation Steps

# Defining Colors for text output

red=$( tput setaf 1 );
yellow=$( tput setaf 3 );
green=$( tput setaf 2 );
blue=$( tput setaf 4 )
normal=$( tput sgr 0 );

#if [ "${UID}" != 0 ]; 
#then
#    echo "${red}
#    This script must be run as root or with sudo permissions.
#    Please run using sudo.${normal}
#    "
#fi

#check for user is root use or not

ID=$(id -u)
if [ "x$ID" != "x0" ]; then
  printf "[!] User is not root, run script with root access for the best outcomes"
  sleep 3
fi

# Checking whether auditd is installed, and installing if not.

PKGNAME="auditd"
echo

command -v $PKGNAME > /dev/null

INSTALLED="${?}"

if [ "$INSTALLED" -eq 0 ]
then
  echo "${green}$PKGNAME is already installed. Proceeding.${normal}"
else
  echo "${green}Installing $PKGNAME."
apt-get install $PKGNAME -y
  echo "$PKGNAME installed.${normal}
"
fi

docker ps -q >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to connect to Docker Daemon."
  exit 1
fi

#check if Docker is latest installed or not

var1="$(sudo docker version)"
var2="Version: 20.10.12"

echo -en '\n'

if [ "$var1" != "$var2" ]
then
	echo "Docker is out of date! To update: apt-get install docker-engine"
fi



echo -en '\n'
echo "All running containers are stopped.."
sleep 1
docker stop $(docker ps -q -a)

echo -en '\n'
echo "Deleting old containers.."
sleep 1
docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm

echo -en '\n'
echo "Deleting untagged containers.."
sleep 1
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi 2> /dev/null

echo -en '\n'

#adding audit rules to docker daemon

echo "Adding audit rules.."
sleep 1

#removing any previous audit file
rm /etc/audit/rules.d/audit.rules

#adding new rules

cat << EOF >> /etc/audit/rules.d/audit.rules
-b 320
-w /usr/bin/docker -k docker
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/lib/systemd/system/docker-registry.service -k docker
-w /usr/lib/systemd/system/docker.service -k docker
-w /var/run/docker.sock -k docker
-w /usr/bin/docker-containerd -k docker
-w /usr/bin/docker-runc -k docker
-w /etc/docker/daemon.json -k docker

-w /usr/bin/docker -p wa
-w /var/lib/docker -p wa
-w /etc/docker -p wa
-w /lib/systemd/system/docker.service -p wa
-w /lib/systemd/system/docker.socket -p wa
-w /etc/default/docker -p wa
-w /etc/docker/daemon.json -p wa
-w /usr/bin/docker-containerd -p wa
-w /usr/bin/docker-runc -p wa

EOF

echo -en '\n'

echo "Client-side signature integrity is activated.."
sleep 1

#enabling content trust 

cat << EOF >> /root/.bash_profile
export DOCKER_CONTENT_TRUST=1
EOF

echo -en '\n'

# Ensure operations on legacy registry (v1) are Disabled

echo "Starting Registry Daemon as v2.."
sleep 1
docker daemon --disable-legacy-registry --icc=false 2> /dev/null

#securing docker.service from other user

echo -en '\n'
echo "Changing permissions of Docker service.."
chmod 640 /usr/lib/systemd/system/docker.service

sleep 1
echo -en '\n'

echo "Links associated with logs on the server" '\n'

echo "http://localhost:8080/logs/images/images.csv" '\n'

echo "http://localhost:8080/logs/containers/containers.csv" '\n'

echo "http://localhost:8080/logs/apparmor.txt" '\n'

echo "http://localhost:8080/logs/docker-container-ls.txt" '\n'

echo "http://localhost:8080/logs/docker-daemon-json.txt" '\n'

echo "http://localhost:8080/logs/docker-image-ls.txt" '\n'

echo "http://localhost:8080/logs/docker-ps.txt" '\n'

echo "http://localhost:8080/logs/docker-system-info.txt" '\n'

echo "http://localhost:8080/logs/docker-version.txt" '\n'

echo "http://localhost:8080/logs/env.txt" '\n'

echo "http://localhost:8080/logs/ps-dockerd.txt" '\n'

echo "http://localhost:8080/logs/ifconfig.txt" '\n'

echo "http://localhost:8080/logs/seccomp.txt" '\n'

echo "http://localhost:8080/logs/selinux.txt" '\n'

echo "http://localhost:8080/logs/docker-sock.txt" '\n'

echo "http://localhost:8080/logs/docker-group.txt" '\n'


exit 0

 


