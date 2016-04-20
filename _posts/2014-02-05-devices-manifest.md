---
category: Devices
title: 'Manifest'
---

Every device manufacturer should provide a manifest specifying the translation from the reporting format for each device to the API standard fields.

The manifest is a json that must include two fields: *metadata* and *field_mapping*. And additionally may contain *custom_fields*.

# Metadata

The metadata header must include the version of the manifest, the version of the API, a list of the models that it applies to, the source data type (json, xml or csv), and the list of conditions that the device reports.

``` {
  "metadata" : {
    "version" : "1.2.1",
    "device_models" : ["GX4001", "GX4002"],
    "conditions" : ["mtb", "rif", "inh"],
    "source": {"type" : "json"}
  }
}
```

# Version

The current version of the manifest is "1.2.1".

## Source type

Current source types are *json*, *xml*, *csv*, and *headless_csv* for the cases when the csv contains no header data. For custom CSVs an additional *separator* can be specified. If no separator is specified, the default is ",".

In some cases the CSV can include some header that is necessary to skip. The number of lines to skip can be specified using *skip_lines_at_top*.

### Example

``` "source": {
  "type" : "csv",
  "separator" : ";",
  "skip_lines_at_top" : 1
}
```

## Conditions

The manifest conditions must be encoded using snake notation: underscore_with_dashes

# Field Mappings

The field mapping is an object that describes the translation from a reported value to a core field. Each key of the object is a reference to a field, and each value is a *source* object that represents the required transformations to obtain its value.

A typical manifest may look like this:

``` {
  "metadata" : {
    ...
  }
  "custom_fields" : {
    "patient.name" : { "pii" : true },
    "test.temperature": {},
    ...
  },
  "field_mapping" : {
    "patient.name" : { ... },
    "sample.id" : { ... },
    "test.name" : { ... },
    "test.temperature": { ... },
    ...
  }
}
```

This *source* object may contain a number of pre-defined functions in order to retrieve and transform the data provided by the device into something that matches the required format. These are:

- *lookup* - expects the source path of the reported field, using json path if the source_data_type is json: for multiple elements the [\*] notation must be used; for each nesting level, the depth is specified using a period (.). For instance, the element 'test_result' has a field named 'conditions' that contains an array, and for every element of this array, the element 'name' is taken.
  `{ "lookup" : "test_result.conditions[*].name" }`

  If the source is an xml, the XPath notation is used. In the case described above, the result would be:
  `{ "lookup" : "test_result/conditions/name/text()" }`

  If the source is a csv, then the path should be the column name, or if it's a headless_csv, it should be only the column number, 0 based.
  `{ "lookup" : "0" }`

- _case_ - expects the element to transform as the first parameter and an array of transformations as the second one. If a match applies, the result will be the output specified. Wildcards are specified as '\*'.
  ``` {
    "case" : [
      { "lookup" : "conditions[*].condition" },
      [
        { "when" : "*MTB*",  "then" : "MTB" },
        { "when" : "*FLU*",  "then" : "H1N1" },
        { "when" : "*FLUA*", "then" : "A1N1" }
      ]
    ]
  }
  ```

- *lowercase* - Converts the parsed field value into a lowercase string
  `{ "lowercase" : { "lookup" : "last_name" } }`

- *concat* - expects two or more parameters and returns a string containing all the parameters joined
  ``` {
    "concat" : [
      { "lookup" : "patient_information.last_name" },
      ", ",
      { "lookup" : "patient_information.first_name" }
    ]
  }
  ```

- *strip* - removes trailing spaces from the given parameter
  `{ "strip" : { "lookup" : "patient_information.last_name" } }`

- *convert_time* - it will convert a numeric time from a given time unit to another one specified. The source time unit is expected first. Possible units are: years, months, days, hours, minutes, seconds, milliseconds. When reducing the unit precision, no rounding will be made. When converting from days to years, all years will be considered as 365.25 days long. When converting from days to months, all months will be considered as 30 days long.
  ``` {
    "convert_time" : [
      { "lookup" : "patient_information.age_in_years" },
      "years",
      "days"
    ]
  }
  ```

- *beginning_of* [year, month] - Useful for date related PII, it converts a date into a less specific time span. Expects the value as the first parameter, and the time unit as the second one.
  ``` {
    "beginning_of" : [
      { "lookup" : "patient_information.age" },
      "month"
    ]
  }
  ```

- *milliseconds_between* / *hours_between* / *minutes_between* / *seconds_between* / *years_between* / *months_between* / *days_between* - measures the number of milliseconds, hours, years, etc. between two given dates. Useful to compute ages or test durations. It will always round to the smallest value.
  ``` {
    "years_between" : [
      { "lookup" : "patient_information.birth_date" },
      { "lookup" : "test_information.run_at" }
    ]
  }
  ```

- *parse_date* - parse the field value using the specified format for further processing. Eg: 'yyyy-mm-dd hh:mm:ss'. All dates must be stored using ISO 8601 format. If the device reports a date using another format, it must be parsed. If the date will be used in another function that expects a date, it must be parsed.
  ``` {
    "parse_date" : [
      { "lookup" : "patient_information.birth_date" },
      "%d-%m-%Y %I:%M:%S %p"
    ]
  }
  ```

- *duration* - It expects a duration object with years, months, days, seconds, and milliseconds. There is no required component, but at least one must be present.
  ``` {
    "duration" : {
      "years" : {
        "years_between" : [
          {"parse_date" : [
            {"lookup" : "Birthday"},
            "%d.%m.%Y"
          ]},
          {"parse_date" : [
            {"lookup" : "DateOfAnalysis"},
            "%d.%m.%Y"
          ]}
        ]
      }
    }
  }
  ```

- *clusterise* - given an array of steps and a number, it returns the bucket that contains it. The lower boundary will always be zero and the upper bucket will always contain all the values that are greater or equal the last step value. The step value will always be the greater value of the generated cluster. In the following example, the buckets created will be: "0-5", "6-15", "16-45", "46+"
  ``` {
      "clusterise" : [
          { "lookup" : "patient_information.age_in_years" },
          [ 5, 15, 45 ]
      ]
  }
  ```

- *substring* - it extracts the string in the specified positions. Negative values are counted from the end of the string being -1 the last element. The given example will return the original string untouched.
  `{ "substring" : [ { "lookup" : "test_information.assay_code" }, 0, -1 ] }`

- *equals* - Used inside an if expression. It checks if its two arguments are equal. Returns true or false and allows an *if* to be executed in return. The order of the arguments is not important. Any of the arguments can be any valid expression or a string.
  `{"equals" : ["A", {"lookup" : "Condition"}]}`

- *if* - Used with a conditional expression. It receives an array containing a conditional in the first position, and true and false expressions in the second and third positions of the array
  ``` {
    "if" : [
      { "equals" : [ { "lookup" : "Condition" }, "A" ] },
      { "lookup" : "A Column" },
      { "lookup" : "B Column" }
    ]
  }
  ```

- *script* - Used when the needed calculation is too complex or you need to access basic CDX elements like the device, its laboratory, institution or location. The only value will be a Javascript that in the last line returns the result to be assigned for that field. The message sent by the device would be accessible through a *message* object, and its properties would be accessible as a regular Javascript object.
  `{ "script" : "message['Condition']" }`
  Or as a simple property
  `{ "script": "message.first_name + ' ' + message.last_name" }`
  If the message sent is a csv, then it would be accessed by column header:
  `{ "script" : "message['Result']" }`
  If it doesn't have header, it can be accessed by column number:
  `{ "script" : "message['5']" }`
  If the message sent is an xml, then you will have xpath available:
  `{"script": "message.xpath('Patient/@name').first().value"}`
  To access basic CDX elements just reference them:
  `{ "script": "device.name + ', ' + device.uuid" }`
  `{ "script": "location.name + ': ' + parseInt(location.lat) + ',' + parseInt(location.lng)" }`
  `{ "script": "laboratory.id + '-' + new Date().getFullYear() + '-' + message['SampleId']" }`

A sample field may look like this:

`{
  "test.patient_age" : {
    "if" : [
      { "equals" : [ { "lookup" : "Birthday" }, "n.a." ] },
      null,
      {
        "duration" : {
          "years" : {
            "years_between" : [
              { "parse_date" : [ { "lookup" : "Birthday" }, "%d.%m.%Y" ] },
              { "parse_date" : [ { "lookup" : "DateOfAnalysis" }, "%d.%m.%Y" ] }
            ]
          }
        }
      }
    ]
  }
}`

# Custom Fields

If the device reports additional information that is necessary for further analysis, it should be included in the manifest definition. Additionally to the field mappings, the manifest may define custom_fields. This custom fields are to be used in the field_mapping section.

Each custom field may contain:

- *pii* - boolean. Indicates if the field must be considered PII or not.

A sample custom field would be:

`{"patient.telephone_number" : { "pii" : true } }`

# Personally Identifiable Information

The device can report information that allows the test to be linked with the patient. This information must be kept encrypted and must not be indexed. Therefore, all PII must have "pii" field set to true.

## Implementation Specific Field Mapping Metadata

Manifests support implementation specific metadata at the field level. Such metadata is ignored by reference implementations, but could be of use for specific ones.

Implementation specific field mapping metadata can be included simply by adding a non-standard key-value pair to the root level of a field mapping. Implementation specific keys MUST NOT override the standard field mapping elements listed above.

Implementation specific keys can be anything, but we SUGGEST to prefix them with -x--, which makes it easier to distinguish standard field mapping elements from ad hoc ones.

As an example, let's say there's a need to treat some fields as *Maximum Security*, which has certain implications for a particular implementation. An *x-max_security* field could be added to those fields as shown below:

```
{
  ...
  pii: false
  valid_values: { ... }
  x-max_security: true
  ...
}
```

Given this manifest, standard manifest processors MAY ignore *x-max_security*, but they WON'T fail because of it. It's then up to each implementation to provide a specific (still compliant) processor that knows what to do when a mapping includes *x-max_security*.

It's up to the reference implementations to define this attributes for the core fields, as the manifest will only allow to define them for the custom fields of each device model.
