---
category: Applications
title: 'Push Notifications'

layout: nil
---

Allows an application to subscribe for new reports of a particular disease.

# Setup

The necesary steps for setting this up are:

* Create a events query specifying which laboratory and condition you want to monitor.
* Register a subscriber endpoint to be notified when the events of the query changes.

The query will be executed in regular intervals depending on the installation. If the result of the query changes, the push notification will be triggered for every new event returned by the query.

# Parameters

* Name - to identify the subscriber
* URL - the endpoint that will be triggered with a post for every new events
* User - Optional. Basic auth. The user that must be used to login in the URL provided
* Password - Optional. Basic auth. The password that must be used to login in the URL provided

# Fields

This is a list of fields that can be sent in the query string request to the subscriber:

* patient_id
* patient_name
* patient_telephone_number
* patient_zip_code
* created_at
* device_uuid
* institution_id
* laboratory_id
* location_id
* assay_name
* device_serial_number
* age
* gender
* system_user
* start_time
* condition
* result

# Example

`URL: 'www.example.com/foo'
Fields:
  - patient_id
  - result
POST: www.example.com/foo?patient_id=1&result="negative"`
