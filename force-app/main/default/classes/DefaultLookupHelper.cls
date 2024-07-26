/**
* Invokable apex class used to set the default lookup value from Process Builder
*
* @Author Ivan Yeung
* @Date 2018/11/01
* @Group Helper
*
* @description
*  this helper class help to set the value of a lookup field in a record. There are two ways to invoke this helper class
*     1. as an invokeable method from process builder. : List<Response> execute(List<Request> requests)
*     2. as an implementaiton of DynamicBusinessRuleAction interface   void processRecords(Map<Id,SObject> recordMap,  List <SObject> records). DynamicBusinessRuleAction is in trun invoked from DynamicBusinessRuleActionTriggerHandler
*
*
* ** TO DO: the implementation for process builder is too limited. will have to remove
*/
public with sharing class DefaultLookupHelper implements DynamicBusinessRuleAction {

    ///Establish Variables that will be passed in by Process Builder
    public class Request {

        @InvocableVariable(
                label = 'Record ID'
                description = 'The ID of the record to have the default value populated'
                required = true
        )
        public Id targetRecordId;


        @InvocableVariable(
                label = 'Lookup Field Name'
                description = 'The Developer Name of the lookup filed name to be populated'
                required = true
        )
        public String targetField;


        @InvocableVariable(
                label = 'Target Join Field #1'
                description = 'The developerName for field #1 in the record to updated. It is used to related the target record with lookup'
                required = false
        )
        public String targetJoinField1;

        @InvocableVariable(
                label = 'Target Join Field #2'
                description = 'The developerName for field #2 in the record to updated. It is used to related the target record with lookup'
                required = false
        )
        public String targetJoinField2;

        @InvocableVariable(
                label = 'Target Join Field #3'
                description = 'The developerName for field #3 in the record to updated. It is used to related the target record with lookup'
                required = false
        )
        public String targetJoinField3;
        /*
         *    e.g. select AccountId, AssetId, Asset.Name, Asset.AccountId, Id, BusinessHoursId, CasesPerEntitlement,
         *   EndDate, Name, StartDate, Status, SystemModstamp, Type from Entitlement
         *
         *  the id field is supposed to
         */

        @InvocableVariable(
                label = 'Lookup Object Name'
                description = 'The lookup object Name '
                required = true
        )
        public String lookupObjectName;


        @InvocableVariable(
                label = 'Lookup SOQL'
                description = 'The SOQL query to find the lookup value. It binds to record IDs by default '
                required = true
        )
        public String lookupSOQL;


        @InvocableVariable(
                label = 'Condition field name #1'
                description = 'The developerName for condition field #1'
                required = false
        )
        public String lookupConditionField1;

        @InvocableVariable(
                label = 'Condition field name #2'
                description = 'The developerName for condition field #3'
                required = false
        )
        public String lookupConditionField2;

        @InvocableVariable(
                label = 'Condition field name #3'
                description = 'The developerName for condition field #3'
                required = false
        )
        public String lookupConditionField3;


        @InvocableVariable(
                label = 'Lookup field'
                description = 'The field where the value will be populated to the target. by default it is id'
                required = false
        )
        public String lookupField;


        @InvocableVariable(
                label = 'field Id #1'
                description = 'For PB, This field is used to related the lookup records and the target record. i.e. we expect the same value exist in both target object and lookup object'
                required = false
        )
        public Id field1Id;

        @InvocableVariable(
                label = 'field Id #2'
                description = 'For PB, This field is used to related the lookup records and the target record. i.e. we expect the same value exist in both target object and lookup object'
                required = false
        )
        public Id field2Id;

        @InvocableVariable(
                label = 'field Id #3'
                description = 'For PB, This field is used to related the lookup records and the target record. i.e. we expect the same value exist in both target object and lookup object'
                required = false
        )
        public Id field3Id;

    }

    //Establish response for error handling
    public class Response {

        @InvocableVariable(
                label = 'Error Message'
                description = 'The message of the error'
        )
        public String errorMesssage;

        @InvocableVariable(
                label = 'Is Success'
                description = 'Successfully changed'
        )
        public Boolean success;
    }


    //Enable this method to be called by Process Builder
    /*
    @InvocableMethod(
            label = 'Set Lookup Field'
            description = 'Set Lookup Field Default Value'
    )
    */
    /***********************************************************************
    * @description Method for gathering inputs from Process Builder
    *
    * @param Requests
    * @return Responses
    */
    /*
    public static List<Response> execute(List<Request> requests) {

        List<Response> responses = new List<Response>();

        System.debug('#~#~ staring');

        try {
            if (requests != null && requests.size() > 0) {

                // construct lookup SOQL string
                String mySOQL;
                String objectName;
                List <Id> targetRecordIds = new List <Id>();
                Map <Id, Id> field1IdMap = new Map <Id, Id>();

                for (Request req : requests) {
                    targetRecordIds.add(req.targetRecordId);
                    field1IdMap.put(req.targetRecordId, req.field1Id);
                    objectName = req.targetRecordId.getSObjectType().getDescribe().getName();

                }
                List <Id> field1Ids = field1IdMap.values();

                mySOQL = requests[0].lookupSOQL;
                // e.g. select AccountId, AssetId, Asset.Name, Asset.AccountId, Id, BusinessHoursId, CasesPerEntitlement,
                // EndDate, Name, StartDate, Status, SystemModstamp, Type from Entitlement where StartDate <= Today and EndDate >=Today
                // and Name = 'Premium Support'
                boolean existingCondition = mySOQL.contains('where');
                mySOQL += (existingCondition) ? '' : ' where ';
                if (requests[0].lookupConditionField1 != null && requests[0].lookupConditionField1.length() > 0) {
                    mySOQL += (existingCondition) ? ' and ' : '';
                    mySOQL += requests[0].lookupConditionField1 + ' in :field1Ids';
                    existingCondition = true;
                }


                System.debug('#~#~ Lookup SOQL: ' + mySOQL);
                Map<Object, Object> lookupMap = new Map<Object, Object>();
                List<sObject> sObjectLookup = Database.query(mySOQL);
                for (sObject obj : sObjectLookup) {
                    // assume the lookup condiiton is also in the result
                    if (requests[0].lookupConditionField1 != null && requests[0].lookupConditionField1.length() > 0) {
                        lookupMap.put(obj.get(requests[0].lookupConditionField1), obj.get('Id'));
                    }
                }
                System.debug('#~#~ sObjectLookup: ' + sObjectLookup);


                String targetSOQL = 'select id, ' + requests[0].targetField ;
                if (requests[0].targetJoinField1 != null && requests[0].targetJoinField1.length() > 0) {
                    targetSOQL += ', ' + requests[0].targetJoinField1;
                }
                targetSOQL += ' from ' + objectName + ' where id in :targetRecordIds';
                System.debug('#~#~ Target SOQL: ' + targetSOQL);
                List <SObject> sObjectTarget = Database.query (targetSOQL);
                System.debug('#~#~ sObjectTarget (original): ' + sObjectTarget);


                For (sObject obj : sObjectTarget) {
                    // scenario 1. use join field to join 2 object
                    if (field1IdMap.size() > 0) {
                        // join field is not null, try to related the lookup object and target object with the join field
                        Object targeJoinValue1 = obj.get(requests[0].targetJoinField1);
                        if (targeJoinValue1 != null && lookupMap.containsKey(targeJoinValue1)) {
                            obj.put(requests[0].targetField, lookupMap.get(targeJoinValue1));
                        }
                    } else if (sObjectLookup.size() == 1) {
                        // scenario 2 . join is not used, and there is only one record  from lookup query
                        obj.put(requests[0].targetField, sObjectLookup[0].get('Id'));
                    }
                }

                System.debug('#~#~ sObjectTarget (updated): ' + sObjectTarget);

                // update
                DML.save(sObjectTarget);

            }

            for (Request request : requests) {
                Response rp = new Response();
                rp.success = true;
                responses.add(rp);
            }

        } catch (Exception ex){

            for (Request request : requests) {
                Response rp = new Response();
                rp.success = false;
                rp.errorMesssage = ex.getMessage();
                responses.add(rp);
            }
        }

        return responses;
    }
    */


    private static String  setMySOQL (String objName, String fieldName, Integer fieldNum,   List <Object> fieldValues, FieldValueDTO fieldValue , Boolean existingCondition ){


        String mySOQL = '';

        if ( String.isNotBlank( fieldName)) {
            mySOQL += (existingCondition) ? ' and ' : '';


            DisplayType targetFieldType  = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe().getType();

            if (targetFieldType == Schema.DisplayType.Boolean) {
                fieldValue.fieldBooleans = RuleEngine.objsToBooleans(fieldValues);
                mySOQL += fieldName + ' in :field' + fieldNum + 'Booleans';

            } else if (targetFieldType == Schema.DisplayType.Double ) {
                fieldValue.fieldDecimals = RuleEngine.objsToDecimals(fieldValues);
                mySOQL += fieldName + ' in :field' + fieldNum + 'Decimals';
            } else {
                fieldValue.fieldStrings = RuleEngine.objsToStrings(fieldValues);
                mySOQL += fieldName + ' in :field' + fieldNum + 'Strings';
            }
        }

        System.debug('#~#~ setMySOQL :' + mySOQL);

        return mySOQL;

    }

    private class FieldValueDTO {

        List <Boolean> fieldBooleans;
        List <String> fieldStrings;
        List <Decimal> fieldDecimals;

        Set <Boolean> setBooleans  {
            get {
                Set <Boolean> s = new Set <Boolean>();
                if (fieldBooleans != null) {
                    for (Boolean f : fieldBooleans) {
                        s.add(f);
                    }
                }
                return s;
            }
        }

        Set <String> setStrings  {
            get {
                Set <String> s = new Set <String>();
                if (fieldStrings != null) {
                    for (String f : fieldStrings) {
                        s.add(f);
                    }
                }
                return s;
            }
        }

        Set <Decimal> setDecimals  {
            get {
                Set <Decimal> s = new Set <Decimal>();
                if (fieldDecimals != null) {
                    for (Decimal f : fieldDecimals) {
                        s.add(f);
                    }
                }
                return s;
            }
        }

    }

    private static void  processLookup( Request request , List <Object> field1Values, List <Object> field2Values,  List <Object> field3Values,  List <SObject> sObjectTarget ){

        // construct lookup SOQL string
        String mySOQL;

        /*
        System.debug('#~#~ process Lookup Start ' );
        System.debug('#~#~ request '  + request);
        System.debug('#~#~ field1Values '  + field1Values);
        System.debug('#~#~ field2Values ' + field2Values );
        System.debug('#~#~ field3Values ' + field3Values );
        System.debug('#~#~ sObjectTarget ' + sObjectTarget );
        */

        mySOQL = request.lookupSOQL;
        // e.g. select AccountId, AssetId, Asset.Name, Asset.AccountId, Id, BusinessHoursId, CasesPerEntitlement,
        // EndDate, Name, StartDate, Status, SystemModstamp, Type from Entitlement where StartDate <= Today and EndDate >=Today
        // and Name = 'Premium Support'
        boolean existingCondition = mySOQL.contains('where');
        mySOQL += (existingCondition) ? '' : ' where ';

        String conString = '';
        // join field 1
        FieldValueDTO fieldValue1 = new FieldValueDTO();
        conString = setMySOQL(request.lookupObjectName, request.lookupConditionField1, 1, field1Values, fieldValue1, existingCondition );
        mySOQL += conString;
        existingCondition = String.isNotBlank(conString);
        Set <Boolean> field1Booleans = fieldValue1.setBooleans;
        Set <String> field1Strings = fieldValue1.setStrings;
        Set <Decimal> field1Decimals = fieldValue1.setDecimals;

        // join field 2
        FieldValueDTO fieldValue2 = new FieldValueDTO();
        conString =  setMySOQL(request.lookupObjectName, request.lookupConditionField2, 2, field2Values, fieldValue2, existingCondition );
        mySOQL += conString;
        existingCondition = String.isNotBlank(conString);
        Set <Boolean> field2Booleans = fieldValue2.setBooleans;
        Set <String> field2Strings = fieldValue2.setStrings;
        Set <Decimal> field2Decimals = fieldValue2.setDecimals;


        // join field 3
        FieldValueDTO fieldValue3 = new FieldValueDTO();
        conString =  setMySOQL(request.lookupObjectName, request.lookupConditionField3, 3 , field3Values, fieldValue3 , existingCondition );
        mySOQL += conString;
        existingCondition = String.isNotBlank(conString);
        Set <Boolean> field3Booleans = fieldValue3.setBooleans;
        Set <String> field3Strings = fieldValue3.setStrings;
        Set <Decimal> field3Decimals = fieldValue3.setDecimals;

        /*
        if ( String.isNotBlank( request.lookupConditionField2)) {
            mySOQL += (existingCondition) ? ' and ' : '';
            mySOQL += request.lookupConditionField2 + ' in :field2Ids';
            existingCondition = true;
        }
        if ( String.isNotBlank( request.lookupConditionField3)) {
            mySOQL += (existingCondition) ? ' and ' : '';
            mySOQL += request.lookupConditionField3 + ' in :field3Ids';
            existingCondition = true;
        }
        */

        System.debug('#~#~' + field1Strings);
        System.debug('#~#~' + field2Strings);
        System.debug('#~#~' + mySOQL);
        List<sObject> sObjectLookup = Database.query(mySOQL);

        /*
        System.debug('#~#~ Lookup SOQL: ' + mySOQL);
        System.debug('#~#~ field2Strings: ' + field2Strings);
        System.debug('#~#~ field1Strings: ' + field1Strings);
        System.debug('#~#~ sObjectLookup: ' + sObjectLookup);
        */

        String lookupFieldName = 'Id'; // by default lookup field is id,
        if (String.isNotBlank(request.lookupField)){
            lookupFieldName = request.lookupField;  // assume lookup field is already in the SOQL
        }

        Map<Object, Object> lookupMap = new Map<Object, Object>();
        for (sObject obj : sObjectLookup) {
            // make sure the SOQL include the lookupConditionField1 field
            String hashKey = '';
            if ( String.isNotBlank( request.lookupConditionField1)) {
                hashKey += String.valueOf(obj.get(request.lookupConditionField1));
            }
            if ( String.isNotBlank( request.lookupConditionField2)) {
                hashKey += String.valueOf(obj.get(request.lookupConditionField2));
            }
            if ( String.isNotBlank( request.lookupConditionField3)) {
                hashKey += String.valueOf(obj.get(request.lookupConditionField3));
            }

            if (String.isNotBlank(hashKey)) {
                lookupMap.put(hashKey, obj.get(lookupFieldName));
            }
        }

        For (sObject obj : sObjectTarget) {
            // scenario 1. use join field to join 2 object
            if ( String.isNotBlank( request.lookupConditionField1)  || String.isNotBlank( request.lookupConditionField2)
                    || String.isNotBlank( request.lookupConditionField3)) {
                // join field is not null, try to related the lookup object and target object with the join field

                String hashKey = '';
                if ( String.isNotBlank( request.lookupConditionField1)) {
                    hashKey += String.valueOf(obj.get(request.targetJoinField1));
                }
                if ( String.isNotBlank( request.lookupConditionField2)) {
                    hashKey += String.valueOf(obj.get(request.targetJoinField2));
                }
                if ( String.isNotBlank( request.lookupConditionField3)) {
                    hashKey += String.valueOf(obj.get(request.targetJoinField3));
                }
                if (String.isNotBlank(hashKey) && lookupMap.containsKey(hashKey)) {
                    obj.put(request.targetField, lookupMap.get(hashKey));
                } else {
                    // 2019-07-21 reset the target field to null if there is no matching
                    obj.put(request.targetField , null);
                }
            } else if (sObjectLookup.size() == 1) {
                // scenario 2 . join is not used, and there is only one record  from lookup query
                obj.put(request.targetField, sObjectLookup[0].get(lookupFieldName));
            } else {
                // 2019-07-21 reset the target field to null if there is no matching
                obj.put(request.targetField , null);
            }
        }

        System.debug('#~#~ sObjectTarget (updated): ' + sObjectTarget);


    }


    //Enable this method to be called by Process Builder
    @InvocableMethod(
            label = 'Set Lookup Field'
            description = 'Set Lookup Field Default Value'
    )
    /***********************************************************************
    * @description Method for gathering inputs from Process Builder
    *
    * @param Requests
    * @return Responses
    */
    public static List<Response> execute(List<Request> requests) {

        List<Response> responses = new List<Response>();

        System.debug('#~#~ staring');

        try {
            if (requests != null && requests.size() > 0) {



                List <Id> targetRecordIds = new List <Id>();
                Map <Id, Id> field1IdMap = new Map <Id, Id>();
                Map <Id, Id> field2IdMap = new Map <Id, Id>();
                Map <Id, Id> field3IdMap = new Map <Id, Id>();

                for (Request req : requests) {
                    targetRecordIds.add(req.targetRecordId);
                    field1IdMap.put(req.targetRecordId, req.field1Id);
                    field2IdMap.put(req.targetRecordId, req.field2Id);
                    field3IdMap.put(req.targetRecordId, req.field3Id);
                }

                String objectName = requests[0].targetRecordId.getSObjectType().getDescribe().getName();

                String targetSOQL = 'select id, ' + requests[0].targetField ;
                if (  String.isNotBlank(requests[0].targetJoinField1)) {
                    targetSOQL += ', ' + requests[0].targetJoinField1;
                }
                if (  String.isNotBlank(requests[0].targetJoinField2)) {
                    targetSOQL += ', ' + requests[0].targetJoinField2;
                }
                if (  String.isNotBlank(requests[0].targetJoinField3)) {
                    targetSOQL += ', ' + requests[0].targetJoinField3;
                }
                targetSOQL += ' from ' + objectName + ' where id in :targetRecordIds';
                System.debug('#~#~ Target SOQL: ' + targetSOQL);
                List <SObject> sObjectTarget = Database.query (String.escapeSingleQuotes(targetSOQL));
                System.debug('#~#~ sObjectTarget (original): ' + sObjectTarget);


                processLookup(requests[0] ,  field1IdMap.values(), field2IdMap.values(), field3IdMap.values(), sObjectTarget);


                // update
                DML.save(sObjectTarget);

            }

            for (Request request : requests) {
                Response rp = new Response();
                rp.success = true;
                responses.add(rp);
            }

        } catch (Exception ex){

            for (Request request : requests) {
                Response rp = new Response();
                rp.success = false;
                rp.errorMesssage = ex.getMessage();
                responses.add(rp);
            }
        }

        return responses;
    }

    /***********************************************************************
    * @description method to invoked by DynamicBusinessRuleActionTriggerHandler
    *
    * @param Map<Id,SObject> recordMap,  List <SObject> records, jsonParameter
    *

    the jsonParameter need to be created from workbench with this script like:

    DefaultLookupHelper.Request req = new DefaultLookupHelper.Request();
    req.targetField = 'EntitlementId';
    req.targetJoinField1 = 'AssetId';
    req.lookupConditionField1 = 'AssetId';

    req.lookupSOQL = 'select AccountId, AssetId, Asset.AccountId, Id, EndDate, Name, StartDate, Status, Type from Entitlement where Status=\'Active\' and Name =\'Premium Support\' ';
    List<DefaultLookupHelper.Request> requests = new List <DefaultLookupHelper.Request> {req};
    DefaultLookupHelper.execute(requests);



    {"targetRecordId":null,"targetJoinField1":"AssetId","targetField":"EntitlementId","lookupSOQL":"select AccountId, AssetId, Asset.AccountId, Id, EndDate, Name, StartDate, Status, Type from Entitlement where Status='Active' and Name ='Premium Support' ","lookupConditionField1":"AssetId","field1Id":null}


    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,    List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        // Deserialize the list of invoices from the JSON string.
        System.debug('#~#~  processRecords start');
        Request request  = (DefaultLookupHelper.Request) JSON.deserialize(jsonParameter, DefaultLookupHelper.Request.class);
        System.debug('#~#~  processRecords reuest' + request);

        List <Object> field1Ids = new List <Object>();
        List <Object> field2Ids = new List <Object>();
        List <Object> field3Ids = new List <Object>();

        for (SObject obj : records) {
            if ( String.isNotBlank(request.targetJoinField1)) {
                field1Ids.add( obj.get(request.targetJoinField1));
            }
            if ( String.isNotBlank(request.targetJoinField2)) {
                field2Ids.add( obj.get(request.targetJoinField2));
            }
            if ( String.isNotBlank(request.targetJoinField3)) {
                field3Ids.add( obj.get(request.targetJoinField3));
            }
        }

        System.debug('#~#~  processRecords prep');
        processLookup(  request , field1Ids,  field2Ids,  field3Ids, records );

    }




}