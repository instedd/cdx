---
category: Reference Implementation
title: 'Policies'
---

The reference implementation uses a flexible policy model to set user permissions. It allows a user to grant specific permissions to specific resources.

A policy consists of a list of statements that grants or denies permission to execute a list of actions over a list of resources. The policy can be delegable to other users.

## The possible actions are:

* device:read
* device:update
* device:delete
* device:support
* device:regenerateKey
* device:generateActivationToken
* device:reportMessage

* deviceModel:read
* deviceModel:update
* deviceModel:delete
* deviceModel:publish

* encounter:read
* encounter:update
* encounter:pii

* institution:create
* institution:read
* institution:update
* institution:delete
* institution:createSite
* institution:registerDevice
* institution:registerDeviceModel
* institution:createRole
* institution:createPatient
* institution:readUsers

* patient:read
* patient:update
* patient:delete

* role:read
* role:update
* role:delete
* role:assignUser
* role:removeUser

* site:read
* site:update
* site:delete
* site:assignDevice
* site:createRole
* site:createEncounter
* site:readUsers

* testResult:query
* testResult:pii
* testResult:medicalDashboard

* user:update

## The supported resources are:

* device
* deviceModel
* encounter
* institution
* patient
* role
* site
* testResult
* user

A resource can represent all the list of resources or a single one. They follow the URI standard.

A list of resources can be blacklisted using the *except* statement.

# Examples

The following policy will allow the user to perform any action on any institution, device or site that the grantee can access, with the exception of the site 2:

```
{
  "statement": [
    {
      "action": "*",
      "delegable" : false,
      "resource": [
        "institution",
        "device",
        "site"
      ]
      "except": "site/2"
    }
  ]
}
```

This policy would only allow control over the institution with id 1, and only its devices and laboratories.

```
{
  "statement": [
    {
      "delegable" : false,
      "action": "*",
      "resource": [
        "institution/1",
        "device?institution=1",
        "site?institution=1"
      ]
    }
  ]
}
```

The same way, this one would grant only read access to the site with id 4, but this time the receiver can delegate this rights to another user

```
{
  "statement": [
    {
      "action": [
        "readInstitution",
        "readLaboratory",
        "readDevice",
        "updateDevice",
        "deleteDevice",
        "assignDeviceLaboratory",
        "regenerateDeviceKey",
        "queryTest",
        "reportMessage"
      ],
      "delegable": true,
      "resource": [
        "institution/1",
        "device?institution=1&site=4",
        "site/4"
      ]
    }
  ]
}
```

Every user starts with an _implicit_ policy that allows it to create institutions and be its admin:

```
{
  "statement": [
    {
      "action": "*",
      "delegable": true,
      "resource": [
        "institution",
        "device",
        "site"
      ],
      "condition": {"is_owner" : true}
    }
  ]
}
```

A superadmin would have then a policy that allows him to do anything to any resource:

```
{
  "statement": [
    {
      "action": "*",
      "delegable": true,
      "resource": "*"
    }
  ]
}
```
