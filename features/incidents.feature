Feature: view incidents

  Background:
    Given the user has an account

  Scenario: No alerts then no incidents
    Then the user should see no incidents