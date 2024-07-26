trigger CaseAddtionalTrigger on Case_Additional_Info__c  (after insert,after update) {
  if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    BCCEmailUserHandler.publishBCCEmailEvent(Trigger.new,Trigger.OldMap); 
}