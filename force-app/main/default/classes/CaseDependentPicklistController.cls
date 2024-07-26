public with sharing class CaseDependentPicklistController {
    public CaseDependentPicklistController() {}

    /* public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
*/

    @AuraEnabled
    public static String initData(String reqStr){ 
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(reqStr); 
        Map<String, Object> res = new Map<String, Object>();
        String recordId = (String) requestMap.get('recordId');
        List<Map<String,Object>> options = new List<Map<String,Object>>();
        Schema.DescribeFieldResult fieldResult = Case.Product_Family_List__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options.add(new Map<String,Object>{ 'label' => f.getLabel(), 'value' => f.getValue() });
        }    
        
        
        List<Map<String,Object>> options1 = new List<Map<String,Object>>();
        fieldResult = Case.Pick_Product_only_if_Essentials__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options1.add(new Map<String,Object>{ 'label' => f.getLabel(), 'value' => f.getValue() });
        }   
        
        List<Map<String,Object>> options2 = new List<Map<String,Object>>();
        fieldResult = Case.Case_Reason__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options2.add(new Map<String,Object>{ 'label' => f.getLabel(), 'value' => f.getValue() });
        }   

        List<Map<String,Object>> options3 = new List<Map<String,Object>>();
        fieldResult = Case.Closed_Case_Reason__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            options3.add(new Map<String,Object>{ 'label' => f.getLabel(), 'value' => f.getValue() });
        }   


        res.put('productFamily', options);
        res.put('pickProducts', options1);
        res.put('caseReasons', options2);
        res.put('caseClosedReasons', options3);
        
        //res.put('subReasone', CaseDependentPicklistController.getDependentPicklistValues(Case.Sub_Reason__c));
        res.put('casePickProduct', [SELECT Id,Case_Closed_Reason_WM__c,Case_Reason__c,Sub_Reason__c,Pick_Product_only_if_Essentials__c,Product_Family_List__c FROM Case_Picklist_Values__c]);

        res.put('caseRecord', [SELECT Id,Product_Family_List__c,Pick_Product_only_if_Essentials__c,Case_Reason__c,Closed_Case_Reason__c,Sub_Reason__c FROM Case WHERE Id=:recordId LIMIT 1 ]);

        return JSON.serializePretty(res);
    }

}