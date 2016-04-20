---
category: Reference Implementation
path: '/encounters/schema[.format]'
title: Encounters schema
type: GET
---

```
{
  $schema: "http://json-schema.org/draft-04/schema#",
  type: "object",
  title: "en-US",
  properties: {
    institution: {
      type: "object",
      title: "Institution",
      properties: {
        uuid: {
          title: "Uuid",
          type: "string",
          searchable: true
        },
        name: {
          title: "Name",
          type: "string",
          searchable: false
        }
      }
    },
    site: {
      type: "object",
      title: "Site",
      properties: {
        uuid: {
          title: "Uuid",
          type: "string",
          searchable: true
        },
        name: {
          title: "Name",
          type: "string",
          searchable: false
        },
        path: {
          title: "Path",
          type: "string",
          searchable: true
        }
      }
    },
    patient: {
      type: "object",
      title: "Patient",
      properties: {
        id: {
          title: "Id",
          type: "string",
          searchable: false
        },
        name: {
          title: "Name",
          type: "string",
          searchable: false
        },
        dob: {
          title: "Dob",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: false
        },
        gender: {
          title: "Gender",
          type: "string",
          enum: [
            "male",
            "female",
            "other"
          ],
          values: {
            male: {
              name: "Male"
            },
            female: {
              name: "Female"
            },
            other: {
              name: "Other"
            }
          },
          searchable: true
        },
        email: {
          title: "Email",
          type: "string",
          searchable: false
        },
        phone: {
          title: "Phone",
          type: "string",
          searchable: false
        }
      }
    },
    encounter: {
      type: "object",
      title: "Encounter",
      properties: {
        id: {
          title: "Id",
          type: "string",
          searchable: false
        },
        uuid: {
          title: "Uuid",
          type: "string",
          searchable: true
        },
        patient_age: {
          title: "Patient Age",
          type: "object",
          class: "duration",
          properties: {
            milliseconds: {
              type: "integer",
              title: "Patient Age milliseconds"
            },
            seconds: {
              type: "integer",
              title: "Patient Age seconds"
            },
            minutes: {
              type: "integer",
              title: "Patient Age minutes"
            },
            hours: {
              type: "integer",
              title: "Patient Age hours"
            },
            days: {
              type: "integer",
              title: "Patient Age days"
            },
            months: {
              type: "integer",
              title: "Patient Age months"
            },
            years: {
              type: "integer",
              title: "Patient Age years"
            }
          },
          searchable: true
        },
        start_time: {
          title: "Start Time",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: true
        },
        end_time: {
          title: "End Time",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: true
        },
        observations: {
          title: "Observations",
          type: "string",
          searchable: false
        },
        diagnosis: {
          title: "Diagnosis",
          type: "array",
          items: {
            type: "object",
            properties: {
              name: {
                title: "Name",
                type: "string",
                searchable: true
              },
              condition: {
                title: "Condition",
                type: "string",
                enum: [
                  "atsc",
                  "cd4_count",
                  "ct",
                  "emb",
                  "hiv",
                  "hiv_1_m_n",
                  "hiv_1_o",
                  "hiv_2",
                  "inh",
                  "lvx",
                  "malaria_pf",
                  "malaria_pv",
                  "mtb",
                  "ng",
                  "pas",
                  "pza",
                  "rif",
                  "stm",
                  "tch"
                ],
                searchable: true
              },
              result: {
                title: "Result",
                type: "string",
                enum: [
                  "positive",
                  "negative",
                  "indeterminate"
                ],
                values: {
                  positive: {
                    name: "Positive",
                    kind: "positive"
                  },
                  negative: {
                    name: "Negative",
                    kind: "negative"
                  },
                  indeterminate: {
                    name: "Indeterminate"
                  }
                },
                searchable: true
              },
              quantitative_result: {
                title: "Quantitative Result",
                type: "string",
                searchable: true
              }
            }
          },
          searchable: true
        }
      }
    }
  }
}
```
