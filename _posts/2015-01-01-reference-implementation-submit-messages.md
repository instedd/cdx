---
category: Reference Implementation
path: '/devices/[device_uuid]/messages'
title: 'Submit messages'
type: 'POST'
---

# Authentication

The reference implementation allows two ways of authentication:

- Authentication Token - By passing the parameter _authentication\_token_ into the query string, resulting in:

  `cdp2.instedd.org/devices/e9KehDBFrN1N/messages?authentication_token=ZF25WdAMu3XA`

- Basic auth - leaving the username as just a space and with the authentication token as password:

  `' :ZF25WdAMu3XA@cdp2.instedd.org/devices/e9KehDBFrN1N/messages'`
