<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Gather IR files  -->
    <!-- ================ -->
    <!-- Generates a single hierarchical tree with one process_network element -->
    <!-- at the root and nested composite_process elements with process_network elements. -->

    <xsl:template match="process_network" mode="hierarchy">     <!-- entry mode -->
	<xsl:param name="p_name" />                             <!-- parameter -->
	<xsl:variable name="pn_name">                           <!-- variable -->
	    <xsl:choose>
  		<xsl:when test="$p_name != ''">
  		    <xsl:value-of select="$p_name" />
  		</xsl:when>
  		<xsl:otherwise>
  		    <xsl:value-of select="@name" />
  		</xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<xsl:if test="$debug"><xsl:message>[hierarchy] : started gathering all processes under '<xsl:value-of select="$pn_name"/>' </xsl:message></xsl:if>
	<process_network name="{$pn_name}"> 
	    <xsl:apply-templates select="port" mode="hierarchy" />
	    <xsl:apply-templates select="signal" mode="hierarchy" />
	    <xsl:apply-templates select="leaf_process" mode="hierarchy" />
	    <xsl:apply-templates select="composite_process" mode="hierarchy">
  		<xsl:with-param name="p_name" select="$pn_name" />
	    </xsl:apply-templates>
	</process_network>
    </xsl:template>

    <xsl:template match="port" mode="hierarchy">
	<xsl:copy-of select="." />
    </xsl:template>

    <xsl:template match="signal" mode="hierarchy">
	<xsl:copy-of select="." />
    </xsl:template>

    <xsl:template match="leaf_process" mode="hierarchy">
	<xsl:copy-of select="." />
    </xsl:template>

    <xsl:template match="composite_process" mode="hierarchy">
	<xsl:param name="p_name" />
	<xsl:if test="$debug"><xsl:message>[hierarchy] : attaching '<xsl:value-of select="@name"/>' to '<xsl:value-of select="$p_name"/>'</xsl:message></xsl:if>
	<composite_process name="{concat($p_name, '_', @name)}" component_name="@component_name">
	    <xsl:apply-templates select="document(concat($inputFolder, @component_name, '.xml'))/process_network" mode="hierarchy">
		<xsl:with-param name="p_name" select="concat($p_name, '_', @name)" />
	    </xsl:apply-templates>
	</composite_process>
    </xsl:template>



    <!-- Flatten ForSyDe IR -->
    <!-- ================== -->
    <!-- Removes the composite_process and port elements, moves the nested signal and leaf_process -->
    <!-- elements to the first hierarchy level. Assigns new names to signals and leaf_processes. -->

    <xsl:template match="process_network" mode="flattened">         <!-- entry mode -->
	<process_network name="{@name}">
	    <xsl:if test="$debug"><xsl:message>[flattened] : started flattening '<xsl:value-of select="@name"/>'</xsl:message></xsl:if>
	    <xsl:apply-templates select="." mode="flattened-signals" />
	    <xsl:apply-templates select="." mode="flattened-processes" />
	</process_network>
    </xsl:template>

    <xsl:template match="process_network" mode="flattened-signals">
	<xsl:if test="$debug"><xsl:message>[flattened-signals] : flattening signals for '<xsl:value-of select="@name"/>'</xsl:message></xsl:if>
	<xsl:apply-templates select="signal" mode="flattened" />
	<xsl:for-each select="composite_process">
	    <xsl:apply-templates select="process_network" mode="flattened-signals" />
	</xsl:for-each>
    </xsl:template>

    <xsl:template match="signal" mode="flattened">
	<xsl:if test="$debug"><xsl:message>[flattened] : finding endpoints for '<xsl:value-of select="@name"/>'</xsl:message></xsl:if>
	<xsl:variable name="source_endpoint">
	    <xsl:apply-templates select="../.." mode="flattened-find-deep-endpoint">
		<xsl:with-param name="pr_name" select="@source" />
		<xsl:with-param name="pr_port" select="@source_port" />
	    </xsl:apply-templates>
	</xsl:variable>
	<xsl:variable name="target_endpoint">
	    <xsl:apply-templates select="../.." mode="flattened-find-deep-endpoint">
		<xsl:with-param name="pr_name" select="@target" />
		<xsl:with-param name="pr_port" select="@target_port" />
	    </xsl:apply-templates>
	</xsl:variable>
	<signal name="{concat(../@name, concat('_', @name))}" 
		source="{$source_endpoint/endpoint/@process_name}" 
		source_port="{$source_endpoint/endpoint/@process_port}" 
		target="{$target_endpoint/endpoint/@process_name}"
		target_port="{$target_endpoint/endpoint/@process_port}">
	    <xsl:copy-of select="./@* except (@name, @source, @target, @source_port, @target_port)" />
	</signal>
    </xsl:template>

    <xsl:template match="process_network" mode="flattened-find-deep-endpoint">
	<xsl:param name="pr_name" />
	<xsl:param name="pr_port" />
	<xsl:variable name="pn_name" select="@name" />
	<xsl:variable name="pn_full_name" select="concat($pn_name, concat('_', $pr_name))" />
	<xsl:variable name="composite_pr" select="composite_process[@name = $pn_full_name]" />
	<xsl:choose>
	    <xsl:when test="$composite_pr">
		<xsl:variable name="composite_pr_port" select="$composite_pr/process_network/port[@name = $pr_port]" />
		<xsl:apply-templates select="$composite_pr/process_network" mode="flattened-find-deep-endpoint">
		    <xsl:with-param name="pr_name" select="$composite_pr_port/@bound_process"/>
		    <xsl:with-param name="pr_port" select="$composite_pr_port/@bound_port"/>
		</xsl:apply-templates>
	    </xsl:when>
	    <xsl:otherwise>
		<endpoint process_name="{$pn_full_name}" process_port="{$pr_port}"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:template>

    <xsl:template match="process_network" mode="flattened-processes">
	<xsl:apply-templates select="leaf_process" mode="flattened" />
	<xsl:for-each select="composite_process">
	    <xsl:apply-templates select="process_network" mode="flattened-processes" />
	</xsl:for-each>
	<xsl:if test="$debug"><xsl:message>[flattened-processes] : removed composite '<xsl:value-of select="@name"/>'</xsl:message></xsl:if>
    </xsl:template>

    <xsl:template match="leaf_process" mode="flattened">
	<leaf_process name="{concat(../@name, concat('_', @name))}">
	    <xsl:copy-of select="./*" />
	</leaf_process>
	<xsl:if test="$debug"><xsl:message>[flattened] : renamed leaf '<xsl:value-of select="concat(../@name, concat('_', @name))"/>'</xsl:message></xsl:if>
    </xsl:template>

</xsl:transform>
