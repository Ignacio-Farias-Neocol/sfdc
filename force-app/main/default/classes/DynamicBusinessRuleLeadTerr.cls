/**
* @author HZ
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to update lead with territory hierarchy data
*   2019-01-02 : revise this class so that it can support update both lead and account territory hierarchy data
*/

public with sharing class DynamicBusinessRuleLeadTerr implements DynamicBusinessRuleAction {

    public static Map<String, TerritoryField> TerritoryFieldMap;

    public class TerritoryField {
        public String stateCode;
        public String countryCode;
        public String terrLocation;
        public String terrSubTerritory;
        public String territory;
        public String terrRegion;
        public String terrSubTheater;
        public String terrTheater;
        public String alignmentRun; // Terr_Alignment_Run__c
        public String Territory2ID; 
        public String StandardStateCode; 

        public TerritoryField(
                String stateCode,
                String countryCode,
                String terrLocation,
                String terrSubTerritory,
                String territory,
                String terrRegion,
                String terrSubTheater,
                String terrTheater,
                String alignmentRun,
                String Territory2ID,
                String StandardStateCode
        ) 
        
        {
            this.stateCode = stateCode;
            this.countryCode = countryCode;
            this.terrLocation = terrLocation;
            this.terrSubTerritory = terrSubTerritory;
            this.territory = territory;
            this.terrRegion = terrRegion;
            this.terrSubTheater = terrSubTheater;
            this.terrTheater = terrTheater;
            this.alignmentRun = alignmentRun;
            this.Territory2ID = Territory2ID;
            this.StandardStateCode = StandardStateCode;            
        }
    }
    
    static{
        TerritoryFieldMap = new  Map<String, TerritoryField>();
        TerritoryFieldMap.put('Account', new TerritoryField('State_Code__c',
                                                            'BillingCountryCode',
                                                            'Terr_Location__c',
                                                            'Terr_Sub_Territory__c',
                                                            'Territory__c',
                                                            'Terr_Region__c',
                                                            'Terr_Sub_Theater__c',
                                                            'Terr_Theater__c', 
                                                            'Terr_Alignment_Run__c',
                                                            'Territory_ID__c',
                                                            'BillingStateCode'));

        TerritoryFieldMap.put('Lead', new TerritoryField('State_Code__c',
                                                         'CountryCode',
                                                         'Terr_Location__c',
                                                         'Terr_Sub_Territory__c',
                                                         'Territory__c',
                                                         'Terr_Region__c',
                                                         'Terr_Sub_Theater__c',
                                                         'Terr_Theater__c', '',
                                                         'Territory_ID__c',
                                                         'StateCode') );

    }


    private static Map<String, ObjectTerritory2AssignmentRuleItem> pTerritoryRuleItem;
    private static Map<String, ObjectTerritory2AssignmentRuleItem> territoryRuleItem {
        get {
            if (pTerritoryRuleItem == null){

                pTerritoryRuleItem = new Map<String, ObjectTerritory2AssignmentRuleItem>();


                List <ObjectTerritory2AssignmentRuleItem> rules = [select  Field, Id,  Operation, RuleId, SortOrder, Value from ObjectTerritory2AssignmentRuleItem
                where Field in( 'Account.State_Code__c' , 'Account.BillingCountryCode', 'Account.BillingStateCode') and operation in ( 'contains', 'equals')  ];

                Map <Id, Integer> ruleCount = new Map<Id, Integer>();
                for (ObjectTerritory2AssignmentRuleItem rule: rules ) {
                    if (ruleCount.containsKey(rule.RuleId)){
                        ruleCount.put(rule.RuleId, ruleCount.get(rule.RuleId) + 1);
                    } else {
                        ruleCount.put(rule.RuleId, 1);
                    }
                }

                for (ObjectTerritory2AssignmentRuleItem rule: rules ){
                    // ignore the ruleitem that has more than one entry
                    if (ruleCount.get(rule.ruleId) == 1){
                        // note the value can be a comma delimited list, so break it down by each one
                        List <String> values = rule.value.split(',');
                        for (String s: values){
                            pTerritoryRuleItem.put(rule.Field + s, rule);
                        }

                    }
                }
            }

            return pTerritoryRuleItem;
        }

    }

    private static Map <Id, ObjectTerritory2AssignmentRule > pTerritoryRule;
    private static Map <Id, ObjectTerritory2AssignmentRule > territoryRule{
        get {

            if (pTerritoryRule == null){
                pTerritoryRule = new Map <Id, ObjectTerritory2AssignmentRule >();
                Set<Id> ruleIds = new Set<Id>();
                for (ObjectTerritory2AssignmentRuleItem item : territoryRuleItem.values() ){
                    ruleIds.add(item.RuleId);
                }

                for (ObjectTerritory2AssignmentRule rule: [ select BooleanFilter,  DeveloperName, Id, IsActive,
                        IsDeleted, Language, MasterLabel, ObjectType,
                        Territory2ModelId from ObjectTerritory2AssignmentRule where id in :ruleIds ]){
                    pTerritoryRule.put(rule.Id, rule);
                }
            }

            return pTerritoryRule;
        }
    }

    private static List <RuleTerritory2Association> pTerritory2Associations;
    private static List  <RuleTerritory2Association> territory2Associations {
        get {
            if (pTerritory2Associations == null){
                pTerritory2Associations = [select  Id,  RuleId, SystemModstamp, Territory2Id, Territory2.Name,
                        Territory2.Territory2Type.MasterLabel,  Territory2.Territory2TypeId, Territory2.Territory2Type.Priority ,
                        Territory2.ParentTerritory2Id, Territory2.Location2__c, Territory2.Region2__c, Territory2.Sub_Territory2__c,
                        Territory2.Sub_Theater2__c, Territory2.Territory2__c, Territory2.Theater2__c
                from RuleTerritory2Association order by Territory2.Territory2Type.Priority];
            }
            return pTerritory2Associations;
        }
    }


    @TestVisible
    private void processLeads(List <SObject> records, TerritoryField t ){

        for (SObject obj : records) {
            Boolean itemFlag = FALSE;
            // for each record check in order of both value/items for StateCode->StandardStateCode->CountryCode
            if (String.isNotBlank((String)obj.get(t.stateCode))) {
                String ky = 'Account.State_Code__c' + obj.get(t.stateCode);
                itemFlag = addLeadTerritoryByStateCode(obj, t, ky);
            } 
            if (String.isNotBlank((String)obj.get(t.StandardStateCode)) && itemFlag == FALSE) {
                String ky = 'Account.BillingStateCode' + obj.get(t.StandardStateCode);
                itemFlag = addLeadTerritoryByStateCode(obj, t, ky);
            }
            if (String.isNotBlank((String)obj.get(t.countryCode)) && itemFlag == FALSE) {
                String ky = 'Account.BillingCountryCode' + obj.get(t.countryCode);
                itemFlag = addLeadTerritoryByStateCode(obj, t, ky);
            }
        }
    }

    @TestVisible
    private boolean addLeadTerritoryByStateCode(SObject obj, TerritoryField t, String ky ){
        // first find the ObjectTerritory2AssignmentRuleItem by state Code

        // by default reset the territory field
        obj.put(t.terrLocation, null );
        obj.put(t.terrSubTerritory,null);
        obj.put(t.territory, null );
        obj.put(t.terrRegion, null );
        obj.put(t.terrSubTheater,  null );
        obj.put(t.terrTheater, null);
        obj.put(t.Territory2ID, null);        

        ObjectTerritory2AssignmentRuleItem item = territoryRuleItem.get(ky);
        System.debug('------- matched rule item: ' + item);

        if (item != null){
            // find the rule associated with this item
            ObjectTerritory2AssignmentRule rule = territoryRule.get(item.RuleId);

            System.debug('------- matched rule: ' + rule);
            if (rule != null){

                Map<Integer, Integer> countByPriority = new Map<Integer, Integer>();
                // tranverse the list of territory2Associations, find the count by priority
                for (RuleTerritory2Association a: territory2Associations ) {

                    // count by priority
                    if (a.RuleId == rule.Id) {
                        if (countByPriority.containsKey(a.Territory2.Territory2Type.Priority)) {
                            countByPriority.put(a.Territory2.Territory2Type.Priority, countByPriority.get(a.Territory2.Territory2Type.Priority) + 1);
                        } else {
                            countByPriority.put(a.Territory2.Territory2Type.Priority, 1);
                        }
                    }
                }

                System.debug('------- count by Priority: ' + countByPriority);

                // tranverse the list of territory2Associations, use the first rule association that has a count of 1
                for (RuleTerritory2Association a: territory2Associations ) {

                    if (a.RuleId == rule.Id){

                        if (countByPriority.get(a.Territory2.Territory2Type.Priority) == 1){
                            System.debug('------- matched territory association: ' + a);

                            // set all the fields on the lead
                            obj.put(t.terrLocation, a.Territory2.Location2__c );
                            obj.put(t.terrSubTerritory, a.Territory2.Sub_Territory2__c );
                            obj.put(t.territory, a.Territory2.Territory2__c );
                            obj.put(t.terrRegion, a.Territory2.Region2__c );
                            obj.put(t.terrSubTheater,  a.Territory2.Sub_Theater2__c );
                            obj.put(t.terrTheater, a.Territory2.Theater2__c);
                            obj.put(t.Territory2ID, a.Territory2.id);

                            break;
                        }

                    }
                }
            }
            return TRUE;
        }
        else return FALSE;
    }


            /*******************************************************************************************************
            * @description  update territory fields, based upon state_code__c field
            * @param trigger.new map
            * @return none, the result should be set to the records itself
            * @example
            */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){



        if (records == null || records.size() == 0 ){
            return;
        }
        // 09-04-2019: this call fail on creating lead from live chat.
        // live chat is invoked using 'live Agent Site Guest User' user which has a system profile 'live Agent Profile'
        // the usual tactic of object / field level check does not readily apply , so use a crude way to check for access to territory objects such as ObjectTerritory2AssignmentRuleItem
        Boolean hasTerritoryAccess = true;
        try {
            Map<String, ObjectTerritory2AssignmentRuleItem> tri = territoryRuleItem;
            Map <Id, ObjectTerritory2AssignmentRule > tr = territoryRule;
            List  <RuleTerritory2Association> ta = territory2Associations ;
        } catch (Exception e){
            hasTerritoryAccess = false;
        }
        if (hasTerritoryAccess == false ){
            return;
        }

        try {
            String objectName =  records[0].getSObjectType().getDescribe().getName();
            TerritoryField t = TerritoryFieldMap.get(objectName);
            System.debug('~~~ TerritoryField: ' + t);

            if (objectName == 'Lead'){
                processLeads(records, t);
            } else {
                // older logic, depcreated , 7/22/
                // processOthers(records, t);
            }

        } Catch (Exception e){
            System.debug('processRecords failed: ' + e);
        }


    }


    // older logic deprecated.
    /*
    private void processOthers(List <SObject> records, TerritoryField t){




        // get all territories associated with the either Lead.CountryCode or Lead.State_Code__c into a map
        Set <String> terrNames = new Set <String>();
        Set <String> terrDevNames = new Set <String>();
        for (SObject obj : records) {


            if (obj.get(t.stateCode) != null)
                terrNames.add((String) obj.get(t.stateCode));
            else if (obj.get(t.countryCode) != null)
                terrDevNames.add('COUNTRY_ISO_'+ obj.get(t.countryCode) );

        }
        Map <String, Territory2> terrMap = new Map <String, Territory2> ();
        for(Territory2 terrObj : [
                SELECT
                        Name,
                        Territory2Type.DeveloperName,
                        ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name
                FROM Territory2 WHERE Name IN :terrNames
        ])
            terrMap.put(terrObj.Name, terrObj);
        for(Territory2 terrObj2 : [
                SELECT
                        Name,
                        DeveloperName,
                        Territory2Type.DeveloperName,
                        ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name,
                        ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name
                FROM Territory2 WHERE DeveloperName IN :terrDevNames
        ])
            terrMap.put(terrObj2.DeveloperName, terrObj2);

        // use map to lookup the various levels of the terr hierarchy (limited to 6 i.e 5 parents)
        for (SObject obj : records) {
            Territory2 leadTerr;

//            Lead l = (Lead)obj;
//            if (l.State_Code__c != null)
//                leadTerr = terrMap.get(l.State_Code__c);
//            else if (l.CountryCode != null)
//                leadTerr = terrMap.get('COUNTRY_ISO_'+l.CountryCode);
            if (obj.get(t.stateCode) != null)
                leadTerr = terrMap.get((String) obj.get(t.stateCode)); else if (obj.get(t.countryCode) != null)
                leadTerr = terrMap.get('COUNTRY_ISO_' + obj.get(t.countryCode));


            if (leadTerr != null) {
                switch on leadTerr.Territory2Type.DeveloperName {
                    when 'Location' {
                        obj.put(t.terrLocation, leadTerr.Name);  // l.Terr_Location__c =        leadTerr.Name;
                        obj.put(t.terrSubTerritory, leadTerr.ParentTerritory2.Name); // l.Terr_Sub_Territory__c =   leadTerr.ParentTerritory2.Name;
                        obj.put(t.territory, leadTerr.ParentTerritory2.ParentTerritory2.Name); // l.Territory__c =            leadTerr.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrRegion, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name); // l.Terr_Region__c =          leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrSubTheater, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name); // l.Terr_Sub_Theater__c =     leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrTheater, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name);     // l.Terr_Theater__c =         leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                    }
                    when 'Sub_Territory' {
                        obj.put(t.terrLocation, ''); // l.Terr_Location__c =        '';
                        obj.put(t.terrSubTerritory, leadTerr.Name); // l.Terr_Sub_Territory__c =   leadTerr.Name;
                        obj.put(t.territory, leadTerr.ParentTerritory2.Name);  // l.Territory__c =            leadTerr.ParentTerritory2.Name;
                        obj.put(t.terrRegion, leadTerr.ParentTerritory2.ParentTerritory2.Name); // l.Terr_Region__c =          leadTerr.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrSubTheater, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name);  // l.Terr_Sub_Theater__c =     leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrTheater, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name); // l.Terr_Theater__c =         leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                    }
                    when 'Territory' {
                        obj.put(t.terrLocation, ''); // l.Terr_Location__c =        '';
                        obj.put(t.terrSubTerritory, ''); // l.Terr_Sub_Territory__c =   '';
                        obj.put(t.territory, leadTerr.Name);   // l.Territory__c =            leadTerr.Name;
                        obj.put(t.terrRegion, leadTerr.ParentTerritory2.Name); // l.Terr_Region__c =          leadTerr.ParentTerritory2.Name;
                        obj.put(t.terrSubTheater, leadTerr.ParentTerritory2.ParentTerritory2.Name); // l.Terr_Sub_Theater__c =     leadTerr.ParentTerritory2.ParentTerritory2.Name;
                        obj.put(t.terrTheater, leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name);  // l.Terr_Theater__c =         leadTerr.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name;
                    }
                    when 'Region' {
                        obj.put(t.terrLocation, ''); // l.Terr_Location__c =        '';
                        obj.put(t.terrSubTerritory, ''); // l.Terr_Sub_Territory__c =   '';
                        obj.put(t.territory, ''); // l.Territory__c =            '';
                        obj.put(t.terrRegion, leadTerr.Name);  // l.Terr_Region__c =          leadTerr.Name;
                        obj.put(t.terrSubTheater, leadTerr.ParentTerritory2.Name); // l.Terr_Sub_Theater__c =     leadTerr.ParentTerritory2.Name;
                        obj.put(t.terrTheater, leadTerr.ParentTerritory2.ParentTerritory2.Name);  // l.Terr_Theater__c =         leadTerr.ParentTerritory2.ParentTerritory2.Name;
                    }
                    when 'Sub_Theater' {
                        obj.put(t.terrLocation, ''); // l.Terr_Location__c =        '';
                        obj.put(t.terrSubTerritory, ''); // l.Terr_Sub_Territory__c =   '';
                        obj.put(t.territory, ''); // l.Territory__c =            '';
                        obj.put(t.terrRegion, ''); // l.Terr_Region__c =          '';
                        obj.put(t.terrSubTheater, leadTerr.Name); // l.Terr_Sub_Theater__c =     leadTerr.Name;
                        obj.put(t.terrTheater, leadTerr.ParentTerritory2.Name); // l.Terr_Theater__c =         leadTerr.ParentTerritory2.Name;
                    }
                    when else {          // default block, 'Theater'
                        obj.put(t.terrLocation, '');  // l.Terr_Location__c =        '';
                        obj.put(t.terrSubTerritory, '');  // l.Terr_Sub_Territory__c =   '';
                        obj.put(t.territory, '');  // l.Territory__c =            '';
                        obj.put(t.terrRegion, '');  // l.Terr_Region__c =          '';
                        obj.put(t.terrSubTheater, '');  // l.Terr_Sub_Theater__c =     '';
                        obj.put(t.terrTheater, leadTerr.Name);  // l.Terr_Theater__c =         leadTerr.Name;
                    }
                }
            }
        }


    }*/



}