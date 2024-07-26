trigger DnBConnectCompanyRecord on DNBConnect__D_B_Connect_Company_Profile__c (before insert, before update, after insert, after update, after delete, after undelete) {
  new DnBCompanyTriggerHandler().run();
}