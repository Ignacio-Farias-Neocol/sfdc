({
	doInit : function(component, event, helper) {
        console.log('##recordId:: ' + component.get("v.recordId"));
        var action = component.get("c.checkIfDuplicate");
        action.setParams({ recordId :  component.get("v.recordId")});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('##responseFromServer:: ' + JSON.stringify(response.getReturnValue()));
                component.set("v.hasDuplicates", response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
                helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    console.log('##errors:: ' + JSON.stringify(errors));
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