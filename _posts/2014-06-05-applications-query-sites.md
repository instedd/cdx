---
category: Applications
path: '/sites[.format]'
title: 'Query Sites'
type: 'GET'
---

Returns a list of Laboratories

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format don't include the total count.

The default response format is JSON.

# Filters

The institution Id can be specified, filtering the sites list.

* `institution_uuid` - filter sites by institution uuid.

`/sites?institution_uuid=2`

# Response

`Status: 200 OK`

##JSON

The response will include a total_count and a list of sites

```
{
  "total_count" : 2,
  "sites" : [
    {
      "uuid" : 1,
      "name" : "First Lab",
      "location" : "ne:CHE_3424",
      "parent_uuid": null,
      "institution_uuid": 2
    },
    {
      "uuid" : 2,
      "name" : "Second Lab",
      "location" : "ne:IND_2428",
      "parent_uuid": 1,
      "institution_uuid": 2
    }
  ]
}
```

## CSV

```
uuid,name,location,parent_uuid,institution_uuid
1,First Lab,ne:CHE_3424,,2
2,Second Lab,ne:IND_2428,1,2
```

For error responses, see the [response status codes documentation](#http-response-codes).
