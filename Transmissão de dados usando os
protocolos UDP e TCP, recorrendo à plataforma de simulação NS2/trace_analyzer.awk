#=====================================================================================
#    Trace_analyzer.awk 
#
#    Copyright 2013 Vasco Pereira <vasco@dei.uc.pt>
#     
#
#    This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
#    
#    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#    
#    You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#    
#=====================================================================================
#   How to use: 
#   >$ awk -f trace_analyzer.awk type=<x> src=<y> dest=<z> flow=<w> <trace_file> >
#
#  - type: packet type ; src: packet source ; dest: packet destination (for that hop) ; 
#    trace_file: NS trace file
#
#   Result file has 5 lines:
#     Total sent
#     Total received
#     Number of lost packets
#     Average delay			- average time a packet spends from sender to receiver
#     Total transmission time		- difference between last packet time arrival and first packet departure
#
# =====================================================================================
#
# NS file format:
#
# event=$1 ; time=$2 ; from_node_id=$3 ; to_node_id=$4 ; pkt_type=$5 ; flow_id=$8 ; pktid=$12
#
# =====================================================================================
#
# initial processing - variable initialization
BEGIN {
        for (i in send) {
                send[i] = 0
        }
        for (i in recv) {
                recv[i] = 0
        }
	delay = 0
	total_send = 0
	total_recv = 0
	min_send_time=100000 #just a big number
	max_recv_time=0
}
# Line by line processing
{
        # Trace line format: normal
        event = $1
        time = $2
        from_node_id=$3
        to_node_id=$4
        pkt_type = $5
	flow_id = $8
        pkt_id = $12

        # Store packets send time
        if ( flow_id == flow && pkt_type == type && from_node_id == src && event == "+") {
                send[pkt_id] = time
        }
        # Store packets arrival time
        if ( flow_id == flow && pkt_type == type && to_node_id == dest && event == "r") {
                 recv[pkt_id] = time
        }
}
# Final processing
END {
	for (i in send) {
		total_send=total_send+1
		if (send[i]<min_send_time){
			min_send_time=send[i]
			}
		}

        for (i in recv) {
		total_recv=total_recv+1
		delay=delay+recv[i]-send[i]	# sums delays
		if (recv[i]>max_recv_time){
			max_recv_time=recv[i]
			}
		}
	delay = delay/total_recv	# calculates average

	printf("\nStatistics for %s from node %d to %d in flow %d\n", type,src,dest,flow)
	printf("Total sent: %d\n",total_send)
	printf("Total received: %d\n",total_recv)
	printf("Lost packets: %d\n",total_send-total_recv)
	printf("Average delay: %010.6f\n",delay)		# %010.f to enable leading zeros
	printf("Total transmission time: %010.6f\n",max_recv_time-min_send_time)
}

