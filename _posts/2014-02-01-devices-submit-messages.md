---
category: Devices
path: '/devices/[device_uuid]/messages'
title: 'Submit messages'
type: 'POST'
---

Allows devices to submit messages.

# Request

* The path must include a valid **device UUID**.
* **The body can't be empty** and must include a [test](#/test-resource).

`/devices/[device_uuid]/messages`

`/devices/f862f658-ad89-4fcb-995b-7a4c50554ff6/messages`

If the same test is sent more than once (with the same test_id), the result data gets updated and no duplicated record is created.

# Response

**If it succeeds**, it returns the created [test](#/test-resource).

`Status: 201 Created`

For error responses, see the [response status codes documentation](#http-response-codes).
