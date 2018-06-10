#!/bin/sh

#  SimulatorErase
#  XSimulatorMngr
#
#  Copyright © 2017 xndrs. All rights reserved.


osascript -e 'tell application "iOS Simulator" to quit'
osascript -e 'tell application "Simulator" to quit'

xcrun simctl erase all
