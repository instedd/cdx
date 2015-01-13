---
category: Resources
title: 'Event'

layout: nil
---

The Event resource contains the fields related to the event reported by the device. No personal identifiable information is contained in this resource.

`{
  "start_time": "2014-09-26T22:09:05Z",
  "event_id": "570254af-eb74-367b-3b0e-0b1f1029ba73",
  "uuid": "570254af-eb74-367b-3b0e-0b1f1029ba73",
  "device_uuid": "9d68e8fd-3ebe-a163-2ad6-7a675dac5dde",
  "system_user": "jdoe",
  "device_serial_number" : "123456789",
  "error_code": null,
  "error_description": null,
  "laboratory_id": 11,
  "institution_id": 13,
  "location": {
      "admin_level_0": "0",
      "admin_level_1": "0000000US",
      "admin_level_2": "0400000US08",
      "admin_level_3": "0500000US08021"
  },
  "age": 20,
  "assay_name": "MTB Assay",
  "gender": "male",
  "ethnicity": null,
  "race": null,
  "race_ethnicity": null,
  "status": null,
  "results": [
      {
          "result": "positive_with_rif",
          "condition": "mtb",
          "custom_fields" : [ //per analyte
              ...
          ]
      }
  ],
  "test_type": "specimen",
  "created_at": "2014-09-26T22:09:05Z",
  "updated_at": "2014-09-26T22:09:05Z",
  "location_id": "0500000US08021",
  "parent_locations": [
      "0",
      "0000000US",
      "0400000US08",
      "0500000US08021"
  ],
  "custom_fields" : [ //per analyte
      ...
  ]
}`

Non standard fields reported by the device will be included inside the "custom_fields" section.
