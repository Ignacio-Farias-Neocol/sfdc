({
    doInit: function(component, event, helper) {
        var action = component.get("c.getCommunityBaseUrl"); 
        action.setCallback(this, function(a) {
            component.set("v.siteUrl", a.getReturnValue()); 
        })
        $A.enqueueAction(action); 
    }
})