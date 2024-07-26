({
    openContactModal : function(component, event, helper) {
        alert('In Child Component::'+ component.get('v.currentUserAccountId'));  
        var flow = component.find("flowData");
        component.set("v.showButton",false);
        //Input variable for Flow
        var inputVariables = [
            { name : "recordId", type : "String", value: component.get("v.currentUserAccountId") }
            
        ];
        flow.startFlow("Create_Contact_Community_Users_New_screen_flow",inputVariables);
    },
    
    doInit: function(component, event, helper){
     //   alert('In Child Component::'+ component.get('v.currentUserAcctId'));  
        const flow = component.find("flowData");
      var inputVariables = [
            { name : "recordId", type : "String", value: component.get("v.currentUserAcctId") }
            
        ];
        flow.startFlow("Create_Contact_Community_Users_New_screen_flow",inputVariables);
    },
closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            var compEvent = component.getEvent("flowFinishedEvent");
            compEvent.setParams({
            "message" : 'false' 
        });
        compEvent.fire();
        }
    }
})