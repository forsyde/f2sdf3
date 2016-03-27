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
    <xsl:include href="lib/p2p-tran.xsl" />

    <!-- SUMMARY -->
    <!-- ======= -->
    <!-- Phase 1 : Flatten types and extract channel info -->
    <!-- Phase 2a: Bring all composite processes under a single hierarchical root -->
    <!-- Phase 2b: Flatten the hierarchy, i.e get rid of the composite processes and ports -->
    <!-- Phase 3a: Convert to graph model-->
    <!-- Phase 3b: Annotate graph with number of channels -->
    <!-- Phase 4a: Convert to p2p linked model -->
    <!-- Phase 4b: Find factors and update initial rates in p2p -->
    <!-- Phase 4c: Remove zip, unzip, fanout, source, constant and sink processes -->
    <!-- Phase 5a: Reconstruct the graph for source generation-->
    <!-- Phase 5b: Annotate graph with channel sizes -->
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
    <xsl:variable name="graph-initial">
	<xsl:apply-templates select="$forsyde-flattened" mode="graph" />
    </xsl:variable>
    <xsl:variable name="graph-count">
	<xsl:apply-templates select="$graph-initial" mode="graph-channel-count" >
	    <xsl:with-param name="types_base" select="$type-info"/>
	</xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="p2p-initial">
	<xsl:apply-templates select="$graph-count" mode="graph-to-p2p" />
    </xsl:variable>
    <xsl:variable name="p2p-factors">
	<xsl:apply-templates select="$p2p-initial" mode="p2p-factors-upd-rates"/>
    </xsl:variable>
    <xsl:variable name="p2p-with-rates">
	<xsl:apply-templates select="$p2p-factors" mode="p2p-initial-tokens"/>
    </xsl:variable>
    <xsl:variable name="p2p-with-types">
	<xsl:apply-templates select="$p2p-with-rates" mode="p2p-fix-types"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-zips">
	<xsl:apply-templates select="$p2p-with-types" mode="p2p-remove-zips-unzips"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-fanouts">
	<xsl:apply-templates select="$p2p-no-zips" mode="p2p-remove-all-fanouts"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-sources">
	<xsl:apply-templates select="$p2p-no-fanouts" mode="p2p-remove-sources"/>
    </xsl:variable>
    <xsl:variable name="p2p-no-delays">
	<graph name="{$application-name}">
	    <xsl:apply-templates select="$p2p-no-sources" mode="p2p-remove-delays"/>
	</graph>
    </xsl:variable>
    <xsl:variable name="graph-reconstructed">
	<xsl:apply-templates select="$p2p-no-delays" mode="p2p-to-graph">
	    <xsl:with-param name="original_graph" select="$graph-count"/>
	</xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="graph-sizes">
	<xsl:apply-templates select="$graph-reconstructed" mode="graph-channel-sizes" >
	    <xsl:with-param name="types_base" select="$type-info"/>
	</xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="sdf3-initial">
	<xsl:apply-templates select="$graph-sizes" mode="graph-to-sdf3">
	</xsl:apply-templates>
    </xsl:variable>

    <!-- Root -->
    <xsl:template match="/">

	<xsl:message> 
	== Phase 1 : Flattening the data types == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="1_types-flat.xml" format="xml-output">
		<xsl:copy-of select="$type-info" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '1_types-flat.xml') </xsl:message>
	</xsl:if>


	<!-- Outputs -->
	<xsl:message> 
	== Phase 2 : Flattening ForSyDe process network == 
	</xsl:message>
	<xsl:if test="$debug"> 
	    <xsl:result-document href="2_forsyde-flat.xml" format="xml-output">
		<xsl:copy-of select="$forsyde-flattened" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '2_forsyde-flat.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 3 : Translating the process network into a graph and annotating it == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="3_graph-initial.xml" format="xml-output">
		<xsl:copy-of select="$graph-count" />
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '3_graph-initial.xml') </xsl:message>
	</xsl:if>


	<xsl:message> 
	== Phase 4a: Converting the graph into point-to-point model == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="4_p2p-initial.xml" format="xml-output">
		<xsl:copy-of select="$p2p-initial"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '4a_p2p-initial.xml') </xsl:message>
	</xsl:if>


	<xsl:message> 
	== Phase 4b-c: Performing all kind of stuff on the point-to-point model == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="5_p2p-modified.xml" format="xml-output">
		<xsl:copy-of select="$p2p-no-delays"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '4c_p2p-modified.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 5: Reconstructing graph from point-to-point model and annotating it == 
	</xsl:message>
	<xsl:if test="$debug">
	    <xsl:result-document href="6_graph-reconstructed.xml" format="xml-output">
		<xsl:copy-of select="$graph-sizes"/>
	    </xsl:result-document>
	    <xsl:message>(dumped intermediate result in '5_graph-reconstructed.xml') </xsl:message>
	</xsl:if>

	<xsl:message> 
	== Phase 6 : Converting annotated graph to SDF3 model == 
	</xsl:message>
	<xsl:result-document href="sdf3.xml" format="xml-output">
	    <xsl:copy-of select="$sdf3-initial"/>
	</xsl:result-document>
	<xsl:message>(dumped final result in 'sdf3.xml') </xsl:message>

    </xsl:template>

</xsl:transform>
