<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Find point to point connections -->
    <!-- =============================== -->
    
    <xsl:template match="graph" mode="graph-to-p2p">
	<xsl:if test="$debug"><xsl:message>[graph-to-p2p] : Starting the search for connections... </xsl:message></xsl:if>
	<xsl:variable name="connections">
	    <xsl:apply-templates select="node[not(starts-with(@kind, 'zip') or starts-with(@kind, 'unzip') 
					 or starts-with(@kind, 'fanout') or starts-with(@kind, 'delay'))]" 
				 mode="find-virtual-connects"/>
	</xsl:variable>
	<xsl:copy-of select="$connections"/>
    </xsl:template>
    
    <xsl:template match="node" mode="find-virtual-connects">
	<xsl:variable name="current_node" select="."/>
	
	<xsl:if test="$debug">
	    <xsl:message>[find-virtual-connects] : '<xsl:value-of select="@name"/>' 1-to-n connection info </xsl:message>
	</xsl:if>
	<xsl:variable name="node_connections">
	    <xsl:for-each select="output">
		<xsl:variable name="output_connections">
		    <xsl:apply-templates select="." mode="multi_output_looper">
			<xsl:with-param name="count" select="1"/>
		    </xsl:apply-templates>
		</xsl:variable>
		<connection from="{$current_node/@name}" 
			    kind="{$current_node/@kind}" 
			    output="{@name}"
			    type="{@type}"
			    rate="{@rate}" 
			    output_count="{@output_count}">
		    <xsl:copy-of select="$output_connections"/>
		</connection>
	    </xsl:for-each>
	</xsl:variable>
	
	<xsl:if test="$debug">
	    <xsl:message>[find-virtual-connects] : '<xsl:value-of select="@name"/>' 1-to-n to 1-to-1 representation  </xsl:message>
	</xsl:if>
	<xsl:variable name="node_connections_p2p">
	    <xsl:apply-templates select="$node_connections//actor" mode="linearize_connection"/>
	</xsl:variable>

	<xsl:copy-of select="$node_connections_p2p"/>
    </xsl:template>
    
    <!-- multi_output_looper -->

    <xsl:template match="output" mode="multi_output_looper">
	<xsl:param name="count"/>
	<xsl:if test="$count &lt;= @output_count">
	    <virtual_link count="{$count}">
		<xsl:apply-templates select="." mode="output_fanout_handler">
		    <xsl:with-param name="count" select="$count"/>
		</xsl:apply-templates>
	    </virtual_link>
	    <xsl:apply-templates select="." mode="multi_output_looper">
		<xsl:with-param name="count" select="$count + 1"/>
	    </xsl:apply-templates>
	</xsl:if>
    </xsl:template>
    
    <xsl:template match="output" mode="output_fanout_handler">
	<xsl:param name="count"/>
	<xsl:variable name="current_node" select="./.."/>
	<xsl:if test="$debug">
	    <xsl:message>[output_fanout_handler] : traversing '<xsl:value-of select="$current_node/@name"/>:<xsl:value-of select="@name"/>' </xsl:message>
	</xsl:if>	
	<!-- For each edge connected to this output -->
	<xsl:variable name="edges" select="//graph/edge[@source = $current_node/@name and @source_port = current()/@name]"/>
	<xsl:choose>
	    <xsl:when test="count($edges) &gt; 1">
		<fanout node_name="{$current_node/@name}" 
			port="{@name}" 
			type="{@type}"
			explicit="{starts-with($current_node/@kind, 'fanout')}">
		    <xsl:if test="$debug">
			<xsl:message>[output_fanout_handler] :!!fanout <xsl:value-of select="./@*"/>' </xsl:message>
		    </xsl:if>
		    <xsl:for-each select="$edges">
			<xsl:variable name="current_edge" select="."/>
			<xsl:variable name="target_node" select="//graph/node[@name = $current_edge/@target]"/>
			<way>
			    <xsl:apply-templates select="$target_node" mode="traverse_graph_for_virtual_connections">
				<xsl:with-param name="count" select="$count"/>
				<xsl:with-param name="input_name" select="$current_edge/@target_port"/>
			    </xsl:apply-templates>
			</way>
		    </xsl:for-each>
		</fanout>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:variable name="current_edge" select="$edges[1]"/>
		<xsl:variable name="target_node" select="//graph/node[@name = $current_edge/@target]"/>
		<xsl:if test="$debug">
		    <xsl:message>[output_fanout_handler] :   to <xsl:value-of select="$target_node/@kind"/> '<xsl:value-of select="$target_node/@name"/>:<xsl:value-of select="$current_edge/@target_port"/>' </xsl:message>
		</xsl:if>
		<xsl:apply-templates select="$target_node" mode="traverse_graph_for_virtual_connections">
		    <xsl:with-param name="count" select="$count"/>
		    <xsl:with-param name="input_name" select="$current_edge/@target_port"/>
		</xsl:apply-templates>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:template>
    
    <xsl:template match="node[starts-with(@kind, 'zip')]" mode="traverse_graph_for_virtual_connections">
	<xsl:param name="count"/>
	<xsl:param name="input_name"/>
	<xsl:variable name="input" select="input[@name = $input_name]"/>
	<xsl:variable name="next_count" select="sum($input/preceding-sibling::input/@input_count) + $count"/>
	<zip node_name="{@name}"
	     type="{$input/@type}" 
	     rate="{$input/@rate}"/>
	<xsl:apply-templates select="output" mode="output_fanout_handler">
	    <xsl:with-param name="count" select="$next_count"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="node[starts-with(@kind, 'unzip')]" mode="traverse_graph_for_virtual_connections">
	<xsl:param name="count"/>
	<xsl:param name="input_name"/>
	<xsl:variable name="current_node" select="."/>
	<xsl:for-each select="output">
	    <xsl:variable name="no_of_prev_signals" select="sum(preceding-sibling::output/@output_count)"/>
	    <xsl:if test="$count &gt; $no_of_prev_signals and $count &lt;= $no_of_prev_signals + @output_count">
		<xsl:variable name="next_count" select="$count - $no_of_prev_signals"/>
		<unzip node_name="{$current_node/@name}"
		       type="{self::node()/@type}"
		       rate="{@rate}"/>
		<xsl:apply-templates select="." mode="output_fanout_handler">
		    <xsl:with-param name="count" select="$next_count"/>
		</xsl:apply-templates>
	    </xsl:if>
	</xsl:for-each>
    </xsl:template>
    
    <xsl:template match="node[starts-with(@kind, 'delay')]" mode="traverse_graph_for_virtual_connections">
	<xsl:param name="count"/>
	<xsl:param name="input_name"/>
	<delay node_name="{@name}" n="{@n}" count="{$count}" input_count="{input/@input_count}" init_val="{@init_val}"/>
	<xsl:apply-templates select="output" mode="output_fanout_handler">
	    <xsl:with-param name="count" select="$count"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="node[starts-with(@kind, 'fanout')]" mode="traverse_graph_for_virtual_connections">
	<xsl:param name="count"/>
	<xsl:param name="input_name"/>
	<xsl:apply-templates select="output" mode="output_fanout_handler">
	    <xsl:with-param name="count" select="$count"/>
	</xsl:apply-templates>
    </xsl:template>

    <xsl:template match="node[ends-with(@kind, 'sink')]" mode="traverse_graph_for_virtual_connections">
    </xsl:template>
    
    <xsl:template match="node" mode="traverse_graph_for_virtual_connections">
	<xsl:param name="count"/>
	<xsl:param name="input_name"/>
	<actor name="{@name}" 
	       count="{$count}" 
	       input="{$input_name}" 
	       type="{input[@name = $input_name]/@type}"
	       rate="{input[@name = $input_name]/@rate}" 
	       input_count="{input[@name = $input_name]/@input_count}"/>
    </xsl:template>
    

    <!-- linearize_connection -->

    <xsl:template match="connection" mode="linearize_connection">
	<xsl:param name="prec"/>
	<connection>
	    <xsl:copy-of select="./@*"/>
	    <xsl:copy-of select="$prec"/>
	</connection>
    </xsl:template>
    
    <xsl:template match="virtual_link" mode="linearize_connection">
	<xsl:param name="prec"/>
	<xsl:variable name="prec">
	    <virtual_link count="{@count}">
		<xsl:copy-of select="$prec"/>
	    </virtual_link>
	</xsl:variable>
	<xsl:apply-templates select=".." mode="linearize_connection">
	    <xsl:with-param name="prec" select="$prec"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="fanout" mode="linearize_connection">
	<xsl:param name="prec"/>
	<xsl:param name="way"/>
	<xsl:variable name="prec">
	    <xsl:copy-of select="preceding-sibling::*"/>	
	    <fanout node_name="{@node_name}" port="{@port}" explicit="{@explicit}" way="{$way}"/>
	    <xsl:copy-of select="$prec"/>
	</xsl:variable>
	<xsl:apply-templates select=".." mode="linearize_connection">
	    <xsl:with-param name="prec" select="$prec"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="way" mode="linearize_connection">
	<xsl:param name="prec"/>
	<xsl:apply-templates select=".." mode="linearize_connection">
	    <xsl:with-param name="prec" select="$prec"/>
	    <xsl:with-param name="way" select="count(preceding-sibling::way)"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="actor" mode="linearize_connection">
	<xsl:variable name="prec">
	    <xsl:copy-of select="preceding-sibling::*"/>	
	    <xsl:copy-of select="."/>
	</xsl:variable>
	<xsl:apply-templates select=".." mode="linearize_connection">
	    <xsl:with-param name="prec" select="$prec"/>
	</xsl:apply-templates>
    </xsl:template>
    


    <!-- Transform to SDF3 -->
    <!-- ================= -->

    <xsl:template match="graph" mode="graph-to-sdf3">
	<xsl:if test="$debug"><xsl:message>[graph-to-sdf3] : Starting conversion... </xsl:message></xsl:if>
	<sdf3 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="sdf" version="1.0" xsi:noNamespaceSchemaLocation="http://www.es.ele.tue.nl/sdf3/xsd/sdf3-sdf.xsd">
	    <applicationGraph name="{@name}">
		<sdf name="{@name}" type='g'>
		    <xsl:apply-templates select="node" mode="convert-to-actor"/>
		    <xsl:apply-templates select="edge" mode="convert-to-channel"/>
		</sdf>
		<sdfProperties>
		    <xsl:apply-templates select="node" mode="convert-to-properties"/>
		    <xsl:apply-templates select="edge" mode="convert-to-properties"/>
		</sdfProperties>
		<!-- <graphProperties>
		     <timeConstraints>-->
		<!-- <throughput></throughput> -->
		<!-- </timeConstraints>
		     </graphProperties> -->
	    </applicationGraph>
	</sdf3>
    </xsl:template>

    <xsl:template match="node" mode="convert-to-actor">
	<xsl:if test="$debug"><xsl:message>[convert-to-actor] : '<xsl:value-of select="@name"/>' </xsl:message></xsl:if>
	<actor name="{@name}" type='a'>
	    <!-- <executionTime time="1000" /> -->
	    <xsl:for-each select="input">
		<port name="{@name}" type="in" rate="{@rate}"/>
	    </xsl:for-each>
	    <xsl:for-each select="output">
		<port name="{@name}" type="out" rate="{@rate}"/>
	    </xsl:for-each>
	</actor>
    </xsl:template>

    <xsl:template match="edge" mode="convert-to-channel">
	<xsl:if test="$debug"><xsl:message>[convert-to-channel] : '<xsl:value-of select="@name"/>' </xsl:message></xsl:if>
	<channel name="{@name}" srcActor="{@source}" srcPort="{@source_port}" dstActor="{@target}" dstPort="{@target_port}" initialTokens="{@initial_tokens}"/>
    </xsl:template>

    <xsl:template match="node" mode="convert-to-properties">
	<xsl:if test="$debug"><xsl:message>[convert-to-properties] : '<xsl:value-of select="@name"/>' </xsl:message></xsl:if>
	<actorProperties actor="{@name}">
	    <processor type="microblaze0" default="true">
		<executionTime time="1000" />
		<memory>
		    <stateSize max="1000" />
		</memory>
	    </processor>
	</actorProperties>
    </xsl:template>

    <xsl:template match="edge" mode="convert-to-properties">
	<xsl:if test="$debug"><xsl:message>[convert-to-properties] : '<xsl:value-of select="@name"/>' </xsl:message></xsl:if>
	<channelProperties channel="{@name}">
            <tokenSize sz="{@token_size * 8}"/>
      	</channelProperties>
    </xsl:template>

</xsl:transform>
