/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-12-15
* @description   A helper for the DPL check request
*       5/15/2019: suppress DPL if the records are already in suspect or banned status
*       8/22/2019 put safe guard on batch operation
*
*       9/11/2019: DPL check class
*           DPL check class is first implemented as an synchronous .
*           During UAT process, we noticed that Opportunity Process builder has SOQL usage that close to limit.
*           In order to minimze the impact of DPLCHeck with Opportunity and other 'front end' process, we have changed the implementation to an asynchronous queueable job
*           On 9/6, there is an incident that in production, the queueable job priority was bumped down the lower tier.
*           DPLCHeck by natre is not time senstive. However, CPQ package has several key proceses to use queueable implementation
*           e.g. QueueableQuoteDocumentService, JSRGClient, QueueableContractOrdersClient, OrderPriceCalculatorService
*           In order to maximize the performance of CPQ process, the queueable interface will be replaced by a combination synchronous process or future job:
*           if DPL is with account, contact, address - we need reference to the old record to determine any change. so they are changed to syncrhonous process
*           for opportunity and case , we will implement as future method which is asynchronous but not interfere with job queue.
*
*      07/29/2020: Adding retry mechanism for status updates after compliance log is generated
*
*      09/30/2020: Merging SFDC-12059 changes from DEV/QA path with SDEV/SQA path 
* @group         Helper
*
*
*/
public without sharing class DPLCheckHelper implements DynamicBusinessRuleAction { // ,  Queueable{

public final static String EVENT_TYPE_CONTACT_CREATION = 'Contact Creation';
public final static String EVENT_TYPE_CONTACT_UPDATE = 'Contact Update';
public final static String EVENT_TYPE_CASE_CREATION = 'Case Creation';
public final static String EVENT_TYPE_OPPORTUNITY_CREATION = 'Opportunity Creation';
public final static String EVENT_TYPE_ADDRESS_CREATION = 'Address Creation';
public final static String EVENT_TYPE_ADDRESS_UPDATE = 'Address Update';
public final static String EVENT_TYPE_ACCOUNT_CREATION = 'Account Creation';
public final static String EVENT_TYPE_ACCOUNT_UPDATE = 'Account Update';

public final static String STATUS_PENDING = 'Pending';
public final static String STATUS_BANNED = 'Banned';
public final static String STATUS_SUSPECTED = 'Suspect';
public final static String STATUS_ACTIVE = 'Active';
//Added as a part of SFDC-19668
public final static String STATUS_NO_LONGER_WITH_COMPANY = 'No Longer with Company';

public final static Integer GRACE_PERIOD_HOURS = 24;
private final static Integer MAX_EVENT_24_HOURS = 10000; // if there are more than 10K records, account / contact / address  DPL will stop for

//Developer name for Technical Support record type (added for SFDC-12059)
private final static String CASE_REC_TYPE_TS = 'Technical_Support';


/*  // queueable
private Map<Id,SObject> myNewRecordMap;
private Map<Id,SObject> myOldRecordMap;
private List <SObject> myRecords;
private String myJsonParameter;
private String myTriggerOrder;
private String myTriggerContext;
*/

private static Set<Id> DPLIdSet = new Set<Id>();

// the list of all integration events in the current session. mostly for debugging purpose
@testVisible private  List<Process_Compliance_Check_Event__e> eventList = new List<Process_Compliance_Check_Event__e>();

public class FieldMap {
    public String AccountIdField;
    public String nameField;
    public String nameField2;
    public String streetField;
    public String cityField;
    public String stateField;
    public String countryField;
    public String stateCodeField;
    public String statusField;
    public String lastSuccessDPLField;

    FieldMap(String AccountIdField, String nameField, String nameField2, String streetField, String cityField, String stateField, String countryField, String stateCodeField, String statusField , String lastSuccessDPLField ) {
        this.AccountIdField = AccountIdField;
        this.nameField = nameField;
        this.nameField2 = nameField2;
        this.streetField = streetField;
        this.cityField = cityField;
        this.stateField = stateField;
        this.countryField = countryField;
        this.stateCodeField = stateCodeField;
        this.statusField = statusField;
        this.lastSuccessDPLField = lastSuccessDPLField;
    }

}
    
private final static Map<String, FieldMap> objFieldMap =  new Map<String, FieldMap>{
            'AccountBilling' =>  new FieldMap('Id', 'Name', '',
                    'Billingstreet', 'Billingcity', 'BillingState', 'BillingCountryCode', 'BillingStateCode', 'Compliance_Status__c', 'Last_Success_DPL__c'),
            'AccountShipping' =>  new FieldMap('Id', 'Name', '',
                    'ShippingStreet', 'Shippingcity', 'ShippingState', 'ShippingCountryCode', 'ShippingStateCode', 'Compliance_Status__c', 'Last_Success_DPL__c'),
            'Contact' =>  new FieldMap('AccountId', 'LastName', 'FirstName',
                    'MailingStreet', 'Mailingcity', 'MailingState', 'MailingCountryCode', 'MailingStateCode', 'Contact_Status__c', 'Last_Success_DPL__c'),
            'Address__c' =>  new FieldMap('Account__c', 'Account_Name__c', '',
                    'Street__c', 'City__c', 'State_Name__c', 'Country_ISO__c', 'State_ISO__c', 'Status__c' , 'Last_Success_DPL__c')

    };


/*
DPLRequest": {
      "name": "bleh",
      "address": {
          "state":"",
          "city":"",
          "country":"",
          "street":""
      },
      "maxReturnHits": 50
     }
 */
public class DPLRequest {
        public String recordId;
        public String parentId;
        DplCheckInfo dplCheckInfo;
    }

public class DplCheckInfo {
        public String name;
        public Address address;
        public Integer maxReturnHits;

    }

public class Address {
    public String city;
    public String country;
    public String state;
    public String street;
    public String stateCode;
}

/**
 * constructor for DPL checker
 *
 * @param sID
 * @param bSize
 * @param iRecordsBatch
 * @param iRunNumber
 */
/*    // queueable
public DPLCheckHelper(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,  List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext ) {

    this.myNewRecordMap = newRecordMap;
    this.myOldRecordMap = oldRecordMap;
    this.myRecords = records;
    this.myJsonParameter = jsonParameter;
    this.myTriggerOrder = triggerOrder;
    this.myTriggerContext = triggerContext;

}
*/



/**
 *  constructor without parameter. used by DynamicBusinessRuleActionRuleEngine to instainate class and invoke processRecords method
 */
public DPLCheckHelper(){

}

private void accountDPL (Set<Id > accountIds, Map <Id, DPLRequest> dplRecordAccounts){

    if (accountIds.size() > 0 ){

        List <Account> accounts = [ select Last_Success_DPL__c, 
                                           Compliance_Status__c, 
                                           Id, 
                                           Name, 
                                           Billingstreet, 
                                           BillingStateCode,  
                                           Billingcity, 
                                           BillingState, 
                                           BillingCountryCode,
                                           ShippingStreet, 
                                           Shippingcity, 
                                           ShippingState,  
                                           ShippingCountryCode 
                                    from Account 
                                    where Id in:accountIds FOR UPDATE]; //SFDC-15447 - Unable to Lock Rows Error Fix
        for (Account o: accounts ){
            if ((o.Last_Success_DPL__c == null || (o.Last_Success_DPL__c != null && o.Last_Success_DPL__c.addHours(GRACE_PERIOD_HOURS) < Datetime.now()   ) )
                    && o.Compliance_Status__c != STATUS_BANNED && o.Compliance_Status__c != STATUS_SUSPECTED
                    ) {
                if (String.isNotBlank(o.BillingCountryCode) ) {
                    DPLRequest request = createDPLRequest(o, o.Id, 'AccountBilling');
                    dplRecordAccounts.put(o.Id, request);
                    o.Compliance_Status__c = STATUS_PENDING; // mark all of those as pending
                } else if (String.isNotBlank(o.ShippingCountryCode) ) {
                    DPLRequest request = createDPLRequest(o, o.Id, 'AccountShipping');
                    dplRecordAccounts.put(o.Id, request);
                    o.Compliance_Status__c = STATUS_PENDING; // mark all of those as pending
                }
            }

        }
        withoutSharingDML.save(accounts); // update as pending

    }
}

private void contactDPL  (Set<Id> contactIds, Map <Id, DPLRequest> dplRecordContacts)  {

    if (contactIds.size() > 0 ){



        List <Contact> contacts = [ select Last_Success_DPL__c, Contact_Status__c, Id,  AccountId, LastName, FirstName, MailingStreet, Mailingcity , MailingState, MailingStateCode, MailingCountryCode  from Contact where Id in:contactIds   ];
        for (Contact o: contacts ){
            if ((o.Last_Success_DPL__c == null || (o.Last_Success_DPL__c != null && o.Last_Success_DPL__c.addHours(GRACE_PERIOD_HOURS) < Datetime.now()   ))
                 &&  String.isNotBlank(o.MailingCountryCode) && o.Contact_Status__c != STATUS_BANNED && o.Contact_Status__c != STATUS_SUSPECTED 
               	//Added as a part of SFDC-19668
				&& o.Contact_Status__c != STATUS_NO_LONGER_WITH_COMPANY){
                DPLRequest request = createDPLRequest(o, o.Id, 'Contact');
                dplRecordContacts.put( o.Id, request );
                o.Contact_Status__c = STATUS_PENDING; // mark all of those as pending
            }

        }
        withoutSharingDML.save(contacts); // update as pending

    }

}


private void opportunitiyDPL(Map <Id, DPLRequest> dplRecordAccounts, Map <Id, DPLRequest> dplRecordContacts, Map <Id, DPLRequest> dplRecordAddress, Map<Id,SObject> newRecordMap ){
    Set <Id> accountIds = new Set<Id>();
    Set <Id> contactIds = new Set<Id>();

    For (SObject o: newRecordMap.values()) {

        Id recordId = (Id) o.get('Id');


        if (o.get('AccountId') != null){
            accountIds.add((Id)o.get('AccountId'));
        }
        if (o.get('Distributor__c') != null){
            accountIds.add((Id)o.get('Distributor__c'));
        }
        if (o.get('Reseller__c') != null){
            accountIds.add((Id)o.get('Reseller__c'));
        }

        if (o.get('Contact_Name__c') != null){
            contactIds.add((Id)o.get('Contact_Name__c'));
        }
        if (o.get('SE_Involved__c') != null){
            contactIds.add((Id)o.get('SE_Involved__c'));
        }
        if (o.get('Primary_Contact__c') != null){
            contactIds.add((Id)o.get('Primary_Contact__c'));
        }
        if (o.get('Reseller_Contact__c') != null){
            contactIds.add((Id)o.get('Reseller_Contact__c'));
        }
        if (o.get('Distributor_Contact__c') != null){
            contactIds.add((Id)o.get('Distributor_Contact__c'));
        }

    }

    System.debug('~~#~~ DPLChecker accountIds: ' +accountIds );
    System.debug('~~#~~ DPLChecker contactIds: ' +contactIds );


    accountDPL (accountIds, dplRecordAccounts);
    contactDPL(contactIds, dplRecordContacts);



}

private void caseDPL(Map <Id, DPLRequest> dplRecordAccounts, Map <Id, DPLRequest> dplRecordContacts, Map <Id, DPLRequest> dplRecordAddress, Map<Id,SObject> newRecordMap ){

        Set <Id> accountIds = new Set<Id>();
        Set <Id> contactIds = new Set<Id>();

        For (SObject o: newRecordMap.values()) {

            Id recordId = (Id) o.get('Id');


            if (o.get('AccountId') != null){
                accountIds.add((Id)o.get('AccountId'));
            }

            if (o.get('ContactId') != null){
                contactIds.add((Id)o.get('ContactId'));
            }

        }

        System.debug('~~#~~ DPLChecker accountIds: ' +accountIds );
        System.debug('~~#~~ DPLChecker contactIds: ' +contactIds );


        accountDPL (accountIds, dplRecordAccounts);
        contactDPL(contactIds, dplRecordContacts);

    }

private DPLRequest createDPLRequest(SObject o, Id recordId,  String lookkupName  ){


    DPLCheckHelper.DPLRequest request = new DPLCheckHelper.DPLRequest();
    DplCheckInfo i = new DplCheckInfo();
    i.name = String.isNotBlank(objFieldMap.get(lookkupName).nameField2) ? (String) o.get(objFieldMap.get(lookkupName).nameField2) + ' ' : '';
    i.name += (String) o.get(objFieldMap.get(lookkupName).nameField);

    DPLCheckHelper.address addr = new DPLCheckHelper.address();
    addr.city = (String) o.get( objFieldMap.get(lookkupName).cityField);
    addr.state = (String) o.get(objFieldMap.get(lookkupName).stateField);
    addr.street = (String)o.get(objFieldMap.get(lookkupName).streetField);
    addr.country =(String)  o.get(objFieldMap.get(lookkupName).countryField);
    addr.stateCode =(String)  o.get(objFieldMap.get(lookkupName).stateCodeField);
    i.address = addr;
    request.recordId = (String) recordId;
    request.parentId = (String) o.get(objFieldMap.get(lookkupName).AccountIdField);
    request.dplCheckInfo = i;
    return request;

}

private void  prepDPL(Map <Id, DPLRequest> dplRecords, Map<Id,SObject> newRecordMap,
        Map<Id,SObject> oldRecordMap, String lookupName) {

    For (SObject o: newRecordMap.values()) {

        Id recordId = (Id) o.get('Id');
        SObject oldRecord = oldRecordMap != null ? oldRecordMap.get(recordId) : null;

        Boolean qualified = false;
        if (dplRecords.containsKey(recordId)) {
           // already in map, do noting skip
            qualified = false;
        } else if (
                ((o.get( objFieldMap.get(lookupName).lastSuccessDPLField ) != null &&  ((Datetime)o.get( objFieldMap.get(lookupName).lastSuccessDPLField )).addHours(GRACE_PERIOD_HOURS) >= Datetime.now() ) )
                ||  o.get( objFieldMap.get(lookupName).statusField )  == STATUS_BANNED || o.get( objFieldMap.get(lookupName).statusField )  == STATUS_SUSPECTED  ){
            // skip suspect and banned record, or in grace period
            qualified = false;
        } else if (oldRecord == null){ //         check if it is a new record
            qualified = true;
        } else if (
                ( o.get( objFieldMap.get(lookupName).nameField ) != oldRecord.get(objFieldMap.get(lookupName).nameField) ||
                o.get(objFieldMap.get(lookupName).streetField) != oldRecord.get(objFieldMap.get(lookupName).streetField) ||
                o.get(objFieldMap.get(lookupName).cityField) != oldRecord.get(objFieldMap.get(lookupName).cityField) ||
                o.get(objFieldMap.get(lookupName).stateField) != oldRecord.get(objFieldMap.get(lookupName).stateField) ||
                o.get(objFieldMap.get(lookupName).stateCodeField) != oldRecord.get(objFieldMap.get(lookupName).stateCodeField) ||
                        o.get(objFieldMap.get(lookupName).countryField) != oldRecord.get(objFieldMap.get(lookupName).countryField))
                        && String.isNotBlank(String.valueOf( o.get(objFieldMap.get(lookupName).countryField)) ) && String.isNotBlank(String.valueOf(o.get(objFieldMap.get(lookupName).nameField) ))
                ){  // min requirement is name and iso country code
            qualified = true;
        } else if (String.isNotBlank(objFieldMap.get(lookupName).nameField2)  && o.get(objFieldMap.get(lookupName).nameField2) != oldRecord.get(objFieldMap.get(lookupName).nameField2)){
            qualified = true;
        }

        // System.debug('~~#~~ DPLChecker o: ' + o + ' name : ' + objFieldMap.get(lookupName).nameField + ' ' +  o.get(objFieldMap.get(lookupName).nameField));

        if (qualified  ){
//            DPLCheckHelper.DPLRequest request = new DPLCheckHelper.DPLRequest();
//            DplCheckInfo i = new DplCheckInfo();
//            i.name = String.isNotBlank(nameField2) ? (String) o.get(nameField2) + ' ' : '';
//            i.name += (String) o.get(nameField);
//
//            DPLCheckHelper.address addr = new DPLCheckHelper.address();
//            addr.city = (String) o.get(cityField);
//            addr.state = (String) o.get(stateField);
//            addr.street = (String)o.get(streetField);
//            addr.country =(String)  o.get(countryField);
//            i.address = addr;
//            request.recordId = (String) recordId;
//            request.parentId = (String) o.get(AccountIdField);
//            request.dplCheckInfo = i;
            DPLRequest request = createDPLRequest(o, recordId, lookupName );
            dplRecords.put( recordId, request );

        }


    }

}

private void updatePending(Map <Id, DPLRequest> dplRecords, String sObjName , String statusField, String lastSuccessDPLField){


    if (dplRecords != null && dplRecords.size() > 0 ) {
        Set <Id> ids = dplRecords.keySet();
        String soql = ' select Id, ' + statusField + ' from ' + sObjName + ' where id in: ids';
        List<sObject> sobjList = Database.query(soql);
        for (SObject o : sobjList) {
            o.put(statusField, STATUS_PENDING);
            o.put(lastSuccessDPLField, null);
        }
        withoutSharingDML.save(sobjList);

    }
}

/**
 *
 *
 * @param newRecordMap
 * @param oldRecordMap
 * @param records
 * @param jsonParameter
 * @param triggerOrder
 * @param triggerContext
 */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                               Map<Id,SObject> oldRecordMap,  
                               List <SObject> records, 
                               String jsonParameter, 
                               String triggerOrder, 
                               String triggerContext) {


        Try {

            if (!System.isBatch() ){
                List <SObject> unqiueRecords = new List<SObject>();
                Map<Id,SObject>  uniqueNewRecordMap = new Map<Id,SObject>();
                Map<Id,SObject>  uniqueOldRecordMap = new Map<Id,SObject>();
                List <Id> uninqueRecordIds = new List <Id> ();
                for (SObject o: records){
                    if (o.Id != null && !DPLIdSet.contains(o.Id)){

                        DPLIdSet.add(o.Id);
                        unqiueRecords.add(o);
                        uninqueRecordIds.add(o.Id);
                        if (newRecordMap != null && newRecordMap.containsKey(o.Id)){
                            uniqueNewRecordMap.put(o.Id, newRecordMap.get(o.Id));
                        }
                        if (oldRecordMap != null && oldRecordMap.containsKey(o.Id)){
                            uniqueOldRecordMap.put(o.Id, oldRecordMap.get(o.Id));
                        }
                    }
                }

                /* 9/11 refactor queueable implementation
                // span all the queueable jobs
                System.debug('~~#~~ DPLChecker ' + ' queable jobs: ' + Limits.getQueueableJobs()  + ' job limit: ' +  Limits.getLimitQueueableJobs() );
                if (unqiueRecords.size() > 0 && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ){
                    // System.enqueueJob(new DPLCheckHelper( newRecordMap, oldRecordMap, records, jsonParameter,triggerOrder, triggerContext  ));
                    System.enqueueJob(new DPLCheckHelper( uniqueNewRecordMap, uniqueOldRecordMap, unqiueRecords, jsonParameter,triggerOrder, triggerContext  ));
                    System.debug('~~#~~ DPLChecker job queued successfully ');
                }
                 */

                String sObjName = ((Id)records[0].get('Id')).getSObjectType().getDescribe().getName();
                if (sObjName == 'Address__c' || sObjName == 'Account' || sObjName == 'Contact'){
                    DPLCheck( uniqueNewRecordMap, uniqueOldRecordMap, unqiueRecords, jsonParameter,triggerOrder, triggerContext  );
                } else {
                    // future
                    DPLCheckFuture(uninqueRecordIds, jsonParameter,triggerOrder, triggerContext  );
                }


            } else {
                System.debug('~~#~~ DPLChecker SKIP DPL SINCE IT IS IN BATCH');
            }

        } Catch (Exception e){
            // it fails mostly on recursive logic. so ignore
            System.debug('#### Exceptions: ' + e.getMessage());
        }



    }







@future static public void DPLCheckFuture( List <Id> recordIds, String jsonParameter, String triggerOrder, String triggerContext) {
    
    if(recordIds.isEmpty()){
        return;
    }

    String sObjName = recordIds[0].getSObjectType().getDescribe().getName();  // Opportunity or Case
    Map<Id,SObject> newRecordMap = new Map<Id,SObject>();
    Map<Id,SObject> oldRecordMap = new Map<Id,SObject>();
    List <SObject> records = new List <SObject>();
    if (sObjName == 'Opportunity'){
        For (Opportunity o: [select id, 
                                    AccountId, 
                                    Distributor__c, 
                                    Reseller__c, 
                                    Contact_Name__c, 
                                    SE_Involved__c, 
                                    Primary_Contact__c, 
                                    Reseller_Contact__c, 
                                    Distributor_Contact__c 
                             from Opportunity 
                             where id in :recordIds ]){
            records.add(o);
            newRecordMap.put(o.id, o);
        }
    } else if (sObjName == 'Case'){
        // For (Case o: [select id, AccountId, ContactId from Case where id in :recordIds ]){
        //SFDC_12059: Added a where condition to run DPL check only for Tech Support cases
        for (Case o: [select id, 
                             AccountId, 
                             ContactId 
                      from Case 
                      where id in :recordIds 
                      and RecordType.DeveloperName = :CASE_REC_TYPE_TS]){ 

            records.add(o);
            newRecordMap.put(o.id, o);
        }
    }
    if (records.size() > 0){
        // call the main DPL logic
        DPLCheckHelper d = new DPLCheckHelper();
        d.DPLCheck(newRecordMap, oldRecordMap, records, jsonParameter,triggerOrder, triggerContext  );
    }

}

/**
 *
 *
 * @param newRecordMap
 * @param oldRecordMap
 * @param records
 * @param jsonParameter
 * @param triggerOrder
 * @param triggerContext
 */
public void DPLCheck(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,  List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){


    System.debug('~~#~~ DPLChecker newRecordMap: ' +newRecordMap );
    System.debug('~~#~~ DPLChecker oldRecordMap: ' +oldRecordMap );
    System.debug('~~#~~ DPLChecker records: ' +records );
    System.debug('~~#~~ DPLChecker jsonParameter: ' +jsonParameter );
    System.debug('~~#~~ DPLChecker triggerOrder: ' +triggerOrder );
    System.debug('~~#~~ DPLChecker triggerContext: ' +triggerContext );

    String sObjName = ((Id)records[0].get('Id')).getSObjectType().getDescribe().getName();
    // String statusField = '';
    String eventType = '';

    Map <Id, DPLRequest> dplRecordsAccount = new Map <Id, DPLRequest>();
    Map <Id, DPLRequest> dplRecordsAddress = new Map <Id, DPLRequest>();
    Map <Id, DPLRequest> dplRecordsContact = new Map <Id, DPLRequest>();

    Integer DPLCount = [select count() from Integration_Snapshot__c where Integration_App__c = 'DPL Trigger' and LastModifiedDate > Yesterday];
    System.debug('DPL Count in last 24 hours: ' + DPLCount);

    if (sObjName == 'Address__c'){
        if (DPLCount != null && DPLCount > MAX_EVENT_24_HOURS ){
            System.debug('Skip Address DPL check because ' + DPLCount + 'exceed safeguard limit of ' + MAX_EVENT_24_HOURS);
            return;
        }
        // check which records qualify for DPL check
        prepDPL(dplRecordsAddress, newRecordMap, oldRecordMap, sObjName  );
        updatePending(dplRecordsAddress, sObjName,  objFieldMap.get(sObjName).statusField, objFieldMap.get(sObjName).lastSuccessDPLField );
        if (oldRecordMap == null || oldRecordMap.size() == 0){
            eventType = EVENT_TYPE_ADDRESS_CREATION;
        } else {
            eventType = EVENT_TYPE_ADDRESS_UPDATE;
        }
    } else if (sObjName == 'Account'){
        if (DPLCount != null && DPLCount > MAX_EVENT_24_HOURS ){
            System.debug('Skip Account DPL check because ' + DPLCount + 'exceed safeguard limit of ' + MAX_EVENT_24_HOURS);
            return;
        }
        // check which records qualify for DPL check - billing address
        prepDPL(dplRecordsAccount, newRecordMap, oldRecordMap,  sObjName + 'Billing' );
        // check which records qualify for DPL check - shipping
        prepDPL(dplRecordsAccount, newRecordMap, oldRecordMap, sObjName + 'Shipping' );
        updatePending(dplRecordsAccount, sObjName,  objFieldMap.get(sObjName + 'Billing' ).statusField, objFieldMap.get(sObjName + 'Billing').lastSuccessDPLField );
        if (oldRecordMap == null || oldRecordMap.size() == 0){
            eventType = EVENT_TYPE_ACCOUNT_CREATION;
        } else {
            eventType = EVENT_TYPE_ACCOUNT_UPDATE;
        }
    } else if (sObjName == 'Contact') {
        if (DPLCount != null && DPLCount > MAX_EVENT_24_HOURS ){
            System.debug('Skip Contact DPL check because ' + DPLCount + 'exceed safeguard limit of ' + MAX_EVENT_24_HOURS);
            return;
        }
        // check which records qualify for DPL check - Mailing
        prepDPL(dplRecordsContact, newRecordMap, oldRecordMap, sObjName );
        updatePending(dplRecordsContact, sObjName, objFieldMap.get(sObjName).statusField, objFieldMap.get(sObjName).lastSuccessDPLField );
        if (oldRecordMap == null || oldRecordMap.size() == 0){
            eventType = EVENT_TYPE_CONTACT_CREATION;
        } else {
            eventType = EVENT_TYPE_CONTACT_UPDATE;
        }
    } else if (sObjName == 'Opportunity') {
        opportunitiyDPL(dplRecordsAccount, dplRecordsContact, dplRecordsAddress, newRecordMap );
        eventType = EVENT_TYPE_OPPORTUNITY_CREATION;

    } else if (sObjName == 'Case'){
        caseDPL(dplRecordsAccount, dplRecordsContact, dplRecordsAddress, newRecordMap );
        eventType = EVENT_TYPE_CASE_CREATION;
    }


    // to do capture the opportunity and case creation




    if (dplRecordsAccount.size() > 0 ) {
        System.debug('~~#~~ DPLChecker dplRecordsAccount: ' + dplRecordsAccount );
        List<Database.SaveResult> results = publishObject(eventType, 'Account', dplRecordsAccount);
        System.debug('~~#~~ DPLChecker dplRecordsAccount results: ' + results );

    }

    if (dplRecordsContact.size() > 0 ) {
        System.debug('~~#~~ DPLChecker dplRecordsContact: ' + dplRecordsContact );
        List<Database.SaveResult> results = publishObject(eventType, 'Contact', dplRecordsContact);
        System.debug('~~#~~ DPLChecker dplRecordsContact results: ' + results );

    }

    if (dplRecordsAddress.size() > 0 ) {
        System.debug('~~#~~ DPLChecker dplRecordsAddress: ' + dplRecordsAddress );
        List<Database.SaveResult> results = publishObject(eventType, 'Address__c', dplRecordsAddress);
        System.debug('~~#~~ DPLChecker dplRecordsAddress results: ' + results );
    }



    // to do : logging when empty ??

}

/**
 *
 *
 * @param operationType
 * @param dplRecords
 *
 * @return List<Database.SaveResult> generated
 */
public  List<Database.SaveResult>  publishObject( String operationType, String sObjName, Map <Id, DPLRequest> dplRecords){

    List<Process_Compliance_Check_Event__e> intEvents = new List<Process_Compliance_Check_Event__e>();
    List<Database.SaveResult> results = new List<Database.SaveResult>();
    // 2019-05-30 . add integration snapshot
    List <Integration_Snapshot__c> snapshots = new List <Integration_Snapshot__c>();


    LogModel log = LogModel.startLog('DPLCheckHelper', 'publishObject');
    try {
        for (Id i : dplRecords.keySet()) {
            Process_Compliance_Check_Event__e iEvent = new Process_Compliance_Check_Event__e();
            iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
            iEvent.Object_Name__c = sObjName;
            iEvent.Record_ID__c = i;
            iEvent.Parent_ID__c = dplRecords.get(i).parentId;
            iEvent.Object_Payload__c = JSON.serialize(dplRecords.get(i));
            iEvent.Event_Type__c = operationType;
            intEvents.add(iEvent);
            eventList.add(iEvent);

            Integration_Snapshot__c snapshot = new Integration_Snapshot__c();
            // so the external id should have the format of concatenation of object type , system name, transaction type and record id field
            snapshot.External_ID__c = sObjName + '_' + 'SF' + '_' + 'DPL' + '_' + i;
            snapshot.Integration_App__c = 'DPL Trigger';
            snapshot.System_Name__c = 'Salesforce';
            snapshot.Sync_Status__c = 'Success';
            snapshot.Record_ID__c = i;
            snapshot.System_Record_ID__c = i;
            snapshot.Object_Name__c = sObjName;
            snapshot.Message_Payload__c = JSON.serialize(dplRecords.get(i));
            snapshots.add(snapshot);

        }

        System.debug('~~#~~ DPLChecker eventList: ' + eventList);
        results = withoutSharingDML.save(intEvents);
        upsert snapshots External_ID__c;

    } Catch (Exception e){
        System.debug('#### Exceptions: ' + e.getMessage());
        log.addExceptionLog(e);
    }
    return results;
}



/*******************************************************************************************************
* @description update the  status for the corresponding object
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    public static void updateStatus(List <SObject> records){

        //Create a log instance
        LogModel log = LogModel.startLog('DPLCheckHelper',
                                         'updateStatus'
                                        );

        try{
            Map <Id, SObject> updateMap = new Map <Id, SObject>();
            
            //Loop through compliance records and prepare records for update
            //Order is important since Account is populated for Address and contact compliance logs.
            //Hence Address first, then Contact and then Account
            for(SObject o: records){
                Compliance_Log__c c = (Compliance_Log__c) o;
                if (c.Address__c != null && !updateMap.containsKey(c.Address__c)){
                    updateMap.put(c.Address__c, new Address__c(Id=c.Address__c, 
                                                               Status__c = c.Number_Of_Hits__c == 0? STATUS_ACTIVE: (c.Number_Of_Hits__c > 0 ? STATUS_SUSPECTED : '')));
                } 
                else if (c.Contact__c != null && !updateMap.containsKey(c.Contact__c)){
                    updateMap.put(c.Contact__c, new Contact(Id=c.Contact__c, 
                                                            Contact_Status__c = c.Number_Of_Hits__c == 0? STATUS_ACTIVE: (c.Number_Of_Hits__c > 0 ? STATUS_SUSPECTED : '')));
                } 
                else if (c.Log_Account__c != null && !updateMap.containsKey(c.Log_Account__c)){
                    updateMap.put(c.Log_Account__c, new Account(Id=c.Log_Account__c, 
                                                                    Compliance_Status__c = c.Number_Of_Hits__c == 0? STATUS_ACTIVE: (c.Number_Of_Hits__c > 0 ? STATUS_SUSPECTED : '')));
                }
            }

            //If UpdateMap is not empty then update records
            if(!updateMap.isEmpty()){
                //Prepare a map for retrying if error occurs
                Map <Id, SObject> retryMap = new Map <Id, SObject>();
                for(Database.SaveResult sr : Database.update(updateMap.values(), false)){
                    if(!sr.success){
                        for(Database.Error error: sr.getErrors()){
                            if(String.isNotBlank(error.getMessage()) && error.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                                log.addLog('Error First try: ' + error.getMessage());
                                if(!retryMap.containsKey(sr.getId())){
                                    //Prepare map for retry
                                    retryMap.put(sr.getId(),updateMap.get(sr.getId()));
                                }
                            }
                        } //END FOR
                    }
                } //END FOR
                
                //Retry if any updates failed due to lock errors
                if(!retryMap.isEmpty()){
                    for(Database.SaveResult retrySR : Database.update(retryMap.values(), false)){
                        if(!retrySR.success){
                            for(Database.Error retryError: retrySR.getErrors()){
                                log.addLog('Error Second try: ' + retryError.getMessage());
                            } //END FOR
                        }
                    } //END FOR  
                }
            }
            //End Log
            log.endLog('End of update status log');
        }
        catch(System.DmlException de){
            System.debug('Exception updating compliance status' +  de.getMessage());
            log.addExceptionLog(de);
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }
    }
}