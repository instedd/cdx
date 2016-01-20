Feature: create an alert

  Background:
    Given the user has an account

  Scenario: Successful create alert
    Given the user creates a new alert with name "errorcodealer"
    Then the user should see in list alerts "errorcodealer"

  Scenario: Successful create error category alert with all fields
    Given the user creates a new error category alert with all fields with name "errorcodealer1"
    Then the user should see in list alerts "errorcodealer1"


  Scenario: Successful create anomalie category alert with all fields
    Given the user creates a new anomalie category alert with all fields with name "errorcodealer1"
    Then the user should see in list alerts "errorcodealer1"