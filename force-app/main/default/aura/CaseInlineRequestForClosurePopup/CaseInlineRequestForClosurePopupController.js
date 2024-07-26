({
    doInit: function(component) {
        console.log('caseId in popup:: ' + component.get("v.recordId"));   
        var action = component.get("c.getPicklistValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('##response:: ' + JSON.stringify(response.getReturnValue()));
				component.set("v.options", response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
                // do something
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
    },
    
   closeModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
      $A.get('e.force:refreshView').fire();
   },   
    
   openModel: function(component, event, helper) {
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", true);
       console.log('##isModelOpen:: ' + component.get("v.isModalOpen"));
   },     
    
   submitDetails: function(component, event, helper) {       
       var reason = component.find("reason").get("v.value");
       var comment = component.find("comment").get("v.value");
       console.log('##reason:: ' + reason);
       console.log('##comment:: ' + comment);
       
       if($A.util.isUndefinedOrNull(reason)){
           component.set("v.errorMessage", 'Please enter Community Request Close Reason');
           return;
       } 
       
       if($A.util.isUndefinedOrNull(comment)){
           component.set("v.errorMessage", 'Please enter Close Reason Comments');
           return;
       }           
       
       //var cmpTarget = component.find('spinner');
       //$A.util.addClass(cmpTarget, 'slds-show');       
       //$A.util.removeClass(cmpTarget, 'slds-hide');       
        var action = component.get("c.updateCase");
        action.setParams({ reason : reason,
                           comment : comment,
                           recordId : component.get("v.recordId")});
 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('##response:: ' + JSON.stringify(response.getReturnValue()));
                //$A.util.addClass(cmpTarget, 'slds-hide');       
                //$A.util.removeClass(cmpTarget, 'slds-show');                 
                component.set("v.showSuccessMessage", true);
            }
            else if (state === "INCOMPLETE") {
                // do something
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
   },   
    
   showSuccess: function(component, event, helper) {
       	component.set("v.showSuccessMessage", true);
   },         
})