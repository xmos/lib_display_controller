#include <platform.h>
#include <xs1.h>
#include "lcd.h"
#include <print.h>
#include <stdlib.h>

static void init(streaming chanend c_lcd){
    c_lcd :> int;
    c_lcd <: 0;
}

static void return_pointer(streaming chanend c_lcd, unsigned * unsafe buffer){
    unsafe {
        c_lcd <: buffer;
    }
}

static void fetch_pointer(streaming chanend c_lcd, unsigned * unsafe & buffer){
    c_lcd :> buffer;
}


void dummy_lcd_server(streaming chanend c_client,
        const static unsigned width,
        const static unsigned height,
        const static unsigned h_front_porch,
        const static unsigned h_back_porch,
        const static unsigned h_pulse_width,
        const static unsigned v_front_porch,
        const static unsigned v_back_porch,
        const static unsigned v_pulse_width,
        const static unsigned clock_divider)
{
    timer t; unsigned time;

    //wait here for the client to say that it is ready
    init(c_client);

    int error_flag = 0;
    unsigned lcd_clocks = 2*clock_divider;
    t :> time;
    time += 1000;
    t when timerafter(time) :> unsigned;
    unsigned h_sync_clocks = (h_pulse_width + h_front_porch + h_back_porch + width)*lcd_clocks;


    unsafe{
    for (unsigned r=0; r<3; r++){

        time += (v_pulse_width + v_back_porch) * h_sync_clocks;
        t when timerafter(time) :> unsigned;

        for (int y = 0; y < height; y++) {
            time += (h_pulse_width + h_back_porch) * lcd_clocks;
            t when timerafter(time) :> unsigned;
            unsigned * unsafe buffer;
            fetch_pointer(c_client, buffer);

            for (unsigned c=0; c<width/2;c++)
                if (buffer[c]!=0x00000000)
                    error_flag=1;

            time += width*lcd_clocks;
            t when timerafter(time) :> unsigned;
            return_pointer(c_client, buffer);
            time += h_front_porch*lcd_clocks;
            t when timerafter(time) :> unsigned;
        }

        time += (h_sync_clocks * v_front_porch);
        t when timerafter(time) :> unsigned;

    }
    }

    if (error_flag)
        printstrln("ERROR: wrong data to LCD");
    else
        printstrln("3 correct LCD frames");

    exit(1);

}
