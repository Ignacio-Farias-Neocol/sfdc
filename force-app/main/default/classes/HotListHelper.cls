global with sharing class HotListHelper {
    
    global class HotListException extends Exception {}

    global class CreateHotListRequestParams {

        @InvocableVariable (required=true)
        global String activityId;
        
        @InvocableVariable
        global String recordTypeId;

        @InvocableVariable
        global String source;
    }

    global class CreateHotListResult {

        @InvocableVariable 
        global String hotlistId;
    }

    @InvocableMethod(label='Create Hot List')
    global static List<CreateHotListResult> createHotListResult(List<CreateHotListRequestParams> params) {
        return createHotList(params[0]);
    }

    private static  List<CreateHotListResult> createHotList(CreateHotListRequestParams param) {

        // Get the token for hotlist
        Schema.sObjectType objDef = Schema.getGlobalDescribe().get('Hot_List__c').getDescribe().getSObjectType();
        //Find all the fields for this object type
        Map<String, Schema.SobjectField> fieldsMap = objDef.getDescribe().fields.getMap();

        //create a generic sObject to contain the new values
        sObject newObj = objDef.newSobject();

        SObject taskObj = Database.query(getDynamicQuery('Task', 'Id', param.activityId))[0];
        //SObject taskObj = sObj.getSObject('Task');

        String jsonInput = taskObj.get('Description') != null?'{'+(String)taskObj.get('Description')+'}':'';
        /* SFDC-9477: Replacing following special characters in the JSON input
         * \n - New Line Character
         * \r - Carriage Return
         * \  - Backslash
         */
        String cleanJSONInput = jsonInput.replaceAll('\n', '').replaceAll('\r', '').replaceAll('\\\\', '');
        Map<String, Object> jsonMap =(Map<String, Object>)JSON.deserializeUntyped(cleanJSONInput);
        
        System.debug('###jsonMap: '+jsonMap);
        
        for(Hot_List_Fields_Mapping__mdt mdtRec : getHotListCustomMetadataMap().values()) {
            
            String fieldType = fieldsMap.get(mdtRec.SObject_Field_Name__c).getDescribe().getType().name()/*.toLowerCase()*/;
            if(/*taskObj != null && (String)taskObj.get('Source__c') == 'Marketo'*/ 
                param.source == 'Marketo' && (String)taskObj.get('Description') != null && mdtRec.SObject_Name__c == 'Marketo') {
                
                if (fieldsMap.containsKey(mdtRec.SObject_Field_Name__c) && !String.isBlank(getFieldValue(mdtRec.DeveloperName, jsonMap))) {
                    if(fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT'){
                        newObj.put(mdtRec.SObject_Field_Name__c, Decimal.valueOf(getFieldValue(mdtRec.DeveloperName, jsonMap))); 
                    } 
                    else if(fieldType == 'BOOLEAN'){
                        newObj.put(mdtRec.SObject_Field_Name__c, Boolean.valueOf(getFieldValue(mdtRec.DeveloperName, jsonMap))); 
                    } 
                    else if(fieldType == 'DATE') {
                        newObj.put(mdtRec.SObject_Field_Name__c, Date.valueOf(getFieldValue(mdtRec.DeveloperName, jsonMap))); 
                    } 
                    else {
                        newObj.put(mdtRec.SObject_Field_Name__c, getFieldValue(mdtRec.DeveloperName, jsonMap));
                    }
                } 
                else if(fieldType == 'REFERENCE' && String.isBlank(getFieldValue(mdtRec.DeveloperName, jsonMap))) {
                    newObj.put(mdtRec.SObject_Field_Name__c, null); 
                } 
            } 
            else if (fieldsMap.containsKey(mdtRec.SObject_Field_Name__c) && taskObj.get(mdtRec.Label) != null) { 
                if(fieldType == 'CURRENCY' || fieldType == 'DOUBLE' || fieldType == 'PERCENT'){
                    newObj.put(mdtRec.SObject_Field_Name__c, Decimal.valueOf((String)taskObj.get(mdtRec.Label))); 
                } 
                else if(fieldType == 'BOOLEAN'){
                    newObj.put(mdtRec.SObject_Field_Name__c, Boolean.valueOf(taskObj.get(mdtRec.Label))); 
                } 
                else if(fieldType == 'DATE') {
                    newObj.put(mdtRec.SObject_Field_Name__c, Date.valueOf(taskObj.get(mdtRec.Label))); 
                } 
            } 
        } 
        // Set the Contact/Lead for Marketo-based HotList
        if(/*(String)taskObj.get('Source__c')*/
            param.source == 'Marketo') {
            String tmp = (String)taskObj.get('WhoId');
            tmp = tmp != null && tmp.length() > 3 ? tmp.substring(0,3) : tmp;
            if(tmp == '003') {
                newObj.put('Contact__c', taskObj.get('WhoId'));
            } else if(tmp == '00Q') {
                newObj.put('Lead__c', taskObj.get('WhoId'));
            }
        }
        // Record Type 
        if(param.recordTypeId != null && param.recordTypeId != '') {
            newObj.put('RecordTypeId', param.recordTypeId);
        }
        
        System.debug('###newObj: '+newObj);
        // insert HotList record
        insert newObj;

        CreateHotListResult result = new CreateHotListResult();
        result.hotlistId = newObj.Id;
        return new List<CreateHotListResult>{result};

    }

    private static String getFieldValue(String fieldApiName, Map<String, Object> jsonMap) {
        Map<String, Hot_List_Fields_Mapping__mdt> hotListMap = getHotListCustomMetadataMap();
        Hot_List_Fields_Mapping__mdt mdtRecord = hotListMap.get(fieldApiName);
        String srcFieldLabel = mdtRecord.MasterLabel/*.toLowerCase()*/;
        //System.debug('###srcFieldLabel: '+srcFieldLabel);
        //System.debug('###jsonMap.get(srcFieldLabel): '+jsonMap.get(srcFieldLabel));
        return (String)jsonMap.get(srcFieldLabel);
    }

    private static String getDynamicQuery(String sObjectApiName, String filterFieldName, String filterFieldValue) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sObjectApiName).getDescribe().fields.getMap();
        String commaSeparatedFields = '';
        for(String fieldName : fieldMap.keyset()){
            if(commaSeparatedFields == null || commaSeparatedFields == ''){
                commaSeparatedFields = fieldName;
            } else {
                commaSeparatedFields = commaSeparatedFields + ', ' + fieldName;
            }
        }
        String query = 'SELECT '+commaSeparatedFields+' FROM '+sObjectApiName+' WHERE '+filterFieldName+' = \''+filterFieldValue+'\'';
        return query;
    }

    private static Map<String, Hot_List_Fields_Mapping__mdt> getHotListCustomMetadataMap() {
        Map<String, Hot_List_Fields_Mapping__mdt> hotListMap = new Map<String, Hot_List_Fields_Mapping__mdt>();
        for(Hot_List_Fields_Mapping__mdt hotList : [SELECT Id, 
                                                DeveloperName, 
                                                Label,
                                                MasterLabel, 
                                                SObject_Field_Name__c,
                                                SObject_Name__c
                                            FROM Hot_List_Fields_Mapping__mdt
                                            WHERE Active__c = true]) {
            hotListMap.put(hotList.DeveloperName, hotList);
        }
        return hotListMap;
    }

}