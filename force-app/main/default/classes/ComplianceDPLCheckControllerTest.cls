@isTest
public class ComplianceDPLCheckControllerTest {
    
    @testSetup static void methodName() {
        Territory2 territory = new Territory2(
            Name = 'CA1 - LOCATION',                                                                                                                                   // Parent Territory
            Theater2__c = 'AMERICAS',                                                                                                                                            // Theater
            Territory2__c = 'BAY AREA - TERRITORY',                                                                                                                              // Territory
            Sub_Theater2__c = 'US - SUB THEATER',                                                                                                                                // Sub Theater
            Sub_Territory2__c = 'BAY AREA - SUB TERRITORY',                                                                                                                      // Sub Territory
            Region2__c = 'WEST - REGION',                                                                                                                                        // Region
            Location2__c = 'CA1 - LOCATION',                                                                                                                                     // Location
            AccountAccessLevel = 'Users in this territory can view and edit accounts assigned to this territory.',                                                               // Account Access Level
            ContactAccessLevel = 'Users in this territory can view and edit all contacts associated with accounts in the territory, regardless of who owns the contacts.',       // Contact Access Level
            OpportunityAccessLevel = 'Users in this territory can view all opportunities associated with accounts in the territory, regardless of who owns the opportunities.',  // Opportunity Access Level
            CaseAccessLevel = 'Users in this territory cannot access cases that they do not own that are associated with accounts in the territory.'                            // Case Access Level
        );
        
        Account acc1 = new Account(
            Name = 'salesforce',                                               // Account Name
            Compliance_Status__c = 'Pending',                                                     // Compliance Status
            Type = 'End User - Core',                                                             // Type
            Status__c = 'Prospect',                                                               // Status
            Shared_Partner_Account__c = false,                                                    // Shared Partner Account
            Focus_Partner__c = false,                                                             // Focus Partner
            Master_MSP__c = false,                                                                // Master MSP
            Nationwide_Partner_for_Channel_Comms__c = false,                                      // Nationwide Partner for Channel Comms
           // Auto_Renewal_Eligible__c = false,                                                     // Auto Renewal Eligible (Core)
           // DO_NOT_CONTACT_END_USER__c = false,                                                   // DO NOT CONTACT END USER
            Territory_ID__c = territory.id,                                               // Territory ID
            Terr_Alignment_Run__c = 14,                                                         // Terr Alignment Run
            Terr_Theater__c = 'AMERICAS',                                                         // Theater
            IsExcludedFromRealign = false,                                                        // Exclude from territory assignment rules
            Terr_Sub_Theater__c = 'US - SUB THEATER',                                             // Sub Theater
            Exclude_from_Territory_Ownership_Logic__c = false,                                    // Exclude from Territory Ownership Logic
            Terr_Region__c = 'WEST - REGION',                                                     // Region
            House_Account__c = false,                                                             // House Account
            Territory__c = 'BAY AREA - TERRITORY',                                                // Territory
            Global_Account__c = false,                                                            // Global Account
            Terr_Sub_Territory__c = 'BAY AREA - SUB TERRITORY',                                   // Sub Territory
            Named_Account__c = false,                                                             // Named Account
            State_Code__c = 'CA1',                                                                // State Code
            Employee_Count_Override__c = 12345,                                                // 1 - Employee Count (Override)
            Justification_Reason__c = 'something',                                                // Justification Reason
            Employee_Override_Last_Modified_By__c = Userinfo.getUserId(),                            // Employee (Override) Last Modified By
            Partner_Tax_Exempt_Certificate_Received__c = false,                                   // Partner Tax Exempt Certificate Received
            Payment_Terms__c = 'Net 30',                                                          // Payment Terms
            Agreement_Territory__c = 'US',                                        // Agreement Territory
            Signed_disti__c = false,                                                              // Signed Billing Aggregator
            X_Large__c = false,                                                                   // X-Large
            SBQQ__RenewalPricingMethod__c = 'List',                                               // Renewal Pricing Method
            Out_of_Business__c = false                                                      // Account Record Type
        );
        insert acc1;
        
        Contact mContact = new Contact(
            AccountId = acc1.id,                    // Account Name
            Contact_Status__c = 'Pending',                      // Contact Status
            Email = 'htut-validation-sfdc-9824@test.com',       // Email
            HasOptedOutOfEmail = false,                         // Email Opt Out
            Primary_Contact__c = false,                         // Primary Contact
            Validated__c = false,                               // Validated
            Most_Recent_Lead_Source__c = 'Paid Search',         // Most Recent Lead Source
            DoNotSyncToMarketo__c = false,                      // DoNotSyncToMarketo
            Invalid_Email__c = false,                           // Invalid Email
            Use_Alt_Email_for_Case__c = false,                  // Use Alt Email for Case
            Sonian_Admin__c = false,                            // Sonian Admin
            BU_Manger_Contact__c = false,                       // Campus Manager
            Primary_Backup_Technician__c = false,               // Primary Backup Tech
            Do_Not_Send_Support_Survey__c = false,              // Do Not Send Support Survey
            Primary_FW_Tech__c = false,                         // Primary FW Tech
            Lastname= 'TYEST'
        );
        insert mContact;
        
        Pricebook2 priseBook = new Pricebook2(
            Name = 'Standard Price Book',           // Price Book Name
            Description = 'ID:  01sf2000002YVy2AAG',  // Description
            IsActive = true,                          // Active
            ExtId__c = 'Standard Price Book'         // ExtId
        );
        insert priseBook;
        
        Address__c addressBill = new Address__c(
            Primary__c = true,               // Primary
            City__c = 'San Francisco',       // City
            Zip_Postal_Code__c = '94107',    // Zip/Postal Code
            Account__c = acc1.id,  // Account
            Type__c = 'Billing'             // Type
        );
        insert addressBill;
        
        Address__c addressShip = new Address__c(
            Primary__c = true,               // Primary
            City__c = 'San Francisco',       // City
            Zip_Postal_Code__c = '94107',    // Zip/Postal Code
            Account__c = acc1.id,  // Account
            Type__c = 'Shipping'            // Type
        );
        insert addressShip;
        
        Opportunity opp = new Opportunity(
            Name = 'salesforce - Deal Registration Opportunity',         // Opportunity Name
            CloseDate = Date.today().addDays(1),                       // Close Date
            AccountId = acc1.id,                               // Account Name
            StageName = 'Accepted',                                      // Stage
            Business_Group__c = 'Core',                                  // Business Group
            Probability = 2,                                             // Probability (%)
            ForecastCategoryName = 'Pipeline',                           // Forecast Category
            LeadSource = 'Paid Search',                                  // Lead Source
            Primary_Product_Family_2__c = 'Barracuda Reporting Server',  // Primary Product Family
            Model_Series__c = 'BRS600a',                                 // Model Series
            Primary_Contact__c = mContact.id,                      // Primary Contact
            Migration__c = false,                                        // Migration
            Order_In_House__c = false,                                   // Order In-House
            Technical_Win__c = false,                                    // Technical Win
            Deal_Exception_Approval__c = false,                          // Deal Exception Approval
            Legacy_Data__c = false,                                      // Legacy Data
            Trigger_Quote_Update__c = false,                             // Trigger Quote Update
            Distributor_Override__c = false,                             // Distributor Override
            Bill_To_Account__c = acc1.id,                      // Bill To Account
            Focus_Partner_Checkbox__c = false,                           // Focus Partner (Opp Closed)
            Nationwide_for_Channel_Comms_checkbox__c = false,            // Nationwide Channel Comms (Opp Closed)
            POC_Deployment_Type__c = 'Development',                      // POC Deployment Type
            Tech_Issues__c = false,                                      // Tech Issues
            SE_Notes__c = '\n',                                          // SE Notes / Next Steps
            Customer_Dependent__c = false,                               // Customer Dependent?
            MSP_Agreement_Territory_Approval__c = 'Not Required',        // MSP Agreement Territory Approval
            City__c = 'San Francisco',                                   // Billing City
            Zip_Postal_Code__c = '94107',                                // Billing Zip/Postal Code
            Ship_To_City__c = 'San Francisco',                           // Ship To City
            Ship_To_Zip_Postal_Code__c = '94107',                        // Ship To Zip/Postal Code
            Ship_To_Account__c = acc1.id,                      // Ship To Account
            SBQQ__Ordered__c = false,                                    // Ordered
         //   Auto_Renewal_Eligible__c = false,                            // Auto Renewal Eligible
            Kickback__c = false,                                         // Kickback
            RightOfReturn__c = '30 Days',                                // Right Of Return
            Payment_Terms__c = 'Net 30',                                 // Payment Terms
            Pricebook2Id = priseBook.id,                                 // Price Book
            Bypass_Validation__c = false,                                // Bypass Validation
            Has_Contract_Error__c = false,                               // Has Contract Error
            Billing_Address__c = addressBill.id,                      // Billing Address
            Shipping_Address__c = addressShip.id                              // Opportunity Record Type
        );
        insert opp;
        
        
    }
    
    @isTest static void myUnitTestPositive() {
        Account acc1 = [Select id from Account where name = 'salesforce' limit 1][0];
        Contact mContact = [Select id from Contact where AccountId =: acc1.id limit 1][0];
        Compliance_Log__c sobj = new Compliance_Log__c(
            Log_Account__c = acc1.id,                                                                                                                                                                                                                                                                                                                                                                   // Log Account
            Event__c = 'Contact Update',                                                                                                                                                                                                                                                                                                                                                                            // Event
            Max_Hits_Surpassed__c = false,                                                                                                                                                                                                                                                                                                                                                                          // Max Hits Surpassed
            Result__c = '{"result": "FAILURE","message": "Some Error Message from Record FSD2434F."}',  // Result
            Record_ID__c = mContact.id                                                                                                                                                                                                                                                                                                                                                                   // Record ID
        );
        insert sobj;
        
        Opportunity opp = [Select id from Opportunity where AccountId =: acc1.id][0];
        
        Test.startTest();
        ComplianceDPLCheckController.getRecords(opp.id,'ComplianceFields');
        Test.stopTest();
    }
    
    @isTest static void myUnitTestNegative() {
        
        Account acc1 = [Select id from Account where name = 'salesforce' limit 1][0];
        Contact mContact = [Select id from Contact where AccountId =: acc1.id limit 1][0];
        Opportunity opp = [Select id from Opportunity where AccountId =: acc1.id][0];
        Compliance_Log__c sobj = new Compliance_Log__c(
            Log_Account__c = acc1.id,                                                                                                                                                                                                                                                                                                                                                                   // Log Account
            Event__c = 'Contact Update',                                                                                                                                                                                                                                                                                                                                                                            // Event
            Max_Hits_Surpassed__c = false,                                                                                                                                                                                                                                                                                                                                                                          // Max Hits Surpassed
            Result__c = '{"result": "SUCCESS","message": "Some Error Message from Record FSD2434F."}',  // Result
            Record_ID__c = mContact.id                                                                                                                                                                                                                                                                                                                                                                   // Record ID
        );
        insert sobj;
        
        Test.startTest();
        ComplianceDPLCheckController.getRecords(opp.id,'ComplianceFields');
        Test.stopTest();
    }
}