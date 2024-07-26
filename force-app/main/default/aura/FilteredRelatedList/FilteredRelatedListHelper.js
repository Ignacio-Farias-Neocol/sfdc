({
    getFilteredData : function(component) {
        let action = component.get("c.fetchRecs");

        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();

            if (state === "SUCCESS") {
                let records =response.getReturnValue();                
                var isOnCommunityPage = component.get("v.isOnCommunityPage");
                records.forEach(function(record){
                    if(!$A.util.isUndefinedOrNull(record.Contact))
                    	record.ContactId = record.Contact.Name;
                    record.RecordTypeId = record.RecordType.Name;
                });
                if(!isOnCommunityPage){
                    var newRecords = [];
                    for(var i=0; i<5; i++){
                        if(records.length > i)
                            newRecords.push(records[i]);
                    }
                    component.set('v.sdata', newRecords);                    
                } else {
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
            console.error(error);
        }        
    }      
})