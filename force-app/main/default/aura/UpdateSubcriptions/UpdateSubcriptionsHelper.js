({
	getReasons : function(component, event, helper) {
        var action = component.get('c.getAnnoReasons');
        action.setParams({});
         action.setCallback(this,function(res){
             if (res.getState() === 'SUCCESS') {
                 component.set("v.reasons", res.getReturnValue());
                 console.log(res.getReturnValue());
             }
         });
        $A.enqueueAction(action);
    }
})