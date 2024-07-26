({
    handleChange : function(component, event, helper) {
        var changeElement = component.find("DivOps");
        $A.util.toggleClass(changeElement, "slds-hide");
    },
    handleLoad: function(cmp, event, helper) {
        //cmp.set('v.showSpinner', false);
    },

    handleSubmit: function(cmp, event, helper) {
        cmp.set('v.disabled', true);
        //cmp.set('v.showSpinner', true);
    },

    handleError: function(cmp, event, helper) {
        // errors are handled by lightning:inputField and lightning:nessages
        // so this just hides the spinner
        //cmp.set('v.showSpinner', false);
    },

    handleSuccess: function(cmp, event, helper) {
        //cmp.set('v.showSpinner', false);
        cmp.set('v.saved', true);

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been Saved successfully.",
            "type": "success!"
        });
        toastEvent.fire();

        $A.get("e.force:closeQuickAction").fire();

    },
    showSpinner: function(cmp, event, helper) {
        cmp.set("v.showSpinner", true); 
    },
    hideSpinner : function(cmp,event,helper){
        cmp.set("v.showSpinner", false);
    },
    handleCancel : function(cmp, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})