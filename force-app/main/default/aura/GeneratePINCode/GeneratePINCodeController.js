/*
 * @author Abi A - 5/1/2019
 * 
*/
({
	generatePINCode : function(component, event, helper) {
		
        //This is how the Javascript controller gets the record ID
        var id = component.get("v.recordId");
        
        //This is how the Javascript controller gets the function from the Apex controller
        //The component works like a bridge between the Javascript controller and the Apex controller
        var action = component.get("c.getRandomUniquePIN");
        
        //Set the parameters of the Apex controller function
        //The parameter name must be exactly the same as in the Apex controller
        action.setParams({
            "nocSiId" : id
        });
        
        //This defines what to do when the response from the Apex controller is received.
        action.setCallback(this,
            //We define what to do inside a function that gets the response from the Apex controller as a parameter
            function(response){
                //This saves the state of the response (successful or not).
            	var state = response.getState();
            	if(state === "SUCCESS") {

                    //This sets the object of the response in the component
                    component.set("v.result", response.getReturnValue());
                    
                    //Now that the result we got from the server is saved in the component,
                    //we get it from the component to use its data.
                    var result = component.get("v.result");
                    
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title" : "Success",
                        "message" : result,
                        "type" : "success"
                    });
                    resultsToast.fire();
                	var refreshPageAction = $A.get("e.force:refreshView").fire();
                	var closeModalAction = $A.get("e.force:closeQuickAction").fire();
            	}else{
                    //This is a common way to handle possible errors.
                	var errors = response.getError();
                    if(errors){
                        if(errors[0] && errors[0].message){
                            console.log("Error Message: " + errors[0].message);
                        }else{
                            console.log("Unknown error");
                        }
                    }
            	}
        	}
        );
        //This executes the function in the APEX controller
        $A.enqueueAction(action);
	},
    
     cancel : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
    
})