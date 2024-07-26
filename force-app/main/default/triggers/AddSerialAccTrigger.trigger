TRIGGER AddSerialAccTrigger on Additional_Serial_Access__c (Before Insert, Before Update, After Insert, After Update) {
    //Call AddSerialAccTriggerHandler class.
    new AddSerialAccTriggerHandler().run();
}