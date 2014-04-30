---
category: Applications
path: '/results/[result_guid]'
title: 'Retrieve a Test Result'
type: 'GET'

layout: nil
---

Retrieves the private patient information for a given test result.

# Request Parameters

```/results/[test_result_guid]```

* The path must include a **valid test_result_guid**.
* ```test_result_guid``` - guid of the desired test result.

### Example

```/results/2```

# Response

```Status: 200 OK```

Returns a [test_result](#/test_result_resource)

For errors responses, see the [response status codes documentation](#http-response-codes).
