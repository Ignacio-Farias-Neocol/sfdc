({
	updateStatus : function(cmp, event) {
		
        cmp.set('v.isLoading',true);
        let recordId = cmp.get('v.recordId');
        let action  = cmp.get('c.updateOrderStatus');
        //let action  = cmp.get('c.checkVoidOrderCriteria');
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this,(result)=>{ 
            let state = result.getState();
			if(state === "SUCCESS"){
            	$A.get("e.force:closeQuickAction").fire();
                let statusVal = result.getReturnValue();
            	cmp.set('v.isLoading',false);
            	
            	this.showToastMessage(cmp, event, 'Success', 'Order is in ' + statusVal, 'success')
            }else{
                let errors = action.getError();
        		cmp.set('v.isLoading',false);
        	    this.showToastMessage(cmp, event, 'Error', errors[0].message, 'error');
                }            
        })
        $A.enqueueAction(action)
	},
    showToastMessage : function(cmp, event, title, message, type){
        
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            type: type
        });
        toastEvent.fire();
    }

})