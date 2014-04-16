---
category: Devices
path: '/api'
title: 'Query events'
type: 'PUT'

layout: nil
---

This method allows devices to report test results.

###Request Parameters###

* `timestamp` - retrieve events reported after a specific date time

`/event?timestamp=2014-04-10T15:22:12+0000`


REQUIRED FIELDS

* `location` - filter events by location

`/events?location={location1}`

OPTIONAL FIELDS

PERSONAL IDENTIFIABLE INFORMATION



### Response


For errors responses, see the [response status codes documentation](#http-response-codes).
