---
category: Reference Implementation
title: 'Policies'

layout: nil
---

The reference implementation uses a flexible policy model to set user permissions. It allows a user to grant specific permissions to specific resources.

A policy consists of a list of statements that grants or denies permission to execute a list of actions over a list of resources. The policy can be delegable to other users.

The possible effects that a statement can have are: _allow_, and _deny_

## The possible actions are:

* cdxp:createInstitution
* cdxp:readInstitution
* cdxp:updateInstitution
* cdxp:deleteInstitution
* cdxp:createInstitutionLaboratory
* cdxp:readLaboratory
* cdxp:updateLaboratory
* cdxp:deleteLaboratory
* cdxp:registerInstitutionDevice
* cdxp:readDevice
* cdxp:updateDevice
* cdxp:deleteDevice
* cdxp:assignDeviceLaboratory
* cdxp:regenerateDeviceKey
* cdxp:generateActivationToken
* cdxp:queryTest
* cdxp:reportMessage

## The supported resources are:

* cdxp:institution
* cdxp:device
* cdxp:laboratory

A resource can represent all the list of resources or a single one. They follow the URI standard.

# Examples

The following policy will allow the user to perform any action on any institution, device or laboratory that the grantee can access:

`{
  "statement": [
    {
      "effect": "allow",
      "action": "*",
      "resource": [
        "cdxp:institution",
        "cdxp:device",
        "cdxp:laboratory"
      ]
    }
  ],
  "delegable" : false
}`

This policy would only allow control over the institution with id 1, and only its devices and laboratories.

`{
  "statement": [
    {
      "effect": "allow",
      "action": "*",
      "resource": [
        "cdxp:institution/1",
        "cdxp:device?institution=1",
        "cdxp:laboratory?institution=1"
      ]
    }
  ],
  "delegable" : false
}`

The same way, this one would grant only read access to the laboratory with id 4, but this time the receiver can delegate this rights to another user

`{
  "statement": [
    {
      "effect": "allow",
      "action": [
        "cdxp:readInstitution",
        "cdxp:readLaboratory",
        "cdxp:readDevice",
        "cdxp:updateDevice",
        "cdxp:deleteDevice",
        "cdxp:assignDeviceLaboratory",
        "cdxp:regenerateDeviceKey",
        "cdxp:queryTest",
        "cdxp:reportMessage"
      ],
      "resource": [
        "cdxp:institution/1",
        "cdxp:device?institution=1&laboratory=4",
        "cdxp:laboratory/4"
      ]
    }
  ],
  "delegable": true
}`

Every user starts with an _implicit_ policy that allows it to create institutions and be its admin:

`{
  "statement": [
    {
      "effect": "allow",
      "action": "*",
      "resource": [
        "cdxp:institution",
        "cdxp:device",
        "cdxp:laboratory"
      ],
      "condition": {"is_owner" : true}
    }
  ],
  "delegable": true
}`

A superadmin would have then a policy that allows him to do anything to any resource:

`{
  "statement": [
    {
      "effect": "allow",
      "action": "*",
      "resource": "*"
    }
  ],
  "delegable": true
}`
