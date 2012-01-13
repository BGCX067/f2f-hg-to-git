# Copyright 2002-2007, Impulse Accelerated Technologies, Inc.
# All rights reserved.

proc xdefine_params {drv_handle file_name drv_string args} {
    
    # Open include file
    set file_handle [xopen_include_file $file_name]

    # Get all peripherals connected to this driver
    set periphs [xget_periphs $drv_handle] 

    # Print all parameters for all peripherals
    foreach periph $periphs {
	foreach arg $args {
       	    set value [xget_value $periph "PARAMETER" $arg]
	    if {$value != ""} {
	       set value [xformat_addr_string $value $arg]
	       puts $file_handle "#define [xget_name $periph $arg] $value"
	    }
	}
    }		
    close $file_handle
}

proc generate {drv_handle} {
    
    xdefine_params $drv_handle "xparameters.h" "" "C_BASEADDR" "C_HIGHADDR"
}

