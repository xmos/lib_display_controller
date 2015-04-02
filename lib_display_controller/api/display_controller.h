// Copyright (c) 2015, XMOS Ltd, All rights reserved
#ifndef _display_controller_h_
#define _display_controller_h_

#include "sdram.h"
#include "lcd.h"
#include "memory_address_allocator.h"

typedef enum {
  CMD_WRITE,
  CMD_READ,
  CMD_SET_FRAME
} e_commands;

typedef enum {
    CMD_SUCCESS,
    CMD_OUT_OF_RANGE,
    CMD_MODIFY_CURRENT_FB
} e_command_return_val;

typedef struct {
    e_commands type;
    unsigned image_no;

    unsigned line;
    unsigned word_offset;
    unsigned word_count;
} s_command;

//////////////////////////////// cmd buffering ////////////////////////////////////////

interface app_to_cmd_buffer_i {
    [[notification]] slave void ready();
    [[guarded, clears_notification]] void push(s_command cmd, unsigned * movable p);
};


interface cmd_buffer_to_dc_i {
    [[notification]] slave void ready();
    [[guarded, clears_notification]] {s_command, unsigned * movable} pop();
};

[[distributable]]
void command_buffer(server interface app_to_cmd_buffer_i  tx,
                    server interface cmd_buffer_to_dc_i rx);

//////////////////////////////////response buffering //////////////////////////////////


interface dc_to_res_buf_i {
    [[notification]] slave void ready();
    [[guarded, clears_notification]] void push(unsigned * movable p, unsigned return_val);
};

interface res_buf_to_app_i {
    [[notification]] slave void ready();
    [[guarded, clears_notification]] {unsigned * movable, unsigned}  pop();
};

[[distributable]]
void response_buffer(server interface dc_to_res_buf_i  tx,
                    server interface res_buf_to_app_i rx);


////////////////////////////////////////////////////////////////////////

interface dc_vsync_interface_i {


    [[notification]] slave void update();

    
    [[guarded, clears_notification]] unsigned vsync();
};

////////////////////////////////////////////////////////////////////////


/** This issues a read command to the display controller.
 *
 * \param app_to_cmd_buf  The interface for the application to send commands to the command buffering.
 * \param buffer          A pointer to an array where the data should be saved to.
 * \param image_no        The image number to be read from.
 * \param line            The line number of the image to be read from.
 * \param word_count      The number of words to be read.
 * \param word_offset     The number of words from the begining of the line to begin the read.
 */
void display_controller_read(
        client interface app_to_cmd_buffer_i app_to_cmd_buf,
        unsigned * movable buffer,
        unsigned image_no,
        unsigned line,
        unsigned word_count,
        unsigned word_offset);


/** This issues a write command to the display controller.
 *
 * \param app_to_cmd_buf  The interface for the application to send commands to the command buffering.
 * \param buffer          A pointer to an array where the data should be read from.
 * \param image_no        The image number to be written to.
 * \param line            The line number of the image to be written to.
 * \param word_count      The number of words to be written.
 * \param word_offset     The number of words from the begining of the line to begin the write.
 */
void display_controller_write(
        client interface app_to_cmd_buffer_i app_to_cmd_buf,
        unsigned * movable buffer,
        unsigned image_no,
        unsigned line,
        unsigned word_count,
        unsigned word_offset);

/** This schedules the given image to be displayed on the LCD at the next vertical refresh
 *
 * \param from_app       The interface for the application to send commands to the command buffering
 * \param image_no       The image number to be commited to the display.
 */
void display_controller_frame_buffer_commit(
        client interface app_to_cmd_buffer_i from_dc,
        unsigned image_no);

/** The display controller server task
 *
 * \param to_dc          The interface for the command buffering to send commands to the display controller
 * \param from_dc        The interface for thedisplay controller to send responses to the command buffering
 * \param vsync          The interface used to indicate when a vertical restart has happened
 * \param num_frame_buffers  The number of frame bufferes required by the application
 * \param height         The width of each of the frame buffers(they are all be the same)
 * \param width          The height of each of the frame buffers(they are all be the same)
 * \param bytes_per_pixel  The bytes per pixel
 * \param mem_alloc           The interface to the memory address allocator
 * \param c_sdram_lcd,        The streaming channel to the SDRAM server (high priority)
 * \param c_sdram_client,     The streaming channel to the SDRAM server (low priority)
 * \param c_lcd               The streaming channel to the LCD server
 */
void display_controller(
        client interface cmd_buffer_to_dc_i to_dc,
        client interface dc_to_res_buf_i from_dc,
        server interface dc_vsync_interface_i vsync,
        static const unsigned num_frame_buffers,
        static const unsigned height,
        static const unsigned width,
        static const unsigned bytes_per_pixel,
        client interface memory_address_allocator_i mem_alloc,
        streaming chanend c_sdram_lcd,
        streaming chanend c_sdram_client,
        streaming chanend c_lcd);

#endif
