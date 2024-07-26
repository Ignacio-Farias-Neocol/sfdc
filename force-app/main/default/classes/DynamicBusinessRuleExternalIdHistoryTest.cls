@isTest
public with sharing class DynamicBusinessRuleExternalIdHistoryTest {
    
    @isTest static void insertTest() {

        External_ID_History__c history = new External_ID_History__c();
        history.Account__c = TestDataFactory.customers[0].Id;
        history.Object_Name__c = 'Account';
        history.Record_Content__c = '{"attributes":{"type":"Account","url":"/services/data/v45.0/sobjects/Account/0018A000009mF7fQAE"},"Test_For_Partner_Portal__c":false,"LastModifiedDate":"2019-01-24T00:00:37.000+0000","Out_of_Business__c":false,"DNBoptimizer__DnBCompanyRecord__c":"a2V8A0000002Nr5UAE","SBQQ__RenewalPricingMethod__c":"Same","Name":"Test Account 003","Validated__c":false,"IsExcludedFromRealign":false,"X_Large__c":false,"CreatedById":"0058A0000013qSuQAI","DNBoptimizer__Family_Tree_Link_Status__c":"Standalone","MasterRecordId":"0018A000009mF3JQAU","Payment_Terms__c":"Net 30","OwnerAlias":"rnotrang","IsDeleted":false,"SBQQ__ContractCoTermination__c":"Never","Referral_Account__c":false,"AVA_SFCPQ__Is_Seller_Importer_Of_Record__c":false,"SBQQ__IgnoreParentContractedPrices__c":false,"CurrencyIsoCode":"USD","Global_Account_Indicator__c":"No","Partner_Tax_Exempt_Certificate_Received__c":false,"House_Account__c":false,"DNBoptimizer__Number_Of_Contact__c":0,"Premium_Support__c":false,"CreatedDate":"2019-01-23T23:39:31.000+0000","Id":"0018A000009mF7fQAE","Status__c":"Prospect","DNBoptimizer__Number_Of_Task__c":0,"IsPartner":false,"Active__c":false,"MSP_Region__c":"MSP - International","Escalated_to_Engineering__c":false,"DNBoptimizer__DNB_D_U_N_S_Number__c":"087126020","Global_Account__c":false,"Global_Network__c":false,"BillingCountryCode":"US","Embargoed_Account__c":"No","Business_Group__c":"Core","Do_Not_Disturb__c":false,"SBQQ__CoTermedContractsCombined__c":false,"Named_Account__c":false,"OwnerId":"0058A0000013qSuQAI","EligibleForPartnerPortalUpdate__c":false,"Count_of_Sonian_Won__c":0,"RecordTypeId":"0128A0000000IfiQAE","ShippingCountry":"United States","DNBoptimizer__Number_Of_Opportunity__c":0,"SBQQ__TaxExempt__c":"No","IsCustomerPortal":false,"Subsidiary__c":"US","SystemModstamp":"2019-01-24T00:00:37.000+0000","ShippingCountryCode":"US","Signed_disti__c":false,"Bypass_Validation__c":false,"Active_Owner__c":false,"Type":"Partner - Reseller","SBQQ__PreserveBundle__c":true,"BillingCountry":"United States","Account_On_Hold_Indicator__c":"No","X18_ID__c":"0018A000009mF7fQAE","LastModifiedById":"0058A0000013ja9QAA","SBQQ__AssetQuantitiesCombined__c":false}';

        insert history;
    }   

}