({
    getAlerts : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        var getAlerts = component.get("c.retrieveAlerts");
        getAlerts.setParams({
            "recordId": recordId
        });
        
        getAlerts.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                
                if ($A.util.isEmpty(result.errorMsg)) {
                    if (result.alertIncreaseQtyOnRenewalQuote == true)
                        helper.showIncreaseQtyOnRenewalQuoteToast(component, event, helper);
                    if (result.alertSubscriptionAlreadyRenewed == true)
                        helper.showSubAlreadyRenewedToast(component, event, helper);
                    if (result.alertOtherAmendmentQuote == true)
                        helper.showOtherAmendmentQuoteToast(component, event, helper);
                    if (result.alertConflictingVOL == true)
                        helper.showConflictingVOLToast(component, event, helper);
                }
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(getAlerts);
    },
    
    showIncreaseQtyOnRenewalQuoteToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "warning",
            "duration": "10000",
            "message": "The quantity on this quote has been increased. if this order is placed prior to the expiration date the customer will be receiving free services for the increased number of seats until expiration of the initial contract."
        });
        toastEvent.fire();
    },
    
    showSubAlreadyRenewedToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "warning",
            "duration": "10000",
            "message": "You cannot close win this opportunity. One or more of the subscriptions on the Primary Quote have already been renewed or are associated with multiple line items in the quote. Please double check your subscriptions have not already been renewed, or ensure that you have one of your quote options marked as optional. You can see this by looking at the subscription record in the Renewed by Subscription field."
        });
        toastEvent.fire();
    },
    
    showConflictingVOLToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "warning",
            "duration": "10000",
            "message": "You cannot close win this opportunity. Primary Quote contains multiple VOLs or VOLs conflicting with the active VOLs on the account."
        });
        toastEvent.fire();
    },

    showOtherAmendmentQuoteToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "warning",
            "duration": "10000",
            "message": "There may be a newer amendment quote in the current oppotunity."
        });
        toastEvent.fire();
    }
})