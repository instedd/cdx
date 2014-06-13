---
category: Applications
path: '/events/[event_uuid]/pii'
title: 'Retrieve PII'
type: 'GET'

layout: nil
---

Retrieves the private patient information for a given event.

# Request Parameters

`/events/[event_uuid]/pii`

* The path must include a **valid event_uuid**.
* ```event_uuid``` - UUID of the desired event.

### Example

`/events/c4c52784-bfd5-717d-7a91-614acd972d5d/pii`

# Response

Returns the [private patient information](#/pii).

`Status: 200 OK`

For error responses, see the [response status codes documentation](#http-response-codes).
