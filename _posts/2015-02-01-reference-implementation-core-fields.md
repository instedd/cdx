---
category: Reference Implementation
title: 'Core Fields'
---

## Added fields for the reference implementation

- _sample.uid_ - In order to disambiguate the sample Id, manifests should ensure that the value in this field uniquely identifies each sample institution-wise. Two tests are considered to have the same sample if and only if they belong to the same institution and have the same _sample.uid_ value. A possible sample uid for an test is a composition of the original _sample.id_, the month of the test's _start\_time_ (to handle repetitions over time) and the identifier of the laboratory where the test was run (to handle repetitions across labs). This _sample.uid_ is currently provided by the manifest.
- _location.parents_ - The natural earth geo id of all the the device location's parents.
- _location.admin_levels_ - The natural earth parents geo ids tagged by administrative level.
- _location.lat_ - The latitude of the center of the geo id location.
- _location.lng_ - The longitude of the center of the geo id location.
