public with sharing class BypassAutomationUtility {

     public static Boolean isCaseTriggerBypassed() {
        Bypass_Automation_Settings__c settings = Bypass_Automation_Settings__c.getInstance();
        return settings.BypassCaseTrigger__c;
    }

    public static Boolean isEmailMessageTriggerBypassed() {
        Bypass_Automation_Settings__c settings = Bypass_Automation_Settings__c.getInstance();
        return settings.BypassEmailMessageTrigger__c;
    }

   
}