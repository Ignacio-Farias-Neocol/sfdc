({
    doInit : function(component, event, helper) {
        console.log(component.get('v.message')); 
        var action = component.get("c.setWarningOnQuote");
        action.setParams({ quoteId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var msg = response.getReturnValue();
                console.log('res '+msg);
                if(msg !== ''){
                   component.set('v.message',msg); 
                } 
            }
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    }
})