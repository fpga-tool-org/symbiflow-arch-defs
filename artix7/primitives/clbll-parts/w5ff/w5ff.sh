#! /bin/bash

W=$(echo $1 | sed -e's/^pb_type.//' -e's/5FF.xml$//')

cat > $1 <<EOF
<!-- D5FF, C5FF, B5FF, A5FF == W5FF -->
<pb_type name="${W}5FF" num_pb="1" xmlns:xi="http://www.w3.org/2001/XInclude">
  <input name="D" num_pins="1"/>
  <input name="CE" num_pins="1"/>
  <clock name="CK" num_pins="1"/>
  <input name="SR" num_pins="1"/>
  <output name="Q" num_pins="1"/>

  <xi:include href="../../../../vpr/ff/pb_type.xml"/>
  <interconnect>
    <direct name="D" input="${W}5FF.D" output="FF.D"/>
    <direct name="Q" input="FF.Q" output="${W}5FF.Q"/>
    <direct name="C" input="${W}5FF.CK" output="FF.clk"/>
  </interconnect>
</pb_type>
EOF
