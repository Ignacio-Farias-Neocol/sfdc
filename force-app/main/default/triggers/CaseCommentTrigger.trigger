trigger CaseCommentTrigger on CaseComment (before insert) {

     new CaseCommentTriggerHandler().run();
}