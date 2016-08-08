// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
/*******************************************************************************************
 * This program tests the initialization of the LCD display by the display controller server
********************************************************************************************/

#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include "display_controller.h"

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
#define LCD_ROW_WORDS (LCD_WIDTH/2)

#define DISPLAY_CONTROLLER_IMAGE_COUNT (2)

void dummy_sdram_server(streaming chanend c_client[client_count],
        const static unsigned client_count);
void dummy_lcd_server(streaming chanend c_client,
        const static unsigned width,
        const static unsigned height,
        const static unsigned h_front_porch,
        const static unsigned h_back_porch,
        const static unsigned h_pulse_width,
        const static unsigned v_front_porch,
        const static unsigned v_back_porch,
        const static unsigned v_pulse_width,
        const static unsigned clock_divider);


void app(client interface app_to_cmd_buffer_i to_dc, client interface res_buf_to_app_i from_dc,
        client interface dc_vsync_interface_i vsync)
{
	/* This empty app just performs the initialization part of the display controller */
}



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

      on tile[1]: dummy_lcd_server(c_lcd,LCD_WIDTH,LCD_HEIGHT,
              LCD_H_FRONT_PORCH,
              LCD_H_BACK_PORCH,
              LCD_H_PULSE_WIDTH,
              LCD_V_FRONT_PORCH,
              LCD_V_BACK_PORCH,
              LCD_V_PULSE_WIDTH,
              LCD_CLOCK_DIVIDER);

      on tile[1]: dummy_sdram_server(c_sdram, 2);

     on tile[1]: par(int i=0;i<4;i++) while(1);
  }
  return 0;
}
