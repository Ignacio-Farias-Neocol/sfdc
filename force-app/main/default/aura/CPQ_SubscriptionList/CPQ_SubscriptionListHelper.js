({
    getSubscriptions : function(component, event, helper, recordId) {
        if ($A.util.isEmpty(recordId)) {
            return;
        }
        
        component.set("v.inprogress", true);
        
        var getSubscriptions = component.get("c.retrieveSubscriptions");
        getSubscriptions.setParams({
            "inputrecordId": recordId
        });
        
        getSubscriptions.setCallback(this, function(response) {
            component.set("v.inprogress", false);
            
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                if (!$A.util.isEmpty(result.errorMsg)) {
                    helper.showToast(component, event, helper, result.errorMsg);
                } else {
                    component.set('v.primaryQuoteId', result.primaryQuoteId);
                    component.set('v.record', result.record);
                    
                    var renewedSubscriptions = result.renewedSubscriptions;
                    var upgradedSubscriptions = result.upgradedSubscriptions;
                    
                    if (!$A.util.isEmpty(renewedSubscriptions)) {
                        component.set('v.gridColumns', renewedSubscriptions.columns);
                        component.set('v.gridData', renewedSubscriptions.gridData);
                    }
                    
                    if (!$A.util.isEmpty(upgradedSubscriptions)) {
                        component.set('v.gridColumns2', upgradedSubscriptions.columns);
                        component.set('v.gridData2', upgradedSubscriptions.gridData);
                    }
                }
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(getSubscriptions);
    },
    
    showToast : function(component, event, helper, errorMsg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "duration": "10000",
            "message": errorMsg
        });
        toastEvent.fire();
    }
})