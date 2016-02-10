Feature: create an alert

  Background:
    Given the user has an account

  Scenario: Successful create alert
    Given the user creates a new alert with name "errorcodealer"
    Then the user should see in list alerts "errorcodealer"

  Scenario: Successful create error category alert with all fields
    Given the user creates a new error category alert with all fields with name "errorcodealer1"
    Then the user should see in list alerts "errorcodealer1"
    Then the user should have alert result 
    Then the user should have an incident

  Scenario: Successful create anomalie category alert with all fields
    Given the user creates a new anomalie category alert with all fields with name "errorcodealer1"
    Then the user should see in list alerts "errorcodealer1"

  Scenario: Successful create testresult category alert with all fields
    Given the user creates a new testresult alert with all fields with name "errorcodealer5"
    Then the user should see in list alerts "errorcodealer5"

  Scenario: Successful create and view alert
    Given the user creates a new alert with name "errorcodealer2"
    And the user should see in list alerts "errorcodealer2"
    And the user should click edit "errorcodealer2"
    Then the user should view edit page "errorcodealer2"
    Then the user should see no edit alert incidents

  Scenario: Successful create, view and delete alert 
    Given the user creates a new alert with name "errorcodealer4"
    And the user should see in list alerts "errorcodealer4"
    And the user should click edit "errorcodealer4"
    And delete the alert  
    Then the user should not see in list alerts "errorcodealer4"