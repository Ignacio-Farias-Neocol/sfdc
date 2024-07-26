({
	init : function(component, event, helper) {
        helper.getSubscriptionsHelper(component, event, helper);
        helper.getSerialHelper(component, event, helper);
	},  
    
	openModel : function(component, event, helper) {
		component.set("v.isModalOpen", true);        
        component.set('v.columns', [
            {label: 'Serial Number', fieldName: 'Serial_Number__c', type: 'text'},
            {label: 'Subscription', fieldName: 'subscriptionLink', type: 'url', typeAttributes: {label: { fieldName: 'SubscriptionNumber' }, target: '_blank'}},
            {label: 'Subscription Name', fieldName: 'SubscriptionName', type: 'text'},
            {
                label: 'Subscription End Date',
                fieldName: 'SubscriptionEndDate',
                type: 'date',
                typeAttributes: {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                }
            }
        ]);    
        
        helper.openModelHelper(component, event, helper);
	},
    
	closeModel : function(component, event, helper) {
		component.set("v.isModalOpen", false);
	},    
    
	handleKeyUp : function(component, event, helper) {
		
	},
    
    updateSelectedText: function (cmp, event) {
        if(cmp.get("v.isSerialMadeNull")){
            return;
        }
        console.log('##updateSelectedText');
        var selectedSerialId = cmp.get("v.selectedSerialId");
        var selectedSubscriptions = cmp.get("v.selectedSubscriptions");
        var refinedSubs = [];
        selectedSubscriptions.forEach(function(sub){
            if(sub.Serial__c != selectedSerialId) refinedSubs.push(sub);
        });
        selectedSubscriptions = refinedSubs;
        var selectedRecords = event.getParam('selectedRows');
        var selectedRows = [];
        selectedRecords.forEach(function(rec){
            selectedSubscriptions.push(rec);
            selectedRows.push(rec.Id);
        });
        cmp.set("v.selectedRows", selectedRows);
        cmp.set("v.selectedSubscriptions", selectedSubscriptions);
        console.log('##selectedRecords:: ' + JSON.stringify(selectedRows));
    },

	submitDetails : function(component, event, helper) {
		helper.submitDetailsHelper(component, event, helper);
	}, 
    
	onSerialChange : function(component, event, helper) {
		var lookupId = event.getParam("value")[0];
        if(lookupId == null || lookupId == ''){
            component.set("v.isSerialMadeNull", true);
        } else {
            component.set("v.isSerialMadeNull", false);
        }
        component.set("v.selectedSerialId", lookupId);
        console.log('##lookupId:: ' + lookupId);
        helper.openModelHelper(component, event, helper);
	},     
})