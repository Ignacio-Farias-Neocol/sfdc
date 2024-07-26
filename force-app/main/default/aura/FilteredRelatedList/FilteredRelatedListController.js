({
    init : function(component, event, helper) {
        component.set("v.scolumns", [
            {label:"Date/Time Opened", fieldName:"Table_Source__c", type:"text", sortable: true},
            {label:'Case Number', type: "button", sortable: true, fieldName: 'CaseNumber', typeAttributes: {  
                    label: {fieldName: 'CaseNumber'},  
                    name: 'View',  
                    title: 'View', 
                	variant: 'base',
                    disabled: false,  
                	value: 'view',  
                    iconPosition: 'left'  
                }},
            {label:"Contact", fieldName:"ContactId", type:"text", sortable: true}, 
            {label:"Subject", fieldName:"Subject", type:"text", sortable: true},
            {label:"Status", fieldName:"Status", type:"text", sortable: true},
            {label:"Serial", fieldName: "Serial_Number__c", type:"text", sortable: true},
            {label:"Product Family", fieldName: "Product_Family__c", type:"text", sortable: true},
            {label:"Record Type", fieldName:"RecordTypeId", type:"text", sortable: true}
        ]);
        helper.getFilteredData(component);
    },
    
    navigateToCaseRelatedList : function(component, event, helper) {            
        event.preventDefault();  
        var navService = component.find( "navService" );  
        var pageReference = {  
            type: "comm__namedPage",  
            attributes: {  
                pageName: "caserelatedlist"  
            }
        };   
        navService.navigate(pageReference);            
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
                "objectApiName": "Case",
                "actionName": "view"
             }
            }               
            navService.navigate(pageReference);                                      		
    },
    
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    }       
})