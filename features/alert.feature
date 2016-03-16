Feature: create an alert

  Background:
    Given the user has an account

  Scenario: Successful create error category alert with all fields
    Given the user creates a new error category alert with all fields with name "errorcategory"
    Then the user should see in list alerts "errorcategory"
    Then the user should have error_code alert result 
    Then the user should have an incident

  Scenario: Successful create error category alert with all fields but no incident for QC test type
    Given the user creates a new error category alert with all fields with name "errorcategory"
    Then the user should see in list alerts "errorcategory"
    Then the user should have no error_code alert result for qc test 

  Scenario: Successful create anomalie category alert with all fields
    Given the user creates a new anomalie category alert with all fields with name "anomaliecategory"
    Then the user should see in list alerts "anomaliecategory"
    Then the user should have no_sample_id alert result 
    Then the user should have an incident

  Scenario: Successful create testresult category alert with all fields
    Given the user creates a new testresult alert with all fields with name "testresultcategory"
    Then the user should see in list alerts "testresultcategory"

  Scenario: Successful create utilization efficiency category alert with all fields
    Given the user Successful creates a new utilization efficiency category with all fields with name "utilisationcategory"
    Then the user should see in list alerts "utilisationcategory"

  Scenario: Successful create and view alert
    Given the user creates a new error category alert with all fields with name "viewalert"
    And the user should see in list alerts "viewalert"
    And the user should click edit "viewalert"
    Then the user should view edit page "viewalert"
    Then the user should see no edit alert incidents

  Scenario: Successful create, view and delete alert 
    Given the user creates a new error category alert with all fields with name "deletealert"
    And the user should see in list alerts "deletealert"
    And the user should click edit "deletealert"
    And delete the alert  
    Then the user should not see in list alerts "deletealert"

  Scenario: Successful create error category alert with email limit 2 and verify only 2 emails sent 
   Given the user creates a new error category alert with all fields with name "verifyemaillimit"
   Then the user should see in list alerts "verifyemaillimit"
   Then the user should have error_code alert result 
   Then the user should have error_code alert result 
   Then the user should have error_code alert result 
   Then the user should have error_code alert result 
   Then the user should have two emails
