---
category: Devices
path: '/devices/[device_uuid]/results'
title: 'Submit test results'
type: 'POST'

layout: nil
---

Allows devices to submit test results.

# Request

* The path must include a valid **device UUID**.
* **The body can't be empty** and must include .

`/devices/[device_uuid]/results`

`/devices/f862f658-ad89-4fcb-995b-7a4c50554ff6/results`

```{
  "assay" : "ASSAY001",
  "assay_name" : "MTB",
  "device_serial_number" : "123456789",
  "result" : "positive",
  "start_time" : "2014-04-24T17:16:03+0000",
  "system_user" : "jdoe",
  "age" : "21"
}```

# Response

**If succeeds**, returns the created [test-result](#/test-result-resource).

`Status: 201 Created`

For errors responses, see the [response status codes documentation](#http-response-codes).
