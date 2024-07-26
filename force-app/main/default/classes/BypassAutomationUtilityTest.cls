@isTest
public class BypassAutomationUtilityTest {

   @isTest
    public static void utilitTest(){
        
        
        Bypass_Automation_Settings__c setting=new Bypass_Automation_Settings__c(name='triggerBypass',BypassEmailMessageTrigger__c=false,BypassCaseTrigger__c=false);
        insert setting;
        Test.startTest();
        BypassAutomationUtility.isCaseTriggerBypassed();
        BypassAutomationUtility.isEmailMessageTriggerBypassed();
        Test.StopTest();
    }
}