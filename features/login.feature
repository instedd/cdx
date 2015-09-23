Feature: Logging into system
  Scenario: Failed login
    Given the user 'foouser' does not have an account
    When he attempts to log-in
    Then he should see "Invalid email or password."

  Scenario: Multiple failed logins
    Given the user 'foouser' does not have an account
    When he attempts to log-in 3 times
    Then he should see "Your account has been locked."
