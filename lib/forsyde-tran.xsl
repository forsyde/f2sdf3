<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


    <!-- Translation to graph model -->
    <!-- ========================== -->
    <!-- Transforms ForSyDe process networks to annotated graphs -->

    <xsl:template match="process_network" mode="graph">
	<xsl:if test="$debug"><xsl:message>[graph] : Transforming '<xsl:value-of select="@name"/>' into a graph </xsl:message></xsl:if>
	<graph name="{@name}">
	    <xsl:apply-templates select="signal" mode="graph"/>
	    <xsl:apply-templates select="leaf_process" mode="graph"/>
	</graph>
    </xsl:template>
    
    <xsl:template match="signal" mode="graph">
	<edge name="{@name}" 
	      moc="{@moc}"  
	      source="{@source}" 
	      source_port="{@source_port}" 
	      target="{@target}" 
	      target_port="{@target_port}" 
	      token_size="" 
	      initial_tokens="0" 
	      tokens="" 
	      signal_count="" 
	      source_kind="{//process_network/leaf_process[@name = current()/@source]/process_constructor/@name}" 
	      target_kind="{//process_network/leaf_process[@name = current()/@target]/process_constructor/@name}"/>
	<xsl:if test="$debug"><xsl:message>[graph] : Translated signal '<xsl:value-of select="@name"/>' into an edge </xsl:message></xsl:if>
    </xsl:template>
    
    <xsl:template match="leaf_process" mode="graph">
	<xsl:variable name="current_process" select="." />
	<xsl:variable name="process_kind" select="process_constructor/@name" />
	<node name="{@name}"
	      moc="{process_constructor/@moc}" 
	      kind="{$process_kind}" 
	      function="{process_constructor/argument[@name = '_func']/@value}" 
	      init_val="{$current_process/process_constructor/argument[@name = 'init_val']/@value}" 
	      take="{$current_process/process_constructor/argument[@name = 'take']/@value}" 
	      n="{$current_process/process_constructor/argument[@name = 'n']/@value}">
	    <!-- <outputs> -->
	    <xsl:for-each select="port[@direction = 'out']">
		<xsl:variable name="output_signal" select="//process_network/signal[@source = $current_process/@name and @source_port = current()/@name]"/>
		<xsl:variable name="port_index" select="./count(preceding-sibling::port[@direction = 'out']) + 1" />
		<xsl:variable name="port_rate">
		    <xsl:choose>
			<xsl:when test="starts-with($process_kind, 'delay')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'zip')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'constant')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'source')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'fanout')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'unzipN')">
			    <xsl:value-of select="tokenize(translate($current_process/process_constructor/argument[starts-with(@name, 'o') and ends-with(@name, 'toks')]/@value, ',[]', ''),' ')" />
			</xsl:when>
			<xsl:otherwise>
			    <xsl:value-of select="$current_process/process_constructor/argument[starts-with(@name, 'o') and ends-with(@name, 'toks')]/@value" />
			</xsl:otherwise>
		    </xsl:choose>
		</xsl:variable>
		<output name="{@name}" 
			type="{@type}" 
			rate="{tokenize($port_rate, ' ')[$port_index]}"
			target="{$output_signal/@target}" 
			target_port="{$output_signal/@target_port}" 
			output_count=""/>
	    </xsl:for-each>
	    <!-- </outputs> -->
	    <!-- <inputs> -->
	    <xsl:for-each select="port[@direction = 'in']">
		<xsl:variable name="input_signal" select="//process_network/signal[@target = $current_process/@name and @target_port = current()/@name]"/>
		<xsl:variable name="port_index" select="./count(preceding-sibling::port[@direction = 'in']) + 1" />
		<xsl:variable name="port_rate">
		    <xsl:choose>
			<xsl:when test="starts-with($process_kind, 'delay')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'unzip')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'sink')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'fanout')"><xsl:value-of select="1"/></xsl:when>
			<xsl:when test="starts-with($process_kind, 'zipN')">
			    <xsl:value-of select="tokenize(translate($current_process/process_constructor/argument[starts-with(@name, 'i') and ends-with(@name, 'toks')]/@value, ',[]', ''),' ')" />
			</xsl:when>
			<xsl:otherwise>
			    <xsl:value-of select="$current_process/process_constructor/argument[starts-with(@name, 'i') and ends-with(@name, 'toks')]/@value" />
			</xsl:otherwise>
		    </xsl:choose>
		</xsl:variable>
		<input name="{@name}"
		       type="{@type}"
		       rate="{tokenize($port_rate, ' ')[$port_index]}" 
		       source="{$input_signal/@source}" 
		       source_port="{$input_signal/@source_port}"
		       input_count=""/>
	    </xsl:for-each>
	    <!-- </inputs> -->
	</node>
	<xsl:if test="$debug"><xsl:message>[graph] : Translated process '<xsl:value-of select="@name"/>' into a node </xsl:message></xsl:if>
    </xsl:template>

</xsl:transform>
