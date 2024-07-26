@isTest
public class BCCEmailUserHandlerTest {
    @testSetup
    public static void setRecord(){
        
        Profile prfile = [select Id,name from Profile where  name='System Administrator' limit 1];
        
        User newUser1 = new User(
            profileId = prfile.id,
            username = 'newUsertestt@yahoo.com' + System.currentTimeMillis(),
            email = 'pb@f.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuser',
            lastname='lastname'
        );
        insert newUser1; 
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Edit_State_Country_Territory_Data'];
        insert new PermissionSetAssignment(AssigneeId = newUser1.id, PermissionSetId = ps.Id);
        
    }
    
    @isTest
    public static void insertAddtionCase(){
        
         User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
        Test.startTest();   
        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        TriggerContextVariables.RUN_CASE_TRIGGER = false;
        List <Case> l = TestDataFactory.webCases;
        TriggerHandler.clearAllBypasses();
        
        Case_Additional_Info__c caI=new Case_Additional_Info__c();
        caI.Case__c=l[0].Id;
        caI.Bcc_User_Emails__c='abc@gmail.com';
        insert caI;
            Test.stopTest();
        }
    }
}