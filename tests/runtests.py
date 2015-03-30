#!/usr/bin/env python
import xmostest

if __name__ == "__main__":
    xmostest.init()

    xmostest.register_group("lib_display_controller",
                            "initialization_test",
                            "Display Controller Initialization Test",
    """
Test is performed by running the display controller library connected to a testbench and dummy severs for SDRAM and LCD 
(written in xC). The dummies check the initialization of display controller.

""")

    xmostest.register_group("lib_display_controller",
                            "functionality_tests",
                            "Display Controller Functionality Tests",
    """
Tests are performed by running the display controller library connected to a testbench and dummy severs for SDRAM and LCD 
(written in xC). The dummies check the basic functionality of display controller such
as SDRAM read and write, and frame commit.

""")

    xmostest.runtests()

    xmostest.finish()


