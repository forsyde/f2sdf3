<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Phase 7: Reconstruct the graph from p2p model -->
  <!-- ============================================= -->
  
  <xsl:template match="graph" mode="convert-p2p-graph">
    <graph name="{@name}">
      <xsl:variable name="through_edges">	
	<xsl:apply-templates select="connection" mode="convert-p2p-graph-emit-edges"/>
      </xsl:variable>
      <xsl:variable name="actual_edges">
	<xsl:for-each-group select="$through_edges/edge" group-by="@name">
	  <xsl:sequence select="."/>
	</xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="actual_edges_fo_corrected">
	<xsl:for-each select="$actual_edges/edge">
	  <xsl:variable name="fo_edges" select="../*[@source = current()/@source and @source_port = current()/@source_port]"/>
	  <xsl:variable name="current_edge" select="."/>
	  <xsl:choose>
	    <xsl:when test="count($fo_edges) &gt; 1">
	      <edge name="{@name}" moc="{@moc}" type="{@type}" source="{@source}" source_port="{@source_port}_{count(preceding-sibling::*[@source = current()/@source and @source_port = current()/@source_port])}" target="{@target}" target_port="{@target_port}" token_size="{@token_size}" initial_tokens="{@initial_tokens}" tokens="{@tokens}" signal_count="{@signal_count}" source_kind="{@source_kind}" target_kind="{@target_kind}" fanout_of="{@source_port}" source_rate="{@source_rate}" target_rate="{@target_rate}">
		<xsl:copy-of select="*"/>
	      </edge>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:copy-of select="."/>
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:for-each>
      </xsl:variable>
      <xsl:variable name="nodes_multiple">
	<xsl:for-each-group select="$actual_edges/edge" group-by="@source">
	  <node name="{@source}" kind="{@source_kind}"/>
	</xsl:for-each-group>
	<xsl:for-each-group select="$actual_edges/edge" group-by="@target">
	  <node name="{@target}" kind="{@target_kind}"/>
	</xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="unique_nodes">
	<xsl:for-each-group select="$nodes_multiple/node" group-by="@name">
	  <xsl:sequence select="."/>
	</xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="nodes">	
	<xsl:apply-templates select="$unique_nodes" mode="convert-p2p-graph-emit-nodes">
	  <xsl:with-param name="edges" select="$actual_edges_fo_corrected"/>
	</xsl:apply-templates>
      </xsl:variable>
      <xsl:copy-of select="$actual_edges_fo_corrected"/>
      <xsl:copy-of select="$nodes"/>
    </graph>
  </xsl:template>
  
  <xsl:template match="connection" mode="convert-p2p-graph-emit-edges">
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]"/>
    <xsl:variable name="count" select="virtual_link/@count"/>
    <xsl:variable name="this" select="."/>
    <xsl:variable name="edge">
      <xsl:choose>
	<xsl:when test="($node/@kind = 'constant' or $node/@kind = 'source' or $node/@kind = 'file_source') and starts-with(@output, 'take_val')">
	  <edge name="{@from}_{@output}_{$count}" moc="{$node/@moc}" type="unsigned long long" source="{@from}" source_port="{@output}_{$count}" target="FILL ME" target_port="FILL_ME" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="{$node/@kind}" target_kind="FILL ME" source_rate="{@rate}" target_rate="FILL ME"/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:variable name="type" select="tokenize($node/output[@name = $this/@output]/@type, '\.')"/>
	  <edge name="{@from}_{@output}_{$count}" moc="{$node/@moc}" type="{$type[position() = $count]}" source="{@from}" source_port="{@output}_{$count}" target="FILL ME" target_port="FILL_ME" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="{$node/@kind}" target_kind="FILL ME" source_rate="{@rate}" target_rate="FILL ME"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="virtual_link/*[1]" mode="convert-p2p-graph-emit-edges">
      <xsl:with-param name="edges" select="$edge"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="fanout" mode="convert-p2p-graph-emit-edges">
    <xsl:param name="edges"/>
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@node_name]"/>
    <xsl:variable name="last_edge" select="$edges/edge[last()]"/>
    <xsl:variable name="new_edges">
      <xsl:for-each select="$edges/edge[position() &lt; last()]">
	<xsl:copy-of select="."/>
      </xsl:for-each>
      <edge name="{$last_edge/@name}_FO" moc="{$last_edge/@moc}" type="{$last_edge/@type}" source="{$last_edge/@source}" source_port="{$last_edge/@source_port}" target="{$last_edge/@name}_FO" target_port="{@port}" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="{$last_edge/@source_kind}" target_kind="fanout" source_rate="{$last_edge/@source_rate}" target_rate="{$last_edge/@source_rate}">
	<xsl:copy-of select="$last_edge/*"/>
      </edge>
      <edge name="{$last_edge/@name}_FO" moc="{$node/@moc}" type="{$last_edge/@type}" source="{$last_edge/@name}_FO" source_port="{@port}" target="FILL_ME" target_port="FILL_ME" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="fanout" target_kind="FILL_ME" source_rate="{$last_edge/@source_rate}" target_rate="FILL ME"/>
    </xsl:variable>
    <xsl:apply-templates select="following-sibling::*[1]" mode="convert-p2p-graph-emit-edges">
      <xsl:with-param name="edges" select="$new_edges"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="delay" mode="convert-p2p-graph-emit-edges">
    <xsl:param name="edges"/>
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@node_name]"/>
    <xsl:variable name="last_edge" select="$edges/edge[last()]"/>
    <xsl:variable name="new_edges">
      <xsl:for-each select="$edges/edge[position() &lt; last()]">
	<xsl:copy-of select="."/>
      </xsl:for-each>
      <edge name="{$last_edge/@name}" moc="{$last_edge/@moc}" type="{$last_edge/@type}" source="{$last_edge/@source}" source_port="{$last_edge/@source_port}" target="{$last_edge/@target}" target_port="{$last_edge/@target_port}" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="{$last_edge/@source_kind}" target_kind="{$last_edge/@target_kind}" source_rate="{$last_edge/@source_rate}" target_rate="{$last_edge/@target_rate}">
	<xsl:copy-of select="$last_edge/*"/>
	<delay node_name="{@node_name}" n="{@n}" count="{@count}" input_count="{@input_count}" init_val="{@init_val}" type="{$node/output/@type}"/>
      </edge>
    </xsl:variable>
    <xsl:apply-templates select="following-sibling::*[1]" mode="convert-p2p-graph-emit-edges">
      <xsl:with-param name="edges" select="$new_edges"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="actor" mode="convert-p2p-graph-emit-edges">
    <xsl:param name="edges"/>
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@name]"/>
    <xsl:variable name="last_edge" select="$edges/edge[last()]"/>
    <xsl:variable name="new_edges">
      <xsl:for-each select="$edges/edge[position() &lt; last()]">
	<xsl:copy-of select="."/>
      </xsl:for-each>
      <edge name="{$last_edge/@name}_{@name}_{@input}_{@count}" moc="{$last_edge/@moc}" type="{$last_edge/@type}" source="{$last_edge/@source}" source_port="{$last_edge/@source_port}" target="{@name}" target_port="{@input}_{@count}" token_size="" initial_tokens="0" tokens="" signal_count="1" source_kind="{$last_edge/@source_kind}" target_kind="{$node/@kind}" source_rate="{$last_edge/@source_rate}" target_rate="{@rate}">
	<xsl:copy-of select="$last_edge/*"/>
      </edge>
    </xsl:variable>
    <xsl:copy-of select="$new_edges"/>
  </xsl:template>
  
  <xsl:template match="node" mode="convert-p2p-graph-emit-nodes">
    <xsl:param name="edges"/>
    <xsl:variable name="this" select="."/>
    <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = $this/@name]"/>
    <node name="{@name}" moc="{$node/@moc}" kind="{@kind}" function="{$node/@function}" init_val="{$node/@init_val}" take="{$node/@take}" n="{$node/@n}">
      <xsl:for-each select="$edges/edge[@target = $this/@name]">
	<input name="{@target_port}" type="{@type}" rate="{@target_rate}" source="{@source}" source_port="{@source_port}" input_count="1"/>
      </xsl:for-each>
      <xsl:variable name="ports">
	<xsl:for-each-group select="$edges/edge[@source = $this/@name]" group-by="@fanout_of">
	  <port name="{current-group()[1]/@name}" outputs="{count(current-group())}" org_port_name="{@fanout_of}"/>
	</xsl:for-each-group>
	<xsl:for-each select="$edges/edge[@source = $this/@name and not(@fanout_of)]">
	  <port name="{@name}" outputs="1" org_port_name="{@source_port}"/>
	</xsl:for-each> 
      </xsl:variable>
      <xsl:variable name="ordered_ports">
	<xsl:for-each select="$edges/edge[@source = $this/@name]">
	  <xsl:variable name="current_port" select="$ports/port[@name = current()/@name]" />
	  <xsl:choose>
	    <xsl:when test="$current_port/@outputs &gt; 1">
	      <output name="{$current_port/@org_port_name}" type="{@type}" rate="{@source_rate}" output_count="1">
		<xsl:for-each select="$edges/edge[@source = $this/@name and @fanout_of = $current_port/@org_port_name]">
		  <fanout name="{@source_port}" target="{@target}" target_port="{@target_port}"/>
		</xsl:for-each>
	      </output>
	    </xsl:when>
	    <xsl:when test="$current_port/@outputs = '1'">
	      <output name="{$current_port/@org_port_name}" type="{@type}" rate="{@source_rate}" target="{@target}" target_port="{@target_port}" output_count="1"/>
	    </xsl:when>
	  </xsl:choose>
	</xsl:for-each> 
      </xsl:variable>
      <xsl:copy-of select="$ordered_ports"/>
    </node>
  </xsl:template>
  
</xsl:transform>
