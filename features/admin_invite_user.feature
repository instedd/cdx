@wip
Feature: Superadmin can invite users to the system
  As a user with superadmin privileges
  I want to invite new users to the system
  So they can have defined access

  Background:
    Given an authenticated superadmin called Bob
    And an institution name "Foo Labs Incorporated"
    And a prospective user called Bill Smith, with email "billsmith@copado.com"

  @single_tenant
  Scenario: Bob invites Bill Smith to Foo Labs Incorporated
    Given Bill does not have an account
    When Bob sends an invitation to Bill Smith
    Then Bob should see "An invitation email has been sent to billsmith@copado.com"

  Scenario: Bob views users he added to a specific lab
    Given the following users created by Bob
      | first_name | last_name | lab_name |
      | John       | Lennon    | Lab One  |
      | George     | Harrison  | Lab One  |
      | Ringo      | Starr     | Lab One  |
      | Paul       | McCartney | Lab Two  |
    When Bob view the users on Lab One
    Then Bob should see "John Lennon"
    And Bob should see "George Harrison"
    And Bob should see "Ringo Starr"
    But Bob should not see "Paul McCartney"
