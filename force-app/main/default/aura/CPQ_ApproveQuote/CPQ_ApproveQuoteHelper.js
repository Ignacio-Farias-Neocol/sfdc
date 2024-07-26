({
    approve : function(component, event, helper) {
        component.set("v.inprogress", true);
        
        var recordId = component.get("v.recordId");
        
        var approve = component.get("c.approve");
        approve.setParams({
            "recordId": recordId
        });
        
        approve.setCallback(this, function(response) {
            component.set("v.inprogress", false);
            
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                
                if (!$A.util.isEmpty(result)) {
                    alert(result);
                }
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail",
                    "isredirect": "false"
                });
                navEvt.fire();
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(approve);
    }
})