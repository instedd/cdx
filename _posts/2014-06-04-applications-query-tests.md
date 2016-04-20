---
category: Applications
path: '/tests[.format]'
title: 'Query Tests'
type: 'GET [POST]'
---

Returns a list of Tests. All the filters can be specified in the **POST** request body or in the **GET** query string.

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format doesn't include the total count.

The default response format is JSON.

# Filters

Filter parameters allow querying a subset of the available tests.

The data returned will be sorted by default by the test creation date.

### Date filters

All the possible dates can be filtered by since and until as in **test.end_time.since** and **test.end_time.until**, but as the start_time is the default query, it has a shortened version by only typing **since** and **until**
The available dates are:

* test.start_time
* test.end_time
* test.reported_time
* test.updated_time
* encounter.start_time
* encounter.end_time

When querying from the query string the **+** sign must be escaped as **%2B**. For instance: **2014-08-01T18:10:36+07:00**, will be: **2014-08-01T18:10:36%2B07:00**

#### Example

* since: will retrieve tests started after a specific date time.

`/tests?since=2014-04-10T15:22:12+00:00`

* `test.end_time.until` will retrieve tests ended before a specific date time. Useful to define a time window in combination with “since”.

`/tests?test.end_time.until=2014-04-10T15:22:12-0300`

### Location filters

* `location` - filter tests by geo location id

`/tests?location=ne:CHE_3424`

### Institution filters

* `institution.uuid` - filter tests by institution UUID

`/tests?institution.uuid=1`

### Device filters

* `device.uuid` - filter tests by device UUID

`/tests?device.uuid=9d68e8fd-3ebe-a163-2ad6-7a675dac5dde`

* `device.model` - filter tests by device model name

`/tests?device.model=genexpert`

* `device.serial_number` - filter tests by device serial number

`/tests?device.serial_number=A-1234567890`

### Site filters

* `site.uuid` - filter tests by site UUID

`/tests?site.uuid=1`

* `test.site_user` - filter tests for the user that executed the test.

`/tests?system_user=jdoe`

### Demographic filters

* `patient.gender` - filter tests by the patient gender

`/tests?patient.gender=male`

* `encounter.patient_age` - filter tests for people by the range specified. This is the age at the moment of the encounter.

`/tests?encounter.patient_age=50yo..60yo`

### Test filters

* `test.assays.result` - filter by the outcome of any of the assays: **positive / negative / indeterminate / n/a**.

`/tests?test.assays.result=positive`

* `test.assays.condition` - filter tests for the condition name of any of the assays. The possible values will be the combination of all the conditions of all the manifests in the system.

`/tests?test.assays.condition=mtb`

* `test.assays.name` - filter tests for the assays name

`/tests?test.assays.name=mtb`

* `test.name` - filter tests for a particular test name

`/tests?test.name=MTBDRplus`

* `test.uuid` - retrieves the test with a particular UUID

`/tests?uuid=c4c52784-bfd5-717d-7a91-614acd972d5e`

* `test.error_code` - filter tests for a particular error code.

`/tests?test.error_code=1`

* `test.type` - filter tests for the type of the test: **qc / specimen**.

`/tests?test.type=qc`

* `test.status` - filter tests for the status of the test: **invalid / error / no_result / success / in_progress**.

`/tests?test.status=success`

### Encounter filters

* `encounter.uuid` - filter tests by the encounter UUID

`/tests?encounter.uuid=c4c52784-bfd5-717d-7a91-614acd972d5e`

### Sample filters

* `sample.uuid` - filter tests by sample id

`/tests?sample.uuid=475`

## Multiple Values

With the exception of _since_, _until_, _min_age_ and _max_age_, all the fields can accept multiple values using a comma as a separator:

`/tests?test.error_code=A01,A02`

`/tests?patient.gender=male,female`

# Unknown values

If a field value is not specified, the keyword used to represent it in filters is "**null**".

If the value is specified, but impossible to determine at the moment of the test, the keyword used to represent it is "**unknown**".

`/tests?patient.gender=male,unknown,null`

The response must include all the unknown and null values.

If you want all the results where the gender is a known value, you can ignore the null using:

`/tests?patient.gender=not(null)`

When grouping, a bucket must be included for all elements that fall into the unknown or null buckets.

`/tests?group_by=patient.gender,test.assays.result`

Assuming gender values of male, female, unknown and null, and result values of positive and negative, an expected result could be:

```{
  tests: [
    {
      patient.gender: "male",
      test.assays.result: "positive",
      count: 99
    },
    {
      patient.gender: "male",
      test.assays.result: "negative",
      count: 86
    },
    {
      patient.gender: "female",
      test.assays.result: "positive",
      count: 120
    },
    {
      patient.gender: "female",
      test.assays.result: "negative",
      count: 14
    }
  ],
  total_count: 319
}
```

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

`/tests?group_by=site,gender,result`

The possible groupings are:

* location
* institution
* device
* site
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

```{
  "tests": [
    {
      "test": {
        "start_time": "2015-08-18T00:00:00.000Z",
        "site_user": "Cornelia Kazmaier",
        "name": "MTBDRplus",
        "assays": [
          {
            "condition": "mtb",
            "name": "mtb",
            "result": "positive"
          },
          {
            "condition": "rif",
            "name": "rif",
            "result": "positive"
          },
          {
            "condition": "inh",
            "name": "inh",
            "result": "positive"
          }
        ],
        "type": "specimen",
        "reported_time": "2016-02-16T19:59:09Z",
        "updated_time": "2016-02-16T19:59:09Z",
        "uuid": "7d321113-2b39-3100-08f4-776e2c8cee8b",
        "custom_fields": {
          "clia_waived_test": "n.a.",
          "revision": "038",
          "control": "n.a.",
          "ig_type": "ig_g",
          "control_strip": "patient",
          "bands": "TUB(198,6);rpoB(383,4);rpoBWT1(737,1);rpoBWT2(1341,0);rpoBWT3(1069,0);rpoBWT4(792,4);rpoBWT5(1154,0);rpoBWT6(1224,0);rpoBWT8(818,9);rpoBMUT2B(79,0);katG(82,7);katGMUT1(0,0);inhA(197,2);inhAWT1(524,6);inhAWT2(388,6)"
        }
      },
      "device": {
        "uuid": "K-rz4b3I2X_d",
        "model": "Genoscan",
        "serial_number": "8938490238432",
        "name": "Than Hoa"
      },
      "location": {
        "id": "ne:VNM_456",
        "parents": [
          "ne:VNM",
          "ne:VNM_456"
        ],
        "admin_levels": {
          "admin_level_0": "ne:VNM",
          "admin_level_1": "ne:VNM_456"
        },
        "lat": 19.9556168685236,
        "lng": 105.513240945362
      },
      "institution": {
        "uuid": "417d35a8-ff37-3cd8-dc69-e35e9edd5ce8",
        "name": "CDC"
      },
      "site": {
        "uuid": "595ac805-ff5c-2f7e-e814-f60abfdcce56",
        "path": [
          "595ac805-ff5c-2f7e-e814-f60abfdcce56"
        ],
        "name": "Thanh Hoa Provincial Hospital"
      },
      "sample": {
        "id": "3",
        "custom_fields": {},
        "uuid": [
          "202b8e68-c28a-3550-3c80-392267be4fdc"
        ],
        "entity_id": [
          "3"
        ]
      },
      "encounter": {
        "patient_age": {
          "years": 35,
          "in_millis": 1103760000000
        },
        "start_time": "2015-08-18T00:00:00Z",
        "end_time": "2016-02-16T19:59:09Z",
        "custom_fields": {},
        "uuid": "4f0d2e6f-1162-a853-5685-85da117c6e35"
      },
      "patient": {
        "gender": "female",
        "custom_fields": {},
        "uuid": "5c4f8ad5-59f1-e3d8-6aec-a9a3cbc1b856"
      }
    },
    {
      "test": {
        "start_time": "2015-10-18T00:00:00.000Z",
        "site_user": "Cornelia Kazmaier",
        "name": "MTBDRplus",
        "assays": [
          {
            "condition": "mtb",
            "name": "mtb",
            "result": "positive"
          },
          {
            "condition": "rif",
            "name": "rif",
            "result": "negative"
          },
          {
            "condition": "inh",
            "name": "inh",
            "result": "negative"
          }
        ],
        "type": "specimen",
        "reported_time": "2016-02-16T19:59:09Z",
        "updated_time": "2016-02-16T19:59:09Z",
        "uuid": "e55ef842-1c70-2d29-8a34-6186fba4d196",
        "custom_fields": {
          "clia_waived_test": "n.a.",
          "revision": "038",
          "control": "n.a.",
          "ig_type": "ig_g",
          "control_strip": "patient",
          "bands": "TUB(194,9);rpoB(290,9);rpoBWT1(692,1);rpoBWT2(59,2);rpoBWT3(19,4);rpoBWT4(680,1);rpoBWT5(970,7);rpoBWT6(779,7);rpoBWT7(539,2);rpoBWT8(627,8);katG(206,5);katGWT(469,2);inhA(233,3);inhAWT1(528,9);inhAWT2(385,6)"
        }
      },
      "device": {
        "uuid": "K-rz4b3I2X_d",
        "model": "Genoscan",
        "serial_number": "8938490238432",
        "name": "Than Hoa"
      },
      "location": {
        "id": "ne:VNM_456",
        "parents": [
          "ne:VNM",
          "ne:VNM_456"
        ],
        "admin_levels": {
          "admin_level_0": "ne:VNM",
          "admin_level_1": "ne:VNM_456"
        },
        "lat": 19.9556168685236,
        "lng": 105.513240945362
      },
      "institution": {
        "uuid": "417d35a8-ff37-3cd8-dc69-e35e9edd5ce8",
        "name": "CDC"
      },
      "site": {
        "uuid": "595ac805-ff5c-2f7e-e814-f60abfdcce56",
        "path": [
          "595ac805-ff5c-2f7e-e814-f60abfdcce56"
        ],
        "name": "Thanh Hoa Provincial Hospital"
      },
      "sample": {
        "id": "5",
        "custom_fields": {},
        "uuid": [
          "3b2e77f1-b717-395d-1ded-25d379c3421f"
        ],
        "entity_id": [
          "5"
        ]
      },
      "encounter": {
          "patient_age": {
            "years": 41,
            "in_millis": 1292976000000
          },
        "start_time": "2015-06-18T00:00:00Z",
        "end_time": "2016-02-16T19:59:09Z",
        "custom_fields": {},
        "uuid": "4d8fef0c-80f3-f525-32c6-34b5eab7a9d5"
      },
      "patient": {
        "gender": "male",
        "custom_fields": {},
        "uuid": "51058040-1263-fe1b-406a-5f35cbae4364"
      }
    }
  ],
  "total_count" : 2
}
```

### With Grouping

Returns the quantity of tests matching each combination of aggregated fields and the total count of elements that matched the filter.

`test.assays.condition=mtb&group_by=test.assays.result,patient.gender`

```{
  "tests": [
    {
      "patient.gender": "male",
      "test.assays.result": "positive",
      "count": 44
    },
    {
      "patient.gender": "male",
      "test.assays.result": "negative",
      "count": 18
    },
    {
      "patient.gender": "female",
      "test.assays.result": "positive",
      "count": 42
    },
    {
      "patient.gender": "female",
      "test.assays.result": "negative",
      "count": 3
    }
  ],
  "total_count": 107
}

```

## CSV

## Without Grouping

```Test id,Test uuid,Test start time,Test end time,Test reported time,Test updated time,Test error code,Test error description,Test site user,Test name,Test status,Test type,Sample id,Sample type,Sample collection date,Device uuid,Device name,Device model,Device serial number,Institution uuid,Institution name,Site uuid,Site name,Patient gender,Location id,Location lat,Location lng,Encounter id,Encounter uuid,Encounter patient age,Encounter start time,Encounter end time,Location admin levels admin level 0,Location admin levels admin level 1,Test assays name 1,Test assays condition 1,Test assays result 1,Test assays quantitative result 1,Test assays name 2,Test assays condition 2,Test assays result 2,Test assays quantitative result 2,Test assays name 3,Test assays condition 3,Test assays result 3,Test assays quantitative result 3,Sample uuid 1,Encounter diagnosis name 1,Encounter diagnosis condition 1,Encounter diagnosis result 1,Encounter diagnosis quantitative result 1,Encounter diagnosis name 2,Encounter diagnosis condition 2,Encounter diagnosis result 2,Encounter diagnosis quantitative result 2,Encounter diagnosis name 3,Encounter diagnosis condition 3,Encounter diagnosis result 3,Encounter diagnosis quantitative result 3,Encounter diagnosis name 4,Encounter diagnosis condition 4,Encounter diagnosis result 4,Encounter diagnosis quantitative result 4,Test clia waived test,Test control,Test ig type,Test control strip,Test bands,Test revision,Patient pregnancy status
3238-ABC-Positivo-1750-,a71952b3-a1bc-799a-ee78-f4bf1add5ca8,2015-02-10T18:10:28.000Z,2015-02-21T00:00:00.000Z,2016-02-26T18:22:35Z,2016-02-26T18:22:35Z,,,,BACTEC MGIT / tubo 7 mL,success,specimen,3238-ABC,,,dQoLCXoNkF,Epicenter_D,Epicenter M.G.I.T. Spanish,44454,1f5b45d5-81d2-e63a-35ce-378a59acdcbb,WHO Institution,1b998740-4a6d-24c5-fedd-7b109d7b2628,Quilmes Lab,male,ne:ARG_1295,-37.1001929664999,-60.1138534839139,,92e6400b-2794-e165-46a0-c0a0dcac65cd,,2015-02-10T18:10:28Z,2016-02-26T18:22:35Z,ne:ARG,ne:ARG_1295,mycobacterium_tuberculosis,mtb,positive,,,,,,,,,,371c2bce-1b49-6d59-cc68-b27a9efc4315,mycobacterium_tuberculosis,mtb,positive,,,,,,,,,,,,,,,,,,,,
AAA-133-Positivo-1967-,81326729-8a3c-5236-649f-625d9bd46cf3,2015-03-03T19:27:36.000Z,2015-03-13T00:00:00.000Z,2016-02-26T18:22:35Z,2016-02-26T18:22:35Z,,,,BACTEC MGIT / tubo 7 mL,success,specimen,AAA-133,,,dQoLCXoNkF,Epicenter_D,Epicenter M.G.I.T. Spanish,44454,1f5b45d5-81d2-e63a-35ce-378a59acdcbb,WHO Institution,1b998740-4a6d-24c5-fedd-7b109d7b2628,Quilmes Lab,,ne:ARG_1295,-37.1001929664999,-60.1138534839139,,991517fd-c189-1e45-d51e-17292107cfe0,,2015-03-03T19:27:36Z,2016-02-26T18:22:35Z,ne:ARG,ne:ARG_1295,mycobacterium_tuberculosis,mtb,positive,,,,,,,,,,402c4c6f-49b7-cd27-c018-3333f9864971,mycobacterium_tuberculosis,mtb,positive,,,,,,,,,,,,,,,,,,,,
```

## With Grouping

```test.assays.result,patient.gender,count
positive,male,44
negative,male,18
positive,female,42
negative,female,3
```

For error responses, see the [response status codes documentation](#http-response-codes).
