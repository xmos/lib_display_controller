// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include "sdram.h"
#include <print.h>
#include <platform.h>
#include <xclib.h>
#include <stdlib.h>

#define LCD_HEIGHT 272
int count=0, line=0, error_flag=0;


static void handle_command(e_command cmd_type, sdram_cmd &cmd)
{
    if ((cmd_type == SDRAM_CMD_READ) && (count>600)){	//check after 2*272 SDRAM reqs; 272 writes and 272 reads
        if (line < LCD_HEIGHT){
            if ((cmd.address<130560) || (cmd.address>195600))  //Address range for frame 2
                error_flag = 1;
            line++;
        }
        if (line == LCD_HEIGHT){
            if (error_flag)
                printstrln("ERROR: wrong SDRAM address");
            else
                printstrln("committed frame read from SDRAM");
            exit(1);
        }
    }

    count++;
}


void dummy_sdram_server(streaming chanend c_client[client_count],
        const static unsigned client_count)
{
    sdram_cmd cmd_buffer[7][SDRAM_MAX_CMD_BUFFER];
    unsigned head[7] = {0};

    for(unsigned i=0;i<7;i++){
        head[i] = 0;
        cmd_buffer[i]->address = 0;
        cmd_buffer[i]->word_count = 0;
        cmd_buffer[i]->buffer = null;
    }

    unsafe {
        for(unsigned i=0;i<client_count;i++){
            c_client[i] <: (sdram_cmd * unsafe)&(cmd_buffer[i][0]);
            c_client[i] <: get_local_tile_id();
        }
    }

    unsafe{
        char d;
        while (1) {

            select {
                 case c_client[int i] :> d:
                    e_command cmd = (e_command)d;
                    if (i == 0)
                        handle_command(cmd, cmd_buffer[i][head[i]%SDRAM_MAX_CMD_BUFFER]);
                    head[i]++;
                    c_client[i] <: d;
                    break;
            }

        }
    }
}

