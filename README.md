# f2sdf3: A Converter from ForSyDe-IR to the SDF3 Application Format


## DESCRIPTION

This tool converts the intermediate representation of ForSyDe models
which can be automatically generated from ForSyDe-SystemC executable
models to the application format accepted by the [SDF3 tool set](http://www.es.ele.tue.nl/sdf3/).
The input ForSyDe model needs to be in the synchronous data flow (SDF)
model of computation.

The conversion is implemented using XSL transfomations. Assuming the
availability of the [Saxon XSLT](http://saxon.sourceforge.net/) in the path,
a top level shell scripts invokes the transformation.

This tool is based on a [master thesis](http://www.diva-portal.org/smash/get/diva2:647797/FULLTEXT01.pdf)
performed by Ekrem Altinel.

More information, might become available from [wiki pages](http://forsyde.ict.kth.se/).


## INSTALLATION
The top-level folder needs to be copied to an accessible place.
