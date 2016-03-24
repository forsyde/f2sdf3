<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
