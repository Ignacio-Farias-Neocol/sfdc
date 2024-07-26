({
	handleClick : function(component, event, helper) {
		console.log(component.get("v.recordId"));
        console.log(component.find("quickAction").get("v.value"));

        var action = component.get("c.performQuickAction");
        action.setParams({
            "caseId": component.get("v.recordId"), 
            "caseQuickActionButton" : component.find("quickAction").get("v.value")
        });
        action.setCallback(this, function(response) {
           var state = response.getState();
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                // alert("Case comment is added and case status is updated. Please refresh the screen.");
            } else if (state === "INCOMPLETE") {
                // TODO
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message:" + errors[0].message);
                    } else {
                        console.log("Unknown error");
                    }
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    doInit : function(component, event, helper) {
        var action = component.get("c.getCustomButtonActionOptions");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var buttonActions = response.getReturnValue();
                component.set("v.buttonActions", buttonActions);
                window.setTimeout(
                	$A.getCallback( function() {
                    	component.find("quickAction").set("v.value", buttonActions[0].Id);
                    	// show the UI after data is available
                        var cmpTarget = component.find('quickActionContainer');
                        $A.util.removeClass(cmpTarget, 'slds-hide');
                	})
                );

            } else {
                console.log(state);
            }
        });


        /*
        //IY: trying different syntax
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var buttonActions = response.getReturnValue();
                component.set("v.buttonActions", buttonActions);
                component.find("quickAction").set("v.value", buttonActions[0].Id);
            }
        });*/


        $A.enqueueAction(action);
    }
})