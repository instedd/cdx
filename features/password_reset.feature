Feature: Password Reset
  Background:
    Given User foo@example.com has not changed password for 3 months
    When they log-in to app
    Then they should see, "Please renew your password"
  Scenario: Using a previously used password
    Given the previous passwords
      | password    |
      | foo123      |
      | bar123445   |
      | baz767653   |
      | qux67873645 |
    When they try to use one of previous 5 passwords
    Then they should see, "Password was already taken in the past"
