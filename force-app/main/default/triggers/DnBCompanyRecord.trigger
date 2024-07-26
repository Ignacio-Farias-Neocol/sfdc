trigger DnBCompanyRecord on DNBoptimizer__DnBCompanyRecord__c (before insert, before update, after insert, after update, after delete, after undelete) {
  new DnBCompanyTriggerHandler().run();
}