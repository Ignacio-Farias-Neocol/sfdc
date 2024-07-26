trigger EmailMessageTrigger on EmailMessage (before insert, before update, after insert, after update, after delete) {
   
    new EmailMessageTriggerHandler().run();
    
}