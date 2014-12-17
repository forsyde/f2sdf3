<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:param name="application-name" required="yes" />
	<xsl:param name="inputFolder" required="yes" />
	<xsl:param name="outputFolder" required="yes" />
	<xsl:param name="fanouts" required="no" />
	<xsl:param name="initial-tokens-file" required="no" />
	<xsl:param name="size-properties-file" required="no" />
	<xsl:param name="execution-times" required="no" />


	<!-- Input File -->
	<xsl:variable name="initial-token-sizes">
		<xsl:copy-of select="document($initial-tokens-file)/initialTokens"/>
	</xsl:variable>

	<xsl:variable name="size-properties">
		<xsl:copy-of select="document($size-properties-file)/size_info"/>
	</xsl:variable>

	<xsl:variable name="execution-time-properties">
		<xsl:copy-of select="document($execution-times)/execution_times"/>
	</xsl:variable>

	<xsl:output method="text" indent="no" />
	<xsl:output method="text" name="text-output" omit-xml-declaration="yes" indent="no" />
	<xsl:output method="xml" name="xml-output" indent="yes" encoding="UTF-8" />

	<xsl:include href="forsyde-flattener.xsl" />
	<xsl:include href="forsyde-graph-model.xsl" />
	<xsl:include href="graph-p2p-model.xsl"/>
	<xsl:include href="zip-unzip-remover.xsl" />
	<xsl:include href="constant-source-workaround.xsl" />
	<xsl:include href="p2p-graph-model.xsl"/>
	<xsl:include href="remove-delays.xsl"/>
	<xsl:include href="convert-to-sdf3.xsl"/>
    <!-- <xsl:include href="misc.xsl" /> -->

	<!-- SUMMARY -->
	<!-- ======= -->
	<!-- Phase 1: Bring all composite processes under a single hierarchical root -->
	<!-- Phase 2: Flatten the hierarchy, i.e get rid of the composite processes and ports -->
	<!-- Phase 3: Convert to graph model -->
	<!-- Phase 4: Convert to p2p linked model -->
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

	<xsl:variable name="forsyde-single-hierarchy">
		<xsl:apply-templates select="/" mode="hierarchy" >
			<xsl:with-param name="p_name" select="$application-name"/>
		</xsl:apply-templates>
	</xsl:variable>

	<xsl:variable name="forsyde-flattened">
		<xsl:apply-templates select="$forsyde-single-hierarchy" mode="flattened" />
	</xsl:variable>

	<xsl:variable name="forsyde-graph">
		<xsl:apply-templates select="$forsyde-flattened" mode="graph" />
	</xsl:variable>

	<xsl:variable name="forsyde-p2p">
		<xsl:apply-templates select="$forsyde-graph" mode="convert-p2p-model" />
	</xsl:variable>

	<xsl:variable name="forsyde-zippless-unzippless">
		<xsl:apply-templates select="$forsyde-p2p" mode="remove-zips-unzips" />
	</xsl:variable>

	<xsl:variable name="forsyde-fanout-removed">
		<xsl:apply-templates select="$forsyde-zippless-unzippless" mode="remove-fanouts" />
	</xsl:variable>

	<xsl:variable name="forsyde-constant-source-workaround">
		<xsl:apply-templates select="$forsyde-fanout-removed" mode="forsyde-constant-source-workaround" />
	</xsl:variable>

	<xsl:variable name="p2p-graph">
		<xsl:apply-templates select="$forsyde-constant-source-workaround" mode="convert-p2p-graph" />
	</xsl:variable>

	<xsl:variable name="graph-wo-delays">
		<xsl:apply-templates select="$p2p-graph" mode="remove-delays" />
	</xsl:variable>

	<xsl:variable name="sdf3-initial">
		<xsl:apply-templates select="$graph-wo-delays" mode="convert-to-sdf3" />
	</xsl:variable>

	<!-- <xsl:variable name="compsoc-with-size-properties">
		<xsl:apply-templates select="$sdf3-initial" mode="annotate-size-properties" />
	</xsl:variable>

	<xsl:variable name="compsoc-final">
		<xsl:apply-templates select="$compsoc-with-size-properties" mode="annotate-execution-times" />
	</xsl:variable>

	<xsl:variable name="graphml-output">
		<xsl:apply-templates select="$forsyde-flattened" mode="phase-graphml" />
	</xsl:variable>

	<xsl:variable name="srcextr-output">
		<xsl:apply-templates select="$forsyde-flattened" mode="phase-srcextr" />
	</xsl:variable> -->

	<!-- Root -->
	<xsl:template match="/">
		<!-- Outputs -->
		<xsl:text>Dumping Hierarchy Flattening Result (flattened-forsyde.xml)
		</xsl:text>
		<xsl:result-document href="flattened-forsyde.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-flattened" />
		</xsl:result-document>

		<!-- <xsl:text>Dumping Source Extraction Input File (source-extraction.txt)
		</xsl:text>
		<xsl:result-document href="source-extraction.txt" format="text-output">
			<xsl:copy-of select="$srcextr-output" />
		</xsl:result-document> -->

		<xsl:text>Dumping Zip Garph Conversion Results (forsyde-graph.xml)
		</xsl:text>
		<xsl:result-document href="forsyde-graph.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-graph" />
		</xsl:result-document>

		<xsl:text>Dumping Point-to-Point connections (forsyde-p2p.xml)
		</xsl:text>
		<xsl:result-document href="forsyde-p2p.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-p2p" />
		</xsl:result-document>

		<xsl:text>Dumping Zip/Unzip Removal Results (forsyde-zippless-unzippless.xml)
		</xsl:text>
		<xsl:result-document href="forsyde-zippless-unzippless.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-zippless-unzippless" />
		</xsl:result-document>

		<xsl:text>Dumping Fanout Removal Results (forsyde-fanout-removal.xml)
		</xsl:text>
		<xsl:result-document href="forsyde-fanout-removal.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-fanout-removed" />
		</xsl:result-document>

		<xsl:text>Dumping Constant and Source Process Workaround Results (forsyde-constant-source-workaround.xml)
		</xsl:text>
		<xsl:result-document href="forsyde-constant-source-workaround.xml" format="xml-output">
			<xsl:copy-of select="$forsyde-constant-source-workaround" />
		</xsl:result-document>

		<xsl:text>Dumping Reconstructed Graph (p2p-graph-reconstructed.xml)
		</xsl:text>
		<xsl:result-document href="p2p-graph-reconstructed.xml" format="xml-output">
			<xsl:copy-of select="$p2p-graph" />
		</xsl:result-document>

		<xsl:text>Dumping Delay Removal Results (graph-wo-delays.xml)
		</xsl:text>
		<xsl:result-document href="graph-wo-delays.xml" format="xml-output">
			<xsl:copy-of select="$graph-wo-delays" />
		</xsl:result-document>

		<!-- <xsl:if test="$initial-tokens-file !=''"> -->
			<xsl:text>Dumping Initial SDF3 Representation (sdf3-initial.xml)
			</xsl:text>
			<xsl:result-document href="sdf3-initial.xml" format="xml-output">
				<xsl:copy-of select="$sdf3-initial" />
			</xsl:result-document>
		<!-- </xsl:if> -->

		<!-- <xsl:if test="$size-properties-file !=''">
			<xsl:text>Dumping CompSOC Representation Annotated with Actor Memory Sizes and Token Sizes (compsoc-size-final.xml)
			</xsl:text>
			<xsl:result-document href="compsoc-size-final.xml" format="xml-output">
				<xsl:copy-of select="$compsoc-with-size-properties" />
			</xsl:result-document>
		</xsl:if>

		<xsl:if test="$execution-times !=''">
			<xsl:text>Dumping Final CompSOC Representation (compsoc-final.xml)
			</xsl:text>
			<xsl:result-document href="compsoc-final.xml" format="xml-output">
				<xsl:copy-of select="$compsoc-final" />
			</xsl:result-document>
		</xsl:if> -->
	</xsl:template>


</xsl:transform>
