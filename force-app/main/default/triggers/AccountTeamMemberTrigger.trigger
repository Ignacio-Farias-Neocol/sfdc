trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, before update, after insert, after update, after delete, after undelete) {
  new AccountTeamMemeberTriggerHandler().run();
}