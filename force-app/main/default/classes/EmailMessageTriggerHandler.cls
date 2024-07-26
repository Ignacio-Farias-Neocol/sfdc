/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 01-31-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class EmailMessageTriggerHandler extends TriggerHandler {
    public override void afterInsert() {    
        System.debug('####afterInsert');
        List<EmailMessage> emList = Trigger.New; 
        //EmailMessageModel.updateCaseEmail(emList);
        //EmailMessageTriggerHelper.updateCaseOwner();
        //EmailMessageTriggerHelper.updateFromAddress(emList);
       if(!BypassAutomationUtility.isEmailMessageTriggerBypassed()){ 
        if(!FlowActionTriggerHandler.isExecutedAfterInsertForEmailMessage){ 
            System.debug('####inside after insert block');
            FlowActionTriggerHandler.process('EmailMessage', 'AfterInsert');
        } 
       }
    }   
    public override void beforeInsert() {
        if(!BypassAutomationUtility.isEmailMessageTriggerBypassed()){  
            if(!FlowActionTriggerHandler.isExecutedBeforeInsertForEmailMessage){ 
            System.debug('####inside before insert block');
        	FlowActionTriggerHandler.process('EmailMessage', 'BeforeInsert');
            }
        }
        
    }   
    
    public override void afterUpdate() {
        List<EmailMessage> emList = Trigger.New; 
        if(!BypassAutomationUtility.isEmailMessageTriggerBypassed()){ 
            FlowActionTriggerHandler.process('EmailMessage', 'AfterUpdate');
        }

       // EmailMessageModel.updateCaseEmail(emList);
    }
}