({
    doInit: function(cmp, event, helper) {

        var action= cmp.get("c.updateHotList");
        action.setParams({ recordId : cmp.get("v.recordId") });
        //$A.get("e.force:refreshView").fire();
        
        action.setCallback(this,function(response){
            var state= response.getState();
              //$A.log(response);
            if(state == "SUCCESS"){
                
                /* navigateToSObject doesn't currently provide a refresh of the data 01/2019
                var navEvt = $A.get("e.force:navigateToSObject");
		        navEvt.setParams({
		            "recordId": response.getReturnValue(),
		            "slideDevName": "detail"
		        });  
		        setTimeout(
		            $A.getCallback(function() {
		                //navEvt.fire();
		                window.location.href = '/'+response.getReturnValue();
		        	}),1500 // waits 1.5 seconds
		        );
                */
                cmp.find("navigationService").navigate({ 
                    "type": "standard__recordPage",
                    "attributes": {
                        "recordId": response.getReturnValue(),
                        "objectApiName": "Lead",
                        "actionName": "view"
                    }    
                });

                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title" : "Success",
                    "message" : "Hot List has been marked primary. Please convert the Lead.",
                    "type" : "success"
                });
                resultsToast.fire();
            }
        });
        $A.enqueueAction(action);
    },

    cancel : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})