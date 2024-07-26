({
    openmodal : function(component, event, helper) {
        component.set("v.showModal",true);
        var casedet = component.get("v.caseInfo");
        console.log(JSON.stringify(casedet));
        var flow = component.find("flowData");
        //Input variable for Flow
        var inputVariables = [
            { name : "serialID", type : "String", value: casedet.Serial__c },
            { name : "caseId", type : "String", value: casedet.Id }
            
        ];
        console.log(JSON.stringify(inputVariables));
        flow.startFlow("Pick_Product_Screen_Flow",inputVariables);
    },
    closeModal : function(component, event, helper) {
        component.set("v.showModal",false);
    },
    closeModalOnFinish : function(component, event, helper) {
        if(event.getParam('status') === "FINISHED") {
            component.set("v.showModal",false);
            $A.get('e.force:refreshView').fire();
        }
    }
})