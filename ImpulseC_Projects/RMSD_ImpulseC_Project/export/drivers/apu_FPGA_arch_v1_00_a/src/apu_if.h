#ifndef APU_IF_H
#define APU_IF_H

/* APU assignments */
#if !defined(IMPULSE_FIRST_APU)

#define p_Producer_input_data() "0"
#define p_Producer_input_status() "2"
#define p_Consumer_output_data() "4"
#define p_Consumer_output_status() "6"
#define p_config_sys_data() "8"
#else

#if IMPULSE_FIRST_APU == 0

#define p_Producer_input_data() "0"
#define p_Producer_input_status() "2"
#define p_Consumer_output_data() "4"
#define p_Consumer_output_status() "6"
#define p_config_sys_data() "8"
#endif

#if IMPULSE_FIRST_APU == 1

#define p_Producer_input_data() "4"
#define p_Producer_input_status() "6"
#define p_Consumer_output_data() "8"
#define p_Consumer_output_status() "10"
#define p_config_sys_data() "12"
#endif

#if IMPULSE_FIRST_APU == 2

#define p_Producer_input_data() "8"
#define p_Producer_input_status() "10"
#define p_Consumer_output_data() "12"
#define p_Consumer_output_status() "14"
#define p_config_sys_data() "16"
#endif

#if IMPULSE_FIRST_APU == 3

#define p_Producer_input_data() "12"
#define p_Producer_input_status() "14"
#define p_Consumer_output_data() "16"
#define p_Consumer_output_status() "18"
#define p_config_sys_data() "20"
#endif

#if IMPULSE_FIRST_APU == 4

#define p_Producer_input_data() "16"
#define p_Producer_input_status() "18"
#define p_Consumer_output_data() "20"
#define p_Consumer_output_status() "22"
#define p_config_sys_data() "24"
#endif

#if IMPULSE_FIRST_APU == 5

#define p_Producer_input_data() "20"
#define p_Producer_input_status() "22"
#define p_Consumer_output_data() "24"
#define p_Consumer_output_status() "26"
#define p_config_sys_data() "28"
#endif

#if IMPULSE_FIRST_APU == 6

#define p_Producer_input_data() "24"
#define p_Producer_input_status() "26"
#define p_Consumer_output_data() "28"
#define p_Consumer_output_status() "30"
#define p_config_sys_data() "32"
#endif

#if IMPULSE_FIRST_APU == 7

#define p_Producer_input_data() "28"
#define p_Producer_input_status() "30"
#define p_Consumer_output_data() "32"
#define p_Consumer_output_status() "34"
#define p_config_sys_data() "36"
#endif

#endif

#define GENERATE_STREAM_WRITE0 4
#define GENERATE_STREAM_CLOSE2
#define GENERATE_STREAM_INSTR0 "lvewx"
#define GENERATE_STREAM_READ4 4
#define GENERATE_STREAM_INSTR4 "stvewx"

#endif
