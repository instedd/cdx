Feature: A user can request access to the application
  As a prospective user of the applcation
  I want to submit my name and email address
  In order for the admistrator to grant me access
  
  Background:
    Given an administrator called "Bob"
    And an institution name "Foo Labs Incorporated"
    And a prospect named "Bill Smith"

  Scenario: Bill Smith requests access to the application
    Given Bill Smith does not have an account
    When he provides the correct information
    Then Bill should see "Your request has been submitted for approval"

  Scenario: Bob views pending requests
    Given the following pending requests for access
      | first_name | last_name | email              |
      | John       | Lennon    | jonn@beatles.org   |
      | George     | Harrison  | george@beatles.org |
    When Bob visits the Prospects page
    Then Bob should see the requests awaiting approval
