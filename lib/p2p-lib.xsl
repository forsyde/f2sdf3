<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Calculate factors for updating rates -->
    <!-- ==================================== -->
    <!-- see below -->

    <xsl:template match="connection" mode="p2p-factors-upd-rates">
	<xsl:variable name="zip_factor">
	    <xsl:choose>
		<xsl:when test="count(virtual_link/zip) &gt; 0">
		    <xsl:apply-templates select="virtual_link/zip[1]" mode="p2p-factors-upd-rates">
			<xsl:with-param name="factor" select="1"/>
		    </xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="1"/> </xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<xsl:variable name="unzip_factor">
	    <xsl:choose>
		<xsl:when test="count(virtual_link/unzip) &gt; 0">
		    <xsl:apply-templates select="virtual_link/unzip[1]" mode="p2p-factors-upd-rates">
			<xsl:with-param name="factor" select="1"/>
		    </xsl:apply-templates>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:copy-of select="1"/> 
		</xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<xsl:variable name="channel_factor" select="$zip_factor div $unzip_factor"/>
	<xsl:variable name="target_actor" select=".//actor"/>
	<xsl:variable name="prod_rate">
	    <xsl:choose>
		<xsl:when test="(@output_count &gt; 1) and ($channel_factor &lt; 1)">
		    <xsl:value-of select="@rate * (1 div $channel_factor)"/>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="@rate"/> </xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<xsl:variable name="cons_rate">
	    <xsl:choose>
		<xsl:when test="($target_actor/@input_count &gt; 1) and ($channel_factor &gt; 1)">
		    <xsl:value-of select="$target_actor/@rate * $channel_factor"/>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$target_actor/@rate"/> </xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>

	<xsl:if test="$debug"><xsl:message>[p2p-factors-upd-rates] : intermediate rates for '<xsl:value-of select="@from"/>': 
	  * target_actor   : <xsl:value-of select="$target_actor/@name"/> 
	  * zip_factor     : <xsl:value-of select="$zip_factor"/>
	  * unzip_factor   : <xsl:value-of select="$unzip_factor"/>
	  * channel_factor : <xsl:value-of select="$channel_factor"/>
	  * prod_rate      : <xsl:value-of select="$prod_rate"/> 
	  * cons_rate      : <xsl:value-of select="$cons_rate"/> 
	</xsl:message></xsl:if>
	<connection from="{@from}" output="{@output}" rate="{$prod_rate}" output_count="{@output_count}">
	    <virtual_link count="{virtual_link/@count}">
		<xsl:for-each select="virtual_link/* except $target_actor">
		    <xsl:copy-of select="."/>
		</xsl:for-each>
		<actor name="{$target_actor/@name}" 
		       count="{$target_actor/@count}" 
		       input="{$target_actor/@input}" 
		       rate="{$cons_rate}" 
		       input_count="{$target_actor/@input_count}"/>
	    </virtual_link>
	</connection>
    </xsl:template>
    
    <xsl:template match="zip" mode="p2p-factors-upd-rates">
	<xsl:param name="factor"/>
	<xsl:choose>
	    <xsl:when test="following-sibling::zip[1]">
		<xsl:apply-templates select="following-sibling::zip[1]" mode="p2p-factors-upd-rates">
		    <xsl:with-param name="factor" select="$factor * @rate"/>
		</xsl:apply-templates>
	    </xsl:when>
	    <xsl:otherwise><xsl:value-of select="$factor * @rate"/></xsl:otherwise>
	</xsl:choose>
    </xsl:template>
    
    <xsl:template match="unzip" mode="p2p-factors-upd-rates">
	<xsl:param name="factor"/>
	<xsl:choose>
	    <xsl:when test="following-sibling::unzip[1]">
		<xsl:apply-templates select="following-sibling::unzip[1]" mode="p2p-factors-upd-rates">
		    <xsl:with-param name="factor" select="$factor * @rate"/>
		</xsl:apply-templates>
	    </xsl:when>
	    <xsl:otherwise><xsl:value-of select="$factor * @rate"/></xsl:otherwise>
	</xsl:choose>
    </xsl:template>
    

    <!-- Find initial token rates -->
    <!-- ======================== -->
    <!-- Based on the channel structure, delays may represent more than one initial token -->
    
    <xsl:template match="connection" mode="p2p-initial-tokens">
	<connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
	    <virtual_link count="{virtual_link/@count}">
		<xsl:apply-templates select="virtual_link/*[1]" mode="p2p-initial-tokens">
		    <xsl:with-param name="factor" select="1"/>
		</xsl:apply-templates>
	    </virtual_link>
	</connection>
    </xsl:template>
    
    <xsl:template match="zip" mode="p2p-initial-tokens">
	<xsl:param name="factor"/>
	<xsl:copy-of select="." />
	<xsl:apply-templates select="following-sibling::*[1]" mode="p2p-initial-tokens">
	    <xsl:with-param name="factor" select="$factor * @rate"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="unzip" mode="p2p-initial-tokens">
	<xsl:param name="factor"/>
	<xsl:copy-of select="." />
	<xsl:apply-templates select="following-sibling::*[1]" mode="p2p-initial-tokens">
	    <xsl:with-param name="factor" select="$factor div @rate"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="fanout" mode="p2p-initial-tokens">
	<xsl:param name="factor"/>
	<xsl:copy-of select="." />
	<xsl:apply-templates select="following-sibling::*[1]" mode="p2p-initial-tokens">
	    <xsl:with-param name="factor" select="$factor"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="delay" mode="p2p-initial-tokens">
	<xsl:param name="factor"/>
	<xsl:if test="$debug"><xsl:message>[p2p-initial-tokens] : when reaching delay '<xsl:value-of select="@node_name"/> the factor was <xsl:value-of select="$factor"/>'</xsl:message></xsl:if>	
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
	<xsl:apply-templates select="following-sibling::*[1]" mode="p2p-initial-tokens">
	    <xsl:with-param name="factor" select="$factor"/>
	</xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="actor" mode="p2p-initial-tokens">
	<xsl:copy-of select="." />
    </xsl:template>
    
    
  <!-- Remove zips, unzips, etc -->
  <!-- ======================== -->
  
  <xsl:template match="connection" mode="p2p-remove-zips-unzips">
      <xsl:if test="$debug"><xsl:message>[p2p-remove-zips-unzips] : removing zips and unzips from connection '<xsl:value-of select="@from"/>' </xsl:message></xsl:if>
      <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
	  <virtual_link count="{virtual_link/@count}">
  	      <xsl:for-each select="virtual_link/fanout | virtual_link/delay | virtual_link/actor">
  		  <xsl:copy-of select="."/>
  	      </xsl:for-each>
	  </virtual_link>
      </connection>
  </xsl:template>

  
  <!-- Merge fanouts -->
  <!-- ============= -->
  
  <xsl:template match="connection" mode="p2p-remove-chained-fanouts">
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
  
  <xsl:template match="connection" mode="p2p-remove-all-fanouts">
      <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}">
	  <virtual_link count="{virtual_link/@count}">
  	      <xsl:for-each select="virtual_link/delay | virtual_link/actor">
  		  <xsl:copy-of select="."/>
  	      </xsl:for-each>
	  </virtual_link>
      </connection>
  </xsl:template>


  <!-- Remove sources -->
  <!-- ============== -->

  <xsl:template match="connection" mode="p2p-remove-sources">
      <xsl:param name="graph" />
      <xsl:variable name="from" select="./@from" />
      <xsl:variable name="node" select="$graph/graph/node[@name = current()/@from]" />
      <xsl:if test="not($node/@kind = 'constant' or $node/@kind = 'file_source')" >
  	  <xsl:copy-of select="."/>
      </xsl:if>
  </xsl:template>
  
  <!-- <xsl:template match="connection" mode="forsyde-constant-source-workaround-add-self-edges-to-sources"> -->
  <!--   <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]" /> -->
  <!--   <xsl:variable name="prev_connections" select="preceding-sibling::connection[@from = current()/@from and ./virtual_link/@count = current()/virtual_link/@count]"/> -->
  <!--   <xsl:if test="$node/@kind = 'source' and count($prev_connections) = 0"> -->
  <!--     <connection from="{@from}" output="{@output}" rate="{@rate}" output_count="{@output_count}"> -->
  <!-- 	<virtual_link count="{virtual_link/@count}"> -->
  <!-- 	  <delay node_name="{@from}" n="{@rate}" count="{virtual_link/@count}" input_count="{@output_count}" init_val="{$node/@init_val}"/> -->
  <!-- 	  <actor name="{@from}" count="{virtual_link/@count}" input="iport1" rate="{@rate}" input_count="{@output_count}"/> -->
  <!-- 	</virtual_link> -->
  <!--     </connection> -->
  <!--   </xsl:if> -->
  <!-- </xsl:template> -->
  
  <!-- <xsl:template match="connection" mode="forsyde-constant-source-workaround-add-take-val-self-edges"> -->
  <!--   <xsl:variable name="node" select="$forsyde-graph/graph/node[@name = current()/@from]" /> -->
  <!--   <xsl:variable name="prev_connections" select="preceding-sibling::connection[@from = current()/@from]"/> -->
  <!--   <xsl:if test="($node/@kind = 'constant' or $node/@kind = 'source' or $node/@kind = 'file_source') and count($prev_connections) = 0"> -->
  <!--     <connection from="{@from}" output="take_val_oport" rate="1" output_count="1"> -->
  <!-- 	<virtual_link count="1"> -->
  <!-- 	  <delay node_name="{@from}" n="1" count="1" input_count="1" init_val="{$node/@take}"/> -->
  <!-- 	  <actor name="{@from}" count="1" input="take_val_iport" rate="1" input_count="1"/> -->
  <!-- 	</virtual_link> -->
  <!--     </connection> -->
  <!--   </xsl:if> -->
  <!-- </xsl:template> -->

  
</xsl:transform>
