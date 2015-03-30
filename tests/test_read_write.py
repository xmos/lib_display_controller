#!/usr/bin/env python
import xmostest
import os


def runtest():
    resources = xmostest.request_resource("xsim")

    binary = 'read_write_testbench/bin/read_write_testbench.xe' 

    tester = xmostest.ComparisonTester(open('read_write_test.expect'),
                                     'lib_display_controller', 'functionality_tests',
                                     'read_write_test', regexp=True)

#    tester.set_min_testlevel('smoke')
    tester.set_min_testlevel('nightly')

    xmostest.run_on_simulator(resources['xsim'], binary,
                              simthreads = [],
                              simargs=['--weak-external-drive'],
                              suppress_multidrive_messages = True,
                              tester = tester)

  

