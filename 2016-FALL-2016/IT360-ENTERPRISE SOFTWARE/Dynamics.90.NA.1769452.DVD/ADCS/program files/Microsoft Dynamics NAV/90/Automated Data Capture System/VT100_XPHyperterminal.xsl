<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml"/>

<xsl:template match="*">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="Function[.='ESC']">
  <Function Key1="27"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='FIRST']">
  <Function Key1="27" Key2="79" Key3="80" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='LAST']">
  <Function Key1="27" Key2="79" Key3="81" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='REGISTER']">
  <Function Key1="27" Key2="79" Key3="82" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='RESET']">
  <Function Key1="27" Key2="79" Key3="83" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='PGUP']">
  <Function Key1="27" Key2="91" Key3="65" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='PGDN']">
  <Function Key1="27" Key2="91" Key3="66" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='LNDN']">
  <Function Key1="27" Key2="91" Key3="67" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

<xsl:template match="Function[.='LNUP']">
  <Function Key1="27" Key2="91" Key3="68" Key4="0" Key5="0" Key6="0"><xsl:value-of select="."/></Function>
</xsl:template>

</xsl:stylesheet>
