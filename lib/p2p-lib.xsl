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


  <xsl:template match="graph" mode="forsyde-constant-source-workaround">
    <graph name="{@name}">
      <xsl:variable name="remove_source_constants">
	<xsl:apply-templates select="connection" mode="forsyde-constant-source-removal"/>
      </xsl:variable>
      <xsl:copy-of select="$remove_source_constants"/>
    </graph>
  </xsl:template>
  
  <xsl:template match="connection" mode="forsyde-constant-source-removal">
    <xsl:variable name="from" select="./@from" />
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]" />
    <xsl:if test="not($node/@kind = 'constant' or $node/@kind = 'file_source')" >
      <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
	<virtual_link count="{virtual_link/@count}" >
	  <xsl:for-each select="virtual_link/*">
	    <xsl:copy-of select="."/>
	  </xsl:for-each>
	</virtual_link>
      </connection>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="connection" mode="forsyde-constant-source-workaround-add-self-edges-to-sources">
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]" />
    <xsl:variable name="prev_connections" select="preceding-sibling::connection[@from = current()/@from and ./virtual_link/@count = current()/virtual_link/@count]"/>
    <xsl:if test="$node/@kind = 'source' and count($prev_connections) = 0">
      <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
	<virtual_link count="{virtual_link/@count}">
	  <delay node_name="{@from}" n="{@rate}" count="{virtual_link/@count}" input_count="{@output_count}" init_val="{$node/@init_val}"/>
	  <actor name="{@from}" count="{virtual_link/@count}" input="iport1" rate="{@rate}" input_count="{@output_count}"/>
	</virtual_link>
      </connection>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="connection" mode="forsyde-constant-source-workaround-add-take-val-self-edges">
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]" />
    <xsl:variable name="prev_connections" select="preceding-sibling::connection[@from = current()/@from]"/>
    <xsl:if test="($node/@kind = 'constant' or $node/@kind = 'source' or $node/@kind = 'file_source') and count($prev_connections) = 0">
      <connection from="{@from}" output="take_val_oport" rate="1" output_count="1">
	<virtual_link count="1">
	  <delay node_name="{@from}" n="1" count="1" input_count="1" init_val="{$node/@take}"/>
	  <actor name="{@from}" count="1" input="take_val_iport" rate="1" input_count="1"/>
	</virtual_link>
      </connection>
    </xsl:if>
  </xsl:template>

  
</xsl:transform>
