<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="application-name" required="yes" />
    <xsl:param name="types"        required="yes" />
    <xsl:param name="inputFolder"  required="yes" />
    <xsl:param name="outputFolder" required="yes" />
    <xsl:param name="debug"        required="no" select="false()"/>
    <xsl:param name="permissive"   required="no" select="false()"/>

    <xsl:output method="text" indent="no" />
    <xsl:output method="text" name="text-output" omit-xml-declaration="yes" indent="no" />
    <xsl:output method="xml"  name="xml-output" indent="yes" encoding="UTF-8" />

    <xsl:include href="lib/data-types-lib.xsl" />
    <xsl:include href="lib/forsyde-lib.xsl" />
    <xsl:include href="lib/forsyde-tran.xsl" />
    <xsl:include href="lib/graph-lib.xsl" />
    <xsl:include href="lib/graph-tran.xsl" />
    <xsl:include href="lib/p2p-lib.xsl" />

    <!-- SUMMARY -->
    <!-- ======= -->
    <!-- Phase 1 : Flatten types and extract channel info -->
    <!-- Phase 2a: Bring all composite processes under a single hierarchical root -->
    <!-- Phase 2b: Flatten the hierarchy, i.e get rid of the composite processes and ports -->
    <!-- Phase 3a: Convert to graph model-->
    <!-- Phase 3b: Annotate graph with type info -->
    <!-- Phase 4a: Convert to p2p linked model -->
    <!-- Phase 4b: Find factors and update initial rates in p2p -->
    <!-- Phase 4c: Remove zip, unzip, fanout, source, constant and sink processes -->
    <!-- Phase 5a: Reconstruct the graph for source generation-->
    <!-- Phase 5b: Remove delays -->
    <!-- Phase 6 : Convert to SDF3 representation -->

    <!-- Transformation pipeline -->
    <!-- ======================= -->

    <xsl:variable name="type-info">
	<xsl:apply-templates select="document($types)" mode="type-flatten" />
    </xsl:variable>
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
    <xsl:variable name="annotated-graph">
	<xsl:apply-templates select="$forsyde-graph" mode="graph-type-annotate" >
	    <xsl:with-param name="types_base" select="$type-info"/>
	</xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="p2p-initial">
	<xsl:apply-templates select="$annotated-graph" mode="graph-to-p2p" />
    </xsl:variable>
    <xsl:variable name="p2p-factors">
	<xsl:apply-templates select="$p2p-initial" mode="p2p-factors-upd-rates"/>
    </xsl:variable>
    <xsl:variable name="p2p-with-rates">
	<xsl:apply-templates select="$p2p-factors" mode="p2p-initial-tokens"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-zips">
	<xsl:apply-templates select="$p2p-with-rates" mode="p2p-remove-zips-unzips"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-fanouts">
	<xsl:apply-templates select="$p2p-no-zips" mode="p2p-remove-all-fanouts"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-sources">
	<xsl:apply-templates select="$p2p-no-fanouts" mode="p2p-remove-sources">
	    <xsl:with-param name="graph" select="$annotated-graph" />
	</xsl:apply-templates>
    </xsl:variable>


    <!-- Root -->
    <xsl:template match="/">

	<xsl:message> 
	== Phase 1 : Flattening the data types == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="types-flat.xml" format="xml-output">
		<xsl:copy-of select="$type-info" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'types-flat.xml') </xsl:message>
	</xsl:if>


	<!-- Outputs -->
	<xsl:message> 
	== Phase 2a: Gathering all ForSyDe-IR components under one hierarchical node == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="forsyde-single.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-single" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'forsyde-single.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 2b: Performing Hierarchy Flattening Result == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="forsyde-flat.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-flattened" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'forsyde-flat.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 3a: Translating the process network into a graph == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="graph-initial.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-graph" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'graph-initial.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 3b: Annotating the graph with type information == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="graph-annotated.xml" format="xml-output">
		<xsl:copy-of select="$annotated-graph"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'graph-annotated.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 4a: Converting the graph into point-to-point model == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="p2p-initial.xml" format="xml-output">
x		<xsl:copy-of select="$p2p-initial"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'p2p-initial.xml') </xsl:message>
	</xsl:if>


	<xsl:message> 
	== Phase 4b: Finding rates in point-to-point model == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="p2p-with-rates.xml" format="xml-output">
		<xsl:copy-of select="$p2p-with-rates"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'p2p-with-rates.xml') </xsl:message>
	</xsl:if>



	<xsl:message> 
	== Phase 4c: Removing auxiliary processes (zip, unzip, fanout, sources, sinks...) in point-to-point model == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="p2p-without-aux.xml" format="xml-output">
		<xsl:copy-of select="$p2p-no-sources"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in 'p2p-without-aux.xml') </xsl:message>
	</xsl:if>

    </xsl:template>

</xsl:transform>
