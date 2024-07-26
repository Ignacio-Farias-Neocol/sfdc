/**
* @author IY
* @date 2019
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to populate assigned serial when inserting new subscription product
* on renewal
*
*
*
*
*
* https://bugs.cudaops.com/browse/SFDC-6360
* Objective:
Ensure that when new subscriptions are purchased in a bundle which has already been assigned a Serial, the existing Serial is assigned to the new subscriptions.

Solution:
CPQ will identify new subscriptions that are being added to an existing serial through introduction of new fields
on Quote Line → OrderItem → SBQQ_Subscriptionc: New_Sub_Existing_Serial_c.

When a Subscription record is created with SBQQ_Subscriptionc.New_Sub_Existing_Serialc = TRUE and the SBCF_Serial_Number_c field is null,
apex logic should be invoked which queries for new Subscription's RootID (could be Asset or Subscription),
collects all active Serials assigned to that RootID record, and creates Assigned Serials
which relate the Serial to the Subscription and RootID Record.

If a new Subscription record is created with SBQQ_Subscriptionc.New_Sub_Existing_Serialc = TRUE and
the SBCF_Serial_Numberc field is not null,
apex logic should be invoked which queries for the Serial numbers named in the SBCF_Serial_Number_c field and
creates Assigned Serials which relate to the Serial to the Subscription and RootID record.

6/18: found that SBQQ__Subscription__c.rootSubIds is not set during insert. use update instead. and only when is changed from rootSubIds from not null

*
*/
public with sharing class DynamicBusinessRuleNewProdSub implements DynamicBusinessRuleAction {

    public static String subPrefix = 'xxx';
    /*******************************************************************************************************
    * @description  create assigned serial for new subscriptions
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap,  Map<Id,SObject> oldRecordMap,  List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){

        // assumptions: all of the records have passed the condition of premimum case entitlement

        System.debug('*#*## DynamicBusinessRuleNewProdSub ' + ' Starts');

        Set <Id > rootAssetIds = new Set <Id>();
        Set <Id > rootSubIds  = new Set <Id>();
        Set <String> existingSerialNumers = new Set <String>();

        Map<Id, Serial__c> subSerialMap = new Map<Id, Serial__c>();

        for (SObject obj : records) {
            SBQQ__Subscription__c s = (SBQQ__Subscription__c) obj;
            subPrefix = ((String)s.id).left(3);  // CPQ sub prefix is different in each env.

            if (s.New_Sub_Existing_Serial__c == true && s.SBQQ__RootId__c != null && oldRecordMap != null && ((SBQQ__Subscription__c)oldRecordMap.get(s.Id)).SBQQ__RootId__c == null  ){
                // first check if SBCF_Serial_Number__c is null or not
                if (String.isNotBlank( s.SBCF_Serial_Number__c)) {
                    List<String> serials = s.SBCF_Serial_Number__c.split(',');
                    existingSerialNumers.addAll(serials);
                } else  {
                    // find out the root id , either asset of subscription
                    if (s.SBQQ__RootId__c.startsWith('02i')){
                        rootAssetIds.add(s.SBQQ__RootId__c);
                    } else if (s.SBQQ__RootId__c.startsWith(subPrefix)){
                        rootSubIds.add(s.SBQQ__RootId__c);
                    }
                }
            }

        }

        // note: consider to tune this SOQL
        List <Serial__c> existingSerials = [select id, Serial_Number__c  from Serial__c
        where Serial_Number__c in:existingSerialNumers  and Serial_Number__c != null  ];

        List <Assigned_Serial__c> rootAssetAssignedSerials = [select Appliance_Line_Type__c, Asset__c, Base_SKU__c, Contract__c,
                Date_Of_Replacement__c, End_User_Account__c, External_ID__c, Id,  Name, Parent_Subscription__c,
                Serial__c, Serial_Number__c, Status__c, Subscription__c, Subscription_End_Date__c, Subscription_Name__c,
                Subscription_Start_Date__c, Unique_Contract_ID__c from Assigned_Serial__c
        where Asset__c in:rootAssetIds and Asset__c != null    ];

        List <Assigned_Serial__c> rootSubAssignedSerials = [select Appliance_Line_Type__c, Asset__c, Base_SKU__c, Contract__c,
                Date_Of_Replacement__c, End_User_Account__c, External_ID__c, Id,  Name, Parent_Subscription__c,
                Serial__c, Serial_Number__c, Status__c, Subscription__c, Subscription_End_Date__c, Subscription_Name__c,
                Subscription_Start_Date__c, Unique_Contract_ID__c from Assigned_Serial__c
        where (Parent_Subscription__c in:rootSubIds or Subscription__c in:rootSubIds) and  Parent_Subscription__c != null ];

        System.debug('*#*## DynamicBusinessRuleNewProdSub rootAssetAssignedSerials ' + rootAssetAssignedSerials);
        System.debug('*#*## DynamicBusinessRuleNewProdSub rootSubAssignedSerials ' + rootSubAssignedSerials);
        System.debug('*#*## DynamicBusinessRuleNewProdSub existingSerials ' + existingSerials);

        List <Assigned_Serial__c> newAssignedSerials = new List <Assigned_Serial__c>();

        for (SObject obj : records) {
            SBQQ__Subscription__c s = (SBQQ__Subscription__c) obj;
            Set <String>  serialAdded = new Set <String>();

            System.debug('*#*## DynamicBusinessRuleNewProdSub new subscription: ' + s);
            if (s.New_Sub_Existing_Serial__c == true && s.SBQQ__RootId__c != null && oldRecordMap != null && ((SBQQ__Subscription__c)oldRecordMap.get(s.Id)).SBQQ__RootId__c == null ) {

                if (String.isNotBlank( s.SBCF_Serial_Number__c)){
                    for (Serial__c r : existingSerials ){
                        if (s.SBCF_Serial_Number__c.contains(r.Serial_Number__c)){
                            Assigned_Serial__c a = newAssignedSerial(s, r);
                            newAssignedSerials.add(a);
                        }
                    }

                }else if (  s.SBQQ__RootId__c.startsWith('02i')){
                    // asset
                    for (Assigned_Serial__c assignedSerial: rootAssetAssignedSerials){
                        if (s.SBQQ__RootId__c == assignedSerial.Asset__c ){
                            // only insert another assigned serial if one does not exist
                            if (!serialAdded.contains(assignedSerial.Serial_Number__c)){
                                Assigned_Serial__c a = cloneAssignedSerial(s, assignedSerial);
                                newAssignedSerials.add(a);
                                serialAdded.add(a.Serial_Number__c);
                            }
                        }
                    }
                } else if (  s.SBQQ__RootId__c.startsWith(subPrefix)){
                    // matched subscritpion as parent
                    for (Assigned_Serial__c assignedSerial: rootSubAssignedSerials){
                        if (s.SBQQ__RootId__c == assignedSerial.Parent_Subscription__c ){
                            // only insert another assigned serial if one does not exist
                            if (!serialAdded.contains(assignedSerial.Serial_Number__c)){
                                Assigned_Serial__c a = cloneAssignedSerial(s, assignedSerial);
                                a.Subscription__c = s.Id; // make sure this is done after trigger
                                newAssignedSerials.add(a);
                                serialAdded.add(a.Serial_Number__c);
                            }
                        }
                    }
                    // matched subscritpion as subscription only
                    for (Assigned_Serial__c assignedSerial: rootSubAssignedSerials){
                        if (s.SBQQ__RootId__c == assignedSerial.Subscription__c ){
                            // only insert another assigned serial if one does not exist
                            if (!serialAdded.contains(assignedSerial.Serial_Number__c)){
                                Assigned_Serial__c a = cloneAssignedSerial(s, assignedSerial);
                                a.Subscription__c = s.Id; // make sure this is done after trigger
                                newAssignedSerials.add(a);
                                serialAdded.add(a.Serial_Number__c);
                            }
                        }
                    }

                }

                // now that all the serials are populated, set the comma delimited list of serial in sub
                for (String serial: serialAdded){
                    s.SBCF_Serial_Number__c += serial + ',';
                }

            }

        }

        // now insert the assigned serials
        if (newAssignedSerials.size() > 0){
            DML.save(newAssignedSerials)   ;
        }

        System.debug('*#*## DynamicBusinessRuleNewProdSub ' + ' assign serial added ' +  newAssignedSerials);

        // assume this procedure is executed with pre trigger update context. so no need to do DML on subscription
        System.debug('*#*## DynamicBusinessRuleNewProdSub ' + ' modified subscription' +  records);

    }


    /**
     *
     *
     * @param Assigned_Serial__c assignedSerial
     *
     * @return cloned Assigned_Serial__c
     */
    Private Assigned_Serial__c cloneAssignedSerial(SBQQ__Subscription__c s, Assigned_Serial__c assignedSerial ){
        Assigned_Serial__c a = new Assigned_Serial__c();
        a.Asset__c = assignedSerial.Asset__c;
        a.Contract__c = assignedSerial.Contract__c;
        a.Date_Of_Replacement__c = assignedSerial.Date_Of_Replacement__c;
        a.End_User_Account__c = assignedSerial.End_User_Account__c;
        a.Parent_Subscription__c = assignedSerial.Parent_Subscription__c;
        a.Serial__c = assignedSerial.Serial__c;
        a.Subscription__c = s.Id; // make sure this is done after trigger
        // external id logic used by mulesoft : serial + asset + subscription
        // a.External_ID__c = '' + a.Serial__c + (a.Asset__c != null? a.Asset__c : '') + (a.Parent_Subscription__c != null? a.Parent_Subscription__c : '') +  a.Subscription__c;
        a.External_ID__c = '' + a.Serial__c + (a.Asset__c != null? String.valueOf(a.Asset__c) : '') + (a.Parent_Subscription__c != null? String.valueOf(a.Parent_Subscription__c) : '') +  a.Subscription__c;
        return a;
    }

//
    /**
     *
     *
     * @param SBQQ__Subscription__c
     *
     * @return new Assigned_Serial__c
     */
    Private Assigned_Serial__c newAssignedSerial(SBQQ__Subscription__c s, Serial__c r ){

        Assigned_Serial__c a = new Assigned_Serial__c();
        a.Contract__c  =  s.SBQQ__Contract__c ;
        a.End_User_Account__c = s.SBQQ__Account__c;
        if ( String.isNotBlank(s.SBQQ__RootId__c) && s.SBQQ__RootId__c.startsWith('02i')){ // asset
            a.Asset__c = s.SBQQ__RootId__c;
        } else if ( String.isNotBlank(s.SBQQ__RootId__c) && s.SBQQ__RootId__c.startsWith(subPrefix)){
            a.Parent_Subscription__c = s.SBQQ__RootId__c;
        }
        a.Subscription__c = s.Id;
        a.Serial__c = r.Id;
        // external id logic used by mulesoft : serial + asset + parent subscription + subscription

        System.debug('*#*## DynamicBusinessRuleNewProdSub  serial:' +  r);
        System.debug('*#*## DynamicBusinessRuleNewProdSub subscription:' +  s);
        System.debug('*#*## DynamicBusinessRuleNewProdSub asset:' +  a.Asset__c);

        a.External_ID__c = '' + a.Serial__c + (a.Asset__c != null? String.valueOf(a.Asset__c) : '') + (a.Parent_Subscription__c != null? String.valueOf(a.Parent_Subscription__c) : '') +  a.Subscription__c;
        /*
        a.External_ID__c = '' + a.Serial__c ; // + (a.Asset__c != null? a.Asset__c : '') + (a.Parent_Subscription__c != null? a.Parent_Subscription__c : '') +  a.Subscription__c;
        a.External_ID__c += (a.Asset__c != null? '' + a.Asset__c : ''); // + (a.Parent_Subscription__c != null? a.Parent_Subscription__c : '') +  a.Subscription__c;
        a.External_ID__c +=  (a.Parent_Subscription__c != null? a.Parent_Subscription__c : '');  // +  a.Subscription__c;
        a.External_ID__c +=   a.Subscription__c;
        */

        return a;

    }





}