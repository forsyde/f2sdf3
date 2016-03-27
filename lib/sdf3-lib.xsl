<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
