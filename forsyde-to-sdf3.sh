#!/bin/bash
# first argument: the top-level input XML file
# second argument: the application name
# third argument: the folder for the input XML with trailing slash
mkdir -p output
cp DTD/forsyde.dtd $3
saxonb-xslt -s:$1 -xsl:converter.xsl -o:output/converter.log -dtd:off -ext:on application-name=$2 inputFolder=$3 outputFolder=output
