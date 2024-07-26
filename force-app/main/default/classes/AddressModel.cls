/**
*  @author Ivan Yeung
*  @date 11/05/2018
*  @group Model
*  @description  address model class to cover the country__c and state__c
*/
public with sharing class AddressModel {

    public static final string ADDR_TYPE_BILLING = 'Billing';
    public static final string ADDR_TYPE_SHIPPING = 'Shipping';

    private  static Map<Id, Country__c> pCountryMap = null; // id, country name map
    @AuraEnabled public static Map<Id, Country__c>  countryMap{
        get {
            if (pCountryMap == null) {
                pCountryMap =  new Map<Id, Country__c>([SELECT Id, Country_ISO__c,  Name from Country__c order by Name]);
                system.debug('^^^^ Country Map:  ' + pCountryMap);
            }
            return pCountryMap;
        }
    }

    private  static Map<Id, State__c> pStateMap = null; // id, state name map
    @AuraEnabled public static  Map<Id, State__c>  stateMap{
        get {
            if (pStateMap == null) {
                pStateMap =  new Map<Id, State__c>([select Id,  Country__c, Name, State_ISO__c from State__c order by Name]);
                system.debug('^^^^ State Map:  ' + pStateMap);
            }
            return pStateMap;
        }
    }

    private static Map<Id , Map <Id, State__c>> pCountryStateMap = null;  // country to State Map
    @AuraEnabled public static  Map<Id , Map <Id, State__c>>  countryStateMap{
        get {
            if (pCountryStateMap == null) {
                pCountryStateMap = new Map<Id , Map <Id, State__c>>();
                for (Id  key: stateMap.keySet()){
                    Map <Id, State__c> currentStateMap;
                    if (pCountryStateMap.containsKey(stateMap.get(key).Country__c)){ // check if
                        currentStateMap = pCountryStateMap.get(stateMap.get(key).Country__c);
                    } else {
                        // create new
                        currentStateMap = new Map<Id, State__c>();
                        pCountryStateMap.put(stateMap.get(key).Country__c, currentStateMap);
                    }
                    currentStateMap.put(key, StateMap.get(key));
                }
            }
            return pCountryStateMap;
        }
    }

}