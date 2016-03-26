# ForSyDe-M2M

_ForSyDe-M2M_ is a collection of model-to-model transformation tools used in 
the ForSyDe design flow and centered around the ForSyDe XML intermediate 
represenation. It is used as a library of utilities for translating between the
ForSyDe XML intermediate representation and other XML-based models.

## Installation

The top-level folder needs to be copied to an accessible place. The runner scripts
described in the following sections are invoking a set of transformations found
in the `lib` directory.

The scripts are written in the [XSLT language](http://www.w3schools.com/xsl/xsl_intro.asp),
thus we shall assume the availability of an appropriate parser, such as 
[Saxon XSLT](http://saxon.sourceforge.net/). In this case, for example, a runner
script can be executed using the command:

```
saxonb-xslt -s:<input.xml> -xsl:<runner.xsl> -o:<log-file> -dtd:[off|on] -ext:on [runner-arguments]
```

Please consult the parser's manual for a detailed description of the command
arguments.

## f2sdf3

This runner script converts the intermediate representation of ForSyDe models
which can be automatically generated from ForSyDe-SystemC executable
models to the application format accepted by the [SDF3 tool set](http://www.es.ele.tue.nl/sdf3/).
This tool is based on a [master thesis](http://www.diva-portal.org/smash/get/diva2:647797/FULLTEXT01.pdf)
performed by Ekrem Altinel at KTH.

The input ForSyDe model needs to be in the synchronous data flow (SDF)
model of computation, and generated with both the model and type introspection
features activated, since it requires type structure information for correctly 
creating channels between actors.

The script is executed with the following command arguments:
 * `application-name` : the name of the generated application graph (required) 
 * `types` : the full path of the XML file containing the type structures for this process network (required)
 * `inputFolder` : the full path (with trailing `/`) of the directory containing the ForSyDe-IR generated files (required)
 * `outputFolder` : the full path (with trailing `/`) of the output directory (required)
 * `debug` : if set to _true()_, it enables verbose mode. It dumps intermediate XML files into `outputFolder` and logs all transformations steps in `outputFolder/log`. (optional, default _false()_)
 * `permissive` : if set to _true()_, it enables permissive mode. This means that if non-critical information is not found (for example if data type sizes cannot be calculated) the execution is not halted. The missing information can be introduced manually or in later design stages. (optional, default _false()_)


