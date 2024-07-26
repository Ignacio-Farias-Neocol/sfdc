({
    init : function(component, event, helper) {
        var pageReference = component.get("v.pageReference");
        if (pageReference) {
            component.set("v.isRelatedListPageDisplay", "true");
            component.set("v.recordId", pageReference.state.c__recordId);
        }            
        component.set("v.scolumns", [
            {label:'HOT LIST ID', type: "button", sortable: true, fieldName: 'Name', typeAttributes: {  
                label: {fieldName: 'Name'},  
                name: 'View',  
                title: 'View', 
                variant: 'base',
                disabled: false,  
                value: 'view',  
                iconPosition: 'left'  
            }},             
            {label:"CREATED DATE", fieldName:"CreatedDate", type:"date", sortable: true},
            {label:"HOT LIST NAME", fieldName:"Hot_List_Name__c", type:"text", sortable: true}, 
            {label:"HOT LIST REASON", fieldName:"MQL_Reason__c", type:"text", sortable: true},
            {label:"DISPOSITION", fieldName:"Disposition__c", type:"text", sortable: true},
            {label:"MOST RECENT PRODUCT OF INTEREST", fieldName: "Primary_Product_Family_2__c", type:"text", sortable: true},
            {label:"RESELLER", fieldName: "Reseller__c", type:"text", sortable: true},
            {label:"HOT LIST OWNER", fieldName:"Owner_Name__c", type:"text", sortable: true}
        ]);
        helper.getFilteredData(component);
    },
    
    navigateToCaseRelatedList : function(cmp, event, helper) {            
        event.preventDefault();              
        cmp.find("navService").navigate({
            type: "standard__component",
            attributes: {
                componentName: "c__HotlistFilteredRelatedList" 
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
                "objectApiName": "Hot_List__c",
                "actionName": "view"
             }
            }               
            navService.navigate(pageReference);                                      		
    },
    
    handleSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    }       
})