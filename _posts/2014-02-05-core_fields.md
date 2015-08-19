---
category: Resources
title: 'Core Fields'

layout: nil
---

The core fields are:

- _sample.id_ - This field represents the identifier of the sample exactly as entered by the lab user on the diagnostics machine. Its purpose is to keep track of the originally reported sample identifier. Note that the values in this field may not be unique across different laboratories or even over time.
- _sample.uuid_ - The internal id in CDX. An automatically generated UUID to unequivocally identify the sample in CDX.
- _sample.type_ - The type of the sample. String.
- _sample.collection_date_ - The date when the sample was collected.
- _test.id_ - The id given by the device. If the device reports two tests with the same test.id, then the first one will be updated.
- _test.uuid_ - The internal id in CDX. an automatically generated UUID to unequivocally identify the test in CDX.
- _test.start_time_ - The timestamp when the test started running in the device.
- _test.reported_time_ - The creation timestamp in CDX.
- _test.updated_time_ - The last update timestamp in CDX (if two tests are reported with the same test.id, this field will be updated).
- _test.error_code_ - A numeric result code. This will follow the manufacturer's own coding and won't be standardized.
- _test.error_description_ - User friendly error description.
- _test.patient_age_ - The age of the patient at the moment of the test.
- _test.name_ - The name of the test as provided by the device.
- _test.status_ - An enumerated global result of the test.
  - The possible values are:
    - invalid
    - error
    - no_result
    - success
    - in_progress
- _test.assays_ - A single test can run multiple assays.
- _test.assays.name_ - The code name of the assay used in the test as provided by the device.
- _test.assays.condition_ - The condition that this particular assay tests. It must be one of the conditions listed in the metadata, with the same notation.
- _test.assays.result_ - An enumerated result of the assay, if available.
  - The possible values are:
    - positive
    - negative
    - n/a
- _test.assays.quantitative_result_ - The result of the test, if measurable, in a numeric scale. This scale will follow the manufacturer's convention.
- _test.type_ - If the test is from a real sample or if it's just a quality control test.
  - The possible values are:
    - specimen
    - qc
- _device.uuid_ - The internal id that identifies the device in CDX.
- _device.name_ - The name of the device in CDX.
- _device.lab_user_ - The name of the user running the tests.
- _device.serial_number_ - The serial number of the device, identifiable in any external system.
- _patient.id_ - The id of the patient.
- _patient.gender_ - The birth gender of the patient.
  - The possible values are:
    - male
    - female
    - other
- _encounter.id_ - This field represents the identifier of the encounter exactly as entered by the lab user on the diagnostics machine.
- _encounter.uuid_ - The internal id in CDX. an automatically generated UUID to unequivocally identify the test in CDX.
- _institution.id_ - The internal CDX id of the Institution that owns the device.
- _institution.name_ - The name of that Institution.
- _laboratory.id_ - The internal CDX id of the Laboratory where the device is located.
- _laboratory.name_ - The name of that Laboratory.
- _location.id_ - The natural earth geo id of the device location at the moment of the test.

All location, laboratory and institution information will be automatically filled by CDX when a test is reported using the information already available in the system.

If the device can report from multiple laboratories, the laboratory.id will be null, and the location will be the common root of the laboratory's locations.
