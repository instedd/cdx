Feature: Logging into system
  Scenario: Successful login
    Given the user 'foouser@example.com' has an account
    When he attempts to log-in with correct details
    Then he should see "New Institution"

  Scenario: Failed login
    Given the user 'foouser@example.com' has an account
    When he attempts to log-in with incorrect password
    Then he should see "Invalid email or password."

  Scenario: Multiple failed logins
    Given the user 'foouser@example.com' has an account
    When he attempts to log-in 2 times with incorrect password
    Then he should see "You have one more attempt before your account is locked"
    When he attempts to log-in 3 times with incorrect password
    Then he should see "Your account is locked"
