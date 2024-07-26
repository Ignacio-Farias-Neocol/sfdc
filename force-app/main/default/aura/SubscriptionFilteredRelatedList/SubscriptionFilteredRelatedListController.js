({
    init : function(component, event, helper) {
        console.log('init::');
        var pageReference = component.get("v.pageReference");
        if (pageReference) {
            component.set("v.isRelatedListPageDisplay", "true");
            component.set("v.recordId", pageReference.state.c__recordId);
            console.log('##pageRef:: ' + JSON.stringify(pageReference));
            console.log('##recordId:: ' + component.get("v.recordId"));
        }        
        component.set("v.scolumns", [
            {label:"PRODUCT NAME", fieldName:"SBQQ__ProductName__c", type:"text", sortable: true},
            {label:"SERIAL NUMBER", fieldName:"SBCF_Serial_Number__c", type:"text", sortable: true}, 
            {label:"SUBSCRIPTION END DATE", fieldName:"SBQQ__SubscriptionEndDate__c", type:"date", sortable: true},
            {label:'SUBSCRIPTION #', type: "button", sortable: true, fieldName: 'Name', typeAttributes: {  
                    label: {fieldName: 'Name'},  
                    name: 'View',  
                    title: 'View', 
                	variant: 'base',
                    disabled: false,  
                	value: 'view',  
                    iconPosition: 'left'  
                }},            
        ]);
        helper.getFilteredData(component);
    },
    
    navigateToCaseRelatedList : function(cmp, event, helper) {            
        event.preventDefault();              
        cmp.find("navService").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__SubscriptionFilteredRelatedList" 
            },
            state: { 
                "c__isRelatedListPageDisplay": "true",
            	"c__recordId": cmp.get("v.recordId")
            }
        });            
    },
    
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        // console.log('##action:: ' + JSON.stringify(action));
        var row = event.getParam('row');
        // console.log('##rowData:: ' + JSON.stringify(row));
        // console.log(action.name);
            // navigate to case record page 
            console.log(action.name);
            event.preventDefault();  
            var navService = cmp.find( "navService" );  
            var pageReference = {    
                "type": "standard__recordPage",
                "attributes": {
                "recordId": row.Id,
                "objectApiName": "SBQQ__Subscription__c",
                "actionName": "view"
             }
            }               
            navService.navigate(pageReference);                                      		
    },
    
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    }       
})