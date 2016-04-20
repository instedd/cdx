---
category: Applications
path: '/encounters[.format]'
title: 'Query Encounters'
type: 'GET [POST]'
---

Returns a list of Encounters. All the filters can be specified in the **POST** request body or in the **GET** query string.

# Format

The query can be answered in CSV, XML, and JSON formats.

The CSV format doesn't include the total count.

The default response format is JSON.

# Filters

Filter parameters allow querying a subset of the available encounters.

The data returned will be sorted by default by the encounter creation date.

### Date filters

All the possible dates can be filtered by since and until as in **encounter.end_time.since** and **encounter.end_time.until**
The available dates are:

* encounter.start_time
* encounter.end_time

When querying from the query string the **+** sign must be escaped as **%2B**. For instance: **2014-08-01T18:10:36+07:00**, will be: **2014-08-01T18:10:36%2B07:00**

#### Example

* since: will retrieve tests started after a specific date time.

`/encounters?encounter.start_time.since=2014-04-10T15:22:12+00:00`

* `encounter.start_time.until` will retrieve tests ended before a specific date time. Useful to define a time window in combination with “since”.

`/encounters?encounter.start_time.until=2014-04-10T15:22:12-0300`

### Institution filters

* `institution.uuid` - filter tests by institution UUID

`/encounters?institution.uuid=1`

### Site filters

* `site.uuid` - filter tests by site UUID

`/encounters?site.uuid=1`

### Demographic filters

* `patient.gender` - filter tests by the patient gender

`/encounters?patient.gender=male`

* `encounter.patient_age` - filter tests for people by the range specified. This is the age at the moment of the encounter.

`/encounters?encounter.patient_age=50yo..60yo`

### Encounter filters

* `encounter.uuid` - filter tests by the encounter UUID

`/encounters?encounter.uuid=c4c52784-bfd5-717d-7a91-614acd972d5e`

# Response

`Status: 200 OK`

##JSON

### Without Grouping

Returns an array of tests without any PII and the total count of elements that matched the filter.
`/encounters?encounter.diagnosis.condition=mtb`

```{
  encounters: [
  {
    institution: {
      uuid: "1f5b45d5-81d2-e63a-35ce-378a59acdcbb",
      name: "Institution"
    },
    site: {
      uuid: "16e2d7e5-0783-63c2-05da-9ee21ecf6977",
      path: [
      "16e2d7e5-0783-63c2-05da-9ee21ecf6977"
      ],
      name: "Site"
    },
    encounter: {
      diagnosis: [
        {
          condition: "mtb",
          name: "mtb",
          result: "positive"
        },
        {
          condition: "rif",
          name: "rif",
          result: "positive"
        },
        {
          condition: "inh",
          name: "inh",
          result: "positive"
        },
        {
          condition: "hiv_1_m_n",
          name: "HIV-1 M/N",
          result: "positive",
          quantitative_result: 350
        },
        {
          condition: "hiv_1_o",
          name: "HIV-1 O",
          result: "positive",
          quantitative_result: 500
        },
        {
          condition: "hiv_2",
          name: "HIV-2",
          result: "negative"
        }
      ],
      start_time: "2016-03-21T14:28:24Z",
      end_time: "2016-03-21T14:28:24Z",
      custom_fields: { },
      uuid: "39c4c9d6-2b19-bd89-0749-94fe7fd9ac32",
      user_email: null
    },
    patient: {
      gender: "male",
      custom_fields: { },
      uuid: "e64d0d16-5fd1-e12a-eb8b-31b9e68aa623"
    }
  }
  ],
  total_count: 1
}
```

### With Grouping

Returns the quantity of tests matching each combination of aggregated fields and the total count of elements that matched the filter.

`/encounters?encounter.diagnosis.condition=mtb&group_by=patient.gender`

```{
  encounters: [
    {
      patient.gender: "male",
      count: 7
    },
    {
      patient.gender: "female",
      count: 5
    }
  ],
  total_count: 12
}
```

## CSV

## Without Grouping

```Institution uuid,Institution name,Site uuid,Site name,Patient gender,Encounter id,Encounter uuid,Encounter user email,Encounter patient age,Encounter start time,Encounter end time,Encounter diagnosis name 1,Encounter diagnosis condition 1,Encounter diagnosis result 1,Encounter diagnosis quantitative result 1,Encounter diagnosis name 2,Encounter diagnosis condition 2,Encounter diagnosis result 2,Encounter diagnosis quantitative result 2,Encounter diagnosis name 3,Encounter diagnosis condition 3,Encounter diagnosis result 3,Encounter diagnosis quantitative result 3,Encounter diagnosis name 4,Encounter diagnosis condition 4,Encounter diagnosis result 4,Encounter diagnosis quantitative result 4,Encounter diagnosis name 5,Encounter diagnosis condition 5,Encounter diagnosis result 5,Encounter diagnosis quantitative result 5,Encounter diagnosis name 6,Encounter diagnosis condition 6,Encounter diagnosis result 6,Encounter diagnosis quantitative result 6
1f5b45d5-81d2-e63a-35ce-378a59acdcbb,WHO Institution,16e2d7e5-0783-63c2-05da-9ee21ecf6977,Buenos Aires Lab,male,,39c4c9d6-2b19-bd89-0749-94fe7fd9ac32,,,2016-03-21T14:28:24Z,2016-03-21T14:28:24Z,mtb,mtb,positive,,rif,rif,positive,,inh,inh,positive,,HIV-1 M/N,hiv_1_m_n,positive,350,HIV-1 O,hiv_1_o,positive,500,HIV-2,hiv_2,negative,
```

## With Grouping

```encounter.diagnosis.result,patient.gender,count
positive,male,44
negative,male,18
positive,female,42
negative,female,3
```

For error responses, see the [response status codes documentation](#http-response-codes).
