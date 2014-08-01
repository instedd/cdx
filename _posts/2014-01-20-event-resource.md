---
category: Resources
title: 'Event'

layout: nil
---

The Event resource contains the fields related to the event reported by the device. No personal identifiable information is contained in this resource.

`{
  "uuid" : "c4c52784-bfd5-717d-7a91-614acd972d5e",
  "assay_name" : "ASSAY001",
  "age" : "21",
  "created_at" : "2014-04-24T17:16:03+0000",
  "start_time" : "2014-04-24T17:16:03+0000",
  "device_serial_number" : "123456789",
  "device_id" : 2,
  "laboratory_id" : 3,
  "system_user" : "jdoe",
  "institution_id" : 4,
  "location_id" : 5,
  "parent_locations" : [1, 2, 3],
  "test_type" : "specimen",
  "error_code" : "1234",
  "results" : [
    "condition" : "MTB",
    "result" : "positive",
    "custom_fields" : [ //per analyte
      ...
    ]
  ],
  "custom_fields" : [
    ...
  ]
}`

Non standard fields reported by the device will be included inside the "custom_fields" section.
