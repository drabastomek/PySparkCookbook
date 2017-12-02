#!/bin/bash

# Shell script for checking the dependencies 
#
# PySpark Cookbook
# Author: Tomasz Drabas, Denny Lee
# Version: 0.1
# Date: 12/2/2017

_java_required=1.8
_python_required=3.4

function printHeader() {
    echo
    echo "Checking the dependencies for installing Spark 2.2.0"
    echo
    echo "PySpark Cookbook by Tomasz Drabas and Denny Lee"
    echo "Version: 0.1, 12/2/2017"
    echo 
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
        echo "No Java found. Install Java first or specify JAVA_HOME variable that will point to your Java binaries."
        exit
    fi
    
    _java_version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "Java version: $_java_version"
    if [[ "$_java_version" < "$_java_required" ]]; then
        echo "Version required is $_java_required. Install the required version first."
        exit
    fi
    echo
}

function checkPython() {
    echo
    echo "##########################"
    echo
    echo "Checking Python"
    echo

    if type -p python; then
        echo "Python executable found in PATH"
        _python=python
    else
        echo "No Python found. Install Python first or add the path to Python binaries to PATH."
        exit
    fi

    echo $("$_python" --version)
    
    _python_version=$("$_python" --version 2>&1 | awk -F ' ' '{print $2}')
    echo "Python version: $_python_version"
    if [[ "$_python_version" < "$_python_required" ]]; then
        echo "Version required is $_python_required. Install the required version first."
        exit
    fi
    echo
}

_args_len="$#"

printHeader
checkJava
checkPython

if [ "$_args_len" -ge 0 ]; then
    echo $1 $2 "$#"

    POSITIONAL=()
    while [[ "$#" -gt 0 ]]
    do
        key="$1"

        case $key in
            -r|--R)
            _check_R_req=1
            shift # past argument
            shift # past value
            ;;
            -s|--Scala)
            _check_Scala_req=1
            shift # past argument
            shift # past value
            ;;
            *)
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters
    echo "${_check_R_req}"
    
    if [ "${_check_R_req}" = 1 ]; then
        echo "Checking R"
    fi
fi