Feature: create an alert

  Background:
    Given the user has an account

  Scenario: Successful create alert
    Given the user creates a new alert with name "errorcodealer"
    Then the user should see in list alerts "errorcodealer"

  Scenario: Successful create alert with all fields
    Given the user creates a new alert with all fields with name "errorcodealer1"
    Then the user should see in list alerts "errorcodealer1"


