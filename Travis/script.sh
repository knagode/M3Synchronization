#!/bin/sh
set -e
cd UnitTests
xctool -project M3SynchronizationTests.xcodeproj -scheme M3SynchronizationTests build test