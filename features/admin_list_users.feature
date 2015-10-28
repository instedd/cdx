Feature: Users are display in the admin users page

  Background:
    When I create test users

 Scenario: An admin user is taken to the dashboard on login
    Given I log in as an admin
    Then I should be taken to the dashboard

  Scenario: Show all users
    Given I log in as an admin
    When I click the user tab 
    Then I should see a list of 6 users

  Scenario: Show all enabled users
    Given I log in as an admin
    When I select the ENABLED button "Yes"
    Then I should see a list of 4 users

  Scenario: Show all disabled users
    Given I log in as an admin
    When I select the ENABLED button "No"
    Then I should see a list of 2 users

  Scenario: Show all archived users
    Given I log in as an admin
    When I select the ARCHIVED button "Yes"
    Then I should see a list of 2 users

