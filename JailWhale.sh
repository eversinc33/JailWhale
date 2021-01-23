#!/bin/sh

C=$(printf '\033')
RED="${C}[0;31m"
GREEN="${C}[1;32m"
YELLOW="${C}[1;33m"
BLUE="${C}[1;34m"
GREY="${C}[0;90m"
WHITE="${C}[1;37m"
NC="${C}[0m" # No Colour

heading()	 { echo "\n${WHITE}>>> ${1}${NC}";}
log_grey()  	 { echo "$GREY... ${1}$NC"; }
log_g()  	 { echo "$GREEN[+]$NC ${1}"; }
log_y()  	 { echo "$YELLOW[!]$NC ${1}"; }
log_r() 	 { echo "$RED[-]$NC ${1}"; }
log_hint()   { echo "$BLUE-->$NC ${1}"; }
log()        { echo "    ${1}"; }

echo "$WHITE"
echo '        .					'
echo '       ":"				'
echo '     ___:____     |"\/"|	'
echo '   ,"        `.    \  /	'
echo '   |  O        \___/  |	'
echo "$BLUE ~^~^~^~^~^~^~^~^~^~^~^~^~$NC"
echo "$WHITE     JailWhale.sh		$NC"
echo ''
sleep 1

INODE_NUM=`ls -ali / | sed '2!d' |awk {'print $1'}`
if [ "$INODE_NUM" -eq '2' ]; then
	log_y "You are ${WHITE}not${NC} in a container!"
else
	log_g "You are in a container!"
	
	OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY | cut -d'"' -f2)
	if [ "$OS" = "" ]; then
		# for some other distros
		OS=$(cat /etc/issue | cut -d'\' -f1)
	fi
	log_hint "${WHITE}OS: ${OS}${NC}"
	
	CONTAINER_ID=$(basename "$(cat /proc/1/cpuset)")
	SHORT_ID=$(echo $CONTAINER_ID | cut -c -12)
	LONG_ID=$(echo $CONTAINER_ID | cut -c 13-)
	log_hint "${WHITE}ID: ${SHORT_ID}${GREY}${LONG_ID}${NC}"
fi
sleep 1

heading "Looking for docker executable"
if [ $(which docker) ]; then
	log_g "docker executable exists at $WHITE$(which docker)$NC"
	log   "You can try escaping by creating a container and mounting the host system$NC"
	
	# if not root
	if [ $(id -u) -ne 0 ]; then
		if id -nG "$(whoami)" | grep -qw "docker"; then
			log_g "You are part of the ${WHITE}docker${NC} group"
		else
			log_y "You are not part of the ${WHITE}docker${NC} group."
			log   "Try running ${WHITE}sudo -l${NC} or escalate privileges to run docker."
		fi
	fi
else
	log_y "No docker executable found"
fi
sleep 1

heading "Looking for mounted docker socket"
if [ -e /var/docker.sock ]; then
	log_g "Socket is mounted at ${GREEN}/var/docker.sock${NC}"
	log   "You can call the docker-api using ${WHITE}curl --unix-socket${NC}"
else
	DOCKER_SOCK=$(find / -name docker.sock 2>/dev/null)
	if ! [ -z $DOCKER_SOCK ]; then
		log_g "docker.sock is mounted at ${WHITE}${DOCKER_SOCK}${NC}"
		log   "You can call the docker-api using ${WHITE}curl --unix-socket${NC}"
	fi
fi
sleep 1

heading "Looking for docker api ports"
PORTS="2375 2376"
FOUND=0
for PORT in $PORTS; do
	if nc -zv localhost $PORT 1>/dev/null 2>/dev/null; then
		log_g "Port ${WHITE}${PORT}${NC} open. might be a docker api port"
		FOUND=1
	fi
done
if ! [ $FOUND -eq 1 ]; then
	log_y "Port ${WHITE}2375${NC} and ${WHITE}2376${NC} are closed"
	log_hint "The api might be exposed on other ports."
fi
sleep 1

heading "Looking for exploitable capabilities"
if [ $(which capsh) ]; then
	CAPABILITIES="CAP_SYS_ADMIN CAP_SYS_PTRACE CAP_SYS_MODULE DAC_READ_SEARCH DAC_OVERRIDE CAP_SYS_RAWIO"
	for CAP in $CAPABILITIES; do 
		if capsh --print | grep -i $CAP 1>/dev/null 2>/dev/null; then 
			log_g "${WHITE}${CAP}${NC} capability is set"
			
			# TODO: more hints on capabilities
			if [ $CAP = "CAP_SYS_ADMIN" ]; then 	
				log_hint "Check filesystem for mountable host drives by running ${WHITE}fdisk -l${NC}"
			fi
		fi
	done
else
	log_y "${WHITE}capsh${NC} not installed"
fi
sleep 1

heading "Checking CVEs"
echo "... Checking ${WHITE}CVE-2020-15257 (Abstract Shimmer)${NC}"
if cat /proc/net/unix | grep 'containerd-shim' | grep '@'; then
	log_g "Container appears to be vulnerable!"
else
	log_grey "Container does not appear to be vulnerable"
fi
# TODO CVE-2019-5736
# TODO CVE-2019-14271
# TODO CVE-2015-3631

