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
    input="./hosts.txt"

    declare -a _slaves

    i=0
    master=0
    slaves=0

    while IFS= read line
    do

        if [[ "$master" = "1" ]]; then
            _masterNode="$line"
            # echo "$line"
            master=0
        fi

        if [[ "$slaves" = "1" ]]; then
            _slaves[i]="$line"
            # echo "$line"
            ((i++))
        fi

        if [[ "$line" = "master:" ]]; then
            master=1
        fi

        if [[ "$line" = "slaves:" ]]; then
            slaves=1
        fi

        if [[ -z "${line}" ]]; then
            continue
        fi

        
         #(${line// / })
        # slaveNodes[i]=(${line// / })
    done < "$input"

    echo $_masterNode
    echo ${_slaves[@]}
    # echo ${slaveNodes[*]}

    # MATCH="s"

    # if echo $WORD_LIST | grep -w $MATCH > /dev/null; then
    #     echo "matched"
    # else
    #     echo "notmatched"
    # fi
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
    _today=$( date +%Y-%m-%d )

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
# downloadThePackage
# unpack
# moveTheBinaries
# setSparkEnvironmentVariables
# cleanUp