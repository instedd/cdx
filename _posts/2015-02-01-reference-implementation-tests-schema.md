---
category: Reference Implementation
path: '/tests/schema[.format]'
title: Tests schema
type: GET
---

```
{
  $schema: "http://json-schema.org/draft-04/schema#",
  type: "object",
  title: "en-US",
  properties: {
    test: {
      type: "object",
      title: "Test",
      properties: {
        id: {
          title: "Id",
          type: "string",
          searchable: true
        },
        uuid: {
          title: "Uuid",
          type: "string",
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
        reported_time: {
          title: "Reported Time",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: true
        },
        updated_time: {
          title: "Updated Time",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: true
        },
        error_code: {
          title: "Error Code",
          type: "integer",
          searchable: true
        },
        error_description: {
          title: "Error Description",
          type: "string",
          searchable: false
        },
        site_user: {
          title: "Site User",
          type: "string",
          searchable: true
        },
        name: {
          title: "Name",
          type: "string",
          searchable: true
        },
        status: {
          title: "Status",
          type: "string",
          enum: [
            "invalid",
            "error",
            "no_result",
            "success",
            "in_progress"
          ],
          values: {
            invalid: {
              name: "Invalid"
            },
            error: {
              name: "Error"
            },
            no_result: {
              name: "No Result"
            },
            success: {
              name: "Success"
            },
            in_progress: {
              name: "In Progress"
            }
          },
          searchable: true
        },
        assays: {
          title: "Assays",
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
                  "indeterminate",
                  "n/a"
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
                  },
                  n/a: {
                    name: "N/A"
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
        },
        type: {
        title: "Type",
        type: "string",
        enum: [
          "specimen",
          "qc"
        ],
        values: {
          specimen: {
            name: "Specimen"
          },
          qc: {
            name: "Qc"
          }
        },
        searchable: true
        }
      }
    },
    sample: {
      type: "object",
      title: "Sample",
      properties: {
        id: {
          title: "Id",
          type: "string",
          searchable: true
        },
        uuid: {
          title: "Uuid",
          type: "string",
          searchable: true
        },
        type: {
          title: "Type",
          type: "string",
          searchable: true
        },
        collection_date: {
          title: "Collection Date",
          type: "string",
          format: "date-time",
          resolution: "second",
          searchable: false
        }
      }
    },
    device: {
      type: "object",
      title: "Device",
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
        model: {
          title: "Model",
          type: "string",
          searchable: true
        },
        serial_number: {
          title: "Serial Number",
          type: "string",
          searchable: true
        }
      }
    },
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
    location: {
      type: "object",
      title: "Location",
      properties: {
        id: {
          title: "Id",
          type: "string",
          searchable: false
        },
        parents: {
          title: "Parents",
          type: "string",
          searchable: true
        },
        admin_levels: {
          title: "Admin Levels",
          type: "string",
          searchable: true
        },
        lat: {
          title: "Lat",
          type: "string",
          searchable: false
        },
        lng: {
          title: "Lng",
          type: "string",
          searchable: false
        }
      },
      location-service: {
        url: "http://locations-stg.instedd.org",
        set: "ne"
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
