---
category: Applications
path: '/tests/[test_uuid]/pii'
title: 'Retrieve PII'
type: 'GET'
---

Retrieves the private patient information for a given test.

# Request Parameters

`/tests/[test_uuid]/pii`

* The path must include a **valid test_uuid**.
* ```test_uuid``` - UUID of the desired test.

### Example

`/tests/c4c52784-bfd5-717d-7a91-614acd972d5d/pii`

# Response

Returns the [private patient information](#/pii).

`Status: 200 OK`

For error responses, see the [response status codes documentation](#http-response-codes).
