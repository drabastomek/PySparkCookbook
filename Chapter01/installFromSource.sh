#!/bin/bash

# Shell script for installing Spark from sources 
#
# PySpark Cookbook
# Author: Tomasz Drabas, Denny Lee
# Version: 0.1
# Date: 12/2/2017

_spark_source="http://mirrors.ocf.berkeley.edu/apache/spark/spark-2.2.0/spark-2.2.0.tgz"
_spark_archive=$( echo "$_spark_source" | awk -F '/' '{print $NF}' )
_spark_dir=$( echo "${_spark_archive%.*}" )
_spark_destination="/opt/spark"


function checkOS(){
    _uname_out="$(uname -s)"

    # echo "$_uname_out"
    case "$_uname_out" in
        Linux*)     _machine="Linux";;
        Darwin*)    _machine="Mac";;
        *)          _machine="UNKNOWN:${unameOut}"
    esac
}

function printHeader() {
    echo
    echo "####################################################"
    echo
    echo "Installing Spark 2.2.0 from sources on $_machine"
    echo
    echo "PySpark Cookbook by Tomasz Drabas and Denny Lee"
    echo "Version: 0.1, 12/2/2017"
    echo
    echo "####################################################"
    echo
    echo
}

# Set Maven memory options
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"

# Download the package
function downloadThePackage() {
    echo
    echo "##########################"
    echo
    echo "Downloading the $_spark_source"
    echo


    if [ -d _temp ]; then
        sudo rm -rf _temp
    fi

    mkdir _temp
    cd _temp

    if [ "$_machine" = "Mac" ]; then
        curl -O $_spark_source
    elif [ "$_machine" = "Linux"]; then
        wget $_spark_source
    else
        echo "System: $_machine not supported."
        exit
    fi

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

# Build the package
function build(){
    echo
    echo "##########################"
    echo
    echo "Building the distribution of Spark"
    echo

    cd "$_spark_dir"
    ./dev/make-distribution.sh --name custom-spark --pip  --tgz -Phadoop-2.7 -Phive -Phive-thriftserver -Pyarn

    echo
}

# Move the built binaries
function moveTheBinaries() {
    echo
    echo "##########################"
    echo
    echo "Moving compiled binaries to $_spark_destination"
    echo

    if [ -d "$_spark_destination" ]; then
        sudo rm -rf "$_spark_destination"
    fi

    cd ..
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
    cp "$_bash" "$_bash.spark_copy"

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

    echo "export PYSPARK_DRIVER_PYTHON_OPTS=\"notebook --NotebookApp.open_browser=False --NotebookApp.ip='*' --NotebookApp.port=8880\"" >> $_bash
    
    echo "export PATH=$SPARK_HOME/bin:\$PATH" >> $_bash
}

# Clean up
function cleanUp() {
    rm -rf _temp
}

checkOS
printHeader
downloadThePackage
unpack
build
moveTheBinaries
setSparkEnvironmentVariables
cleanUp