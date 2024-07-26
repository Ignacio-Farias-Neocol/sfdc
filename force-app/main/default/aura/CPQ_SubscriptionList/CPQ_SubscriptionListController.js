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
    
    openLineEditor : function(component, event, helper) {
        var primaryQuoteId = component.get("v.primaryQuoteId");
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/apex/SBQQ__sb?id=" + primaryQuoteId
        });
        urlEvent.fire();
    },
    
    openFullList : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/lightning/cmp/c__CPQ_SubscriptionList?c__recordId=" + recordId
        });
        urlEvent.fire();
    }
})