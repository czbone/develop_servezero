#!/bin/bash
# 
# Script Name: build_env.sh
#
# Version:      1.1.0
# Author:       Naoki Hirata
# Date:         2022-01-06
# Usage:        build_env.sh [-test]
# Options:      -test      test mode execution with the latest source package
# Description:  This script builds LEMP environment on Docker server with the one-liner command.
# Version History:
#               1.0.0  (2021-10-22) initial version
#               1.1.0  (2022-01-06) use dynamic working directory
# License:      MIT License

# Define macro parameter
readonly APP_NAME="servezero"
readonly GITHUB_USER="czbone"
readonly GITHUB_REPO="develop_servezero"
readonly REPO_DIR=/usr/local/${APP_NAME}/repo
readonly PLAYBOOK="build_servezero"

# check root user
readonly USERID=`id | sed 's/uid=\([0-9]*\)(.*/\1/'`
echo $USERID;
if [ $USERID -ne 0 ]
then
    echo "error: can only excute by root"
    exit 1
fi

# Check os version
declare OS="unsupported os"
declare DIST_NAME="not ditected"

if [ "$(uname)" == 'Darwin' ]; then
    OS='Mac'
    uname -a
    exit 1
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    RELEASE_FILE=/etc/os-release
    if grep '^NAME="CentOS' ${RELEASE_FILE} >/dev/null; then
        OS="CentOS"
        DIST_NAME="CentOS"
    elif grep '^NAME="Rocky Linux' ${RELEASE_FILE} >/dev/null; then
        OS="CentOS"
        DIST_NAME="Rocky Linux"
    elif grep '^NAME="AlmaLinux' ${RELEASE_FILE} >/dev/null; then
        OS="CentOS"
        DIST_NAME="Alma Linux"
    elif grep '^NAME="Amazon' ${RELEASE_FILE} >/dev/null; then
        OS="Amazon Linux"
        DIST_NAME="Amazon Linux"
        uname -a
        exit 1
    elif grep '^NAME="Ubuntu' ${RELEASE_FILE} >/dev/null; then
        OS="Ubuntu"
        DIST_NAME="Ubuntu"
    else
        echo "Your platform is not supported."
        uname -a
        exit 1
    fi
elif [ "$(expr substr $(uname -s) 1 6)" == 'CYGWIN' ]; then
    OS='Cygwin'
    uname -a
    exit 1
else
    echo "Your platform is not supported."
    uname -a
    exit 1
fi

echo "########################################################################"
echo "# $DIST_NAME"
echo "# START BUILDING ENVIRONMENT"
echo "########################################################################"

# Prepare work directory
work_dir=$(mktemp -d -t ${APP_NAME}-XXXXXXXXXX)

# Get test mode
if [ "$1" == '-test' ]; then
    readonly TEST_MODE="true"
    
    echo "################# START TEST MODE #################"
else
    readonly TEST_MODE="false"
fi

declare INSTALL_PACKAGE_CMD=""
if [ $OS == 'CentOS' ]; then
    INSTALL_PACKAGE_CMD="yum -y install"
    
    # Repository update for latest ansible
    yum -y install epel-release
elif [ $OS == 'Ubuntu' ]; then
    if ! type -P ansible >/dev/null ; then
        INSTALL_PACKAGE_CMD="apt -y install"
    
        # Repository update for ansible
        apt -y update
        apt -y upgrade
        apt -y install software-properties-common
        apt-add-repository --yes --update ppa:ansible/ansible
    fi
fi

# Install ansible command if not exists
if [ "$INSTALL_PACKAGE_CMD" != '' ]; then
    $INSTALL_PACKAGE_CMD ansible
    $INSTALL_PACKAGE_CMD git
fi

# Download the latest repository archive
if [ $TEST_MODE == 'true' ]; then
    url="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/master.tar.gz"
    version="new"
else
    url=`curl -s "https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/tags" | grep "tarball_url" | \
        sed -n '/[ \t]*"tarball_url"/p' | head -n 1 | \
        sed -e 's/[ \t]*".*":[ \t]*"\(.*\)".*/\1/'`
    version=`basename $url | sed -e 's/v\([0-9\.]*\)/\1/'`
fi
filename=${GITHUB_REPO}_${version}.tar.gz
filepath=$work_dir/$filename

# Set current directory at work directory
cd $work_dir
savefilelist=`ls -1`

# Download archived repository
echo "########################################################################"
echo "Start download GitHub repository ${GITHUB_USER}/${GITHUB_REPO}" 
curl -s -o ${filepath} -L $url

# Remove old files
for file in $savefilelist; do
    if [ ${file} != ${filename} ]
    then
        rm -rf "${file}"
    fi
done

# Get archive directory name
destdir=`tar tzf ${filepath} | head -n 1`
destdirname=`basename $destdir`

# Unarchive repository
tar xzf ${filename}
find ./ -type f -name ".gitkeep" -delete
mv ${destdirname} ${GITHUB_REPO}
echo ${filename}" unarchived"

# launch ansible
mkdir -p ${REPO_DIR}
mv $work_dir/${GITHUB_REPO} ${REPO_DIR}
cd ${REPO_DIR}/${GITHUB_REPO}/playbooks/${PLAYBOOK}
rm -rf $work_dir
ansible-galaxy install --role-file=requirements.yml --roles-path=/etc/ansible/roles --force
ansible-playbook -i localhost, main.yml
