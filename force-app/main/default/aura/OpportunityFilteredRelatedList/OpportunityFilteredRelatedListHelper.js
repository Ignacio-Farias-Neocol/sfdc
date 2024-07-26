({
    getFilteredData : function(component) {
        let action = component.get("c.fetchRecs");
		action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                let records =response.getReturnValue();                
                var isOnCommunityPage = component.get("v.isOnCommunityPage");                
                records.forEach(function(record){
                    record.owner = record.Owner.Name;
                    record.recordType = record.RecordType.Name;
                    if(!$A.util.isUndefinedOrNull(record.Reseller__c))
                    	record.reseller = record.Reseller__r.Name;
                    if(!$A.util.isUndefinedOrNull(record.Distributor__c))
                    	record.distributor = record.Distributor__r.Name;                    
                    
                });                
                console.log('##isOnpage:: ' + component.get("v.isRelatedListPageDisplay"));
                if(component.get("v.isRelatedListPageDisplay") == "false"){
                    var newRecords = [];
                    for(var i=0; i<5; i++){
                        if(records.length > i)
                            newRecords.push(records[i]);
                    }
                    component.set('v.sdata', newRecords);                    
                } else {
                    var workspaceAPI = component.find("workspace");
                    workspaceAPI.isConsoleNavigation().then(function(isCon) {
                        console.log('isCon => ', JSON.stringify(isCon));
                        workspaceAPI.getFocusedTabInfo().then(function(response) {
                            var focusedTabId = response.tabId;
                            workspaceAPI.setTabLabel({
                                tabId: focusedTabId,
                                label: "Opportunities(Closed Won last 6months or Open Opps)"
                            });
                            workspaceAPI.setTabIcon({
                                tabId: focusedTabId, 
                                icon: "standard:opportunity",
                                iconAlt: "Subscriptions"
                            });
                        })
                        .catch(function(error) {
                            console.log(error);
                        });
                    });                       
                    component.set('v.sdata', records);
                }

            } else if (state === "ERROR") {
                let errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0){
                    component.set('v.errors',errors[0].message);
                    console.error(errors[0].message);
                }

            } else if (state === "INCOMPLETE") {
                console.error("INCOMPLETE");
            }
        }));
        $A.enqueueAction(action);
    },   
    
    showToast : function(component, event, helper, errorMsg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "error",
            "duration": "10000",
            "message": errorMsg
        });
        toastEvent.fire();
    },
    
    sortBy: function(field, reverse, primer) {
        try {
            var key = primer
            ? function(x) {
                return primer(x[field]);
            }
            : function(x) {
                return x[field];
            };
            
            return function(a, b) {
                a = key(a);
                b = key(b);
                return reverse * ((a > b) - (b > a));
            };
        } catch (error) {
            console.error(error);
        }        
    },    
    
    handleSort: function(cmp, event) {
        try {
            var sortedBy = event.getParam('fieldName');
            var sortDirection = event.getParam('sortDirection');
            
            var cloneData = cmp.get('v.sdata').slice(0);
            cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
            
            cmp.set('v.sdata', cloneData);
            cmp.set('v.sortDirection', sortDirection);
            cmp.set('v.sortedBy', sortedBy);
        } catch (error) {
            console.log('##error');
            console.error(error);
        }        
    }      
})