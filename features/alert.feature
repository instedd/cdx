Feature: create an alert

  Background:
    Given the user has an account

  Scenario: Successful create alert
    Given the user creates a new alert with name "errorcodealer"
    Then the user should see in list alerts "errorcodealer"


