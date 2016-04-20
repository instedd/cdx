---
category: Applications
path: '/institutions[.format]'
title: 'Query Institutions'
type: 'GET'
---

Returns a list of Laboratories

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format don't include the total count.

The default response format is JSON.

# Filters

No filter can be specified

# Response

`Status: 200 OK`

##JSON

The response will include a total_count and a list of institutions

```
{
  "total_count" : 2,
  "institutions" : [
    {
      "uuid" : 1,
      "name" : "First Institution"
    },
    {
      "id" : 2,
      "name" : "Second Institution"
    }
  ]
}
```

## CSV

```
id,name
1,First Institution
2,Second Institution
```

For error responses, see the [response status codes documentation](#http-response-codes).
