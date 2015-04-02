Display controller library
==========================

Display controller library
--------------------------

The XMOS display controller library provides the service of removing the
real-time constraint of maintaining the LCDs line buffer from the 
application and provides a managed frame buffering service. It does this
by using an SDRAM as a storage for the frame buffers.

Features
........

   * Asynchronous non-blocking interface for modifying frame buffers,
   * User configurable number of frame buffers.

Components
...........

 * Display controller
 
 
Resource Usage
..............

.. resusage::
  :widths: 6 1 4 1 1 1

  * - configuration: Display controller server, 2 frame buffers of 480x272 pixels
    - globals: 
    - locals:  interface app_to_cmd_buffer_i     app_to_cmd_buffer;interface cmd_buffer_to_dc_i      cmd_buffer_to_dc;interface dc_to_res_buf_i         dc_to_res_buf;interface res_buf_to_app_i        res_buf_to_app;interface dc_vsync_interface_i    vsync_interface; interface memory_address_allocator_i to_memory_alloc[1]; streaming chan c_sdram[2], c_lcd;
    - fn: command_buffer(app_to_cmd_buffer, cmd_buffer_to_dc); display_controller(cmd_buffer_to_dc, dc_to_res_buf, vsync_interface, 2,272, 480,2, to_memory_alloc[0], c_sdram[0], c_sdram[1], c_lcd);response_buffer(dc_to_res_buf, res_buf_to_app);
    - pins: 0
    - ports: 0

  * - configuration: Display controller server, 4 frame buffers of 480x272 pixels
    - globals: 
    - locals:  interface app_to_cmd_buffer_i     app_to_cmd_buffer;interface cmd_buffer_to_dc_i      cmd_buffer_to_dc;interface dc_to_res_buf_i         dc_to_res_buf;interface res_buf_to_app_i        res_buf_to_app;interface dc_vsync_interface_i    vsync_interface; interface memory_address_allocator_i to_memory_alloc[1]; streaming chan c_sdram[2], c_lcd;
    - fn: command_buffer(app_to_cmd_buffer, cmd_buffer_to_dc); display_controller(cmd_buffer_to_dc, dc_to_res_buf, vsync_interface, 4,272, 480,2, to_memory_alloc[0], c_sdram[0], c_sdram[1], c_lcd);response_buffer(dc_to_res_buf, res_buf_to_app);
    - pins: 0
    - ports: 0

  * - configuration: Display controller server, 8 frame buffers of 480x272 pixels
    - globals: 
    - locals:  interface app_to_cmd_buffer_i     app_to_cmd_buffer;interface cmd_buffer_to_dc_i      cmd_buffer_to_dc;interface dc_to_res_buf_i         dc_to_res_buf;interface res_buf_to_app_i        res_buf_to_app;interface dc_vsync_interface_i    vsync_interface; interface memory_address_allocator_i to_memory_alloc[1]; streaming chan c_sdram[2], c_lcd;
    - fn: command_buffer(app_to_cmd_buffer, cmd_buffer_to_dc); display_controller(cmd_buffer_to_dc, dc_to_res_buf, vsync_interface, 8,272, 480,2, to_memory_alloc[0], c_sdram[0], c_sdram[1], c_lcd);response_buffer(dc_to_res_buf, res_buf_to_app);
    - pins: 0
    - ports: 0


Software version and dependencies
.................................

.. libdeps::

Related application notes
.........................

The following application notes use this library:

  * AN00169 - Using the display controller library

