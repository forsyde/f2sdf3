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

    <xsl:template match="vector" mode="type-traversal">
	<xsl:choose>
	    <xsl:when test="$permissive">
		<xsl:message>[type-traversal] : WARNING! found vector. Impossible to calculate token sizes. 
		The rest of the design flow should not be dependent on channel sizes!</xsl:message>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:message terminate="yes">[type-traversal] : ERROR! found vector. Impossible to calculate channel sizes. 
		If this is not an issue re-run this application with the 'permissive' flag set to true.
		Aborting!</xsl:message>
	    </xsl:otherwise>
	</xsl:choose>
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<token name="vector({$info/token/@name})" size="" />
    </xsl:template>

    <xsl:template match="array" mode="type-traversal">
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<xsl:variable name="size">
	    <xsl:value-of select="$info/size/@value * @length"/>
	</xsl:variable>
	<size value="{$size}" />
	<token name="array({$info/token/@name})" size="{$size}" />
    </xsl:template>

    <xsl:template match="tuple" mode="type-traversal">
	<xsl:variable name="info">
	    <xsl:apply-templates select="*" mode="type-traversal" />
	</xsl:variable>
	<xsl:variable name="size">
	    <xsl:value-of select="sum($info/size/@value)"/>
	</xsl:variable>
	<size value="{$size}" />
	<xsl:copy-of select="$info/token" />
	<xsl:if test="$debug">
	    <xsl:message>[type-traversal] : found tuple with <xsl:value-of select="count($info/token)" /> tokens... </xsl:message>
	</xsl:if>
    </xsl:template>

</xsl:transform>
