/**
* @author        Ivan Yeung/salesforce services
* @date          2018-10-15
* @description   Unit Test class for Test Data Factory
* @group         Test
*
*/
@isTest
public with sharing class WebIntegrationControllerTest {

    @isTest static void unitTestDealRegSuccess() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Opportunity> opportunities  = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        WebIntegrationController.WebDTO wto = WebIntegrationController.getDealRegURL(TestDataFactory.opportunities[0].Id, 'Comments');


        // submit approval
        List <Web_Integration_Setting__mdt> setting = [select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName , Approval_Process__c, Custom_Permission__c, Failure_Message__c, Success_Message__c from Web_Integration_Setting__mdt
        where DeveloperName = 'Deal_Reg'];
        if (setting.size() > 0){
            String approvalErr = WebIntegrationController.sumitDealRegApproval(TestDataFactory.opportunities[0].Id, setting[0].Approval_Process__c, 'Test');
        }


    }

    @isTest static void unitTestDealRegFail() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Opportunity> opportunities  = TestDataFactory.opportunities; // to do: create partner contacts
        TriggerHandler.clearAllBypasses();


        opportunities[0].Model_Series__c = null;  // set to null
        update opportunities[0];


        WebIntegrationController.WebDTO wto = WebIntegrationController.getDealRegURL(TestDataFactory.opportunities[0].Id, 'Comments');


    }

    @isTest static void unitTestOpptyCreditCard() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Opportunity> opportunities  = TestDataFactory.opportunities; // to do: create partner contacts
        TriggerHandler.clearAllBypasses();


        WebIntegrationController.WebDTO wto = WebIntegrationController.getCreditCardURL(TestDataFactory.opportunities[0].Id);

    }


    @isTest static void unitTestAccountCreditCard() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Account> partners  = TestDataFactory.partners;
        TriggerHandler.clearAllBypasses();


        WebIntegrationController.WebDTO wto = WebIntegrationController.getCreditCardURL(TestDataFactory.partners[0].Id);


    }


    @isTest static void unitTestBOSTool() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Order> orders = TestDataFactory.orders;
        TriggerHandler.clearAllBypasses();

        WebIntegrationController.WebDTO wto = WebIntegrationController.getBOSOrderURL(TestDataFactory.orders[0].Id);


    }
}