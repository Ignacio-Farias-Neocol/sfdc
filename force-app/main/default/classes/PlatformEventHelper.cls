/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
*                2019-09-01 : change qualfifier from public to global so that when other package e.g. D&B optimizer change account and contact, it
*                can call the platform event as well.
* @description   A helper for the platform publication and subscription . note use without sharing to make sure that integration is supported regardless of user
* @group         Helper
*
*/
global without sharing class PlatformEventHelper implements DynamicBusinessRuleAction{

    global final static String EVENT_TYPE_INSERT = 'INSERT';
    global final static String EVENT_TYPE_UPDATE = 'UPDATE';
    global final static String EVENT_TYPE_DELETE = 'DELETE';

    // prevent recursive execution
    global static Boolean isAlreadyInsert = false;
    global static Boolean isAlreadyUpdate = false;
    global static Boolean isAlreadyDelete = false;

    // the list of all integration events in the current session. mostly for debugging purpose
    @testVisible private static  List<Integration_Event__e> eventList = new List<Integration_Event__e>();

    private final static Integer MAX_EVENT_24_HOURS = 10000; // if there are more than 10K records, account / contact / address  DPL will stop for



    /**
     *
     *
     * @param objName
     * @param newRecordMap
     * @param oldRecordMap
     * @param filteredRecords
     * @description  given the map of old and new object , find if any of the designated fields are changed. if so, copy to the fitlered list.
     */
    @TestVisible
    global static Boolean findFilteredRecords (String objName, Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> filteredRecords ){


        Boolean anyFilter = false;

        List<Platform_Event_Filter__mdt> filters = new List < Platform_Event_Filter__mdt>([
                select id, Object_API__c, Field_API__c
                from Platform_Event_Filter__mdt
                where Object_API__c = :objName
        ]);

        System.debug('#### Object: ' + objName + ' filters: ' + filters);

        // only try to filter if there is at least one rule, otherwise, leave the filteredRecords intact.
        if (filters != null && filters.size() > 0) {

            anyFilter = true;
            for (Id i : newRecordMap.keySet()) {
                SObject newObject = newRecordMap.get(i);
                SObject oldObject = oldRecordMap.get(i);
                for (Platform_Event_Filter__mdt filter : filters) {
                    if (newObject.get(filter.Field_API__c) != oldObject.get(filter.Field_API__c)) {
                        System.debug('#### Field changed: ' + filter.Field_API__c);
                        System.debug('#### Field old: ' + oldObject.get(filter.Field_API__c));
                        System.debug('#### Field new: ' + newObject.get(filter.Field_API__c));
                        filteredRecords.add(newObject);
                        break;
                    }
                }

            }
        }

        System.debug('#### filtered Records ' + filteredRecords);
        return anyFilter;



    }


    /**
     * @description  implementation of DynamicBusinessRuleAction interface
     *
     * @param recordMap - map from trigger context
     * @param records - list from trigger context
     * @param jsonParameter - not used
     * @param triggerOrder - pre or post
     */
    global void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,  List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){

        System.debug('#### Platform Event Starts: ' +  triggerContext + ' records: ' + records );

        String eventType;

        List <SObject > filteredRecords = new List <Sobject> ();

        if (triggerContext.contains('Delete')){
            if (isAlreadyDelete == null || isAlreadyDelete == false ) {
                eventType = EVENT_TYPE_DELETE;
                filteredRecords = records;
                System.debug('#### Delete platform fired first time');
                isAlreadyDelete = true;
            } else {
                System.debug('#### Delete platform already fired');
                return;
            }

        } else  if (triggerContext.contains('Insert')){
            if (isAlreadyInsert == null || isAlreadyInsert == false){
                eventType = EVENT_TYPE_INSERT;
                filteredRecords = records;
                System.debug('#### Insert platform fired first time');
                isAlreadyInsert = true;
            } else {
                System.debug('#### Insert platform already fired');
                return;
            }

        } else  if (triggerContext.contains('Update')){


            System.debug('#### isAlreadyUpdate: ' + isAlreadyUpdate);

            if (isAlreadyUpdate == null || isAlreadyUpdate == false ) {
                eventType = EVENT_TYPE_UPDATE;

                Boolean anyFilter = false;
                if (newRecordMap != null && newRecordMap.size() > 0 && oldRecordMap != null && oldRecordMap.size() > 0) {

                    String objName = ((id) ((records[0].get('Id')))).getSObjectType().getDescribe().getName();
                    anyFilter = findFilteredRecords(objName, newRecordMap, oldRecordMap, filteredRecords);

                    /*
                    List<Platform_Event_Filter__mdt> filters = new List < Platform_Event_Filter__mdt>([
                            select id, Object_API__c, Field_API__c
                            from Platform_Event_Filter__mdt
                            where Object_API__c = :objName
                    ]);

                    System.debug('#### Object: ' + objName + ' filters: ' + filters);

                    if (filters != null && filters.size() > 0) {
                        filteredRecords = new List <SObject >();
                        for (Id i : newRecordMap.keySet()) {
                            SObject newObject = newRecordMap.get(i);
                            SObject oldObject = oldRecordMap.get(i);
                            for (Platform_Event_Filter__mdt filter : filters) {
                                if (newObject.get(filter.Field_API__c) != oldObject.get(filter.Field_API__c)) {
                                    System.debug('#### Field changed: ' + filter.Field_API__c);
                                    System.debug('#### Field old: ' + oldObject.get(filter.Field_API__c));
                                    System.debug('#### Field new: ' + newObject.get(filter.Field_API__c));
                                    filteredRecords.add(newObject);
                                    break;
                                }
                            }

                        }
                    }

                     */
                }

                if (!anyFilter){ // if there is no filter, just use the all records
                    filteredRecords = records;
                }

                if(filteredRecords != null && filteredRecords.size() > 0  ){
                    System.debug('#### Update platform fired first time');
                    isAlreadyUpdate = true;
                } else {
                    System.debug('#### Update platform fired but no events');
                }


            } else {
                System.debug('#### Update platform already fired');
                return;
            }


        }

        List<Database.SaveResult>  results = publishObject(eventType, filteredRecords);

        // nice to have : logging when empty

    }

    /**
     *  TO DO: add filter by fieldSet in case the whole object record is too large to be serailzed.
     *
     * @param operationType
     * @param listObject
     *
     * @return
     */
    global  List<Database.SaveResult>  publishObject( String operationType, List <sObject> listObject){

        List<Database.SaveResult> results = new List<Database.SaveResult>();

        LogModel log = LogModel.startLog('PlatformEventHelper', 'publishObject');
        try {


            if (listObject != null && listObject.size() > 0) {
                List<Integration_Event__e> intEvents = new List<Integration_Event__e>();
                // 2019-03-21 . add integration snapshot
                List <Integration_Snapshot__c> snapshots = new List <Integration_Snapshot__c>();

                String objName;
                String objLabel;
                objLabel = ((id) ((listObject[0].get('Id')))).getSObjectType().getDescribe().getlabel();
                objName = ((id) ((listObject[0].get('Id')))).getSObjectType().getDescribe().getName();
                log.addlog(objLabel + '-' + objName +' size: ' + listObject.size());
                // 2019-08-23 : this is a safety check to prevent massive Account or Contact platform event blocking the operational important event such as order
                if (objName == 'Account' || objName == 'Contact'){
                    Integer ObjectPlatformCount = [select count() from Integration_Snapshot__c where Integration_App__c = 'Platform Event Trigger' and Object_name__c in ('Account', 'Contact') and LastModifiedDate > Yesterday];
                    System.debug('Object Specific in last 24 hours: ' + ObjectPlatformCount);
                    if (ObjectPlatformCount != null && ObjectPlatformCount > MAX_EVENT_24_HOURS ) {
                        log.addErrorLog(+objName + ' Platform Event in last 24 hours:  ' + ObjectPlatformCount + ' exceeds threshold of ' + MAX_EVENT_24_HOURS);
                        log.endLog('Did not create Platform event due to max event');
                        return results;
                    }
                }

                for (sObject obj : listObject) {
                    Integration_Event__e iEvent = new Integration_Event__e();
                    iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                    iEvent.Object_Name__c = objName;
                    iEvent.Record_ID__c = (String) obj.get('Id');
                    iEvent.Object_Payload__c = JSON.serialize(obj);
                    iEvent.Event_Type__c = operationType;
                    intEvents.add(iEvent);
                    eventList.add(iEvent);


                    Integration_Snapshot__c snapshot = new Integration_Snapshot__c();
                    // so the external id should have the format of concatenation of object type , system name, transaction type and record id field
                    snapshot.External_ID__c = objName + '_' + 'SF' + '_' + 'Platform' + '_' + (String) obj.get('Id');
                    snapshot.Integration_App__c = 'Platform Event Trigger';

                    if(objName=='Order' &&  operationType=='FULFILLED')
                    {
                        snapshot.External_ID__c = objName + '_' + 'SF' + '_' + 'Platform' + '_PAM_' + (String) obj.get('Id');
                        snapshot.Integration_App__c = 'Platform Event Trigger PAM';
                    }
                    /**
                     * Added as a part of SFDC-15817: Void Order functionality : START
                     * */ 
                    if(objName=='Order' &&  operationType=='VOID_ORDER'){
                        snapshot.External_ID__c = objName + '_' + 'SF' + '_' + 'Platform' + '_VOID_ORDER_' + (String) obj.get('Id');
                        snapshot.Integration_App__c = 'Platform Event Trigger VOID ORDER';
                    }             
                    /**
                     * Added as a part of SFDC-15817: Void Order functionality : END
                     * */ 
                    snapshot.System_Name__c = 'Salesforce';
                    snapshot.Sync_Status__c = 'Success';
                    snapshot.Record_ID__c = (String) obj.get('Id');
                    snapshot.System_Record_ID__c = (String) obj.get('Id');
                    snapshot.Object_Name__c = objName;
                    snapshot.Message_Payload__c = JSON.serialize(obj);
                    snapshots.add(snapshot);
                }

                log.addLog('Eventlist size: ' + intEvents.size());
                log.addLog('Snapshot size: ' + snapshots.size());
                System.debug('#### Events Sent: ' + intEvents);
                System.debug('#### Snapshot : ' + snapshots);

                results = withoutSharingDML.save(intEvents);
                for(Database.SaveResult sr: results){
                    if(!sr.isSuccess()){
                        //Operation failed
                        for(Database.Error err : sr.getErrors()) {
                            log.addErrorLog(err.getMessage());
                        }
                    }
                    else{
                        log.addLog(sr.getId());
                    }
                }
                upsert snapshots External_ID__c;
            }
            log.endLog('PlatformEventHelper log ended');
        }
        catch(DmlException de){
            System.debug('#### DML Exceptions: ' + de.getMessage());
            log.addExceptionLog(de);
        } 
        catch (Exception e) {
            System.debug('#### Exceptions: ' + e.getMessage());
            log.addExceptionLog(e);
        }
        return results;

    }


    /** 
    * @description :  generate a 36 chars unique GUID from AES Key
	* 
	* @param  : n/a
	* @return : GUID e.g. 7ca391f6-6588-c4b7-f966-c7c3b3861a5b
    * @example 
        String uuid = PlatformEventHelper.GUIDGenerator();
        System.debug('UUID: ' + uuid); 
    * 
	*/
    global static String GUIDGenerator(){

        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        // system.debug(guid);
        return guid; 

    }

    /** 
    * @description :  generate a 10 char random string wit prefix YYMM
	*  it does 100% guarante to be unquie but it should be good enough as the transaction id 
	* @param  : n/a
	* @return : 10 char random string  e.g. 18101f1453
    * @example 
        String uuid = PlatformEventHelper.GUID10DigitGenerator();
        System.debug('UUID: ' + uuid); 
    * 
	*/
    global static String GUID10DigitGenerator(){
        return Datetime.now().format('yyMM') + GUIDGenerator().substring(0,6);
    }

}