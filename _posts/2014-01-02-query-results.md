---
category: Applications
path: '/api'
title: 'Query events'
type: 'GET'

layout: nil
---

This method allows applications to retrieve test results.

###Request Parameters###

* 'since' - retrieve events reported after a specific date time

'/events.json?since=2014-04-10T15:22:12+0000'


FILTERING

* 'location' - filter events by location

'/events.json?location={location1}'



### Response

'Status: 200 OK'
Returns a collection of [events](#event-resource)

For errors responses, see the [response status codes documentation](#http-response-codes).
