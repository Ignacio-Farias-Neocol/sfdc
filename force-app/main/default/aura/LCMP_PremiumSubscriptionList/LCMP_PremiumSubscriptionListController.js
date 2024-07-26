({
	doInit : function(component, event, helper) {
        var recordId;
        
        var myPageRef = component.get("v.pageReference");
        if (myPageRef != undefined)
            recordId = myPageRef.state.c__recordId;
        else 
            recordId = component.get("v.recordId");
        
        helper.getSubscriptions(component, event, helper, recordId);
    },
    
    openFullList : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/cmp/c__LCMP_PremiumSubscriptionList?c__recordId=" + recordId
        });
        urlEvent.fire();
    },
    
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    }    
})