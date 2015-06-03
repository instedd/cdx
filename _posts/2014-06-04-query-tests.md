---
category: Applications
path: '/tests[.format]'
title: 'Query Tests'
type: 'GET'

layout: nil
---

Returns a list of Tests

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format doesn't include the total count.

The default response format is JSON.

# Filters

Filter parameters allow querying a subset of the available tests.

The data returned will be sorted by default by the test creation date.

* `since` - retrieve tests reported after a specific date time.

`/tests?since=2014-04-10T15:22:12+00:00`

When querying from the query string the _'+'_ sign must be escaped as _'%2B'_

`since=2014-08-01T18:10:36%2B07:00`

* `until` - retrieve tests reported before a specific date time. Useful to define a time window in combination with “since”.

`/tests?until=2014-04-10T15:22:12-0300`

When querying from the query string the _'+'_ sign must be escaped as _'%2B'_

`until=2014-08-01T18:10:36%2B07:00`

* `location` - filter tests by location id

`/tests?location=1`

* `institution` - filter tests by institution id

`/tests?institution=1`

* `device` - filter tests by device uuid

`/tests?device=9d68e8fd-3ebe-a163-2ad6-7a675dac5dde`

* `laboratory` - filter tests by laboratory id

`/tests?laboratory=1`

* `gender` - filter tests by gender

`/tests?gender=male`

* `min_age` - filter tests for people of age greater or equal than min_age

`/tests?min_age=7`

* `max_age` - filter tests for people of age lower or equal than max_age

`/tests?max_age=7`

* `result` - filter by the tests outcome.

`/tests?result=positive`

* `condition` - filter tests for a particular condition name

`/tests?condition=mtb`

* `assay_name` - filter tests for a particular assay name

`/tests?assay_name=ASSAY001`

* `uuid` - retrieves the test with a particular UUID

`/tests?uuid=c4c52784-bfd5-717d-7a91-614acd972d5e`

* `error_code` - filter tests for a particular error code.

`/tests?error_code=A01`

* `system_user` - filter tests for the user that executed the test.

`/tests?system_user=jdoe`

* `test_type` - filter tests for the type of the test: qc / specimen.

`/tests?test_type=qc`

## Multiple Values

With the exception of _since_, _until_, _min_age_ and _max_age_, all the fields can accept multiple values using a comma as a separator:

`/tests?error_code=A01,A02`

`/tests?gender=male,female`

# Unknown values

If a field value is not specified, the keyword used to represent it in filters must be _'null'_.

If the value is specified, but impossible to determine at the moment of the test, the keyword used to represent it is _'unknown'_

`/tests?gender=male,unknown,null`

The response must include all the unknown and null values.

If you want all the results where the gender is a known value, you can ignore the null using:

`/tests?gender=not(null)`

When grouping, a bucket must be included for all elements that fall into the unknown or null buckets.

`/tests?group_by=gender,result`

Assuming gender values of male, female, unknown and null, and result values of positive and negative, an expected result could be:

`{
  "total_count" : 55,
  "tests" : [
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
    {
      "gender" : "unknown",
      "result" : "positive",
      "count" : 3
    },
    {
      "gender" : "unknown",
      "result" : "negative",
      "count" : 1
    },
    {
      "gender" : "null",
      "result" : "positive",
      "count" : 0
    },
    {
      "gender" : "null",
      "result" : "negative",
      "count" : 4
    }
  ]
}`

# Sorting

* `order_by` - orders by a given field.
* Ascending by default. Append a `-` to sort descending.
* Comma separated.

### Examples

* `order_by=age` - orders ascending by age.
* `order_by=age,gender` - orders ascending by age and gender.
* `order_by=-age` - orders descending by age.
* `order_by=age,-gender` - orders ascending by age and descending by gender.

# Pagination

Every request will contain the total amount of records that matched the filters, but will only retrieve a portion of them in each request.

* `page_size` Specifies the number of element returned in the request.

`page_size=20`

* `offset` - Specifies the starting point of the batch in terms of number of elements that have already been retrieved.

`page_size=20&offset=450` will bring the elements 451 to 470.

* to retrieve only a count of the values that will match certain filters, a page size of zero can be specified. The result will be a record with no tests and the desired count:

`{
  "total_count" : 1234,
  "tests" :[]
}`

The default page size is 50.

# Data Aggregation

There are two ways to accomplish data aggregation:

* through the “group_by” option in the query string
* sending a JSON in the request body with the "group_by" key in it

## Query Parameter

In the query parameter the options are limited to indicate the fields to group by.

`/tests?group_by=laboratory,gender,result`

The possible groupings are:

* location
* institution
* device
* laboratory
* gender
* condition
* result
* error_code
* system_user
* test_type
* assay_name
* `year() | month() | week() | day()` - groups the given date field by the time interval specified.

`/tests?group_by=year(created_at)`

## JSON in request body

The JSON allows more complex aggregations, such as:

* `age` - groups and filters by age ranges. The tests are skipped if they are outside those ranges.

`{
  "group_by" : [
    { "age" : [ [0, 10], [11, 20] ] },
    ...
  ]
}`

* `admin_level` - groups by administrative level, up to the third level in this case, which is a state level.

`{
  "group_by" : [
    { "admin_level" : 4 },
    ...
  ]
}`

* All the groupigs of the query string are also available when querying through the request body.

`{
  "group_by" : [
    "age",
    "year(created_at)",
    { "admin_level" : 4 },
    ...
  ]
}`

# Response

`Status: 200 OK`

##JSON

### Without Grouping

Returns an array of tests without any PII and the total count of elements that matched the filter.

`{
  "total_count" : 2,
  "tests" : [
    {
      "uuid" : "c4c52784-bfd5-717d-7a91-614acd972d5e",
      "assay_name" : "ASSAY001",
      "age" : "21",
      "created_at" : "2014-04-24T17:16:03+0000",
      "start_time" : "2014-04-24T17:16:03+0000",
      "device_serial_number" : "123456789",
      "device_uuid" : "9d68e8fd-3ebe-a163-2ad6-7a675dac5dde",
      "laboratory_id" : 3,
      "system_user" : "jdoe",
      "institution_id" : 4,
      "location_id" : 5,
      "parent_locations" : [1, 2, 3],
      "type" : "QC/Specimen",
      "error_code": 1234,
      "results" : [
        "condition" : "MTB",
        "result" : "error",
      ]
    },
    {
      "uuid" : "c4c52784-bfd5-717d-7a91-614acd972d5e",
      "assay_name" : "ASSAY001",
      "age" : "21",
      "created_at" : "2014-04-24T17:16:03+0000",
      "start_time" : "2014-04-24T17:16:03+0000",
      "device_serial_number" : "123456789",
      "device_uuid" : "9d68e8fd-3ebe-a163-2ad6-7a675dac5dde",
      "laboratory_id" : 3,
      "system_user" : "jdoe",
      "institution_id" : 4,
      "location_id" : 5,
      "parent_locations" : [1, 2, 3],
      "type" : "QC/Specimen",
      "results" : [
        "condition" : "MTB",
        "result" : "positive"
      ]
    }
  ]
}`

### With Grouping

Returns the quantity of tests matching each combination of aggregated fields and the total count of elements that matched the filter.

`/tests?group_by=gender,result`

`{
  "total_count" : 55,
  "tests" : [
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
  ]
}`

## CSV

## Without Grouping

`created_at,test_id,uuid,device_uuid,system_user,device_serial_number,error_code,laboratory_id,institution_id,...
2014-08-01T21:29:52Z,b84a0c16-f223-1cd7-3705-71ec0056a682,b84a0c16-f223-1cd7-3705-71ec0056a682,efbc8343-b160-f...
2014-08-01T21:30:06Z,cf44adcb-7414-8fd9-d663-a556c407be69,cf44adcb-7414-8fd9-d663-a556c407be69,efbc8343-b160-f...`

## With Grouping

`gender,result,count
male,positive,23
male,negative,10
female,positive,2
female,negative,30`

For error responses, see the [response status codes documentation](#http-response-codes).
