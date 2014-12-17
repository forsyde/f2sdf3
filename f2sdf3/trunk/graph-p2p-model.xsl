<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Phase 4: Find point to point connections -->
	<!-- ======================================== -->
	
	<xsl:template match="graph" mode="convert-p2p-model">
		<graph name="{@name}">
			<xsl:variable name="connections">
				<xsl:apply-templates select="node[not(starts-with(@kind, 'zip') or starts-with(@kind, 'unzip') or starts-with(@kind, 'fanout') or starts-with(@kind, 'delay'))]" mode="find-virtual-connections"/>
			</xsl:variable>
			<xsl:copy-of select="$connections"/>
		</graph>
	</xsl:template>
	
	<xsl:template match="node" mode="find-virtual-connections">
		<xsl:variable name="current_node" select="."/>
	<!-- Get the connection information with 1-to-n node connections -->
		<xsl:variable name="node_connections">
			<xsl:for-each select="output">
				<xsl:variable name="output_connections">
					<xsl:apply-templates select="." mode="multi_output_looper">
						<xsl:with-param name="count" select="1"/>
					</xsl:apply-templates>
				</xsl:variable>
				<connection from="{$current_node/@name}" output="{@name}" rate="{@rate}" output_count="{@output_count}">
					<xsl:copy-of select="$output_connections"/>
				</connection>
			</xsl:for-each>
		</xsl:variable>
	<!-- Convert the 1-to-n node representation to 1-to-1 node connections -->
		<xsl:variable name="node_connections_p2p">
			<xsl:apply-templates select="$node_connections//actor" mode="linearize_connection"/>
		</xsl:variable>
<!-- 		Find the channel factors and update the rates -->
		<xsl:variable name="node_connections_p2p_with_rates">
			<xsl:apply-templates select="$node_connections_p2p" mode="find_factors_and_update_rates"/>
		</xsl:variable>
<!-- 		Find number of initial tokens in delays with zipped inputs -->
		<xsl:variable name="node_connections_p2p_with_rates_delays">
			<xsl:apply-templates select="$node_connections_p2p_with_rates" mode="find_initial_token_sizes"/>
		</xsl:variable>
<!-- 		<xsl:copy-of select="$node_connections"/> -->
		<xsl:copy-of select="$node_connections_p2p_with_rates_delays"/>
	</xsl:template>
	
	
	
	
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
		<!-- For each edge connected to this output -->
		<xsl:variable name="edges" select="//graph/edge[@source = $current_node/@name and @source_port = current()/@name]"/>
		<xsl:choose>
			<xsl:when test="count($edges) &gt; 1">
				<fanout node_name="{$current_node/@name}" port="{@name}" explicit="{starts-with($current_node/@kind, 'fanout')}">
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
		<zip node_name="{@name}" rate="{$input/@rate}"/>
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
				<unzip node_name="{$current_node/@name}" rate="{@rate}"/>
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
	
	<xsl:template match="node" mode="traverse_graph_for_virtual_connections">
		<xsl:param name="count"/>
		<xsl:param name="input_name"/>
		<actor name="{@name}" count="{$count}" input="{$input_name}" rate="{input[@name = $input_name]/@rate}" input_count="{input[@name = $input_name]/@input_count}"/>
	</xsl:template>
	
	
	
	
	<xsl:template match="connection" mode="linearize_connection">
		<xsl:param name="prec"/>
		<connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
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
	
	
	
	
	<xsl:template match="connection" mode="find_factors_and_update_rates">
		<xsl:variable name="zip_factor">
			<xsl:choose>
				<xsl:when test="count(virtual_link/zip) &gt; 0">
					<xsl:apply-templates select="virtual_link/zip[1]" mode="find_factors_and_update_rates">
						<xsl:with-param name="factor" select="1"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="1"/> </xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="unzip_factor">
			<xsl:choose>
				<xsl:when test="count(virtual_link/unzip) &gt; 0">
					<xsl:apply-templates select="virtual_link/unzip[1]" mode="find_factors_and_update_rates">
						<xsl:with-param name="factor" select="1"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise><xsl:copy-of select="1"/> </xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="channel_factor" select="$zip_factor div $unzip_factor"/>
		<xsl:variable name="target_actor" select=".//actor"/>
		<xsl:variable name="prod_rate">
			<xsl:choose>
				<xsl:when test="(@output_count &gt; 1) and ($channel_factor &lt; 1)"><xsl:value-of select="@rate * (1 div $channel_factor)"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@rate"/> </xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="cons_rate">
			<xsl:choose>
				<xsl:when test="($target_actor/@input_count &gt; 1) and ($channel_factor &gt; 1)"><xsl:value-of select="$target_actor/@rate * $channel_factor"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$target_actor/@rate"/> </xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<connection from="{@from}" output="{@output}" rate="{$prod_rate}" output_count="{@output_count}">
			<virtual_link count="{virtual_link/@count}">
				<xsl:for-each select="virtual_link/* except $target_actor">
					<xsl:copy-of select="."/>
				</xsl:for-each>
				<actor name="{$target_actor/@name}" count="{$target_actor/@count}" input="{$target_actor/@input}" rate="{$cons_rate}" input_count="{$target_actor/@input_count}"/>
			</virtual_link>
		</connection>
	</xsl:template>
	
	<xsl:template match="zip" mode="find_factors_and_update_rates">
		<xsl:param name="factor"/>
		<xsl:choose>
			<xsl:when test="following-sibling::zip[1]">
				<xsl:apply-templates select="following-sibling::zip[1]" mode="find_factors_and_update_rates">
					<xsl:with-param name="factor" select="$factor * @rate"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$factor * @rate"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="unzip" mode="find_factors_and_update_rates">
		<xsl:param name="factor"/>
		<xsl:choose>
			<xsl:when test="following-sibling::unzip[1]">
				<xsl:apply-templates select="following-sibling::unzip[1]" mode="find_factors_and_update_rates">
					<xsl:with-param name="factor" select="$factor * @rate"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$factor * @rate"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	
	<xsl:template match="connection" mode="find_initial_token_sizes">
		<connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
			<virtual_link count="{virtual_link/@count}">
				<xsl:apply-templates select="virtual_link/*[1]" mode="find_initial_token_sizes">
					<xsl:with-param name="factor" select="1"/>
				</xsl:apply-templates>
			</virtual_link>
		</connection>
	</xsl:template>
	
	<xsl:template match="zip" mode="find_initial_token_sizes">
		<xsl:param name="factor"/>
		<xsl:copy-of select="." />
		<xsl:apply-templates select="following-sibling::*[1]" mode="find_initial_token_sizes">
			<xsl:with-param name="factor" select="$factor * @rate"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="unzip" mode="find_initial_token_sizes">
		<xsl:param name="factor"/>
		<xsl:copy-of select="." />
		<xsl:apply-templates select="following-sibling::*[1]" mode="find_initial_token_sizes">
			<xsl:with-param name="factor" select="$factor div @rate"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="fanout" mode="find_initial_token_sizes">
		<xsl:param name="factor"/>
		<xsl:copy-of select="." />
		<xsl:apply-templates select="following-sibling::*[1]" mode="find_initial_token_sizes">
			<xsl:with-param name="factor" select="$factor"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="delay" mode="find_initial_token_sizes">
		<xsl:param name="factor"/>
		<xsl:choose>
			<xsl:when test="@input_count &gt; 1 and not(@n = '')">
				<delay node_name="{@node_name}" n="{@n * $factor}" count="{@count}" input_count="{@input_count}" init_val="{@init_val}"/>
			</xsl:when>
			<xsl:when test="@input_count &gt; 1 and @n = ''">
				<delay node_name="{@node_name}" n="{$factor}" count="{@count}" input_count="{@input_count}" init_val="{@init_val}"/>
			</xsl:when>
			<xsl:when test="@n = ''">
				<delay node_name="{@node_name}" n="1" count="{@count}" input_count="{@input_count}" init_val="{@init_val}"/>
			</xsl:when>
			<xsl:otherwise><xsl:copy-of select="." /></xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="following-sibling::*[1]" mode="find_initial_token_sizes">
			<xsl:with-param name="factor" select="$factor"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="actor" mode="find_initial_token_sizes">
		<xsl:copy-of select="." />
	</xsl:template>
	
	
	
</xsl:transform>