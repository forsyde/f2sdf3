<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Annotate graph with type information -->
    <!-- ==================================== -->
    <!-- Grab flatten type information and annotate the appropriate channel/port attributes -->

    <xsl:template match="graph" mode="graph-type-annotate">
	<xsl:param name="types_base" />
	<graph name="{@name}">
	    <xsl:if test="$debug">
		<xsl:message>[graph-type-annotate] : annotating the edges of '<xsl:value-of select="@name"/>' </xsl:message>
	    </xsl:if>
	    <xsl:apply-templates select="edge" mode="graph-type-annotate">
		<xsl:with-param name="all_types" select="$types_base/forsyde_types"/>
	    </xsl:apply-templates>
	    <xsl:if test="$debug">
		<xsl:message>[graph-type-annotate] : annotating the node ports of '<xsl:value-of select="@name"/>' </xsl:message>
	    </xsl:if>	    
	    <xsl:apply-templates select="node" mode="graph-type-annotate">
		<xsl:with-param name="all_types" select="$types_base/forsyde_types"/>
	    </xsl:apply-templates>
	</graph>
    </xsl:template>
    
    <xsl:template match="edge" mode="graph-type-annotate">
	<xsl:param name="all_types" />
	<xsl:variable name="curr_type"><xsl:value-of select="@type"/></xsl:variable>
	<edge>
	    <xsl:copy-of select="./@*" />
	    <xsl:attribute name="token_size">
		<xsl:value-of select="sum($all_types/type[@name=$curr_type]/token/@size)" />
	    </xsl:attribute>
	    <xsl:attribute name="signal_count">
		<xsl:value-of select="count($all_types/type[@name=$curr_type]/token)" />
	    </xsl:attribute>
	</edge>
    </xsl:template>

    <xsl:template match="node" mode="graph-type-annotate">
	<xsl:param name="all_types" />
	<node>
	    <xsl:copy-of select="./@*" />
	    <xsl:apply-templates select="output" mode="graph-type-annotate">
		<xsl:with-param name="all_types" select="$all_types"/>
	    </xsl:apply-templates>
	    <xsl:apply-templates select="input" mode="graph-type-annotate">
		<xsl:with-param name="all_types" select="$all_types"/>
	    </xsl:apply-templates>
	</node>
    </xsl:template>
    
    <xsl:template match="output" mode="graph-type-annotate">
	<xsl:param name="all_types" />
	<xsl:variable name="curr_type"><xsl:value-of select="@type"/></xsl:variable>
	<output>
	    <xsl:copy-of select="./@*" />
	    <xsl:attribute name="output_count">
		<xsl:value-of select="count($all_types/type[@name=$curr_type]/token)" />
	    </xsl:attribute>
	</output>
    </xsl:template>

    <xsl:template match="input" mode="graph-type-annotate">
	<xsl:param name="all_types" />
	<xsl:variable name="curr_type"><xsl:value-of select="@type"/></xsl:variable>
	<input>
	    <xsl:copy-of select="./@*" />
	    <xsl:attribute name="input_count">
		<xsl:value-of select="count($all_types/type[@name=$curr_type]/token)" />
	    </xsl:attribute>
	</input>
    </xsl:template>



    <!-- Phase 8: Transform delays into initial tokens -->
    <!-- ====================== -->
    
    <xsl:template match="graph" mode="remove-delays">
	<graph name="{@name}">
	    <xsl:apply-templates select="edge" mode="remove-delays"/>
	    <xsl:apply-templates select="node" mode="remove-delays-linearize-outputs"/>
	</graph>
    </xsl:template>
    
    <xsl:template match="edge" mode="remove-delays">
	<edge>
	    <xsl:copy-of select="./@*" />
	    <xsl:attribute name="initial_tokens">
		<xsl:value-of select="./delay/@n" />
	    </xsl:attribute>
	</edge>
    </xsl:template>

    <xsl:template match="node" mode="remove-delays-linearize-outputs">
	<xsl:variable name="fn">
	    <xsl:choose>
		<xsl:when test="@function = ''">
		    <xsl:value-of select="concat(@name, '_func')"/>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:value-of select="@function"/>
		</xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<node function="{$fn}">
	    <xsl:copy-of select="./@* except @function" />
	    <xsl:copy-of select="input" />
	    <xsl:for-each select="output">
		<xsl:choose>
		    <xsl:when test="count(fanout) &gt; 0">
			<xsl:apply-templates select="fanout[1]" mode="convert-fanout-to-output"/>
		    </xsl:when>
		    <xsl:otherwise>
			<xsl:copy-of select="." />
		    </xsl:otherwise>
		</xsl:choose>
	    </xsl:for-each>
	    <xsl:for-each select="output">
		<xsl:if test="count(fanout) &gt; 1">
		    <xsl:for-each select="fanout[position() > 1]">
			<xsl:apply-templates select="." mode="convert-fanout-to-output"/>
		    </xsl:for-each>
		</xsl:if>
	    </xsl:for-each>
	</node>
    </xsl:template>

    <xsl:template match="fanout" mode="convert-fanout-to-output">
	<xsl:variable name="output" select="./.."/>
	<output name="{@name}" type="{$output/@type}" rate="{$output/@rate}" target="{@target}" target_port="{@target_port}" output_count="{$output/@output_count}"/>
    </xsl:template>	
    
</xsl:transform>
