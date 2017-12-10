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
_java_destination="/usr/lib/jvm/java-8-oracle"

_machine=$(cat /etc/hostname)
_today=$( date +%Y-%m-%d )

_current_dir=$(pwd) # store current working directory

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

function checkJava() {
    echo
    echo "##########################"
    echo
    echo "Checking Java"
    echo

    if type -p java; then
        echo "Java executable found in PATH"
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        echo "Found Java executable in JAVA_HOME"
        _java="$JAVA_HOME/bin/java"
    else
        echo "No Java found. Install Java version $_java_required or higher first or specify JAVA_HOME variable that will point to your Java binaries."
        installJava
    fi
}

function installJava() {
    echo
    echo "##########################"
    echo
    echo "Installing Java"
    echo
    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get install oracle-java8-installer
}

function installScala() {
    echo
    echo "##########################"
    echo
    echo "Installing Scala"
    echo
    sudo apt-get install scala
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
    echo
    echo "##########################"
    echo
    echo "Configuring SSH connections "
    echo
    # # install the Open SSH
    # sudo apt-get install openssh-server openssh-client

    # check if master
    IFS=" "
    read -ra temp <<< "$_masterNode"
    _current=( ${temp[1]} )
    _all_machines="$_current\n"

    if [ "$_current" = "$_machine" ]; then
        # generate key pairs (passwordless)
        sudo -u hduser rm -f ~/.ssh/id_rsa && sudo -u hduser ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
        # echo -e 'y\n' | ssh-keygen -q -t rsa -P "" -f ~/.ssh/id_rsa

        IFS="\n"
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
            echo
            echo "Trying to connect to ${temp_inner[1]}"

            # ssh to the remote node from master
            # create .ssh directory
            # and output the public key to authorized_keys
            # file inside .ssh
            cat ~/.ssh/id_rsa.pub | ssh "hduser"@"${temp_inner[1]}" 'mkdir -p .ssh && cat >> .ssh/authorized_keys'

            # append the slave name to the _all_machines
            # (we'll need it later)
            _all_machines=$_all_machines"${temp_inner[1]}\n"
        done
    fi

    echo "Finishing up the SSH configuration"
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
    sudo chown -R hduser:hadoop $_spark_destination

    echo
}

function setSparkEnvironmentVariables() {
    echo
    echo "##########################"
    echo
    echo "Setting Spark Environment variables"
    echo

    _bash=~/.bashrc

    # make a copy just in case
    if ! [ -f "$_bash.spark_copy" ]; then
        cp "$_bash" "$_bash.spark_copy"
    fi

    echo >> $_bash
    echo "###################################################" >> $_bash
    echo "# SPARK environment variables" >> $_bash
    echo "#" >> $_bash
    echo "# Script: installOnRemote.sh" >> $_bash
    echo "# Added on: $_today" >>$_bash
    echo >> $_bash

    echo "export SPARK_HOME=$_spark_destination" >> $_bash
    echo "export JAVA_HOME=$_java_destination" >> $_bash
    
    echo "export PATH=$SPARK_HOME/bin:\$PATH" >> $_bash
}

function updateSparkConfig() {
    echo
    echo "##########################"
    echo
    echo "Configuring Spark"
    echo
    
    cd $_spark_destination/conf

    sudo -u hduser cp spark-env.sh.template spark-env.sh
    echo "export JAVA_HOME=$_java_destination" >> spark-env.sh
    echo "export SPARK_WORKER_CORES=12" >> spark-env.sh

    sudo -u hduser cp slaves.template slaves
    printf "$_all_machines" >> slaves
}

# Clean up
function cleanUp() {
    cd $_current_dir
    rm -rf _temp
}

printHeader
readIPs
checkJava
installScala
updateHosts
configureSSH
downloadThePackage
unpack
moveTheBinaries
setSparkEnvironmentVariables
updateSparkConfig
cleanUp