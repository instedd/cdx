---
category: Devices
path: '/api'
title: 'Add event'
type: 'PUT'

layout: nil
---

This method allows devices to report test results.

###Request Parameters###

* `timestamp` - indicates the date and time for when the event ocurred

`/event?timestamp=2014-04-10T15:22:12+0000`


REQUIRED FIELDS

* `deviceID` - ID of the device where the test was performed

`/events?deviceID={123}`

OPTIONAL FIELDS

PERSONAL IDENTIFIABLE INFORMATION



### Response


For errors responses, see the [response status codes documentation](#http-response-codes).
