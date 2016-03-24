<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Flatten Data structures -->
    <!-- ======================= -->
    <!-- Flattens the hierarchy of data structures to tuples of subtypes -->

    <xsl:template match="forsyde_types" mode="type-flatten">         <!-- entry mode -->
	<forsyde_types>
	    <xsl:apply-templates select="type" mode="type-flatten" />
	</forsyde_types>
    </xsl:template>

    <xsl:template match="type" mode="type-flatten">
	<xsl:if test="$debug"><xsl:message>[type-flat] : flattening the structure for '<xsl:value-of select="@name"/>'</xsl:message></xsl:if>
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<type name="{@name}" size="{$info/size/@value}">
	    <xsl:copy-of select="$info/token" />
	</type>
    </xsl:template>

    <xsl:template match="primitive" mode="type-traversal">
	<size value="{@size}" />
	<token name="{@name}" size="{@size}" />
    </xsl:template>

    <xsl:template match="custom" mode="type-traversal">
	<size value="{@size}" />
	<token name="{@name}" size="{@size}" />
    </xsl:template>

    <xsl:template match="array" mode="type-traversal">
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<xsl:variable name="size">
	    <xsl:value-of select="$info/size/@value * @length"/>
	</xsl:variable>
	<size value="{$size}" />
	<token name="{@name}" size="{@size}" />
    </xsl:template>

    <xsl:template match="tuple" mode="type-traversal">
	<xsl:if test="$debug"><xsl:message>[type-flat] : flattening the structure for tuple </xsl:message></xsl:if>
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<xsl:variable name="size">
	    <xsl:value-of select="sum($info/size/@value)"/>
	</xsl:variable>
	<size value="{$size}" />
	<xsl:copy-of select="$info/token" />
    </xsl:template>



    <!-- <xsl:template match="signal" mode="flattened"> -->
    <!-- 	<xsl:if test="$debug"><xsl:message>[flattened] : finding endpoints for '<xsl:value-of select="@name"/>'</xsl:message></xsl:if> -->
    <!-- 	<xsl:variable name="source_endpoint"> -->
    <!-- 	    <xsl:apply-templates select="../.." mode="flattened-find-deep-endpoint"> -->
    <!-- 		<xsl:with-param name="pr_name" select="@source" /> -->
    <!-- 		<xsl:with-param name="pr_port" select="@source_port" /> -->
    <!-- 	    </xsl:apply-templates> -->
    <!-- 	</xsl:variable> -->
    <!-- 	<xsl:variable name="target_endpoint"> -->
    <!-- 	    <xsl:apply-templates select="../.." mode="flattened-find-deep-endpoint"> -->
    <!-- 		<xsl:with-param name="pr_name" select="@target" /> -->
    <!-- 		<xsl:with-param name="pr_port" select="@target_port" /> -->
    <!-- 	    </xsl:apply-templates> -->
    <!-- 	</xsl:variable> -->
    <!-- 	<signal name="{concat(../@name, concat('_', @name))}"  -->
    <!-- 		source="{$source_endpoint/endpoint/@process_name}"  -->
    <!-- 		source_port="{$source_endpoint/endpoint/@process_port}"  -->
    <!-- 		target="{$target_endpoint/endpoint/@process_name}" -->
    <!-- 		target_port="{$target_endpoint/endpoint/@process_port}"> -->
    <!-- 	    <xsl:copy-of select="./@* except (@name, @source, @target, @source_port, @target_port)" /> -->
    <!-- 	</signal> -->
    <!-- </xsl:template> -->

    <!-- <xsl:template match="process_network" mode="flattened-find-deep-endpoint"> -->
    <!-- 	<xsl:param name="pr_name" /> -->
    <!-- 	<xsl:param name="pr_port" /> -->
    <!-- 	<xsl:variable name="pn_name" select="@name" /> -->
    <!-- 	<xsl:variable name="pn_full_name" select="concat($pn_name, concat('_', $pr_name))" /> -->
    <!-- 	<xsl:variable name="composite_pr" select="composite_process[@name = $pn_full_name]" /> -->
    <!-- 	<xsl:choose> -->
    <!-- 	    <xsl:when test="$composite_pr"> -->
    <!-- 		<xsl:variable name="composite_pr_port" select="$composite_pr/process_network/port[@name = $pr_port]" /> -->
    <!-- 		<xsl:apply-templates select="$composite_pr/process_network" mode="flattened-find-deep-endpoint"> -->
    <!-- 		    <xsl:with-param name="pr_name" select="$composite_pr_port/@bound_process"/> -->
    <!-- 		    <xsl:with-param name="pr_port" select="$composite_pr_port/@bound_port"/> -->
    <!-- 		</xsl:apply-templates> -->
    <!-- 	    </xsl:when> -->
    <!-- 	    <xsl:otherwise> -->
    <!-- 		<endpoint process_name="{$pn_full_name}" process_port="{$pr_port}"/> -->
    <!-- 	    </xsl:otherwise> -->
    <!-- 	</xsl:choose> -->
    <!-- </xsl:template> -->

    <!-- <xsl:template match="process_network" mode="flattened-processes"> -->
    <!-- 	<xsl:apply-templates select="leaf_process" mode="flattened" /> -->
    <!-- 	<xsl:for-each select="composite_process"> -->
    <!-- 	    <xsl:apply-templates select="process_network" mode="flattened-processes" /> -->
    <!-- 	</xsl:for-each> -->
    <!-- 	<xsl:if test="$debug"><xsl:message>[flattened-processes] : removed composite '<xsl:value-of select="@name"/>'</xsl:message></xsl:if> -->
    <!-- </xsl:template> -->

    <!-- <xsl:template match="leaf_process" mode="flattened"> -->
    <!-- 	<leaf_process name="{concat(../@name, concat('_', @name))}"> -->
    <!-- 	    <xsl:copy-of select="./*" /> -->
    <!-- 	</leaf_process> -->
    <!-- 	<xsl:if test="$debug"><xsl:message>[flattened] : renamed leaf '<xsl:value-of select="concat(../@name, concat('_', @name))"/>'</xsl:message></xsl:if> -->
    <!-- </xsl:template> -->



</xsl:transform>
