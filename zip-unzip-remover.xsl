<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Phase 5: Remove zips, unzips, etc -->
  <!-- ======================================== -->
  
  <xsl:template match="graph" mode="remove-zips-unzips">
    <graph name="{@name}">
      <xsl:variable name="connections">
	<xsl:apply-templates select="connection" mode="remove-zips-unzips"/>
      </xsl:variable>
      <xsl:copy-of select="$connections"/>
    </graph>
  </xsl:template>
  
  <xsl:template match="connection" mode="remove-zips-unzips">
    <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
      <virtual_link count="{virtual_link/@count}">
	<xsl:for-each select="virtual_link/fanout | virtual_link/delay | virtual_link/actor">
	  <xsl:copy-of select="."/>
	</xsl:for-each>
      </virtual_link>
    </connection>
  </xsl:template>

  
  <!-- Phase 6: Merge fanouts -->
  <!-- ======================================== -->
  
  <xsl:template match="graph" mode="remove-fanouts">
    <graph name="{@name}">
      <xsl:choose>
	<xsl:when test="$fanouts = 'keep'">
	  <xsl:copy-of select="*" />
	</xsl:when>
	<xsl:when test="$fanouts = 'no-chain'">
	  <xsl:apply-templates select="connection" mode="remove-chained-fanouts"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:apply-templates select="connection" mode="remove-all-fanouts"/>
	</xsl:otherwise>
      </xsl:choose>
    </graph>
  </xsl:template>
  
  <xsl:template match="connection" mode="remove-chained-fanouts">
    <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
      <virtual_link count="{virtual_link/@count}">
	<xsl:for-each select="virtual_link/*">
	  <xsl:if test="not (self::fanout and (preceding-sibling::fanout[1]/position() + 1 = position()))">
	    <xsl:copy-of select="."/>
	  </xsl:if>
	</xsl:for-each>
      </virtual_link>
    </connection>
  </xsl:template>
  
  <xsl:template match="connection" mode="remove-all-fanouts">
    <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
      <virtual_link count="{virtual_link/@count}">
	<xsl:for-each select="virtual_link/delay | virtual_link/actor">
	  <xsl:copy-of select="."/>
	</xsl:for-each>
      </virtual_link>
    </connection>
  </xsl:template>
  
</xsl:transform>
