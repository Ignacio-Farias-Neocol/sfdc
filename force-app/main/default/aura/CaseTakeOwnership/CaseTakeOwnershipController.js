/*
 * @author IY 5/14/2019
 *
*/
({
    takeCaseOwnership : function(component, event, helper) {
        
        var caseRecord = component.get("v.caseRecord");
        console.log('##recordLoadError:: ' + component.get("v.recordLoadError"));
        console.log('##recordId:: ' + component.get("v.recordId"));
        console.log('##caseRecord::' + JSON.stringify(caseRecord));
        if(caseRecord.RecordType.DeveloperName == 'Technical_Support' && (caseRecord.Product_Family_List__c == 'Sonian' || 
           caseRecord.Product_Family_List__c == 'Barracuda Total Email Protection' ||
           caseRecord.Product_Family_List__c == 'Essentials') && 
           $A.util.isUndefinedOrNull(caseRecord.Pick_Product_only_if_Essentials__c)){
            	helper.notificationHelper(component, "error", "Pick Product is required", "Pick Product is required to Move or begin work on case.");
            	return;            
        }

        component.set("v.isDataLoading", true); // set hourglass
        component.set("v.status", "true");

        //This is how the Javascript controller gets the record ID
        var id = component.get("v.recordId");

        //This is how the Javascript controller gets the function from the Apex controller
        //The component works like a bridge between the Javascript controller and the Apex controller
        var action = component.get("c.changeOwner");

        //Set the parameters of the Apex controller function
        //The parameter name must be exactly the same as in the Apex controller
        action.setParams({
            "caseId" : id
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
                    component.set("v.status", "true");

                    // alert(response.getReturnValue());
                    $A.get('e.force:refreshView').fire();


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

                component.set("v.isDataLoading", false); // reset hourglass

            }
        );
        //This executes the function in the APEX controller
        $A.enqueueAction(action);
    },  
})