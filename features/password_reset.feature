Feature: Password Reset
  Scenario: Forcing a password reset after 3 months
    Given User foo@example.com has not changed password for 3 months
    When they log-in to app
    Then they should see, "Please renew your password"

