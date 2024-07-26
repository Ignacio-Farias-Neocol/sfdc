({
	doInit : function(component, event, helper) {
        if(component.get("v.fieldSetName")){
            component.set("v.isFieldSetDefined",true);
            
            component.set("v.columns", [
                                        {
                                            label: "Name", 
                                            fieldName: "name", 
                                            type: "text"
                                        },
                						{	label: "DPL Error Message", 
                                         	fieldName: "errorMessage", 
                                         	type: "text"
                                        }
            ]);
            
            var action = component.get("c.getRecords");
            
            action.setParams({ recordId : component.get("v.recordId") , fieldSetName : component.get("v.fieldSetName")});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('RESPONSE:::',response.getReturnValue());
                    if(response.getReturnValue()){
                        component.set('v.data',response.getReturnValue());
                    }
                } else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.isFieldSetDefined",false);
        }
	}
})