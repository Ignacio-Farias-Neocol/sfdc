({
    init : function (component, event) {
        var myAction = component.get("c.checkClonePermission");
        myAction.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                component.set("v.hasPermission", response.getReturnValue());
                if(response.getReturnValue() === true) {
                    // Find the component whose aura:id is "flowData"
                    var flow = component.find("flowData");
                    var inputVariables = [
                        {
                            name: 'Orig_Opportunity_Id',
                            type: 'String',
                            value: component.get("v.recordId")
                        }
                    ];
                    flow.startFlow("Clone_Opportunity", inputVariables);
                }
            }});
        $A.enqueueAction(myAction);
    },

    handleStatusChange : function (component, event) {
        if(event.getParam("status") === "FINISHED_SCREEN") {
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                if(outputVar.name === "Cloned_Opportunity_Id") {
                    var urlEvent = $A.get("e.force:navigateToSObject");
                    urlEvent.setParams({
                        "recordId": outputVar.value,
                        "isredirect": "true"
                    });
                    urlEvent.fire();
                }
            }
        }
	}
})