.. include:: ../../../README.rst

Hardware characteristics
------------------------

The display controller requires use of an SDRAM and and LCD. The respective hardware requirements of these are covered in:

  - :ref:`SDRAM library <programming_guide>`,
  - :ref:`LCD library <programming_guide>`.


Display Controller API
----------------------

All display controller functions can be accessed via the ``display_controller.h`` header::

  #include <display_controller.h>

You will also have to add ``lib_display_controller`` to the
``USED_MODULES`` field of your application Makefile.

The display controller server and client are instantiated as parallel tasks that run in a
``par`` statement. The client (application on most cases) can connect via
a streaming channel.

The display controller uses distributed tasks to implement bi-directional asynchronous decoupling of the commands between the application(client) and the display controller. This means that
the asynchronous command buffering is handled by the interfaces::

  interface app_to_cmd_buffer_i
  interface cmd_buffer_to_dc_i
  interface dc_to_res_buf_i
  interface res_buf_to_app_i

There is one other interface that connects to the application, this is the vertical synchronization interface. The purpose of this interface is to allow the application to know when the frame is at the start of a new scan, i.e. line zero is about to be written.

As the display controller uses some of the SDRAM the memory address allocator is used to allocate an amount of the SDRAM to the display controller. See ... TODO to find out more about how to use the memory address allocator.

For example, the following code instantiates a display controller server
and connects an application to it (the SDRAM and LCD declarations has been shortened for simplicity)::

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
 
        on tile[1]:lcd_server(c_lcd,... );
        on tile[1]:sdram_server(c_sdram, 2, ... );
 
    }
    return 0;
  }


Note that the client application, display controller, LCD server and SDRAM server
must be on the same tile as the line buffers are transfered by moving pointers
from one task to another.

The display controller library uses movable pointers to pass buffers between
the client and the server. This means that when the client passes a buffer to
the display controller then whilst the server is processing the command the
client will be unable to access that buffer. To handle this that client sends
commands using ``display_controller_read`` and ``display_controller_write``,
both of which will take a movable pointer as an argument. To return the pointer
to the client the client must call the interface from the display controller
(res_buf_to_app_i) using the ``pop()`` method which will take back ownership
of the pointer when the display controller server is finished processing the command.

Client/Server model
...................

The display controller server must be instantiated at the same level as its clients. For example::

   on tile[1]: display_controller(
                 cmd_buffer_to_dc, dc_to_res_buf, vsync_interface,
                 DISPLAY_CONTROLLER_IMAGE_COUNT,
                 LCD_HEIGHT,
                 LCD_WIDTH,
                 LCD_BYTES_PER_PIXEL,
                 to_memory_alloc[0], c_sdram[0], c_sdram[1], c_lcd);
   on tile[1]: app(app_to_cmd_buffer, res_buf_to_app, vsync_interface);

Command buffering
.................

The display controller server implements a single slot command buffer. This means 
that the client can queue up a command to the display controller server through 
calls to ``display_controller_read`` or ``display_controller_write``. A successful 
call to ``display_controller_read`` or ``display_controller_write`` will return 0 
and issue the command to the command buffer. When the command buffer is full then 
a call to ``sdram_read`` or ``sdram_write`` will return 1 and not issue the command.  
Commands are completed, i.e. a slot is freed, when ``sdram_complete`` returns. 
Commands are processed as in a first in first out ordering.

Initialization
..............

The display controller will start by displaying the image with handle 0. There is 
no need to initialize this frame as it will be set to all black (0x0). The application
should then begin by writing to any other registered frames (image handle 1 and up).

Safety through the use of movable pointers
..........................................

The API makes use of movable pointer to aid correct multi-threaded memory handling. See [#]_ to know more about movable pointers.

API
---

.. doxygenfunction:: display_controller
.. doxygenfunction:: display_controller_read
.. doxygenfunction:: display_controller_write
.. doxygenfunction:: display_controller_frame_buffer_commit

.. [#] https://www.xmos.com/download/public/XMOS-Programming-Guide-(documentation)(E).pdf

|newpage|

|appendix|

Known Issues
------------

There are no known issues with this library.

.. include:: ../../../CHANGELOG.rst
