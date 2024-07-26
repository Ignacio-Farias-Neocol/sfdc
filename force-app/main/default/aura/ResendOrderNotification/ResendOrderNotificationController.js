({
    doInit : function(cmp, event, helper) {
        
        cmp.set('v.isLoading',true);
        let recordId = cmp.get('v.recordId');
        let action  = cmp.get('c.checkResendOrderCriteria');
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this,(result)=>{ 
            
            var state = result.getState();
            console.log('state',state);
            if (state === "SUCCESS") {
				let resultValue = result.getReturnValue();
                cmp.set('v.billToConEmail', resultValue);
                cmp.set('v.isOrder', true);
                cmp.set('v.isLoading',false);
            }
            else if (state === "ERROR") {
            
                var errors = result.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                         cmp.set('v.errorMessage', errors[0].message);
                         cmp.set('v.isOrder', false);
                         cmp.set('v.isLoading',false);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        })
        $A.enqueueAction(action)
	},
	handleChangeStatus : function(cmp, event, helper) {
		helper.updateStatus(cmp, event);
	},
    	handleClickNo : function(cmp, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}    
    
})