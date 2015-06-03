---
category: Devices
path: '/devices/[device_uuid]/events'
title: 'Submit events'
type: 'POST'

layout: nil
---

Allows devices to submit events.

# Request

* The path must include a valid **device UUID**.
* **The body can't be empty** and must include an [test](#/test-resource).

`/devices/[device_uuid]/events`

`/devices/f862f658-ad89-4fcb-995b-7a4c50554ff6/events`

If the same test is sent more than once (with the same test_id), the result data gets updated and no duplicated record is created.

# Response

**If it succeeds**, it returns the created [test](#/test-resource).

`Status: 201 Created`

For error responses, see the [response status codes documentation](#http-response-codes).
