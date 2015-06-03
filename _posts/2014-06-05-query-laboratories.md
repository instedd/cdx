---
category: Applications
path: '/laboratories[.format]'
title: 'Query Laboratories'
type: 'GET'

layout: nil
---

Returns a list of Laboratories

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format don't include the total count.

The default response format is JSON.

# Filters

The institution Id can be specified, filtering the laboratories list.

* `institution_id` - filter laboratories by institution id.

`/laboratories?institution_id=2`

# Response

`Status: 200 OK`

##JSON

The response will include a total_count and a list of laboratories

`{
  "total_count" : 2,
  "laboratories" : [
    {
      "id" : 1,
      "name" : "First Lab",
      "location_id" : 2
    },
    {
      "id" : 2,
      "name" : "Second Lab",
      "location_id" : 3
    }
  ]
}`

## CSV

`id,name,location_id
1,First Lab, 2
2,Second Lab, 3`

For error responses, see the [response status codes documentation](#http-response-codes).
