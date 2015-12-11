Feature: create an alert

Background:
  Given the user has an account
  #Given the user 'foouser@example.com' has an account

  Scenario: Successful create alert
    Then he should see New Institution
    Given the user creates a new alert


#    When they select errorcode alert called 'errorcodealert'
#    And select submit
#    Then he should see "errorcodealert" in list alerts
