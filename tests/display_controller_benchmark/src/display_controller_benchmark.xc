#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include "display_controller.h"

/*
 * Put an lcd slice into circle slot of A16 board.
 * Put an sdram slice into square slot of A16 board.
 */
#define LCD_CLOCK_DIVIDER 3
#define LCD_H_FRONT_PORCH 5
#define LCD_H_BACK_PORCH 40
#define LCD_H_PULSE_WIDTH 1
#define LCD_V_FRONT_PORCH 8
#define LCD_V_BACK_PORCH 8
#define LCD_V_PULSE_WIDTH 1
#define LCD_HEIGHT 272
#define LCD_WIDTH 480
#define LCD_BYTES_PER_PIXEL 2
#define LCD_OUTPUT_MODE data16_port16
#define LCD_ROW_WORDS (LCD_WIDTH/2)

#define DISPLAY_CONTROLLER_IMAGE_COUNT (2)

#define SDRAM_CAS_LATENCY           2
#define SDRAM_ROW_WORDS             128
#define SDRAM_COL_BITS              16
#define SDRAM_COL_ADDRESS_BITS      8
#define SDRAM_ROW_ADDRESS_BITS      12
#define SDRAM_BANK_ADDRESS_BITS     2
#define SDRAM_REFRESH_MS            64
#define SDRAM_REFRESH_CYCLES        4096
#define SDRAM_CLOCK_DIVIDER         4

void app(client interface app_to_cmd_buffer_i to_dc, client interface res_buf_to_app_i from_dc,
        client interface dc_vsync_interface_i vsync){

    unsigned current_image=0;
    unsigned buf[LCD_ROW_WORDS];
    unsigned * movable buffer_pointer = buf;
    for(unsigned i=0; i<LCD_ROW_WORDS; i++)
        buffer_pointer[i]=0xffffffff;
    timer t;
    unsigned frames = 0;
#define FRAME_COUNT 1000
    unsigned time;
    t:> time;
    while(1){

        //write the whole of the frame buffer that is not being displayed
        for(unsigned l = 0; l< LCD_HEIGHT;l++){
            display_controller_write(to_dc, move(buffer_pointer), 1, l, LCD_ROW_WORDS, 0);
            unsigned r;
            {buffer_pointer, r} = from_dc.pop();
        }
        frames++;
        if(frames == FRAME_COUNT){
            unsigned now;
            t:> now;

            unsigned clocks_per_frame = (LCD_H_FRONT_PORCH + LCD_H_BACK_PORCH + LCD_WIDTH)*(LCD_V_FRONT_PORCH + LCD_V_BACK_PORCH + LCD_HEIGHT );

            printf("Refresh rate: %.2fHz\n", (100000000.0/(LCD_CLOCK_DIVIDER*2.0))/(float)clocks_per_frame);
            printf("Avaliable read/write bandwidth: %.2f frames per second\n",100000000.0/((float)(now - time)/(float)FRAME_COUNT));
            //_Exit(1);
            frames = 0;
            t:> time;
        }
        current_image = 1 - current_image;
    }
}

on tile[1] : out buffered port:32   lcd_rgb                     = XS1_PORT_16B;
on tile[1] : out port               lcd_clk                     = XS1_PORT_1I;
on tile[1] : out port               ?lcd_data_enabled           = XS1_PORT_1L;
on tile[1] : out buffered port:32   ?lcd_h_sync                 = XS1_PORT_1J;
on tile[1] : out port               ?lcd_v_sync                 = XS1_PORT_1K;
on tile[1] : clock                  lcd_cb                      = XS1_CLKBLK_1;

on tile[1] : out buffered port:32   sdram_dq_ah                 = XS1_PORT_16A;
on tile[1] : out buffered port:32   sdram_cas                   = XS1_PORT_1B;
on tile[1] : out buffered port:32   sdram_ras                   = XS1_PORT_1G;
on tile[1] : out buffered port:8    sdram_we                    = XS1_PORT_1C;
on tile[1] : out port               sdram_clk                   = XS1_PORT_1F;
on tile[1] : clock                  sdram_cb                    = XS1_CLKBLK_2;


int main() {
  interface app_to_cmd_buffer_i     app_to_cmd_buffer;
  interface cmd_buffer_to_dc_i      cmd_buffer_to_dc;

  interface dc_to_res_buf_i         dc_to_res_buf;
  interface res_buf_to_app_i        res_buf_to_app;

  interface dc_vsync_interface_i    vsync_interface;

  interface memory_address_allocator_i to_memory_alloc[1];

  streaming chan c_sdram[2], c_lcd;
  par {
      on tile[1]: [[distribute]] memory_address_allocator( 1, to_memory_alloc, 0, 1024*1024*8);

      on tile[1]: [[distribute]] command_buffer(app_to_cmd_buffer, cmd_buffer_to_dc);
      on tile[1]: display_controller(
              cmd_buffer_to_dc, dc_to_res_buf, vsync_interface,
              DISPLAY_CONTROLLER_IMAGE_COUNT,
              LCD_HEIGHT,
              LCD_WIDTH,
              LCD_BYTES_PER_PIXEL,
              to_memory_alloc[0], c_sdram[0], c_sdram[1], c_lcd);
      on tile[1]: [[distribute]] response_buffer(dc_to_res_buf, res_buf_to_app);

      on tile[1]: app(app_to_cmd_buffer, res_buf_to_app, vsync_interface);

      on tile[1]:lcd_server(
              c_lcd,
              lcd_rgb,
              lcd_clk,
              lcd_data_enabled,
              lcd_h_sync,
              lcd_v_sync,
              lcd_cb,
              LCD_WIDTH,
              LCD_HEIGHT,
              LCD_H_FRONT_PORCH,
              LCD_H_BACK_PORCH,
              LCD_H_PULSE_WIDTH,
              LCD_V_FRONT_PORCH,
              LCD_V_BACK_PORCH,
              LCD_V_PULSE_WIDTH,
              LCD_OUTPUT_MODE,
              LCD_CLOCK_DIVIDER);

      on tile[1]:sdram_server(c_sdram, 2,
              sdram_dq_ah,
              sdram_cas,
              sdram_ras,
              sdram_we,
              sdram_clk,
              sdram_cb,
              SDRAM_CAS_LATENCY,
              SDRAM_ROW_WORDS,
              SDRAM_COL_BITS,
              SDRAM_COL_ADDRESS_BITS,
              SDRAM_ROW_ADDRESS_BITS,
              SDRAM_BANK_ADDRESS_BITS,
              SDRAM_REFRESH_MS,
              SDRAM_REFRESH_CYCLES,
              SDRAM_CLOCK_DIVIDER);

     on tile[1]: par(int i=0;i<4;i++) while(1);
  }
  return 0;
}
