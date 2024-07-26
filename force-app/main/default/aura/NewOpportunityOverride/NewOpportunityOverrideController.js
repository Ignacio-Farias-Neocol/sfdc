({  
    doInit: function(component, event, helper) {
        
        var myAction = component.get("c.checkNewOppPermission");
        myAction.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {

                if(response.getReturnValue() === true) {
                    // Navigate to standard create oppty page
                    var pageReferenceNew = {
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Opportunity',
                            actionName: 'new'
                        },
                        "state": {
                            nooverride: "1"
                        }
                    };
                    var navServiceNew = component.find("navService");
                    navServiceNew.navigate(pageReferenceNew);

                } else {

                    // Show toast error message
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "All opportunities need to start as a hot list.",
                        "message": "Please create and convert a hot list from the customer contact or lead you are working with.",
                        "type": "Error",
                        "mode": "sticky",
                        "duration": 8000,
                        "key": "reject"
                    });
                    toastEvent.fire();

                    //Navigate to standard oppty homepage
                    var pageReference = {
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Opportunity',
                            actionName: 'home'
                        }
                    };
                    var navService = component.find("navService");
                    navService.navigate(pageReference);
                }
            }
        });
        $A.enqueueAction(myAction);
    }
})