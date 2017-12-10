#!/bin/bash

# Shell script for installing Spark from binaries
# on remote servers
#
# PySpark Cookbook
# Author: Tomasz Drabas, Denny Lee
# Version: 0.1
# Date: 12/9/2017

_spark_binary="http://mirrors.ocf.berkeley.edu/apache/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz"
_spark_archive=$( echo "$_spark_binary" | awk -F '/' '{print $NF}' )
_spark_dir=$( echo "${_spark_archive%.*}" )
_spark_destination="/usr/local/spark"

_machine=$(cat /etc/hostname)
_today=$( date +%Y-%m-%d )

function printHeader() {
    echo
    echo "####################################################"
    echo
    echo "Installing Spark from binaries on:"
    echo "                             $_machine"
    echo
    echo "Spark binaries will be moved to:"
    echo "                             $_spark_destination"
    echo
    echo "PySpark Cookbook by Tomasz Drabas and Denny Lee"
    echo "Version: 0.1, 12/9/2017"
    echo
    echo "####################################################"
    echo
    echo
}

function readIPs() {
    echo
    echo "##########################"
    echo
    echo "Reading the hosts.txt list"
    echo
    
    input="./hosts.txt"


    # i=0
    master=0
    slaves=0
    _slaves=""

    IFS=''
    while read line
    do

        if [[ "$master" = "1" ]]; then
            _masterNode="$line"
            master=0
        fi

        if [[ "$slaves" = "1" ]]; then
            _slaves=$_slaves"$line\n"
        fi

        if [[ "$line" = "master:" ]]; then
            master=1
            slaves=0
        fi

        if [[ "$line" = "slaves:" ]]; then
            slaves=1
            master=0
        fi

        if [[ -z "${line}" ]]; then
            continue
        fi
    done < "$input"
}

function updateHosts() {
    echo
    echo "##########################"
    echo
    echo "Updating the /etc/hosts"
    echo

    _hostsFile="/etc/hosts"

    # make a copy (if one already doesn't exist)
    if ! [ -f "/etc/hosts.old" ]; then
        sudo cp "$_hostsFile" /etc/hosts.old
    fi

    t="###################################################\n"
    t=$t"#\n"
    t=$t"# IPs of the Spark cluster machines\n"
    t=$t"#\n"
    t=$t"# Script: installOnRemote.sh\n"
    t=$t"# Added on: $_today\n"
    t=$t"#\n"
    t=$t"$_masterNode\n"
    t=$t"$_slaves\n"

    sudo printf "$t" >> $_hostsFile

}

function configureSSH() {
    # # install the Open SSH
    sudo apt-get install openssh-server openssh-client

    # check if master
    IFS=" "
    read -ra temp <<< "$_masterNode"
    _current=( ${temp[1]} )

    if [ "$_current" = "$_machine" ]; then
        # generate key pairs (passwordless)
        ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa

        # loop through all the slaves
        read -ra temp <<< "$_slaves"
        for slave in ${temp[@]}; do 
            # skip if empty line
            if [[ -z "${slave}" ]]; then
                continue
            fi
            
            # split on space
            IFS=" "
            read -ra temp_inner <<< "$slave"

            # ssh to the remote node from master
            # create .ssh directory
            # and output the public key to authorized_keys
            # file inside .ssh
            cat ~/.ssh/id_rsa.pub | ssh "$USER"@"${temp_inner[1]}" 'mkdir -p .ssh && cat >> .ssh/authorized_keys'

            # alter permissions for the .ssh folder and 
            # for the authorized_keys file
            ssh "$USER"@"${temp_inner[1]}" "chmod 0700 .ssh; chmod 0640 .ssh/authorized_keys"
        done

    fi
}

# Download the package
function downloadThePackage() {
    echo
    echo "##########################"
    echo
    echo "Downloading the $_spark_binary"
    echo


    if [ -d _temp ]; then
        sudo rm -rf _temp
    fi

    mkdir _temp
    cd _temp
    wget $_spark_binary
    
    echo
}

# Unpack the archive
function unpack() {
    echo
    echo "##########################"
    echo
    echo "Unpacking the $_spark_archive archive"
    echo
    tar -xf $_spark_archive

    echo
}

# Move the binaries
function moveTheBinaries() {
    echo
    echo "##########################"
    echo
    echo "Moving the binaries to $_spark_destination"
    echo

    if [ -d "$_spark_destination" ]; then
        sudo rm -rf "$_spark_destination"
    fi

    sudo mv $_spark_dir/ $_spark_destination/

    echo
}

function setSparkEnvironmentVariables() {
    echo
    echo "##########################"
    echo
    echo "Setting Spark Environment variables"
    echo

    if [ "$_machine" = "Mac" ]; then
        _bash=~/.bash_profile
    else
        _bash=~/.bashrc
    fi

    # make a copy just in case
    if ! [ -f "$_bash.spark_copy" ]; then
        cp "$_bash" "$_bash.spark_copy"
    fi

    echo >> $_bash
    echo "###################################################" >> $_bash
    echo "# SPARK environment variables" >> $_bash
    echo "#" >> $_bash
    echo "# Script: installFromSource.sh" >> $_bash
    echo "# Added on: $_today" >>$_bash
    echo >> $_bash

    echo "export SPARK_HOME=$_spark_destination" >> $_bash
    echo "export PYSPARK_SUBMIT_ARGS=\"--master local[4]\"" >> $_bash
    echo "export PYSPARK_PYTHON=$(type -p python)" >> $_bash
    echo "export PYSPARK_DRIVER_PYTHON=jupyter" >> $_bash

    echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --NotebookApp.open_browser=False --NotebookApp.port=6661\"" >> $_bash
    
    echo "export PATH=$SPARK_HOME/bin:\$PATH" >> $_bash
}

# Clean up
function cleanUp() {
    cd ..
    rm -rf _temp
}

printHeader
readIPs
# updateHosts
configureSSH
# downloadThePackage
# unpack
# moveTheBinaries
# setSparkEnvironmentVariables
# cleanUp