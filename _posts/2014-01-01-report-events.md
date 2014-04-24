---
category: Devices
path: '/devices'
title: 'Report an event'
type: 'POST'

layout: nil
---

This method allows devices to report test results.

# Request

* The path must include a **valid authentication token**.
* **The body can't be empty** and must include at the test values.

```Authentication: bearer f862f658-ad89-4fcb-995b-7a4c50554ff6```

```/devices/c4c52784-bfd5-717d-7a91-614acd972d5d```

```{
  "patient_id" : 2,
  "patient_name" : "Lorem Ipsum",
  "patient_telephone_number" : "12345678",
  "patient_zip_code" : "1234",
  "assay" : "ASSAY001",
  "assay_name" : "MTB",
  "device_serial_number" : "123456789",
  "result" : "positive",
  "start_time" : "2014-04-24T17:16:03+0000",
  "system_user" : "jdoe",
  "age" : "21"
}```

# Response

**If succeeds**, returns the created event.

```Status: 201 Created```

For errors responses, see the [response status codes documentation](#http-response-codes).
