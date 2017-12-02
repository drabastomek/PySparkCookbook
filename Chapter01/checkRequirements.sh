#!/bin/bash

# Shell script for checking the dependencies 
#
# PySpark Cookbook
# Author: Tomasz Drabas, Denny Lee
# Version: 0.1
# Date: 12/2/2017

_java_required=1.8
_python_required=3.4
_r_required=3.1
_scala_required=2.11

_args_len="$#"

if [ "$_args_len" -ge 0 ]; then

    POSITIONAL=()
    while [[ "$#" -gt 0 ]]
    do
        key="$1"

        case $key in
            -r|--R)
            _check_R_req="$2"
            shift # past argument
            shift # past value
            ;;
            -s|--Scala)
            _check_Scala_req="$2"
            shift # past argument
            shift # past value
            ;;
            *)
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters
fi

function printHeader() {
    echo
    echo "####################################################"
    echo
    echo "Checking the dependencies for installing Spark 2.2.0"
    echo
    echo "PySpark Cookbook by Tomasz Drabas and Denny Lee"
    echo "Version: 0.1, 12/2/2017"
    echo
    echo "####################################################"
    echo
    echo
    _dependencies="Checking for: Java, Python"

    if [ "${_check_R_req}" = "true" ]; then
        _dependencies="$_dependencies, R"
    fi

    if [ "${_check_Scala_req}" = "true" ]; then
        _dependencies="$_dependencies, Scala"
    fi

    _dependencies="$_dependencies."

    echo "$_dependencies"
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
        echo "Java version required is $_java_required. Install the required version first."
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

    _python_version=$("$_python" --version 2>&1 | awk -F ' ' '{print $2}')
    echo "Python version: $_python_version"
    if [[ "$_python_version" < "$_python_required" ]]; then
        echo "Python version required is $_python_required. Install the required version first."
        exit
    fi
    echo
}

function checkScala() {
    echo
    echo "##########################"
    echo
    echo "Checking Scala"
    echo

    if type -p scala; then
        echo "Scala executable found in PATH"
        _scala=scala
    else
        echo "No Scala found. Install Scala first or add the path to Scala binaries to PATH."
        exit
    fi
    
    _scala_version=$("$_scala" -version 2>&1 | awk -F ' ' '{print $5}')
    echo "Scala version: $_scala_version"
    if [[ "$_scala_version" < "$_scala_required" ]]; then
        echo "Scala version required is $_scala_required. Install the required version first."
        exit
    fi
    echo
}

function checkR() {
    echo
    echo "##########################"
    echo
    echo "Checking R"
    echo

    if type -p R; then
        echo "R executable found in PATH"
        _r=R
    else
        echo "No R found. Install R first or add the path to R binaries to PATH."
        exit
    fi
    
    _r_version=$("$_r" --version 2>&1 | awk -F ' ' '/R version/ {print $3}')
    echo "R version: $_r_version"
    if [[ "$_r_version" < "$_r_required" ]]; then
        echo "R version required is $_r_required. Install the required version first."
        exit
    fi
    echo
}

printHeader
checkJava
checkPython

if [ "${_check_R_req}" = "true" ]; then
    checkR
fi

if [ "${_check_Scala_req}" = "true" ]; then
    checkScala
fi