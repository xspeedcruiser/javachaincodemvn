#!/usr/bin/env bash
#Copyright DTCC 2016 All Rights Reserved.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#

# define maven and gradle variables ( gradle must be in a PATH )
MAVEN_EXE=/usr/bin/mvn
POM_FILE=pom.xml
GRADLE_EXE=`which gradle`
GRADLE_BUILD_FILE=build.gradle

#expected output
CHAINCODE_JAR=./build/chaincode.jar
CURRENT_FOLDER=`pwd`

#determine which build to use. If not specified - maven is default.
# if maven pom.xml is present in a current folder - build with maven
# otherwise if build.gradle present - build with gradle
THIS_BUILD="NA"
if [ -f $GRADLE_BUILD_FILE ];then
  THIS_BUILD="GRADLE"
else if [ -f $POM_FILE ];then
  THIS_BUILD="MAVEN"
else
    echo "pom.xml is not found in a current folder $PWD"
    echo "build.gradle is not found in a current folder $PWD"
    exit 1
  fi
fi


if [ $THIS_BUILD = "MAVEN" ]; then
  echo "Building chaincode with maven... "
  $MAVEN_EXE -f $POM_FILE clean > $CURRENT_FOLDER/chaincode_build.log
  $MAVEN_EXE -f $POM_FILE package >> $CURRENT_FOLDER/chaincode_build.log
  cd $CURRENT_FOLDER
  success=`grep -c "BUILD SUCCESS" chaincode_build.log`
fi

if [ $THIS_BUILD = "GRADLE" ]; then
  echo "Building chaincode with gradle ..."
  $GRADLE_EXE -b $GRADLE_BUILD_FILE clean > chaincode_build.log
  $GRADLE_EXE -b $GRADLE_BUILD_FILE build >> chaincode_build.log
  success=`grep -c "BUILD SUCCESSFUL" chaincode_build.log`
fi

if [ $success = "2" ];then
  echo "build completed successfully"
    #copy for execution in container
  if [ "$#" -ge 1 ];then
      ENV=`echo $1 | tr '[:lower:]' '[:upper:]'`

      if [ "${ENV}" = "DOCKER" ]; then
        echo "Copy files to /root"
        cp $CHAINCODE_JAR /root
        echo "chaincode.jar is available in /root"
      fi
  fi

  
else
 echo "build failed. Please check chaincode_build.log"
 cat $CURRENT_FOLDER/chaincode_build.log
fi