<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Phase 9: Convert to SDF3 Representation -->
	<!-- ======================================= -->

	<xsl:template match="graph" mode="convert-to-sdf3">
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
		<channel name="{@name}" srcActor="{@source}" srcPort="{@source_port}" dstActor="{@target}" dstPort="{@target_port}" initialTokens="{@initial_tokens}"/>
	</xsl:template>

	<xsl:template match="node" mode="convert-to-properties">
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
		<channelProperties channel="{@name}">
        	<tokenSize sz="32"/>
      	</channelProperties>
	</xsl:template>





	<!-- Phase 10: Annotate actor memory size and token size properties -->
	<!-- ============================================================== -->

	<xsl:template match="nest" mode="annotate-size-properties">
		<nest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="sdf" version="1.0" xsi:noNamespaceSchemaLocation="usecase.xsd">
			<applicationGraph name="{applicationGraph/@name}" type="sdf">
				<xsl:copy-of select="applicationGraph/csdfgraph"/>
				<csdfProperties>
					<xsl:apply-templates select="applicationGraph/csdfProperties/actorProperties" mode="annotate-size-properties"/>
					<xsl:apply-templates select="applicationGraph/csdfProperties/channelProperties" mode="annotate-size-properties"/>
				</csdfProperties>
				<xsl:copy-of select="applicationGraph/graphProperties"/>
			</applicationGraph>
		</nest>
	</xsl:template>

	<xsl:template match="actorProperties" mode="annotate-size-properties">
		<actorProperties actor="{@actor}">
            <processor type="microblaze0" default="true">
               <memory>
                  <memoryElement name=".instr">
                     <size><xsl:value-of select="$size-properties/size_info/actor[@name = current()/processor/implementation/function/@symbol]/@instr"/></size>
                     <accessCnt>1</accessCnt>
                     <accessType>IFetch</accessType>
                     <accessSize>word</accessSize>
                  </memoryElement>
                  <memoryElement name=".data">
                     <size><xsl:value-of select="$size-properties/size_info/actor[@name = current()/processor/implementation/function/@symbol]/@data"/></size>
                     <accessCnt>1</accessCnt>
                     <accessType>DRead,DWrite</accessType>
                     <accessSize>halfword</accessSize>
                  </memoryElement>
                  <memoryElement name="sharedVar">
                     <size>0</size>
                     <accessCnt>1</accessCnt>
                     <accessType>DRead,DWrite</accessType>
                     <accessSize>byte</accessSize>
                  </memoryElement>
               </memory>
               <xsl:copy-of select="processor/implementation"/>
            </processor>
         </actorProperties>
	</xsl:template>

	<xsl:template match="channelProperties" mode="annotate-size-properties">
		<xsl:variable name="channelType" select="$graph-wo-delays/graph/edge[@name = current()/@channel]/@type"/>
		<channelProperties channel="{@channel}">
            <tokenSize size="{$size-properties/size_info/tokenType[@name = $channelType]/@size}"/>
            <xsl:copy-of select="implementation"/>
         </channelProperties>
	</xsl:template>


	<!-- Phase 11: Annotate actor execution times -->
	<!-- ======================================== -->

	<xsl:template match="nest" mode="annotate-execution-times">
		<nest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" type="sdf" version="1.0" xsi:noNamespaceSchemaLocation="usecase.xsd">
			<applicationGraph name="{applicationGraph/@name}" type="sdf">
				<csdfgraph>
					<xsl:apply-templates select="applicationGraph/csdfgraph/actor" mode="annotate-execution-times"/>
					<xsl:copy-of select="applicationGraph/csdfgraph/channel"/>
				</csdfgraph>
				<xsl:copy-of select="applicationGraph/csdfProperties"/>
				<xsl:copy-of select="applicationGraph/graphProperties"/>
			</applicationGraph>
		</nest>
	</xsl:template>

	<xsl:template match="actor" mode="annotate-execution-times">
		<actor name="{@name}">
			<executionTime time="{$execution-time-properties/execution_times/actor[@name = current()/@name]/@execution_time}" />
			<xsl:copy-of select="port"/>
	  </actor>
	</xsl:template>

</xsl:transform>
