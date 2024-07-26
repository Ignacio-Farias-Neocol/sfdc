({
    closeModal : function(component, event, helper) {
        console.log('Event Aura');

        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();
       
    }
})