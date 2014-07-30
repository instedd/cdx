---
category: Devices
path: '/events/[event_uuid]/pii'
title: 'Submit PII'
type: 'PUT'

layout: nil
---

Allows submission of Personal Identifiable Information into a previously submitted event.

# Request

`/events/[event_uuid]/pii`

* The path must include a valid **event UUID**.
* **The body can't be empty** and must include the PII.

# Example

```/events/c4c52784-bfd5-717d-7a91-614acd972d5e/pii```

# Response

**If it succeeds**, it returns the [uploaded PII](#/pii).

`Status: 200 Ok`

For error responses, see the [response status codes documentation](#http-response-codes).
