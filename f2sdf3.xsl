<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="application-name" required="yes" />
    <xsl:param name="types" required="yes" />
    <xsl:param name="inputFolder" required="yes" />
    <xsl:param name="outputFolder" required="yes" />
    <xsl:param name="debug" required="no" select="false()"/>

    <xsl:output method="text" indent="no" />
    <xsl:output method="text" name="text-output" omit-xml-declaration="yes" indent="no" />
    <xsl:output method="xml" name="xml-output" indent="yes" encoding="UTF-8" />

    <xsl:include href="lib/forsyde-lib.xsl" />
    <xsl:include href="lib/forsyde-tran.xsl" />
    <xsl:include href="lib/data-types-lib.xsl" />



    <!-- SUMMARY -->
    <!-- ======= -->
    <!-- Phase 1a: Bring all composite processes under a single hierarchical root -->
    <!-- Phase 1b: Flatten the hierarchy, i.e get rid of the composite processes and ports -->
    <!-- Phase 1c: Convert to graph model -->
    <!-- Phase 2a: Flatten types and extract info -->
    <!-- Phase 2b: Annotate graph with type info -->
    <!-- Phase 5: Convert to p2p linked model -->
    <!-- Phase 5: Remove zip, unzip and fanout processes -->
    <!-- Phase 6: Deal with source and constant processes -->
    <!-- Phase 7: Reconstruct the graph for source generation-->
    <!-- Phase 8: Remove delays -->
    <!-- Phase 9: Convert to SDF3 representation -->
    <!-- Phase 10: Annotate actor memory size and token size properties -->
    <!-- Phase 11: Annotate execution times of actors -->
    <!-- Miscellaneous transformations -->

    <!-- Transformation pipeline -->
    <!-- ======================= -->

    <xsl:variable name="forsyde-single">	
	<xsl:apply-templates select="/" mode="hierarchy" >
	    <xsl:with-param name="p_name" select="$application-name"/>
	</xsl:apply-templates>
    </xsl:variable>

    <xsl:variable name="forsyde-flattened">
	<xsl:apply-templates select="$forsyde-single" mode="flattened" />
    </xsl:variable>

    <xsl:variable name="forsyde-graph">
	<xsl:apply-templates select="$forsyde-flattened" mode="graph" />
    </xsl:variable>

    <xsl:variable name="type-info">
	<xsl:apply-templates select="document($types)" mode="type-flatten" />
    </xsl:variable>


    <!-- Root -->
    <xsl:template match="/">


	<xsl:message> 
	== Flattening the data types  == 
	</xsl:message>
	<xsl:result-document href="flat-types.xml" format="xml-output">
	    <xsl:copy-of select="$type-info" />
	</xsl:result-document>
	<xsl:message>(dumped intermediate result in 'flat-types.xml') </xsl:message>


	<!-- Outputs -->
	<xsl:message> 
	== Gathering all ForSyDe-IR components under one hierarchical node == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="forsyde-single.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-single" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'forsyde-single.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Performing Hierarchy Flattening Result == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="forsyde-flat.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-flattened" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'forsyde-flat.xml') </xsl:message>
	</xsl:if>


	<xsl:message> 
	== Translating the process network into a graph  == 
	</xsl:message>
	<xsl:result-document href="graph-initial.xml" format="xml-output">
	    <xsl:copy-of select="$forsyde-graph" />
	</xsl:result-document>
	<xsl:message>(dumped intermediate result in 'graph-initial.xml') </xsl:message>




    </xsl:template>

</xsl:transform>
