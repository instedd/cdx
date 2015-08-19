---
category: Resources
title: 'Test'

layout: nil
---

The Test resource contains the fields related to the test reported by the device. No personal identifiable information is contained in this resource.

`{
  "sample" : {
    "id" : "",
    "uid" : "9d68e8fd-3ebe-a163-2ad6-7a675dac5dde",
    "uuid" : "",
    "type" : "",
    "collection_date" : "",
    "custom_fields" : {}
  },
  "test" : {
    "id" : "12345",
    "uuid" : "570254af-eb74-367b-3b0e-0b1f1029ba73",
    "start_time" : "2014-09-26T22:09:05Z",
    "reported_time" : "2014-09-26T22:09:05Z",
    "updated_time" : "2014-09-26T22:09:05Z",
    "error_code" : 0,
    "error_description" : null,
    "patient_age" : "24",
    "name" : "Mycobacterium Tuberculosis",
    "status" : "success",
    "assays: [
      {
        "name" : "MTB Scan",
        "condition" : "mtb",
        "result" : "negative",
        "quantitative_result" : 0
      }
    ]
    "type" : "qc",
    "custom_fields" : {}
  },
  "device" : {
    "uuid" : "e9KehDBFrN1N",
    "name" : "Test device 1",
    "lab_user" : "jdoe",
    "serial_number" : "1234567890-098765432",
    "custom_fields" : {}
  },
  "patient" : {
    "id" : "1234",
    "uuid" : "1234",
    "gender" : "male",
    "custom_fields" : {}
  },
  "encounter" : {
    "id" : "",
    "uuid" : "",
    "custom_fields" : {}
  }
  "institution" : {
    "id" : "",
    "name" : ""
  },
  "laboratory" : {
    "id" : "",
    "name" : ""
  },
  "location" : {
    "id" : "",
    "parents" : "",
    "admin_levels" : "",
    "lat" : "",
    "lng" : ""
  }
}`
  "start_time": "",
  "test_id": "",
  "uuid": "570254af-eb74-367b-3b0e-0b1f1029ba73",
  "device_uuid": "",
  "system_user": "jdoe",
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
          "custom_fields" : {
            ...
          }
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

}`

Non standard fields reported by the device will be included inside the "custom_fields" section.

The default "test_id" will be the same as the uuid. If the device reports its own id, it will be stored there.
