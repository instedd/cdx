---
category: Devices
path: '/devices/[authehtication_token]/results/[test_result_guid]/pii'
title: 'Submit PII'
type: 'PUT'

layout: nil
---

Allows submission of Personal Identifiable Information into a previously submitted test result.

# Request

`/devices/[authehtication_token]/results/[test_result_guid]/pii`

* The path must include a **valid authentication token**.
* The path must include a valid **test result GUID**.
* **The body can't be empty** and must include the PII.

`Authentication: bearer f862f658-ad89-4fcb-995b-7a4c50554ff6`

# Example

```/devices/f862f658-ad89-4fcb-995b-7a4c50554ff6/results/c4c52784-bfd5-717d-7a91-614acd972d5e/pii```

```{
  "patient_id" : 2,
  "patient_name" : "Lorem Ipsum",
  "patient_telephone_number" : "12345678",
  "patient_zip_code" : "1234"
}```

# Response

**If succeeds**, returns the [test result with the uploaded PII attached](#/test-result-resource-with-pii).

`Status: 200 Ok`

For errors responses, see the [response status codes documentation](#http-response-codes).
