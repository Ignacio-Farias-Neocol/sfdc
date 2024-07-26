({
    getSubscriptions : function(component, event, helper, recordId) {
        if ($A.util.isEmpty(recordId)) {
            return;
        }
        
        component.set("v.inprogress", true);
        
        var getSubscriptions = component.get("c.retrieveSubscriptions");
        getSubscriptions.setParams({
            "inputrecordId": recordId
        });
        
        getSubscriptions.setCallback(this, function(response) {
            component.set("v.inprogress", false);
            
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                if (!$A.util.isEmpty(result.errorMsg)) {
                    helper.showToast(component, event, helper, result.errorMsg);
                } else {
                    component.set('v.record', result.record);
                    
                    var subscriptions = result.subscriptions;
                    console.log('--subscriptions.columns-- ' + JSON.stringify(subscriptions.columns));
                    console.log('--subscriptions.gridData-- ' + JSON.stringify(subscriptions.gridData));
                    if (!$A.util.isEmpty(subscriptions)) {
                        subscriptions.columns.forEach(function(columnRecord){
                            columnRecord.sortable = true;
                        });
                        component.set('v.gridColumns', subscriptions.columns);
                        component.set('v.gridData', subscriptions.gridData);
                    }
                }
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        
        $A.enqueueAction(getSubscriptions);
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
            
            var cloneData = cmp.get('v.gridData').slice(0);
            cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
            
            cmp.set('v.gridData', cloneData);
            cmp.set('v.sortDirection', sortDirection);
            cmp.set('v.sortedBy', sortedBy);
        } catch (error) {
            console.error(error);
        }        
    }    
})