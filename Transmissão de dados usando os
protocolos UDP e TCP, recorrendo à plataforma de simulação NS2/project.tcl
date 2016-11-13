#Argumentos de entrada
if {$argc == 6} {
	set cenario [lindex $argv 0]	
	set flow [lindex $argv 1]	
	set quebra [lindex $argv 2]	
	set window [lindex $argv 3]
	set duracao [lindex $argv 4]
	set velocidade [lindex $argv 5]
	if {$cenario != 1 && $cenario != 2} {
		puts "Choose only 1 or 2."
		exit 1
	}
	if {$flow != "udp" && $flow != "tcp"} {
		puts "Choose only udp or tcp."
		exit 1
	}
	if {$quebra != "yes" && $quebra != "no"} {
		puts "Choose only yes or no."
		exit 1
	}
	if {$flow == "tcp" && $window < 1} {
		puts "window >= 1."
		exit 1
	}
	if {$duracao < 0} {
		puts "duracao > 0."
		exit 1
	}
	if {$velocidade < 0} {
    	puts "velocidade between Servidor1-Router4 > 0."
    	exit 1
	}


} else {
	puts "ns project.tcl <cenario> <flow> <quebra> <window> <duracao> <velocidade>"
	puts "Verify the arguments"
	exit 1
}

set ns [new Simulator]
#protocolo de routing dinâmico
$ns rtproto DV 
set nf [open out.nam w]
$ns namtrace-all $nf
set nt [open out.tr w]
$ns trace-all $nt


proc fim {} {
	global ns nf nt
	$ns flush-trace
	close $nf
	close $nt
	exec nam out.nam
	exit 0
}

#servidor 1
set n0 [$ns node]
#servidor 2 
set n1 [$ns node]
#router 4 
set n2 [$ns node]
#router 5 
set n3 [$ns node]
#router 6 
set n4 [$ns node]
#receptor 1 
set n5 [$ns node]
#receptor 2 
set n6 [$ns node] 

#servidor 1--router 4
$ns duplex-link $n0 $n2 $velocidade+Mb 10ms DropTail 
$ns queue-limit $n0 $n2 2098
$ns duplex-link-op $n0 $n2 queuePos 1.5
#servidor 2--router 5
$ns duplex-link $n1 $n3 0.1Gb 10ms DropTail 
$ns duplex-link-op $n1 $n3 queuePos 1.5
#router 4--router 5
$ns duplex-link $n2 $n3 200Mb 10ms DropTail
#router 4--router 6 
$ns duplex-link $n2 $n4 1Gb 10ms DropTail
#router 5--router 6 
$ns duplex-link $n3 $n4 100Mb 10ms DropTail
#router 6--receptor 1 
$ns duplex-link $n4 $n5 40Mb 3ms  DropTail 
$ns duplex-link-op $n4 $n5 queuePos 0.5
#router 4--receptor 2
$ns duplex-link $n2 $n6 10Mb 10ms DropTail 
$ns duplex-link-op $n2 $n6 queuePos 1.5

#Orientação das ligações
$ns duplex-link-op $n0 $n2 orient down
$ns duplex-link-op $n1 $n3 orient down
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n2 $n4 orient right-down
$ns duplex-link-op $n3 $n4 orient down
$ns duplex-link-op $n4 $n5 orient right
$ns duplex-link-op $n2 $n6 orient down

#forma e cor dos nós
$n0 shape hexagon
$n0 color red
$n1 shape hexagon
$n1 color red
$n5 shape box
$n5 color blue
$n6 shape box
$n6 color blue

#legenda dos nós
$n0 label "Servidor 1"
$n1 label "Servidor 2"
$n2 label "R4"
$n3 label "R5"
$n4 label "R6"
$n5 label "Receptor 1"
$n6 label "Receptor 2"

$ns color 1 Red
$ns color 2 Blue
$ns color 3 Green

set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 2097152
$cbr0 set maxpkts_ 1

if {$flow == "udp"} {
	
	set udp0 [new Agent/UDP]
	$ns attach-agent $n0 $udp0
	$cbr0 attach-agent $udp0
	set null0 [new Agent/Null]
	$ns attach-agent $n5 $null0
	$ns connect $udp0 $null0

	$udp0 set class_ 1

	$ns at 0.5 "$cbr0 start"
} else {
	set tcp0 [new Agent/TCP]
	$ns attach-agent $n0 $tcp0
	$tcp0 set window_ $window
	$cbr0 attach-agent $tcp0
	set sink0 [new Agent/TCPSink]
	$ns attach-agent $n5 $sink0
	$ns connect $tcp0 $sink0

	$tcp0 set class_ 1

	$ns at 0.5 "$cbr0 start"
}
$ns at [expr $duracao + 0.5] "$cbr0 stop"

if {$cenario == 2} {

	set udp1 [new Agent/UDP]
	$ns attach-agent $n1 $udp1

	set cbr1 [new Application/Traffic/CBR]
	$cbr1 set rate_ 3mb
	$cbr1 attach-agent $udp1

	set null1 [new Agent/Null]
	$ns attach-agent $n5 $null1
	$ns connect $udp1 $null1

	set udp2 [new Agent/UDP]
	$ns attach-agent $n1 $udp2

	set cbr2 [new Application/Traffic/CBR]
	$cbr2 set rate_ 3mb
	$cbr2 attach-agent $udp2

	set null2 [new Agent/Null]
	$ns attach-agent $n6 $null2
	$ns connect $udp2 $null2

	$udp1 set class_ 2
	$udp2 set class_ 3
	$ns at 0.5 "$cbr1 start"
	$ns at [expr $duracao + 0.5] "$cbr0 stop"
	$ns at 0.5 "$cbr2 start"
	$ns at [expr $duracao + 0.5] "$cbr0 stop"
}

if {$quebra == "yes"} {
	$ns rtmodel-at 0.6 down $n2 $n4
	$ns rtmodel-at 0.7 up $n2 $n4
}

$ns at [expr $duracao + 1] "fim"

$ns run
