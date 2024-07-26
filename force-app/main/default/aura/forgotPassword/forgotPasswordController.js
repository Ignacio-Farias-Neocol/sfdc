({
    handleForgotPassword: function (component, event, helper) {
        helper.handleForgotPassword(component, event, helper);
    },
    onKeyUp: function(component, event, helper){
    //checks for "enter" key
        if (event.getParam('keyCode')===13) {
            helper.handleForgotPassword(component, event, helper);
        }
    },
    
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },

    initialize: function(component, event, helper) {
        if(component.get("v.instance") == 'Partner'){
            component.set("v.context","partners2");
        }else{
            component.set("v.context","customers");
        }
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();
    },
    
    gotoNextStep: function(component, event, helper) {
        component.set("v.isNextStep", true);
    }
})