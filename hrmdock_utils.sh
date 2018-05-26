#!/bin/bash

# Author: Jim Mainprice
# Please contact mainprice@gmail.com if bugs or errors are found
# in this script.

IMAGE_NAME=ubuntu/hrm_16.04
IMAGE_DIRECTORY=images/16_04
HRMDOCK_FILE=$(basename $BASH_SOURCE)
HRMDOCK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

# To run the last container
# docker ps -a --latest
# docker start -i ID_OF_YOUR_CONTAINER

hrmdock_config() {
    echo " - bash filename is : ${HRMDOCK_FILE}"
    echo " - script directory is in : ${HRMDOCK_DIR}"
    echo " - image name is : ${IMAGE_NAME}"
}

hrmdock_cd() {
    cd ${HRMDOCK_DIR}
}

hrmdock_build_latest() {
    # This will build the latest image as described in the DockerFile
    docker build -t ${IMAGE_NAME} ${HRMDOCK_DIR}/${IMAGE_DIRECTORY}
    echo "Build ${IMAGE_NAME} Done !"
}

hrmdock_run_new_container() {
    # Run the image in a container at the location when the function is called.
    #
    # Should allow percistent containers by not copying the ssh keys.
    # SSH keys, we should find a way to unmount the .ssh volume
    USER=$(whoami)
    ID=$(id -u ${USER})
    docker run -it \
           --rm \
           --runtime=nvidia \
           -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \
           -v $(pwd):/workspace \
           -v ${HOME}/.ssh:/ssh \
	   -v ${HRMDOCK_DIR}:/hrmdock \
	   ${IMAGE_NAME} \
           bash -c "cd workspace \
                    && source /hrmdock/${HRMDOCK_FILE} \
                    && hrmdock_create_user ${USER} ${ID}"
}

hrmdock_import_ssh_keys() {
    # Usefull to import ssh keys in the container.
    # This will be temporarily mounted to the container and copied to
    # the user home directory, if using ssh agent, it will be started.
    echo "check ssh keys"
    if [ ! -d "${HOME}/.ssh" ]; then
        echo "Adding ssh keys"
        # Symbolic link version, we have to figure out how
        # to unmount volumes...
        ln -s /ssh .ssh
        # -------------------- Copy version -------------------
        # mkdir .ssh
        # cp -r /ssh/* ${HOME}/.ssh
        # rm ${HOME}/.ssh/ssh_auth_sock
        # chmod 600 .ssh/*
        # -----------------------------------------------------
        eval `ssh-agent`
        ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
        export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
        ssh-add -l | grep "The agent has no identities" && ssh-add
    fi
}

hrmdock_create_user() {
    # Create a user in the Gest with the name and id passed
    # as argument. If these mach then files can be edited 
    # regardless by the host or the gest.
    # the created user has sudoers rights and we also import the ssh
    # keys of the host.
    echo "Create user $1 with uid $2"
    # echo "$(id -u $1 &>/dev/null)"
    useradd -m -d /home/$1 $1
    usermod -u $2 $1
    usermod -aG sudo $1
    cd /home/$1
    echo "$1 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$1
    echo "source /hrmdock/${HRMDOCK_FILE}" >> .bashrc
    echo "hrmdock_import_ssh_keys" >> .bashrc
    su $1
}

hrmdock_update_this_machine() {
    # This function will create a bash script from the current
    # Dockerfile and update this machine. It supposes that the machine's 
    # version of the operating system agrees with the Dockerfile
    cd ${HRMDOCK_DIR}
    UPDATE_SCRIPT=scripts/autogenerate_update_script.sh
    python scripts/generate_update_script.py \
        ${HRMDOCK_DIR}/${IMAGE_DIRECTORY}/Dockerfile ${UPDATE_SCRIPT}
    sudo bash ${UPDATE_SCRIPT}
    cd -      
}