---
category: Applications
path: '/api/events'
title: 'Query events'
type: 'GET'

layout: nil
---

This method allows applications to retrieve test results.

# Request Parameters

* `since` - retrieve events reported after a specific date time.

`/events?since=2014-04-10T15:22:12+0000`

* `until` - retrieve events reported before a specific date time. Useful to define a time window in combination with “since”.

`/events?until=2014-04-10T15:22:12+0000`

## Filtering

* `location` - filter events by location id

`/events?location=1`

* `institution` - filter events by institution id

`/events?institution=1`

* `device` - filter events by device id

`/events?device=1`

* `laboratory` - filter events by laboratory id

`/events?laboratory=1`

* `gender` - filter events by gender

`/events?gender=male`

* `min_age` - filter events for people of age greater or equal than min_age

`/events?min_age=7`

* `max_age` - filter events for people of age lower or equal than max_age

`/events?max_age=7`

* `result` - filter by the event outcome.

`/events?result=positive`

* `assay_name` - filter events for a particular assay name

`/events?assay_name=MTB`

* `assay` - filter tests for a particular assay ID

`/events?assay=ASSAY001`

## Grouping

* Grouping of results is accomplished through the “group_by” option.

### Query Parameter

In the query parameter the options are limited to indicate a couple of fields to group by

````/events?group_by=gender,result```

### JSON Body

* `age_ranges` - Groups and filters by age ranges. The tests are skipped if they are outside those ranges.
```{ “group_by” : [ { “age_ranges” : [ [0, 10], [11, 20] ] } ] }```

* `location_depth` - Groups by location depth, up to the third level in this case, which is a state level.

```{ “group_by” : [ {“location_depth" : 3 } ] }```

* `time_interval` - Groups by a given time interval, it could be one of: yearly, monthly, weekly, daily, semesterly, or quarterly.

```{ “group_by” : [ {“time_interval” : "yearly" } ] }```

# Response

`Status: 200 OK`

## Without Grouping

Returns a collection of [events](#/event-resource)

## With Grouping

Returns a collection of grouped values

````/events?group_by=gender,result```

```[
  {
    "gender" : "male",
    "result" : "positive",
    "count" : 23
  },
  {
    "gender" : "male",
    "result" : "negative",
    "count" : 10
  },
  {
    "gender" : "female",
    "result" : "positive",
    "count" : 2
  },
  {
    "gender" : "female",
    "result" : "negative",
    "count" : 30
  },
]```

For errors responses, see the [response status codes documentation](#http-response-codes).
