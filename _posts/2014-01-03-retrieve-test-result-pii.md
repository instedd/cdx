---
category: Applications
path: '/results/[result_uuid]/pii'
title: 'Retrieve PII'
type: 'GET'

layout: nil
---

Retrieves the private patient information for a given test result.

# Request Parameters

```/results/[test_result_uuid]/pii```

* The path must include a **valid test_result_uuid**.
* ```test_result_uuid``` - UUID of the desired test result.

### Example

```/results/c4c52784-bfd5-717d-7a91-614acd972d5d/pii```

# Response

Returns the [test result with the private patient information attached](#/test-result-resource-with-pii).

```Status: 200 OK```

For errors responses, see the [response status codes documentation](#http-response-codes).
