({
	doInit : function(component, event, helper) {
        var cmpTarget = component.find('spinner');
        $A.util.removeClass(cmpTarget, 'slds-hide'); 
        $A.util.addClass(cmpTarget, 'slds-show');        
        var action = component.get("c.takeOwnership");
        action.setParams({ taskId :  component.get("v.recordId")});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            $A.util.addClass(cmpTarget, 'slds-hide'); 
            $A.util.removeClass(cmpTarget, 'slds-show');
            if (state === "SUCCESS") {
                var returnMap = response.getReturnValue();
                console.log('##returnMap:: ' + JSON.stringify(returnMap));
                if(returnMap.isSuccess == 'true'){
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    helper.notificationHelper(component, "error", returnMap.errorMessage, "Please contact Admin");
                }
            }
            else if (state === "INCOMPLETE") {
                helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            helper.notificationHelper(component, "error", "Error initializing the component : ", errors[0].message);
                        }
                    } else {
                        helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                    }
                }
        });
        
        $A.enqueueAction(action);   
	}
})