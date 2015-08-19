---
category: Applications
title: 'Push Notifications'

layout: nil
---

Allows an application to subscribe for new reports of a particular disease.

# Setup

The necesary steps for setting this up are:

* Create a tests query specifying which laboratory and condition you want to monitor.
* Register a subscriber endpoint to be notified when the tests of the query changes.

The query will be executed in regular intervals depending on the installation. If the result of the query changes, the push notification will be triggered for every new event returned by the query.

The event structure will match the schema.

# Parameters

* Name - to identify the subscriber
* URL - the endpoint that will be triggered with a post for every new tests
* User - Optional. Basic auth. The user that must be used to login in the URL provided
* Password - Optional. Basic auth. The password that must be used to login in the URL provided
