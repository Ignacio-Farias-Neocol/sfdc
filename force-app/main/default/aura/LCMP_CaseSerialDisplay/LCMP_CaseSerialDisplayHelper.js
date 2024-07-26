({
    // notification helper method
    notificationHelper : function(component, variant, title, errMsg) {
        component.find('notifLib').showToast({
            "variant": variant,
            "title": title,
            "message": errMsg
        });  	
    }, 
    
	getSubscriptionsHelper : function(component, event, helper) {
        try {
            console.log('##getSubscriptionsHelper');
            var action = component.get("c.getCaseSubscriptions");
            action.setParams({ caseId :  component.get("v.recordId")});
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {                    
                    component.set("v.caseSubscriptions", response.getReturnValue());
                    component.set("v.selectedSubscriptions", response.getReturnValue());
                    console.log('##caseSubscriptions:: ' + JSON.stringify(component.get("v.caseSubscriptions")));
                }
                else if (state === "INCOMPLETE") {
                    helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                helper.notificationHelper(component, "error", "Error initializing the component : ", errors[0].message);
                            }
                        } else {
                            helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                        }
                    }
            });
            
            $A.enqueueAction(action);   		
            
        } catch (error) {
            console.error(error);
        }        
	}, 
    
    getSerialHelper : function(component, event, helper) {
        try {
            console.log('##getSerialHelper');
            var action = component.get("c.getSerial");
            action.setParams({ caseId :  component.get("v.recordId")});
            
            action.setCallback(this, function(response) {
                console.log('##response:: ' + JSON.stringify(response));
                var state = response.getState();
                if (state === "SUCCESS") {
                    var returnArr = response.getReturnValue();
                    if(returnArr.length > 0){
                        component.set("v.serialRecords", returnArr);
                        console.log('##serialRecord:: ' + JSON.stringify(component.get("v.serialRecords")));   
                        component.set("v.selectedSerialId", returnArr[0].Id);
                    }
                }
                else if (state === "INCOMPLETE") {
                    helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                helper.notificationHelper(component, "error", "Error initializing the component : ", errors[0].message);
                            }
                        } else {
                            helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                        }
                    }
            });
            
            $A.enqueueAction(action);   		
        } catch (error) {
            console.error(error);
        }        	
    },     
    
	openModelHelper : function(component, event, helper) {
        try {
            console.log('##openModelHelper:: ');
            var action = component.get("c.getActiveSubscriptions");
            action.setParams({ serialId :  component.get("v.selectedSerialId")});
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var subsList = response.getReturnValue();
                    subsList.forEach(function(eachRecord){
                        if(eachRecord.Subscription__c != null){
                            eachRecord.SubscriptionNumber = eachRecord.Subscription__r.Name;
                            eachRecord.SubscriptionName = eachRecord.Subscription__r.SBQQ__ProductName__c; 
                            eachRecord.SubscriptionEndDate = eachRecord.Subscription__r.SBQQ__EndDate__c;
                            eachRecord.subscriptionLink = '/' + eachRecord.Subscription__c;
                        }
                    });
                    console.log('##subsList:: ' + JSON.stringify(subsList));
                    component.set("v.data", subsList);
                    var tempArr = [];
                    var caseSubscriptions = component.get("v.caseSubscriptions");
                    caseSubscriptions.forEach(function(rec){
                        tempArr.push(rec.Id);
                    });                    
                    component.set("v.selectedRows", tempArr);                    
                }
                else if (state === "INCOMPLETE") {
                    helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                helper.notificationHelper(component, "error", "Error initializing the component : ", errors[0].message);
                            }
                        } else {
                            helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                        }
                    }
            });
            
            $A.enqueueAction(action);   
        } catch (error) {
            console.error(error);
            // expected output: ReferenceError: nonExistentFunction is not defined
            // Note - error messages will vary depending on browser
        }                		
	},  

	submitDetailsHelper : function(component, event, helper) {
        try {
            console.log('##submitDetailsHelper:: ');
            var selectedSubscriptions = component.get("v.selectedSubscriptions");
            var selectedRows = [];
            selectedSubscriptions.forEach(function(rec){
                selectedRows.push(rec.Id);
            });                        
            console.log('##selectedRows:: ' + JSON.stringify(selectedRows));
            var action = component.get("c.saveSubscriptions");
            action.setParams({ caseId :  component.get("v.recordId"), ids : selectedRows, serialId : component.get("v.selectedSerialId")});
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var responseVal = response.getReturnValue();    
                    if(responseVal.isSuccess == 'true'){
                        helper.notificationHelper(component, "success", "Save successfull", 'updates saved');
                    } else {
                        helper.notificationHelper(component, "error", "Error found", responseVal.errorMessage);
                    }
                    console.log('##responseVal::' + JSON.stringify(responseVal));
                    component.set("v.isModalOpen", false);
                    helper.getSubscriptionsHelper(component, event, helper);
                    helper.getSerialHelper(component, event, helper);
                }
                else if (state === "INCOMPLETE") {
                    helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                helper.notificationHelper(component, "error", "Error initializing the component : ", errors[0].message);
                            }
                        } else {
                            helper.notificationHelper(component, "error", "Error initializing the component", "Please contact Admin");
                        }
                    }
            });
            
            $A.enqueueAction(action);   
        } catch (error) {
            console.error(error);
        }                		
	},      
    
})