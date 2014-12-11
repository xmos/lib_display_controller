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

TODO

Software version and dependencies
.................................

This document pertains to version |version| of the display controller library. It is
intended to be used with version 13.x of the xTIMEcomposer studio tools.

The library depends on::
  * lib_sdram,
  * lib_lcd,

Related application notes
.........................

The following application notes use this library:

  * AN00xxx - using the dc asynchronously

