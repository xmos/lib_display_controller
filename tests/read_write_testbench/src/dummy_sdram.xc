#include "sdram.h"
#include <print.h>
#include <platform.h>
#include <xclib.h>

#define LCD_ROW_WORDS 240
static void read(unsigned * buffer)
{
    for (unsigned i=0;i<LCD_ROW_WORDS;i++)
        buffer[i] = i;
}

static void write(unsigned * buffer)
{
    int error_flag = 0;
    for (unsigned i=0;i<LCD_ROW_WORDS;i++)
        if (buffer[i] != i)
            error_flag = 1;

    if (error_flag)
        printstrln("ERROR: wrong data written to SDRAM");
    else
        printstrln("correct data written to SDRAM");

}

static void handle_command(e_command cmd_type, sdram_cmd &cmd)
{
    switch (cmd_type) {
    case SDRAM_CMD_READ:
      read(cmd.buffer);
      break;
    case SDRAM_CMD_WRITE:
      write(cmd.buffer);
      break;
    }
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
                    if (i == 1)
                        handle_command(cmd, cmd_buffer[i][head[i]%SDRAM_MAX_CMD_BUFFER]);
                    head[i]++;
                    c_client[i] <: d;
                    break;
            }

        }
    }
}
