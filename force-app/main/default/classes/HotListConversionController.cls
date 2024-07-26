/**
* @author HZ
* @date 2019/01
*
* @group Controller
* @description apex controller for the HotListConversion component
*/
public with sharing class HotListConversionController {

    @AuraEnabled
    public static Id updateHotList(Id recordId){

        // Get Hot List
        Hot_List__c hl = [SELECT Id, Lead__r.Id, Disposition__c from Hot_List__c where Id =:recordId];
        
        // Update Lead Primary Hot List
        Lead ld = [SELECT Id, Primary_Hot_List__c from Lead where Id =:hl.Lead__r.Id];
        ld.Primary_Hot_List__c = hl.Id;
        Update ld;
        
        // return Lead for navigation     
        return hl.Lead__r.Id;
    }
}