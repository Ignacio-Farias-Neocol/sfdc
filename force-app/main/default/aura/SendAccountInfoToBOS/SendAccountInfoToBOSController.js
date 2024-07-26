({
	sendAccount: function(component, event, helper) {
		helper.connectToBOS(component, event, helper);
    },

    cancel : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})