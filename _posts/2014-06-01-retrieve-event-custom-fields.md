---
category: Applications
path: '/events/[event_uuid]/custom_fields'
title: 'Retrieve Custom Fields'
type: 'GET'

layout: nil
---

Retrieves the not indexed user defined custom fields for a given event.

# Request Parameters

`/events/[event_uuid]/custom_fields`

* The path must include a **valid event_uuid**.
* ```event_uuid``` - UUID of the desired event.

### Example

`/events/9aa43890-ed75-11e3-8da1-1231381c1cdd/custom_fields`

# Response

Returns the [custom fields](#/custom-fields).

`Status: 200 OK`

For error responses, see the [response status codes documentation](#http-response-codes).
