({
    init : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        if (pageReference) {
            component.set("v.isRelatedListPageDisplay", "true");
            component.set("v.recordId", pageReference.state.c__recordId);
        }           
        component.set("v.scolumns", [
            {label:'OPPORTUNITY NAME', type: "button", sortable: true, fieldName: 'Name', typeAttributes: {  
                label: {fieldName: 'Name'},  
                name: 'View',  
                title: 'View', 
                variant: 'base',
                disabled: false,  
                value: 'view',  
                iconPosition: 'left'  
            }},             
            {label:"STAGE NAME", fieldName:"StageName", type:"text", sortable: true},
            {label: 'AMOUNT', fieldName: 'Amount', type: 'currency', sortable: true, typeAttributes: { currencyCode: 'USD', currencyDisplayAs: 'code'}, cellAttributes: { alignment: 'left' }},
            {label: 'CLOSE DATE', fieldName: 'CloseDate', type: 'date', sortable: true},
            {label: 'OWNER', fieldName: 'owner', type: 'text', sortable: true},
            {label: 'RECORD TYPE', fieldName: 'recordType', type: 'text', sortable: true},
            {label: 'RESELLER', fieldName: 'reseller', type: 'text', sortable: true},
            {label: 'DISTRIBUTOR', fieldName: 'distributor', type: 'text', sortable: true}
        ]);
        helper.getFilteredData(component);
    },
    
    navigateToCaseRelatedList : function(cmp, event, helper) {            
        event.preventDefault();              
        cmp.find("navService").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__OpportunityFilteredRelatedList" 
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
                "objectApiName": "Opportunity",
                "actionName": "view"
             }
            }               
            navService.navigate(pageReference);                                      		
    },
    
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    }       
})