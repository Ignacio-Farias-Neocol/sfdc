({
    doInit : function(component, event, helper) {
        debugger;
        var createRecordEvent = $A.get("e.force:createRecord");
        let accountId = component.get('v.accountId');
        let contactId = component.get('v.contactId');
        if(accountId != undefined && accountId != '' && accountId.startsWith('001')){
            createRecordEvent.setParams({
                "entityApiName": "Case",
                "recordTypeId" : component.get('v.recordTypeId'),
                "defaultFieldValues": {
                    "AccountId" : accountId
                }
                
            });
        }else if(contactId != undefined && contactId != '' && contactId.startsWith('003')){
            createRecordEvent.setParams({
                "entityApiName": "Case",
                "recordTypeId" : component.get('v.recordTypeId'),
                "defaultFieldValues": {
                    "ContactId" : contactId
                }
            });
        }
        
        createRecordEvent.fire();
    }
})