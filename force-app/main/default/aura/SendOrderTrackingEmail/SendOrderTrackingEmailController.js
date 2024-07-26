({
    sendEmail : function(component, event, helper) {
        var username = component.get("v.userName");
        if(username != null){
            console.log(username);
            var action = component.get("c.sendEmailMessge");
            action.setParams({
                "userName" : username,
                "recordId"  : component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                if(response.getState()==='SUCCESS'){
                    var result = response.getReturnValue();
                    if (result != null) {
                        component.set("v.result", result);
                        console.log('result--'+result.message);
                    }
                }
             });
            $A.enqueueAction(action);
        } else{
            component.set("v.result", "Plese enter user Name or Email");
        }
    }
})