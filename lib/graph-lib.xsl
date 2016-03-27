<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Annotate graph with number of channels -->
    <!-- ====================================== -->
    <!-- Grab flatten type information and annotate the appropriate -->
    <!-- channel/port attributes with the counted number of tokens  -->

    <xsl:template match="graph" mode="graph-channel-count">
	<xsl:param name="types_base" />
	<graph name="{@name}">
	    <xsl:copy-of select="./edge" />	    
	    <xsl:if test="$debug">
		<xsl:message>[graph-channel-count] : annotating the node ports of '<xsl:value-of select="@name"/>' </xsl:message>
	    </xsl:if>	    
	    <xsl:apply-templates select="node" mode="graph-channel-count">
		<xsl:with-param name="all_types" select="$types_base/forsyde_types"/>
	    </xsl:apply-templates>
	</graph>
    </xsl:template>
    
    <xsl:template match="node" mode="graph-channel-count">
	<xsl:param name="all_types" />
	<node>
	    <xsl:copy-of select="./@*" />
	    <xsl:for-each select="output">
		<xsl:variable name="curr_type" select="@type"/>
		<output>
		    <xsl:copy-of select="./@*" />
		    <xsl:attribute name="output_count">
			<xsl:value-of select="count($all_types/type[@name=$curr_type]/token)" />
		    </xsl:attribute>
		</output>
	    </xsl:for-each>
	    <xsl:for-each select="input">
		<xsl:variable name="curr_type" select="@type"/>
		<input>
		    <xsl:copy-of select="./@*" />
		    <xsl:attribute name="input_count">
			<xsl:value-of select="count($all_types/type[@name=$curr_type]/token)" />
		    </xsl:attribute>
		</input>
	    </xsl:for-each>
	</node>
    </xsl:template>


    <!-- Annotate graph with channel sizes -->
    <!-- ================================= -->
    <!-- Grab flatten type information and annotate the appropriate -->
    <!-- channel/port attributes with the token sizes  -->

    <xsl:template match="graph" mode="graph-channel-sizes">
	<xsl:param name="types_base" />
	<graph name="{@name}">
	    <xsl:if test="$debug">
		<xsl:message>[graph-channel-sizes] : annotating the edges of '<xsl:value-of select="@name"/>' </xsl:message>
	    </xsl:if>	    
	    <xsl:for-each select="edge">
		<xsl:variable name="curr_type" select="./@type"/>
		<xsl:variable name="curr_size" select="$types_base/forsyde_types/type[@name=$curr_type]/@size"/>
		<edge>
		    <xsl:copy-of select="./@*" />
		    <xsl:attribute name="token_size">
			<xsl:value-of select="$curr_size" />
		    </xsl:attribute>    
		</edge>
		<xsl:if test="$debug"> 
		    <xsl:message>[graph-channel-sizes] : edge '<xsl:value-of 
		    select="./@name"/>' of type '<xsl:value-of 
		    select="$curr_type"/>' has size <xsl:value-of 
		    select="$curr_size"/> </xsl:message> 
		</xsl:if>
		<xsl:if test="$curr_size = ''"> 
		    <xsl:choose>
			<xsl:when test="$permissive">
			    <xsl:message>[graph-channel-sizes] : WARNING! could not find size for '<xsl:value-of 
			    select="./@name"/>' </xsl:message>
			</xsl:when>
			<xsl:otherwise>
			    <xsl:message terminate="yes">[graph-channel-sizes] : ERROR! could not find size for '<xsl:value-of 
			    select="./@name"/>' Aborting! </xsl:message>
			</xsl:otherwise>
		    </xsl:choose>
		</xsl:if>	
	    </xsl:for-each>
	    <xsl:copy-of select="node" />
	</graph>
    </xsl:template>

    <!-- <xsl:template match="edge" mode="graph-channel-sizes"> -->
    <!-- 	<xsl:param name="all_types" /> -->
    <!-- 	<edge> -->
    <!-- 	    <xsl:copy-of select="./@*" />    -->
    <!-- 	    <xsl:variable name="this" select="."/> -->
    <!-- 	    <xsl:variable name="src_type_id" select="$graph/node[@name = $this/@source]/output[@name = $this/@source_port]/@type"/> -->
    <!-- 	    <xsl:variable name="trg_type_id" select="$graph/node[@name = $this/@target]/input[@name = $this/@target_port]/@type"/> -->
    <!-- 	    <xsl:variable name="src" select="$all_types/type[@name = $src_type_id]/token[position() = $this/@source_port_idx]"/> -->
    <!-- 	    <xsl:variable name="trg" select="$all_types/type[@name = $trg_type_id]/"/> -->
    <!-- 	    <xsl:if test="$debug"> -->
    <!-- 		<xsl:message>[graph-channel-sizes] : type for edge '<xsl:value-of select="@name"/>': <xsl:value-of select="$src_type_id"/> and <xsl:value-of select="$trg_type_id"/> </xsl:message> -->
    <!-- 	    </xsl:if> -->
    <!-- 	    <xsl:if test="$src/@name != '' and $trg/@name != '' and not($src/@name = $trg/@name and $src/@size = $trg/@size )"> -->
    <!-- 		<xsl:message>[graph-channel-sizes] : ERROR!!!type for edge '<xsl:value-of select="@name"/>': <xsl:value-of select="$src/@name"/> and <xsl:value-of select="$trg/@name"/> </xsl:message> -->
    <!-- 	    </xsl:if> -->
    <!-- 	    <xsl:attribute name="type"> <xsl:value-of select="$src/@name" /> </xsl:attribute> -->
    <!-- 	    <xsl:attribute name="token_size"> <xsl:value-of select="$src/@size" /> </xsl:attribute> -->
    <!-- 	</edge> -->
    <!-- </xsl:template> -->
    
    

    <!-- Phase 8: Transform delays into initial tokens -->
    <!-- ====================== -->
    
    <!-- <xsl:template match="graph" mode="remove-delays"> -->
    <!-- 	<graph name="{@name}"> -->
    <!-- 	    <xsl:apply-templates select="edge" mode="remove-delays"/> -->
    <!-- 	    <xsl:apply-templates select="node" mode="remove-delays-linearize-outputs"/> -->
    <!-- 	</graph> -->
    <!-- </xsl:template> -->
    
    <!-- <xsl:template match="edge" mode="remove-delays"> -->
    <!-- 	<edge> -->
    <!-- 	    <xsl:copy-of select="./@*" /> -->
    <!-- 	    <xsl:attribute name="initial_tokens"> -->
    <!-- 		<xsl:value-of select="./delay/@n" /> -->
    <!-- 	    </xsl:attribute> -->
    <!-- 	</edge> -->
    <!-- </xsl:template> -->

    <!-- <xsl:template match="node" mode="remove-delays-linearize-outputs"> -->
    <!-- 	<xsl:variable name="fn"> -->
    <!-- 	    <xsl:choose> -->
    <!-- 		<xsl:when test="@function = ''"> -->
    <!-- 		    <xsl:value-of select="concat(@name, '_func')"/> -->
    <!-- 		</xsl:when> -->
    <!-- 		<xsl:otherwise> -->
    <!-- 		    <xsl:value-of select="@function"/> -->
    <!-- 		</xsl:otherwise> -->
    <!-- 	    </xsl:choose> -->
    <!-- 	</xsl:variable> -->
    <!-- 	<node function="{$fn}"> -->
    <!-- 	    <xsl:copy-of select="./@* except @function" /> -->
    <!-- 	    <xsl:copy-of select="input" /> -->
    <!-- 	    <xsl:for-each select="output"> -->
    <!-- 		<xsl:choose> -->
    <!-- 		    <xsl:when test="count(fanout) &gt; 0"> -->
    <!-- 			<xsl:apply-templates select="fanout[1]" mode="convert-fanout-to-output"/> -->
    <!-- 		    </xsl:when> -->
    <!-- 		    <xsl:otherwise> -->
    <!-- 			<xsl:copy-of select="." /> -->
    <!-- 		    </xsl:otherwise> -->
    <!-- 		</xsl:choose> -->
    <!-- 	    </xsl:for-each> -->
    <!-- 	    <xsl:for-each select="output"> -->
    <!-- 		<xsl:if test="count(fanout) &gt; 1"> -->
    <!-- 		    <xsl:for-each select="fanout[position() > 1]"> -->
    <!-- 			<xsl:apply-templates select="." mode="convert-fanout-to-output"/> -->
    <!-- 		    </xsl:for-each> -->
    <!-- 		</xsl:if> -->
    <!-- 	    </xsl:for-each> -->
    <!-- 	</node> -->
    <!-- </xsl:template> -->

    <!-- <xsl:template match="fanout" mode="convert-fanout-to-output"> -->
    <!-- 	<xsl:variable name="output" select="./.."/> -->
    <!-- 	<output name="{@name}" type="{$output/@type}" rate="{$output/@rate}" target="{@target}" target_port="{@target_port}" output_count="{$output/@output_count}"/> -->
    <!-- </xsl:template>	 -->
    
</xsl:transform>
