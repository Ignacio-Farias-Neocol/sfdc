/**
* Apex Controller for quoteAddressSelectorV1 Lighting component
*
* @Author Sonal Agrawal
* @Date 2022/03/11
* @description: SFDC-18053 - For multiple Reseller for non primary Quote created 'Bill/Ship To Address' LWC component type button on Quote
*
*
*/

public class QuoteAddressSelectorController {
    // Quote associated with the Quote record in context
    private  Id QuoteId = null; // set whenever the first call is made
    @AuraEnabled(cacheable=true)
    public static QuoteAddressSelectorController getQuote(id recordId) {
        //create class instance
        QuoteAddressSelectorController obj = new QuoteAddressSelectorController();
        obj.QuoteId = recordId;
        SBQQ__Quote__c qRecord =  obj.qRecord;
        return obj;
    }
    @AuraEnabled
    public static List<Address__c> getAddress(id Accountid, String addressType) {
        String type = null;
        if (addressType == 'billTo'){
            type = 'Billing';
            return [select Account__c, Account_External_ID__c, City__c, Country_ISO__c, Country__c, Country__r.Name,  Id,
                Name, Primary__c, State__c, State__r.Name, Street__c, Type__c,
                Zip_Postal_Code__c, Status__c from Address__c
                where (Status__c = 'Active' and Status__c != NULL) and Type__c=:type and Account__c = :Accountid and Primary__c=true] ;
        }
        else{
            type = 'Shipping';
            return [select Account__c, Account_External_ID__c, City__c, Country_ISO__c, Country__c, Country__r.Name,  Id,
                Name, Primary__c, State__c, State__r.Name, Street__c, Type__c,
                Zip_Postal_Code__c, Status__c from Address__c
                where (Status__c = 'Active' and Status__c != NULL) and Type__c=:type and Account__c = :Accountid]; 
        }
    }
    @AuraEnabled
    public static SBQQ__Quote__c UpdAddressOnQuote(id addressId, String quoteRecord, String addressType, String addressObj) {
        List<Address__c> newAddressList;
        Address__c SelectedAddress = new Address__c();
        SBQQ__Quote__c updquoteRecord;
        /*System.debug('quoteRecord**'+quoteRecord);
        System.debug('addressType**'+addressType);
        System.debug('addressObj**'+addressObj);
        System.debug('Qrec**'+Qrec);*/
        try {
            newAddressList = (List<Address__c>) JSON.deserialize(addressObj, List<Address__c>.class);
            updquoteRecord = (SBQQ__Quote__c) JSON.deserialize(quoteRecord, SBQQ__Quote__c.class);
            System.debug('newAddress**'+newAddressList[0]);
            for(Address__c add:newAddressList){
                if(add.id==addressId){
                    SelectedAddress = add;
                }
            }
        }    catch (Exception ex) {
            system.debug('Exception***: ' + ex);
        }
        try{
            if (addressType == 'billTo' && SelectedAddress!=null && quoteRecord!=null) {
                updquoteRecord.Billing_Address__c = SelectedAddress.Id;
                updquoteRecord.SBQQ__BillingCity__c = SelectedAddress.City__c;
                updquoteRecord.SBQQ__BillingCountry__c = SelectedAddress.Country__r.Name;
                updquoteRecord.SBQQ__BillingPostalCode__c = SelectedAddress.Zip_Postal_Code__c;
                updquoteRecord.SBQQ__BillingState__c =SelectedAddress.State__r.Name;
                updquoteRecord.SBQQ__BillingStreet__c = SelectedAddress.Street__c;
                updquoteRecord.Billing_Country_ISO_Code__c = SelectedAddress.Country_ISO__c;
                Update updquoteRecord;
            }
            else if(addressType == 'shipTo' && newAddressList.size()>0 && quoteRecord!=null){
                updquoteRecord.Shipping_Address__c = SelectedAddress.Id;
                updquoteRecord.SBQQ__ShippingCity__c = SelectedAddress.City__c;
                updquoteRecord.SBQQ__ShippingCountry__c = SelectedAddress.Country__r.Name;
                updquoteRecord.SBQQ__ShippingPostalCode__c =SelectedAddress.Zip_Postal_Code__c;
                updquoteRecord.SBQQ__ShippingState__c =SelectedAddress.State__r.Name;
                updquoteRecord.SBQQ__ShippingStreet__c = SelectedAddress.Street__c;
                updquoteRecord.Shipping_Country_ISO_Code__c = SelectedAddress.Country_ISO__c;
                Update updquoteRecord;
            }
        }catch (Exception ex) {
            system.debug('Exception**: ' + ex);
        }
        return updquoteRecord;
    }
    /*private  Boolean pOpptyShipEditable = null;
    @AuraEnabled public Boolean billShipEditable {
        get {
            Id profileId= userinfo.getProfileId();
            String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
            List<String> legitimateProfileNames = new List<String>();
            for(BillToShIpToProfiles__mdt eachCustomMetadataRecord : [select Profile_Name__c from BillToShIpToProfiles__mdt]){
                legitimateProfileNames.add(eachCustomMetadataRecord.Profile_Name__c);
            }
            if(legitimateProfileNames.contains(profileName)){
                pOpptyShipEditable = true;
            }
            else{
                pOpptyShipEditable = false;
            }
            return pOpptyShipEditable;
        }
    }*/
    private  SBQQ__Quote__c pQRecord = null;
    @AuraEnabled public SBQQ__Quote__c qRecord{
        get {
            return [
                Select Id, Name,Billing_Address__c,SBQQ__BillingCity__c,SBQQ__BillingCountry__c,SBQQ__BillingName__c,SBQQ__BillingPostalCode__c,SBQQ__BillingState__c,SBQQ__BillingStreet__c,Shipping_Address__c,SBQQ__ShippingCity__c,SBQQ__ShippingCountry__c,SBQQ__ShippingName__c,SBQQ__ShippingPostalCode__c,SBQQ__ShippingState__c,SBQQ__ShippingStreet__c,SBQQ__Account__r.Name,SBCF_Bill_To_Account__c,SBQQ__Opportunity2__r.Ship_To_Account__c,SBCF_Reseller__r.Name,SBQQ__Distributor__r.Name,SBQQ__Opportunity2__r.Name 
                FROM SBQQ__Quote__c 
                where id=:Quoteid limit 1] ;
        }
    }
}