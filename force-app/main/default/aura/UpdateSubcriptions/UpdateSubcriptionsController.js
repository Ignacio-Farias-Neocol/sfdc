({
    doInit : function(component, event, helper) {
        helper.getReasons(component, event, helper);
        var quoteId = component.get("v.recordId");
        var subscriptions = component.get("v.subscriptions");
        
        var action = component.get('c.getSubscriptions');
        action.setParams({
            quoteId : quoteId
        });
        action.setCallback(this,function(res){
            if (res.getState() === 'SUCCESS') {
                subscriptions = res.getReturnValue();
                component.set("v.subscriptions", subscriptions);
            }
        });
        $A.enqueueAction(action); 
    },
    SubmitSubscriptions : function(component, event, helper){
        var subs = component.get("v.subscriptions");
        console.log('subs',subs);
        var action = component.get("c.updateSubscriptions");
        action.setParams({
            upSubscriptions : subs
        });
        action.setCallback(this,function(res){
            if (res.getState() === 'SUCCESS') {
                console.log('subs',res.getReturnValue());
                if(res.getReturnValue() ==null){
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire(); 
                } else {
                    component.set("v.errPresent", true);
                    component.set("v.ErrorMessage", res.getReturnValue());
                }
            }
        });
        $A.enqueueAction(action); 
        
    }
})