/**
* @author Salesforce Services
* @date 07/29/2020
*
* @group Batch
*
* @description: Batch job to add missing assigned serials for subscriptions
*/

global class MissingAssignSerialBatch implements Database.Batchable<sObject>,Schedulable{

    private String query;
    private String defaultQuery = 'SELECT Id, SBCF_Serial_Number__c, SBQQ__Product__r.Family, SBQQ__Product__r.ProductCode,SBQQ__RootId__c,SBQQ__RequiredById__c,Current_Quantity__c' +
                                  ' FROM SBQQ__Subscription__c' +
                                  ' WHERE Id not in (Select Subscription__c from Assigned_Serial__c)' +
                                  ' AND Business_Group__c = \'MSP\'' + 
                                  ' AND SBQQ__RevisedSubscription__c=null' + 
                                  ' AND Active__c = true' + 
                                  ' AND Renewed_By_Subscription__c = null' + 
                                  ' AND SBQQ__Product__r.MSP_Product__c = TRUE';
    private Integer batchSize;
    private Integer defaultSize = 200;

    //Constructor with query and batchsize
    public MissingAssignSerialBatch(String queryString, Integer batch){
        if(String.isNotBlank(queryString)){
            query     = queryString;
        }
        else{
            query     = defaultQuery;
        }
        
        if(batch!=null && batch > 0){
            batchSize = batch;
        }
        else{
            batchSize = defaultSize;
        }
    }

    //Constructor with query and default batch size
    public MissingAssignSerialBatch(String queryString){
        query     = queryString;
        batchSize = defaultSize;
    }

    //Constructor with no parameters
    public MissingAssignSerialBatch(){
        query     = defaultQuery;
        batchSize = defaultSize;
    }

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC){        
        if(String.isNotBlank(query)){
            return Database.getQueryLocator(query);
        }
        else{
            return Database.getQueryLocator(defaultQuery);
        }
    }

    //Execute
    global void execute(Database.BatchableContext BC, List<sObject> scope){
    
        LogModel log = LogModel.startLog(
                'MissingAssignSerialBatch',
                'Adding missing assigned serial in a batch'
        );

        try{

            //List of Assigned Serials to be inserted
            List<Assigned_Serial__c> asInsertList = new List<Assigned_Serial__c>();

            //List of Assigned Serials to be inserted
            Map<String, Map<Id,Assigned_Serial__c>> asInsertMap = new Map<String,Map<Id,Assigned_Serial__c>>();

            //Set of Serial numbers to be used to get Serial Id
            Set<String> serialNumberSet = new Set<String>();

            // //Map of serial number and serial
            // Map<String, Serial__c> serialNumberMap = new Map<String,Serial__c>();

            //Map of Serial Id and asset's assigned serial
            Map<Id, Assigned_Serial__c> serialAssetAssignedSerialMap = new Map<Id, Assigned_Serial__c>();

            //Loop through subscription and get the list of serials listed in the Subscription field
            for(SBQQ__Subscription__c sub: (List<SBQQ__Subscription__c>)scope){
                //Check if the subscription has a serial number
                if(String.isNotBlank(sub.SBCF_Serial_Number__c)){
                    //If serial number is present then split it using comma as delimiter
                    for(String serialNumber: sub.SBCF_Serial_Number__c.split(',')){
                        //Create Assigned serial for each Subscription ID and Serial Number Combination
                        if(!asInsertMap.containsKey(serialNumber)){
                            Map<Id, Assigned_Serial__c> subAssignedSerialMap = new Map<Id, Assigned_Serial__c>();
                            subAssignedSerialMap.put(sub.id, new Assigned_Serial__c(Parent_Subscription__c = sub.SBQQ__RequiredById__c,
                                                                                    Subscription__c = sub.Id,
                                                                                    Capacity__c = sub.Current_Quantity__c,
                                                                                    External_ID__c = sub.SBQQ__RootId__c + sub.Id));
                            asInsertMap.put(serialNumber, subAssignedSerialMap);
                        }
                        else if(asInsertMap.containsKey(serialNumber)){
                            Map<Id, Assigned_Serial__c> subAssignedSerialMap = asInsertMap.get(serialNumber);
                            subAssignedSerialMap.put(sub.id, new Assigned_Serial__c(Parent_Subscription__c = sub.SBQQ__RequiredById__c,
                                                                                    Subscription__c = sub.Id,
                                                                                    Capacity__c = sub.Current_Quantity__c,
                                                                                    External_ID__c = sub.SBQQ__RootId__c + sub.Id));
                        }

                        //Add serial number to set if the set does not contain it already
                        if(!serialNumberSet.contains(serialNumber)){
                            serialNumberSet.add(serialNumber);
                        }
                    }
                }
            } //END FOR

            //Prepare a map of Serial Number and the Asset Assigned Serial
            for(Assigned_Serial__c currentAS: [SELECT Id,
                                                      Serial__c,
                                                      Asset__c
                                               FROM Assigned_Serial__c 
                                               WHERE Serial_Number__c in :serialNumberSet 
                                               AND Subscription__c = null 
                                               AND Parent_Subscription__c = null 
                                               AND Asset__c!=null]){
                if(!serialAssetAssignedSerialMap.containsKey(currentAs.Serial__c)){
                    serialAssetAssignedSerialMap.put(currentAS.Serial__c, currentAS);
                }
            }            

            //Loop through the Serials obtained using serial numbers and prepare the list of Assigned Serials to be created
            for(Serial__c currentSerial: [SELECT Id, 
                                                 Serial_Number__c,
                                                 Expire_Date__c,
                                                 Status__c 
                                          FROM Serial__c 
                                          WHERE Serial_Number__c in :serialNumberSet]){
                for(Assigned_Serial__c currentAS: asInsertMap.get(currentSerial.Serial_Number__c).values()){
                    currentAS.Serial__c      = currentSerial.Id;
                    currentAs.Expire_Date__c = currentSerial.Expire_Date__c;
                    currentAS.External_ID__c = currentSerial.Id + currentAS.External_ID__c;
                    currentAS.Asset__c       = serialAssetAssignedSerialMap.containsKey(currentSerial.Id)? serialAssetAssignedSerialMap.get(currentSerial.Id).Asset__c: null;
                    currentAs.Status__c      = (currentSerial.Status__c == 'Active')? 'Active': 'Inactive';

                    //Add this assigned serial to the final insert list
                    asInsertList.add(currentAS);
                }
            }//END FOR
            
            //Insert this list of Assigned Serial
            Database.SaveResult[] srList = Database.insert(asInsertList, false);
            
            //Loop through the result to check if there were any failures and log these failures
            for(Database.SaveResult sr: srList){
                if(!sr.isSuccess()){
                    for(Database.Error error: sr.getErrors()){
                        log.addLog(error.message);
                    }
                }
                else{
                    log.addLog('Assigned Serial Created: ' + sr.getId());
                }
            }

            //End log
            log.endLog('End of MissingAssignSerialBatch log');

        }
        catch(System.DmlException de){
            System.debug('Exception updating serials' +  de.getMessage());
            log.addExceptionLog(de);
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }
    }

    //Finish method
    global void finish(Database.BatchableContext BC){}

    //Schedulable execute method
    global void execute(SchedulableContext sc){
        Database.executeBatch(new MissingAssignSerialBatch());
    }     
}