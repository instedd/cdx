---
category: Devices
path: '/devices/[device_uuid]/events'
title: 'Submit events'
type: 'POST'

layout: nil
---

Allows devices to submit events.

# Request

* The path must include a valid **device UUID**.
* **The body can't be empty** and must include .

`/devices/[device_uuid]/events`

`/devices/f862f658-ad89-4fcb-995b-7a4c50554ff6/events`

`{
  "event_id" : "1", // Unique by device
  "assay" : "ASSAY001",
  "assay_name" : "MTB",
  "device_serial_number" : "123456789",
  "result" : "positive",
  "start_time" : "2014-04-24T17:16:03+0000",
  "system_user" : "jdoe",
  "age" : "21"
}`

If the same event is sent more than once (with the same event_id), the result data gets updated and no duplicated record is created.

# Response

**If succeeds**, returns the created [event](#/event-resource).

`Status: 201 Created`

For errors responses, see the [response status codes documentation](#http-response-codes).
