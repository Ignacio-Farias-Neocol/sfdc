/**
 * Created by iyeung on 2019-04-26.
 */

public without sharing class TerritoryPreprocessorBatch implements Schedulable{

    @TestVisible
    private  Map<Id, Territory2Type> territory2TypeMap;

    @TestVisible
    private  Map<Id, Territory2> terrtoryMap ;


    // TerritoryPreprocessorBatch.cleanAllAttributes();
    /*
    public static void cleanAllAttributes(){


        List <Territory2> territory2s = [
                select AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, CurrencyIsoCode, Territory2ModelId, Territory2TypeId,
                        Description, DeveloperName, ForecastUserId, Id,  Name, OpportunityAccessLevel, ParentTerritory2Id,
                        // Location__c,  Sub_Territory__c,  Sub_Theater__c, Region__c, Territory__c, Theater__c,
                        Location2__c,  Sub_Territory2__c,  Sub_Theater2__c, Region2__c, Territory2__c, Theater2__c
                from Territory2
        ];

        for (Territory2 t:territory2s ){
            t.Location2__c = '';
            t.Sub_Territory2__c = '';
            t.Sub_Theater2__c = '';
            t.Region2__c = '';
            t.Territory2__c = '';
            t.Theater2__c = '';
        }

        withoutSharingDML.save(territory2s);
    }
     */

    // TerritoryPreprocessorBatch.executeBatch();
    public static void executeBatch(){
        TerritoryPreprocessorBatch batch = new TerritoryPreprocessorBatch();
        batch.processTerritory();
    }

    /**
     *
     *  Examine the Territory2 object which uses he field Territory2.ParentTerritory2Id field to determine the parent territory.
     * For each Territory2 record the logic will need to populate the hierarchy fields: Theater2_c, Sub_Theater2c, Region2c, Territory2c,
     * Sub_Territory2c, Location2_c using the Territory2.ParentTerritory2Id and the Territory2.Territory2TypeId
     * (this is a lookup to the Territory2Type object which contains the type: Theater, Sub Theater, Region, Territory, Sub Territory, Location)
     * The code should recursively determine the the hierarchy down to the leaf
     * The pre-processor should be executable on demand and evaluate the entire model.
     */
    public  void processTerritory() {

        // assume territory2 does not go beyond 2000 rows
        terrtoryMap = new Map <Id, Territory2> ([
            select AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, CurrencyIsoCode, Territory2ModelId, Territory2TypeId,
                    Description, DeveloperName, ForecastUserId, Id,  Name, OpportunityAccessLevel, ParentTerritory2Id,
                    // Location__c,  Sub_Territory__c,  Sub_Theater__c, Region__c, Territory__c, Theater__c
                    Location2__c,  Sub_Territory2__c,  Sub_Theater2__c, Region2__c, Territory2__c, Theater2__c
            from Territory2
            ]);

        territory2TypeMap = new Map <Id, Territory2Type> ([select  Description, DeveloperName, Id,
        Language,  MasterLabel, Priority from Territory2Type]);

        // start the process with top level territory
        List <Territory2> topTerritory2s = new List <Territory2>();
        for (Territory2 t: terrtoryMap.values()) {
            if (t.ParentTerritory2Id == null){
                topTerritory2s.add(t);
            }
        }
        if (topTerritory2s.size() > 0 ){
            setTerritoryAttribute(topTerritory2s);
        }

        // finally save everthing
        List <Territory2> allTerritory2s = terrtoryMap.values();
        withoutSharingDML.save(allTerritory2s);


    }

    @TestVisible
    private  void setTerritoryAttribute(List <Territory2> territories){

        Set <Id> currentIds = new Set<Id>();
        for (Territory2 t: territories){

            // first found the parent territory and copy all the parent theater type fields here
            if (t.ParentTerritory2Id != null ){
                Territory2 parentTerritory = terrtoryMap.get(t.ParentTerritory2Id);
                // t.Location__c = parentTerritory.Location__c;
                t.Location2__c = parentTerritory.Location2__c;
                // t.Region__c = parentTerritory.Region__c;
                t.Region2__c = parentTerritory.Region2__c;
                // t.Sub_Territory__c = parentTerritory.Sub_Territory__c;
                t.Sub_Territory2__c = parentTerritory.Sub_Territory2__c;
                // t.Sub_Theater__c = parentTerritory.Sub_Theater__c;
                t.Sub_Theater2__c = parentTerritory.Sub_Theater2__c;
                // t.Territory__c = parentTerritory.Territory__c;
                t.Territory2__c = parentTerritory.Territory2__c;
                // t.Theater__c = parentTerritory.Theater__c;
                t.Theater2__c = parentTerritory.Theater2__c;
            }

            Territory2Type tt = territory2TypeMap.get(t.Territory2TypeId);
            if (tt.DeveloperName == 'Location'){
                // t.Location__c = t.Name;
                t.Location2__c = t.Name;
            } else  if (tt.DeveloperName == 'Region'){
                // t.Region__c = t.Name;
                t.Region2__c = t.Name;
            } else  if (tt.DeveloperName == 'Sub_Territory'){
                // t.Sub_Territory__c = t.Name;
                t.Sub_Territory2__c = t.Name;
            } else  if (tt.DeveloperName == 'Sub_Theater'){
                // t.Sub_Theater__c = t.Name;
                t.Sub_Theater2__c = t.Name;
            } else  if (tt.DeveloperName == 'Territory'){
                // t.Territory__c = t.Name;
                t.Territory2__c = t.Name;
            } else  if (tt.DeveloperName == 'Theater'){
                // t.Theater__c = t.Name;
                t.Theater2__c = t.Name;
            }

            currentIds.add(t.Id);

        }

        // find any immediate children
        List <Territory2> childreTerritory2s = new List <Territory2>();
        for (Territory2 t: terrtoryMap.values()){
            if (t.ParentTerritory2Id != null && currentIds.contains(t.ParentTerritory2Id )){
                childreTerritory2s.add(t);
            }
        }
        if (childreTerritory2s.size() > 0 ){
            // process next level
            setTerritoryAttribute(childreTerritory2s);
        }


    }



    /**
 * start to update the Lead Territory refresh
 *
 * @param sc
 */
    public void execute(SchedulableContext sc) {
        TerritoryPreprocessorBatch.executeBatch();
    }

    public void finish(Database.BatchableContext BC)
    {
        // kill the active job after finish : i.e. make this scheduler only run once.

        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        String jobId = (BC == null ? '': BC.getJobId());
        List <AsyncApexJob> job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =  :jobId];

        //then use the active job id and abort it
        if (job != null && job.size() > 0 ) {
            system.abortJob(job[0].id);
        }

    }



}