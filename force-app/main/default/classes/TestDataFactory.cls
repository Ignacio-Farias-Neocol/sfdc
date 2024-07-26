/**
 *  @author Ivan Yeung
 *  @date 2018-10-21
 *  @group Test
 *  @description  Factory class for unit test data generation.
 *                Note all test data should be created using singleton, lazy loading pattern
 *  @update: Removed all references of Technical_Alert__c , Account_Alert__c 7/17/19 - raunacq
 *  @update: Added method to create hot list - pshetty
  *  @update: Added method to create Distributor Accounts - Rahul M
 */
public with sharing class TestDataFactory {


    public static boolean createRealData = false; // a flag to indicate if real data should be created. by default only commit data in test unit context 
    private static Integer pSuffixNumber = 1;
    public static Integer suffixNumber {
        get {
            // move to custom setting later     
            return pSuffixNumber; 
        }
        set {
            pSuffixNumber = value; 
        }
        
    }

    private static void createAccounts(){
        List<Account> accountsToSave = new List<Account>();
        accountsToSave.addAll(createCustomerAccount());
        accountsToSave.addAll(createPartnersDistributorAccount());
        accountsToSave.addAll(createPartners());

        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(accountsToSave);
        }

        // retrieve additional fields for troubleshooting and functional testing
        Set<Id> customerIds = new Set<Id>();
        for (Account c:pCustomers ){
            customerIds.add(c.Id);
        }
        pCustomers = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                    AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                    AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                    Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                    Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                    BCC_AuthDB_Account_ID__c,  Bill_To_Email__c,  BillingAddress, 
                    BillingGeocodeAccuracy, 
                    BusinessGroup__c, Bypass_Validation__c, 
                    Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                    Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                    Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                    Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                    IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                    Last_Activity_Date__c, LastActivityDate, LastModifiedById, LastModifiedDate, 
                    LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                    Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                    Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                    PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                    SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                    SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                    SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                    SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c, ShippingAddress, ShippingGeocodeAccuracy, Sic, 
                    SicDesc, Site, Status__c, SystemModstamp, Territory__c, 
                    TickerSymbol, Type, Website, Year_Started__c from Account
                where id in: customerIds];
        
        system.debug('#### Customer List ' + pCustomers);

         // retrieve additional fields for troubleshooting and functional testing
         Set<Id> partnerDistributorIds = new Set<Id>();
         for (Account p:ppartnersDistributor ){
            partnerDistributorIds.add(p.Id);
         }
         ppartnersDistributor = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                     AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                     AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                     Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                     Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                     BCC_AuthDB_Account_ID__c, Bill_To_Email__c,  BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingGeocodeAccuracy,
                     BusinessGroup__c, Bypass_Validation__c,
                     Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                     Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                     Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                     Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                     IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                     LastActivityDate, LastModifiedById, LastModifiedDate, 
                     LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                     Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                     Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                     PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                     SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                     SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                     SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                     SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c,  ShippingStreet, ShippingCity, ShippingCountry, ShippingState, ShippingPostalCode, ShippingGeocodeAccuracy, Sic,
                     SicDesc, Site, Status__c, Strategic_Partner_Type__c, SystemModstamp, Territory__c,
                     TickerSymbol, Type, Website, Year_Started__c from Account
                 where id in: partnerDistributorIds];
         
         system.debug('#### Customer List ' + ppartnersDistributor);

          // retrieve additional fields for troubleshooting and functional testing
          Set<Id> partnerIds = new Set<Id>();
          for (Account p:pPartners ){
            partnerIds.add(p.Id);
          }
          pPartners = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                      AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                      AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                      Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                      Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                      BCC_AuthDB_Account_ID__c, Bill_To_Email__c,  BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingGeocodeAccuracy,
                      BusinessGroup__c, Bypass_Validation__c,
                      Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                      Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                      Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                      Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                      IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                      LastActivityDate, LastModifiedById, LastModifiedDate, 
                      LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                      Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                      Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                      PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                      SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                      SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                      SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                      SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c,  ShippingStreet, ShippingCity, ShippingCountry, ShippingState, ShippingPostalCode, ShippingGeocodeAccuracy, Sic,
                      SicDesc, Site, Status__c, Strategic_Partner_Type__c, SystemModstamp, Territory__c,
                      TickerSymbol, Type, Website, Year_Started__c from Account
                  where id in: partnerIds];
          
          system.debug('#### Customer List ' + pPartners);

          addAccountAddress(accountsToSave);
     }


    private static List<Account> createCustomerAccount(){
        if(suffixNumber == null || suffixNumber == 0){
            suffixNumber = 1;
        }
        suffixNumber++;
        
        pCustomers = new List<Account>();
                
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer' + ' ' + suffixNumber;
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';

        pCustomers.add(customer);

        return pCustomers;
    }

    private static List<Account> createPartnersDistributorAccount(){

        if(suffixNumber == null || suffixNumber == 0){
            suffixNumber = 1;
        }
        suffixNumber++;

        ppartnersDistributor = new List<Account>();

        Account partner = new Account();
        Partner.Is_Unit_Test__c = true;
        partner.Name = 'PartnerDistributor' + ' ' + suffixNumber;
        partner.Partner_Number__c = 12345;
        partner.Partner_Level__c = 'Premier';
        partner.Type = 'Distributor - Core';
        partner.BillingCountryCode = 'US';
        partner.BillingStateCode = 'CA';
        partner.Master_Agreement_Number__c = '1122334455';
        partner.AccountSource = 'Renewal';

        partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

        ppartnersDistributor.add(partner);

        return ppartnersDistributor;
    }
    
    private static List<Account> createPartners(){

        if(suffixNumber == null || suffixNumber == 0){
            suffixNumber = 1;
        }
        suffixNumber++;

        pPartners = new List<Account>();

        Account partner = new Account();
        Partner.Is_Unit_Test__c = true;
        partner.Name = 'Partner' + ' ' + suffixNumber;
         partner.Type = 'Partner - Reseller';
        partner.Partner_Number__c = 12345;
        partner.Partner_Level__c = 'Premier';
      //  partner.Partner_Level__c = 'Affiliate';  
       
        partner.BillingCountryCode = 'US';
        partner.BillingStateCode = 'CA';
        partner.Master_Agreement_Number__c = '1122334455';
        partner.AccountSource = 'Renewal';

        partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

        pPartners.add(partner);

        return pPartners;
    }

    private static void createContacts(){
        List<Contact> contactsToSave = new List<Contact>();
        contactsToSave.addAll(createPartnerContactsDistributor());
        contactsToSave.addAll(createPartnerContact());
        contactsToSave.addAll(createCustomerContact());

        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(contactsToSave);
        }

         // retrieve additional fields for troubleshooting and functional testing
         Set<Id> partnerContactsDistributorIds = new Set<Id>();
         for (Contact c:ppartnercontactsDistributor ){
            partnerContactsDistributorIds.add(c.Id);
         }
         ppartnercontactsDistributor = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                 Birthdate, BU_Manger_Contact__c, Bypass_Validation__c,
                 Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c,
                 Contact_Score__c, Contact_Status__c,
                 CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c,
                 CurrencyIsoCode,
                 Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c,
                 Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email,
                 EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax,
                 FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c,
                 HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id,
                 Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced,
                 LastActivityDate,
                 LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName,
                 LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c,
                 Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress,
                 MailingGeocodeAccuracy,
                 Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c,
                 MiddleName,
                 // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                 // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                 // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                 // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                 MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c,
                 Most_Recent_Lead_Source__c, 
                 Most_Recent_Lead_Source_Detail__c, 
                 Most_Recent_Medium__c,
                 Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c,
                 Name,
                 On24_Profile__c, Original_Blog__c, Original_Blog_Details__c,
                 Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone,
                 OwnerId,
                 Partner_Portal_Access__c, Phone, Phone_Extension__c,
                 PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c,
                 Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c,
                 Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c,
                 Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title,
                 Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c,
                 Use_Alt_Email_for_Case__c from Contact
                 where id in: partnerContactsDistributorIds];

                // update all the contact for the accoun t
               // List <Account> updatedAccounts  = new List <Account>();
                for (Contact c: ppartnercontactsDistributor){
                    Account a = new Account();
                    a.id = c.accountId;
                    a.Billing_Contact__c = c.Id;
                    a.Primary_Contact__c = c.Id;
                    a.Referral_Contact__c = c.Id;
                    a.Ship_To_Contact__c = c.FirstName;
                    a.Bill_To_Contact__c = c.FirstName;
                }

         
            // retrieve additional fields for troubleshooting and functional testing
            Set<Id> partnerContactIds = new Set<Id>();
            for (Contact c:pPartnerContacts ){
                partnerContactIds.add(c.Id);
            }
            pPartnerContacts = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                    Birthdate, BU_Manger_Contact__c, Bypass_Validation__c,
                    Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c,
                    Contact_Score__c, Contact_Status__c,
                    CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c,
                    CurrencyIsoCode,
                    Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c,
                    Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email,
                    EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax,
                    FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c,
                    HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id,
                    Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced,
                    LastActivityDate,
                    LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName,
                    LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c,
                    Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress,
                    MailingGeocodeAccuracy,
                    Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c,
                    MiddleName,
                    // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                    // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                    // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                    // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                    MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c,
                    Most_Recent_Lead_Source__c, 
                    Most_Recent_Lead_Source_Detail__c, 
                    Most_Recent_Medium__c,
                    Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c,
                    Name,
                    On24_Profile__c, Original_Blog__c, Original_Blog_Details__c,
                    Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone,
                    OwnerId,
                    Partner_Portal_Access__c, Phone, Phone_Extension__c,
                    PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c,
                    Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c,
                    Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c,
                    Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title,
                    Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c,
                    Use_Alt_Email_for_Case__c from Contact
            where id in: partnerContactIds];

             // update all the contact for the accoun t
            // List <Account> updatedAccounts  = new List <Account>();
             for (Contact c: pPartnerContacts){
                 Account a = new Account();
                 a.id = c.accountId;
                 a.Billing_Contact__c = c.Id;
                 a.Primary_Contact__c = c.Id;
                 a.Referral_Contact__c = c.Id;
                 a.Ship_To_Contact__c = c.FirstName;
                 a.Bill_To_Contact__c = c.FirstName;
             }


             // retrieve additional fields for troubleshooting and functional testing
             Set<Id> customerContactIds = new Set<Id>();
             for (Contact c:pCustomerContacts ){
                customerContactIds.add(c.Id);
             }
             pCustomerContacts = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                         Birthdate, BU_Manger_Contact__c, Bypass_Validation__c, 
                         Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c, 
                         Contact_Score__c, Contact_Status__c,
                         CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c, 
                         CurrencyIsoCode, 
                         Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c, 
                         Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email, 
                         EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax, 
                         FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c, 
                         HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id, 
                         Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced, 
                         LastActivityDate,
                         LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName, 
                         LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c, 
                         Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress, 
                         MailingGeocodeAccuracy, 
                         Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c, 
                         MiddleName,
                         // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                         // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                         // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                         // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                         MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c, 
                         Most_Recent_Lead_Source__c, 
                         Most_Recent_Lead_Source_Detail__c, 
                         Most_Recent_Medium__c, 
                         Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c, 
                         Name, 
                         On24_Profile__c, Original_Blog__c, Original_Blog_Details__c, 
                         Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone, 
                         OwnerId, 
                         Partner_Portal_Access__c, Phone, Phone_Extension__c, 
                         PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c, 
                         Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c, 
                         Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c, 
                         Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title, 
                         Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c, 
                         Use_Alt_Email_for_Case__c from Contact
                     where id in: customerContactIds];

                List <Account> updatedAccounts  = new List <Account>();
                for (Contact c: pCustomerContacts){
                    Account a = new Account();
                    a.id = c.accountId;
                    a.Billing_Contact__c = c.Id;
                    a.Primary_Contact__c = c.Id;
                    a.Referral_Contact__c = c.Id;
                    a.Ship_To_Contact__c = c.FirstName;
                    a.Bill_To_Contact__c = c.FirstName;
                }      

    }

    private static List<Contact> createPartnerContactsDistributor(){
        ppartnercontactsDistributor = new List<Contact>();


        for (Account acc: partnersDistributor){
            Contact rec = new Contact();
            rec.LastName = 'Doe' + ' ' + suffixNumber;
            rec.FirstName = 'Mary';
            //rec.FirstName__c = 'John';
            //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
            rec.Email = 'Mary.Doe@test.com.Distributor';
            rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
            rec.AccountId = acc.Id;
            rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            rec.LeadSource = 'Renewal';
            ppartnercontactsDistributor.add(rec);
        }

        return ppartnercontactsDistributor;
    }

    private static List<Contact> createPartnerContact(){
        pPartnerContacts = new List<Contact>();


        for (Account acc: partners){
            Contact rec = new Contact();
            rec.LastName = 'Doe' + ' ' + suffixNumber;
            rec.FirstName = 'Mary';
            //rec.FirstName__c = 'John';
            //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
            rec.Email = 'Mary.Doe@test.com';
            rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
            rec.AccountId = acc.Id;
            rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            rec.LeadSource = 'Renewal';
            pPartnerContacts.add(rec);
        }

        return pPartnerContacts;
    }

    private static List<Contact> createCustomerContact(){
        pCustomerContacts = new List<Contact>();


        for (Account acc: customers){
            Contact rec = new Contact();
            rec.LastName = 'Doe' + ' ' + suffixNumber;
            rec.FirstName = 'John';
            //rec.FirstName__c = 'John';
            //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
            rec.Email = 'John.Doe@test.com';
            rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
            rec.AccountId = acc.Id;
            rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            rec.LeadSource = 'Renewal';
            pCustomerContacts.add(rec);

        }

        return pCustomerContacts;

    }

    private static List<Account> pCustomers = null;
    public static List<Account> customers{
 
        get {
            if (pCustomers == null) {
                createAccounts();
               /* pCustomers = new List<Account>();
                
                Account customer = new Account();
                customer.Is_Unit_Test__c  = true;
                customer.Name = 'Customer' + ' ' + suffixNumber;
                customer.billingStreet = '415 Mission Street';
                customer.billingCity = 'San Francisco';
                customer.BillingCountryCode = 'US';
                customer.billingStateCode = 'CA';
                customer.billingPostalCode = '94105'; 
                customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
                customer.Status__c = 'Active';
                customer.Territory_ID__c = '123';
                customer.AccountSource = 'Renewal';
                customer.Terr_Theater__c = 'APAC';

                pCustomers.add(customer);

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pCustomers);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Account c:pCustomers ){
                    ids.add(c.Id);
                }
                pCustomers = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                            AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                            AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                            Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                            Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                            BCC_AuthDB_Account_ID__c,  Bill_To_Email__c,  BillingAddress, 
                            BillingGeocodeAccuracy, 
                            BusinessGroup__c, Bypass_Validation__c, 
                            Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                            Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                            Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                            Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                            IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                            Last_Activity_Date__c, LastActivityDate, LastModifiedById, LastModifiedDate, 
                            LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                            Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                            Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                            PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                            SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                            SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                            SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                            SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c, ShippingAddress, ShippingGeocodeAccuracy, Sic, 
                            SicDesc, Site, Status__c, SystemModstamp, Territory__c, 
                            TickerSymbol, Type, Website, Year_Started__c from Account
                        where id in: ids];
                
                system.debug('#### Customer List ' + pCustomers);*/
            }

            //addAccountAddress(pCustomers);

            return pCustomers;
        }
 
    }


  
  
  private static List<Account> ppartnersDistributor = null;
    public static List<Account> partnersDistributor{

        get {
            if (ppartnersDistributor == null) {
                createAccounts();
               /* ppartnersDistributor = new List<Account>();

                Account partner = new Account();
                Partner.Is_Unit_Test__c = true;
                partner.Name = 'PartnerDistributor' + ' ' + suffixNumber;
                partner.Partner_Number__c = 12345;
                partner.Partner_Level__c = 'Premier';
                partner.Type = 'Distributor - Core';
                partner.BillingCountryCode = 'US';
                partner.BillingStateCode = 'CA';
                partner.Master_Agreement_Number__c = '1122334455';
                partner.AccountSource = 'Renewal';

                partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

                ppartnersDistributor.add(partner);

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(ppartnersDistributor);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Account p:ppartnersDistributor ){
                    ids.add(p.Id);
                }
                ppartnersDistributor = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                            AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                            AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                            Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                            Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                            BCC_AuthDB_Account_ID__c, Bill_To_Email__c,  BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingGeocodeAccuracy,
                            BusinessGroup__c, Bypass_Validation__c,
                            Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                            Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                            Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                            Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                            IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                            LastActivityDate, LastModifiedById, LastModifiedDate, 
                            LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                            Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                            Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                            PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                            SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                            SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                            SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                            SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c,  ShippingStreet, ShippingCity, ShippingCountry, ShippingState, ShippingPostalCode, ShippingGeocodeAccuracy, Sic,
                            SicDesc, Site, Status__c, Strategic_Partner_Type__c, SystemModstamp, Territory__c,
                            TickerSymbol, Type, Website, Year_Started__c from Account
                        where id in: ids];
                
                system.debug('#### Customer List ' + ppartnersDistributor);*/
            }

            //addAccountAddress(ppartnersDistributor);
            return ppartnersDistributor;
        }

    }
  
  
  

    private static List<Account> pPartners = null;
    public static List<Account> partners{

        get {
            if (pPartners == null) {
                createAccounts();
                /*pPartners = new List<Account>();

                Account partner = new Account();
                Partner.Is_Unit_Test__c = true;
                partner.Name = 'Partner' + ' ' + suffixNumber;
                 partner.Type = 'Partner - Reseller';
                partner.Partner_Number__c = 12345;
                partner.Partner_Level__c = 'Premier';
              //  partner.Partner_Level__c = 'Affiliate';  
               
                partner.BillingCountryCode = 'US';
                partner.BillingStateCode = 'CA';
                partner.Master_Agreement_Number__c = '1122334455';
                partner.AccountSource = 'Renewal';

                partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

                pPartners.add(partner);

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pPartners);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Account p:pPartners ){
                    ids.add(p.Id);
                }
                pPartners = [select Account_Description__c, Account_Export_URL__c, Account_External_ID__c, Account_Notes__c, 
                            AccountNumber, AccountSource, Acct_Name_with_Location__c, Active_Owner__c,  
                            AnnualRevenue, Authorized_Countries__c, AWS_Account_Number__c, Azure_Subscription_Number__c, 
                            Barracuda_Rewards_Acceptance__c, Barracuda_Rewards_Acceptance_Date__c, 
                            Barracuda_Rewards_Acceptance_Individual__c, Barracuda_Rewards_Master_Individual__c, 
                            BCC_AuthDB_Account_ID__c, Bill_To_Email__c,  BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingGeocodeAccuracy,
                            BusinessGroup__c, Bypass_Validation__c,
                            Campaign_ID_Association__c, Case_Count__c, Compliance_Status__c, Contract_Name__c, Core_Vertical__c, 
                            Count_of_Account__c, CreatedById, CreatedDate, Credit_Status__c, CurrencyIsoCode, 
                            Current_Email_Security_Solution__c, Description, Do_Not_Disturb__c, DUNS_Number__c, Embargoed_Account__c, 
                            Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, 
                            IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Jigsaw, JigsawCompanyId, 
                            LastActivityDate, LastModifiedById, LastModifiedDate, 
                            LastReferencedDate, LastViewedDate, Master_Agreement_Number__c, MasterRecordId, Name, Named_Account__c, 
                            Number_Of_Locations__c, NumberOfEmployees, OwnerId, Ownership, 
                            Parent_Account_ID__c, ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone, 
                            PhotoUrl, Primary_Sales_Engineer__c, Rating, RecordTypeId, Region__c, 
                            SBQQ__AssetQuantitiesCombined__c, SBQQ__ContractCoTermination__c, SBQQ__CoTermedContractsCombined__c, 
                            SBQQ__CoTerminationEvent__c, SBQQ__DefaultOpportunity__c, SBQQ__IgnoreParentContractedPrices__c, 
                            SBQQ__PreserveBundle__c, SBQQ__PriceHoldEnd__c, SBQQ__RenewalModel__c, SBQQ__RenewalPricingMethod__c, 
                            SBQQ__TaxExempt__c, Secondary_SE__c, Ship_To_Email__c,  ShippingStreet, ShippingCity, ShippingCountry, ShippingState, ShippingPostalCode, ShippingGeocodeAccuracy, Sic,
                            SicDesc, Site, Status__c, Strategic_Partner_Type__c, SystemModstamp, Territory__c,
                            TickerSymbol, Type, Website, Year_Started__c from Account
                        where id in: ids];
                
                system.debug('#### Customer List ' + pPartners); */
            }

            //addAccountAddress(pPartners);
            return pPartners;
        }

    }

    private static List<Lead> pPostMQLLeads = null;
    public static List<Lead> postMQLLeads{

        get {
            if (pPostMQLLeads == null) {
                pPostMQLLeads = new List<Lead>();

                Lead postMQLLead = new Lead();
                postMQLLead.Company = 'TEST CO' + ' ' + suffixNumber;
                postMQLLead.FirstName = 'Larry';
                postMQLLead.LastName = 'Smith';
                postMQLLead.Email = 'larry.smith@test.com';
                postMQLLead.LeadSource = 'Unknown';
                //postMQLLead.status = 'MQL'; do not set directly here - will use default value
                postMQLLead.Business_Group__c = 'Core';
                postMQLLead.LiveChatTranscript_External_Id__c = String.valueOf(Math.random());

                postMQLLead.recordTypeId =   Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Post_MQL').getRecordTypeId();
                pPostMQLLeads.add(postMQLLead);

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    system.debug('#### insert List ' + pPostMQLLeads);
                    DML.save(pPostMQLLeads);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Lead c:pPostMQLLeads ){
                    ids.add(c.Id);
                }
                pPostMQLLeads = [select Address, Alternate_Email__c, AnnualRevenue, Attempts_Made__c, Authority_A__c, AWS_Account_Number__c,
                        Business_Group__c, BVM_Scan_Completed__c,Bypass_Validation__c,Cancel_Pending_Workflow__c, Chanpinleixing__c,
                        Claimed_vs_Unclaimed__c, Closed_Lost_Reason__c, Company, Company_D_U_N_S_Number__c, Completed_Activity_Count__c,
                        ConvertedAccountId, ConvertedContactId, ConvertedDate, ConvertedOpportunityId, Correlation_Data__c, CorrelationID__c,
                        Count_of_Lead__c, Created_by_Role__c, Created_Date_FM__c, Created_Date_FQ__c, Created_Date_FY__c, CreatedById,
                        CreatedDate, Creative__c, Creative_at_Distribution__c, Criteria_C__c, CurrencyIsoCode, Current_Backup_Solution__c,
                        Current_O365_Protection_Vendor__c, Current_Security_Provider__c, Cust_Under_Managed_Svc_Contract__c, Customer_Comments__c,
                        Customer_Dependent__c, Customer_Pains__c, Date_Last_DE_triggered__c, Date_Time_Created__c, Days_Open__c,
                        Days_since_last_update_or_activity__c, Days_to_Convert__c, Deal_Reg_Exp_Date__c, Deal_Reg_Tracking_No__c,
                        Demographic_Score__c, Department__c, Description, Disqualification_Category__c, Distributor__c, DMR_Tracking_Code__c,
                        D_B_DUNS_Number__c, DNBConnect__D_B_Connect_Company_Profile__c, Do_Not_Contact__c, DoNotCall, Duplicate_Lead__c,
                        Email, Email_Archiving__c, Email_Data_Size__c, Email_Domain__c, Email_OptIn__c, Email_Platforms__c, Email_System__c,
                        EmailBouncedDate, EmailBouncedReason, End_Users__c, ETS_ID__c,
                        ETS_Scan_Completed__c, Export_URL__c, Fax, Fenlei__c, FirstName, Form_Filled_Out__c, Found_Us__c, GDPR_Date__c,
                        GDPR_Opt_In__c, GDPR_Source__c, GeocodeAccuracy, geopointe__Geocode__c, HasOptedOutOfEmail, HasOptedOutOfFax,
                        HTTP_Referrer__c, Id, Implementation_I__c, Industry, Interaction_Score__c, Interest_Rating__c, Internal_Comments__c,
                        Invalid_Email__c, IsConverted, IsDeleted, IsUnreadByOwner, Jigsaw, JigsawContactId, Justification__c, Last_Activity__c,
                        Last_Activity_Date_for_Mkto__c, Last_Activity_Days__c, Last_Campaign__c, LastActivityDate, LastModifiedById,
                        LastModifiedDate, LastName, LastReferencedDate, LastTransferDate, LastViewedDate, 
                        Lead_Age__c, Lead_Converted_Date__c, Lead_Counter__c, Lead_Created_By__c, Lead_Created_Date__c,
                        Lead_Email_Domain__c, Lead_Id_For_Mapping__c, Lead_Score_at_Distribution__c, Lead_Source_at_Distribution__c,
                        Lead_Source_Detail__c, Lead_Source_Detail_at_Distribution__c, Lead_Source_Segment__c, Lead_Status_Segment__c,
                        Lead_Type__c, LeadSource, Legacy_archiving_cost__c, License_Key__c, LinkedIn_Company_ID__c, LinkedIn_Member_Token__c,
                        LinkedIn_URL__c, List_Source_Detail__c, List_Upload_Detail__c, List_Upload_Source__c, Live_Chat_Transcript__c,
                        LiveChatTranscript_External_Id__c, Location__c, Maestro_Instance__c, Marketing_Verified__c, MasterRecordId,
                        Medium_at_Distribution__c, Medium_Detail_at_Distribution__c, MiddleName, MobilePhone, Model_Series__c, Money_M__c,
                        Most_Recent_Blog__c, Most_Recent_Campaign_Date__c, Most_Recent_Form_Filled_Out__c, Most_Recent_Lead_Source__c,
                        Most_Recent_Lead_Source_Detail__c, 
                        Most_Recent_Medium__c, Most_Recent_Medium_Detail__c, Most_Recent_Publication__c,
                        MQL_Reason__c, MREFURL__c, MREFURL_at_Distribution__c, Name, Need_N__c, Next_Step__c, Number_of_Servers__c,
                        Number_of_Total_Customers__c, Number_of_Users__c, NumberOfEmployees, On24_Profile__c, Open_Hot_List_Count__c,
                        Opt_In_Newsletter__c, Original_Blog__c, Original_Medium__c, Original_Medium_Detail__c, Other_Competition__c,
                        Other_Notes__c, OwnerId, PA_3_Suppliers_You_Do_Most_Revenue_With__c, PA_Annual_Sales_Revenue__c,
                        PA_Business_Description__c, PA_Customer_Size_That_Drives_Business__c, PA_Describe_Your_Primary_Business__c,
                        PA_Number_of_Sales_Reps__c, PA_Number_of_Tech_Reps__c, PA_of_Business_from_Consulting__c,
                        PA_of_Business_from_Hardware_Sales__c, PA_of_Business_from_Help_Desk__c, PA_of_Business_from_InstallSupport__c,
                        PA_of_Business_from_Service__c, PA_of_Business_from_Software_Dev__c, PA_of_Business_from_Software_Sales__c,
                        PA_of_Business_from_Training__c, PA_Other_Email_Security_Sold__c, PA_Other_Firewall_Products_Sold__c, PA_Other_Vendor_Authorizations_Held__c, PA_Other_Web_Security_Products_Sold__c, PA_Primary_Geographical_Coverage__c, PA_Technical_Certs_Held__c, PA_Value_Added_Services_Provided__c, PA_Vertical_Market_That_Drives_Business__c, Pain__c, Partner_Name__c, PartnerAccountId, Phone, Phone_Extension__c, PhotoUrl, Popup_Exclusive_Distributor_Message__c, Portal_Account_ID__c, Potential_HurdlesConcerns__c, PPC_Keyword__c, Preferred_Deployment_Method__c, Primary_Hot_List__c, Primary_Product_Family_2__c,
                        Product__c, Product_Segment__c, Product_Segment_Detail__c, Prospect_Type__c, PSA__c, Publication__c, Queue_Priority__c, Rating, RecordTypeId, Region__c, Renewals_Email_Opt_In__c, Request_Type__c, Requirements_Description__c, Reseller__c, Reseller_Contact__c, Response_Time__c, RMM__c, Salutation, Score__c, Stack__c, State_Code__c, Status, Suffix, SystemModstamp, Terr_Location__c, Terr_Region__c, Terr_Sub_Territory__c, Terr_Sub_Theater__c, Terr_Theater__c, Territory__c, Time_Frame__c, Title, Track_Campaign__c, Tracking_Code__c, Trial_Expiration_Date__c, Trial_Start_Date__c, Trial_Username__c, Unqualified_Reason__c, Unqualified_Reason_Comment_optional__c, Unread_By_Owner__c, Verification_Method_of_Emp__c, Web_Source__c, Website, Website_Visitor_ID__c, X8_Character_Lead_ID__c, Xinghao__c, Zip_Postal_StartsWith__c from Lead
                where id in: ids];

                system.debug('#### postMQLLead List ' + pPostMQLLeads);
            }


            return pPostMQLLeads;
        }

    }

    
   
      private static List<Contact> ppartnercontactsDistributor = null;
    public static List<Contact> partnercontactsDistributor{

        get {
            if (ppartnercontactsDistributor == null) {
                createContacts();
                /*ppartnercontactsDistributor = new List<Contact>();


                for (Account acc: partnersDistributor){
                    Contact rec = new Contact();
                    rec.LastName = 'Doe' + ' ' + suffixNumber;
                    rec.FirstName = 'Mary';
                    //rec.FirstName__c = 'John';
                    //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
                    rec.Email = 'Mary.Doe@test.com.Distributor';
                    rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
                    rec.AccountId = acc.Id;
                    rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
                    rec.LeadSource = 'Renewal';
                    ppartnercontactsDistributor.add(rec);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(ppartnercontactsDistributor);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Contact c:ppartnercontactsDistributor ){
                    ids.add(c.Id);
                }
                ppartnercontactsDistributor = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                        Birthdate, BU_Manger_Contact__c, Bypass_Validation__c,
                        Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c,
                        Contact_Score__c, Contact_Status__c,
                        CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c,
                        CurrencyIsoCode,
                        Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c,
                        Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email,
                        EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax,
                        FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c,
                        HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id,
                        Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced,
                        LastActivityDate,
                        LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName,
                        LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c,
                        Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress,
                        MailingGeocodeAccuracy,
                        Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c,
                        MiddleName,
                        // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                        // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                        // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                        // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                        MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c,
                        Most_Recent_Lead_Source__c, 
                        Most_Recent_Lead_Source_Detail__c, 
                        Most_Recent_Medium__c,
                        Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c,
                        Name,
                        On24_Profile__c, Original_Blog__c, Original_Blog_Details__c,
                        Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone,
                        OwnerId,
                        Partner_Portal_Access__c, Phone, Phone_Extension__c,
                        PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c,
                        Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c,
                        Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c,
                        Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title,
                        Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c,
                        Use_Alt_Email_for_Case__c from Contact
                where id in: ids];

                // update all the contact for the accoun t
                List <Account> updatedAccounts  = new List <Account>();
                for (Contact c: ppartnercontactsDistributor){
                    Account a = new Account();
                    a.id = c.accountId;
                    a.Billing_Contact__c = c.Id;
                    a.Primary_Contact__c = c.Id;
                    a.Referral_Contact__c = c.Id;
                    a.Ship_To_Contact__c = c.FirstName;
                    a.Bill_To_Contact__c = c.FirstName;
                }
                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(updatedAccounts);
                }

                system.debug('#### Partner Contact List ' + ppartnercontactsDistributor);*/
            }

            return ppartnercontactsDistributor;
        }

    }

   
  




    private static List<Contact> pCustomerContacts = null;
    public static List<Contact> customerContacts{
 
        get {
            if (pCustomerContacts == null) {
                createContacts();
                /*pCustomerContacts = new List<Contact>();


                for (Account acc: customers){
                    Contact rec = new Contact();
                    rec.LastName = 'Doe' + ' ' + suffixNumber;
                    rec.FirstName = 'John';
                    //rec.FirstName__c = 'John';
                    //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
                    rec.Email = 'John.Doe@test.com';
                    rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
                    rec.AccountId = acc.Id;
                    rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
                    rec.LeadSource = 'Renewal';
                    pCustomerContacts.add(rec);

                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pCustomerContacts);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Contact c:pCustomerContacts ){
                    ids.add(c.Id);
                }
                pCustomerContacts = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                            Birthdate, BU_Manger_Contact__c, Bypass_Validation__c, 
                            Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c, 
                            Contact_Score__c, Contact_Status__c,
                            CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c, 
                            CurrencyIsoCode, 
                            Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c, 
                            Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email, 
                            EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax, 
                            FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c, 
                            HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id, 
                            Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced, 
                            LastActivityDate,
                            LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName, 
                            LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c, 
                            Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress, 
                            MailingGeocodeAccuracy, 
                            Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c, 
                            MiddleName,
                            // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                            // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                            // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                            // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                            MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c, 
                            Most_Recent_Lead_Source__c, 
                            Most_Recent_Lead_Source_Detail__c, 
                            Most_Recent_Medium__c, 
                            Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c, 
                            Name, 
                            On24_Profile__c, Original_Blog__c, Original_Blog_Details__c, 
                            Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone, 
                            OwnerId, 
                            Partner_Portal_Access__c, Phone, Phone_Extension__c, 
                            PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c, 
                            Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c, 
                            Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c, 
                            Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title, 
                            Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c, 
                            Use_Alt_Email_for_Case__c from Contact
                        where id in: ids];


                // update all the contact for the accoun t
                List <Account> updatedAccounts  = new List <Account>();
                for (Contact c: pCustomerContacts){
                    Account a = new Account();
                    a.id = c.accountId;
                    a.Billing_Contact__c = c.Id;
                    a.Primary_Contact__c = c.Id;
                    a.Referral_Contact__c = c.Id;
                    a.Ship_To_Contact__c = c.FirstName;
                    a.Bill_To_Contact__c = c.FirstName;
                }
                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(updatedAccounts);
                }
                
                system.debug('#### Customer Contact List ' + pCustomerContacts);*/
            }

            return pCustomerContacts;
        }
 
    }


    private static List<Contact> pPartnerContacts = null;
    public static List<Contact> partnerContacts{

        get {
            if (pPartnerContacts == null) {
                createContacts();
               /* pPartnerContacts = new List<Contact>();


                for (Account acc: partners){
                    Contact rec = new Contact();
                    rec.LastName = 'Doe' + ' ' + suffixNumber;
                    rec.FirstName = 'Mary';
                    //rec.FirstName__c = 'John';
                    //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
                    rec.Email = 'Mary.Doe@test.com';
                    rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
                    rec.AccountId = acc.Id;
                    rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
                    rec.LeadSource = 'Renewal';
                    pPartnerContacts.add(rec);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pPartnerContacts);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Contact c:pPartnerContacts ){
                    ids.add(c.Id);
                }
                pPartnerContacts = [select  AccountId, AssistantName, AssistantPhone, authDBIDcontact__c,
                        Birthdate, BU_Manger_Contact__c, Bypass_Validation__c,
                        Comments__c, contact_18_digit_id__c, Contact_Counter__c, Contact_LeadStatus__c,
                        Contact_Score__c, Contact_Status__c,
                        CreatedById, CreatedDate, Creative__c, Creative_at_Distribution__c,
                        CurrencyIsoCode,
                        Customer_Point_of_Contact__c, Demographic_Score__c, Department, Description, DMR_Region_Vertical__c,
                        Do_Not_Contact__c, Do_Not_Send_Support_Survey__c, DoNotCall, DPLCheck_Timeout__c, Email,
                        EmailBouncedDate,  EmailBouncedReason, External_ID__c, Fax,
                        FirstName, Form_Filled_Out__c, GDPR_Date__c, GDPR_Opt_In__c, GDPR_Source__c,
                        HasOptedOutOfEmail, HasOptedOutOfFax, HomePhone, Id,
                        Interaction_Score__c, Invalid_Email__c, IsDeleted, IsEmailBounced,
                        LastActivityDate,
                        LastCURequestDate, LastCUUpdateDate, LastModifiedById, LastModifiedDate, LastName,
                        LastReferencedDate, LastViewedDate, Lead_Source_at_Distribution__c, Lead_Source_Detail__c,
                        Lead_Source_Detail_at_Distribution__c, LeadSource, LinkedIn_URL__c, MailingAddress,
                        MailingGeocodeAccuracy,
                        Marketing_Point_of_Contact__c, MasterRecordId, Medium_at_Distribution__c, Medium_Detail_at_Distribution__c,
                        MiddleName,
                        // mkto_si__Last_Interesting_Moment_Date__c, mkto_si__Last_Interesting_Moment_Desc__c,
                        // mkto_si__Last_Interesting_Moment_Source__c, mkto_si__Last_Interesting_Moment_Type__c,
                        // mkto_si__Priority__c, mkto_si__Relative_Score__c, mkto_si__Relative_Score_Value__c,
                        // mkto_si__Sales_Insight__c, mkto_si__Urgency__c, mkto_si__Urgency_Value__c, mkto_si__View_in_Marketo__c,
                        MobilePhone, Most_Recent_FeaturePS__c, Most_Recent_FeatureRep__c, Most_Recent_Form_Fill__c,
                        Most_Recent_Lead_Source__c, 
                        Most_Recent_Lead_Source_Detail__c, 
                        Most_Recent_Medium__c,
                        Most_Recent_Medium_Detail__c, Most_Recent_Publication__c, MREFURL__c, MREFURL_at_Distribution__c,
                        Name,
                        On24_Profile__c, Original_Blog__c, Original_Blog_Details__c,
                        Original_Medium_Detail__c, OtherAddress, OtherGeocodeAccuracy, OtherPhone,
                        OwnerId,
                        Partner_Portal_Access__c, Phone, Phone_Extension__c,
                        PhotoUrl, PM_Point_of_Contact__c, PPC_Keyword__c,
                        Primary_Backup_Technician__c, Primary_Business_Owner__c,  Primary_FW_Tech__c,
                        Renewals_Opt_in__c, ReportsToId,  RunDPLCheck__c, Sales_Point_of_Contact__c,
                        Salutation, Sonian_Admin__c, Status__c, Suffix, SystemModstamp, Title,
                        Trial_User_Name__c, Unqualified_Reason__c, Unverified_Email_Address__c,
                        Use_Alt_Email_for_Case__c from Contact
                where id in: ids];

                // update all the contact for the accoun t
                List <Account> updatedAccounts  = new List <Account>();
                for (Contact c: pPartnerContacts){
                    Account a = new Account();
                    a.id = c.accountId;
                    a.Billing_Contact__c = c.Id;
                    a.Primary_Contact__c = c.Id;
                    a.Referral_Contact__c = c.Id;
                    a.Ship_To_Contact__c = c.FirstName;
                    a.Bill_To_Contact__c = c.FirstName;
                }
                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(updatedAccounts);
                }

                system.debug('#### Partner Contact List ' + pPartnerContacts);*/
            }

            return pPartnerContacts;
        }

    }

    public static void addAccountAddress(List <Account> accounts){

        List <Address__c > recList = new List <Address__c>();
        for (Account acct: accounts){
            Address__c addr;

            addr = new Address__c();
            addr.Country__c = countries.get('US').Id;
            addr.State__c = states.get('US').get('CA').Id;
            addr.Street__c = '415 Mission Street';
            addr.City__c = 'San Francisco';
            addr.Zip_Postal_Code__c = '94105';
            addr.Type__c = 'Billing';
            addr.Account__c = acct.Id;
            addr.Primary__c = true; // required to ensure that opportunity default address works
            recList.add(addr);

            addr = new Address__c();
            addr.Country__c = countries.get('US').Id;
            addr.State__c = states.get('US').get('CA').Id;
            addr.Street__c = '415 Mission Street';
            addr.City__c = 'San Francisco';
            addr.Zip_Postal_Code__c = '94105';
            addr.Type__c = 'Shipping';
            addr.Account__c = acct.Id;
            addr.Primary__c = true; // required to ensure that opportunity default address works
            recList.add(addr);

        }
        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(recList);
        }
        system.debug('#### Address List' + recList);

    }
    
    private static List<Asset> pAssets = null;
    public static List<Asset> assets{
 
        get {
            if (pAssets == null) {
                pAssets = new List<Asset>();
                
                for (Account acct: customers){
                        Asset asset = new Asset();
                        asset.AccountId = acct.ID;
                        asset.Name = 'Asset Name';
                        for(Product2 prod: products) {
                            asset.Product2Id = prod.ID; 
                        }
                        for (Serial__c s: serials){
                            asset.SerialNumber = s.Serial_Number__c;
                            asset.BNCPQ_Serial__c = s.Id;
                        }
                        pAssets.add(asset);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pAssets);
                }
                
            Set<Id> ids = new Set<Id>();
                for (Asset a:pAssets ){
                    ids.add(a.Id);
                }
                pAssets = [select AccountId, AssetLevel, AssetProvidedById, AssetServicedById, BNCPQ_Serial__c, ContactId, 
                            CreatedById, CreatedDate, CurrencyIsoCode, Description, Id, InstallDate, IsCompetitorProduct, IsDeleted, 
                            IsInternal, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Name, OwnerId, 
                            ParentId, Price, Product2Id, ProductCode, PurchaseDate, Quantity, RootAssetId, 
                            SBQQ__AdditionalDiscountAmount__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Bundle__c, 
                            SBQQ__Bundled__c, SBQQ__BundledQuantity__c, SBQQ__ChargeType__c, SBQQ__CombineKey__c, 
                            SBQQ__ComponentDiscountedByPackage__c, SBQQ__CreditProductId__c, SBQQ__CurrentSubscription__c, 
                            SBQQ__Dimension__c, SBQQ__Discount__c, SBQQ__DiscountSchedule__c, SBQQ__DiscountScheduleType__c, 
                            SBQQ__DistributorDiscount__c, SBQQ__DynamicOptionId__c, SBQQ__FromServiceCloud__c, 
                            SBQQ__LatestQuoteLine__c, SBQQ__ListPrice__c, SBQQ__MarkupAmount__c, SBQQ__MarkupRate__c, SBQQ__Number__c, 
                            SBQQ__OptionDiscount__c, SBQQ__OptionDiscountAmount__c, SBQQ__OptionLevel__c, SBQQ__OptionType__c, 
                            SBQQ__OrderProduct__c, SBQQ__OriginalUnitCost__c, SBQQ__PartnerDiscount__c, SBQQ__PricingMethod__c, 
                            SBQQ__ProductOption__c, SBQQ__QuoteLine__c, SBQQ__RegularPrice__c, SBQQ__RenewalUpliftRate__c, 
                            SBQQ__RequiredByAsset__c, SBQQ__RequiredById__c, SBQQ__RequiredByProduct__c, 
                            SBQQ__RequiredBySubscription__c, SBQQ__RevisedAsset__c, SBQQ__RootAsset__c, SBQQ__RootId__c, 
                            SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c, SBQQ__SegmentLabel__c, SBQQ__Subscription__c, 
                            SBQQ__SubscriptionEndDate__c, SBQQ__SubscriptionQuoteLine__c, SBQQ__SubscriptionStartDate__c, 
                            SBQQ__TermDiscountSchedule__c, SBQQ__UnitCost__c, SBQQ__VirtualAsset__c, SerialNumber, Status, 
                            StockKeepingUnit, SystemModstamp, UsageEndDate from Asset
                        where id in: ids];
                
                system.debug('#### Asset List ' + pAssets);

            }

            return pAssets;
        }

    }


    // 2019-01-15: AVA trigger failed. to do: figure out to create subscription and contract with minimum data
    /*
    private static List<SBQQ__Subscription__c> pSubscriptions = null;
    public static List<SBQQ__Subscription__c> subscriptions  {

        get {
            if (pSubscriptions == null) {
                pSubscriptions = new List<SBQQ__Subscription__c>();

                for (Account acct: customers){
                    SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
                    sub.SBQQ__Account__c = acct.ID;
                    for (Contract c: contracts){
                        sub.SBQQ__Contract__c = c.Id;
                        break;
                    }
                    for(Product2 prod: products) {
                        sub.SBQQ__Product__c = prod.ID;
                        break;
                    }
                    pSubscriptions.add(sub);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pSubscriptions);
                }

                Set<Id> ids = new Set<Id>();
                for (SBQQ__Subscription__c a:pSubscriptions ){
                    ids.add(a.Id);
                }
                pSubscriptions = [select
                        BOS_Tools__c, CreatedById, CreatedDate, CurrencyIsoCode, DistributorAccount__c, DistributorContact__c, Id,
                        IncumbentPartner__c, Is_Premium_Support__c, IsDeleted, LastModifiedById, LastModifiedDate, Name,
                        OrderNumber__c, Original_Order_Number__c, OwnerId, SBQQ__Account__c, SBQQ__AdditionalDiscountAmount__c,
                        SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__Bundle__c, SBQQ__Bundled__c, SBQQ__BundledQuantity__c,
                        SBQQ__ChargeType__c, SBQQ__ComponentDiscountedByPackage__c, SBQQ__ComponentSubscriptionScope__c, SBQQ__Contract__c,
                        SBQQ__ContractNumber__c, SBQQ__CreditProductId__c, SBQQ__CustomerPrice__c, SBQQ__Dimension__c, SBQQ__DimensionType__c,
                        SBQQ__Discount__c, SBQQ__DiscountSchedule__c, SBQQ__DiscountScheduleType__c, SBQQ__DistributorDiscount__c,
                        SBQQ__DynamicOptionId__c, SBQQ__EndDate__c, SBQQ__ListPrice__c, SBQQ__MarkupAmount__c, SBQQ__MarkupRate__c,
                        SBQQ__NetPrice__c, SBQQ__Number__c, SBQQ__OptionDiscount__c, SBQQ__OptionDiscountAmount__c, SBQQ__OptionLevel__c,
                        SBQQ__OptionType__c, SBQQ__OrderProduct__c, SBQQ__OriginalQuoteLine__c, SBQQ__OriginalUnitCost__c, SBQQ__PartnerDiscount__c,
                        SBQQ__PricingMethod__c, SBQQ__Product__c, SBQQ__ProductId__c, SBQQ__ProductName__c, SBQQ__ProductOption__c,
                        SBQQ__ProductSubscriptionType__c, SBQQ__ProrateMultiplier__c, SBQQ__Quantity__c, SBQQ__QuoteLine__c,
                        SBQQ__RegularPrice__c, SBQQ__RenewalPrice__c, SBQQ__RenewalProductId__c, SBQQ__RenewalProductOptionId__c,
                        SBQQ__RenewalProductOptionProductId__c, SBQQ__RenewalProductOptionSubscriptionPricing__c,
                        SBQQ__RenewalQuantity__c, SBQQ__RenewalUpliftRate__c, SBQQ__RenewedDate__c,
                        SBQQ__RequiredById__c, SBQQ__RequiredByProduct__c, SBQQ__RevisedSubscription__c,
                        SBQQ__RootId__c, SBQQ__SegmentEndDate__c, SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c,
                        SBQQ__SegmentLabel__c, SBQQ__SegmentQuantity__c, SBQQ__SegmentStartDate__c, SBQQ__SegmentUplift__c,
                        SBQQ__SegmentUpliftAmount__c, SBQQ__SpecialPrice__c, SBQQ__StartDate__c, SBQQ__SubscriptionEndDate__c,
                        SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionType__c, SBQQ__TermDiscountSchedule__c,
                        SBQQ__TerminatedDate__c, SBQQ__UnitCost__c, Temporary_Extension_Active_Until__c from SBQQ__Subscription__c
                where id in: ids];

                system.debug('#### subscription List ' + pSubscriptions);

            }

            return pSubscriptions;
        }
    }


    private static List<Contract> pContract = null;
    public static List<Contract> contracts  {

        get {
            if (pContract == null) {
                pContract = new List<Contract>();

                for (Account acct: customers){
                    Contract sub = new Contract();
                    sub.AccountId = acct.ID;
                    // sub.ActivatedDate = Date.today(); // not writeable
                    pContract.add(sub);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pContract);
                }

                Set<Id> ids = new Set<Id>();
                for (Contract a:pContract ){
                    ids.add(a.Id);
                }
                pContract = [select AccountId, ActivatedById, ActivatedDate, BillingAddress, BillingGeocodeAccuracy, BusinessGroup__c,
                        CompanySignedDate, CompanySignedId, ContractNumber, ContractTerm, CreatedById, CreatedDate, CurrencyIsoCode,
                        CustomerSignedDate, CustomerSignedId, CustomerSignedTitle, Description, End_User_Contact__c, End_User_Contact2__c,
                        EndDate, Id, IsDeleted, LastActivityDate, LastApprovedDate, LastModifiedById, LastModifiedDate, LastReferencedDate,
                        LastViewedDate, OwnerExpirationNotice, OwnerId, Pricebook2Id, Primary_Contact__c, SBQQ__ActiveContract__c,
                        SBQQ__AmendmentOpportunityRecordTypeId__c, SBQQ__AmendmentOpportunityStage__c, SBQQ__AmendmentOwner__c, SBQQ__AmendmentPricebookId__c,
                        SBQQ__AmendmentRenewalBehavior__c, SBQQ__AmendmentStartDate__c, SBQQ__DefaultRenewalContactRoles__c, SBQQ__DefaultRenewalPartners__c,
                        SBQQ__DisableAmendmentCoTerm__c, SBQQ__Evergreen__c, SBQQ__ExpirationDate__c, SBQQ__MasterContract__c, SBQQ__MDQRenewalBehavior__c,
                        SBQQ__Opportunity__c, SBQQ__OpportunityPricebookId__c, SBQQ__Order__c, SBQQ__PreserveBundleStructureUponRenewals__c, SBQQ__Quote__c,
                        SBQQ__RenewalForecast__c, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunityRecordTypeId__c, SBQQ__RenewalOpportunityStage__c,
                        SBQQ__RenewalOwner__c, SBQQ__RenewalPricebookId__c, SBQQ__RenewalQuoted__c, SBQQ__RenewalTerm__c, SBQQ__RenewalUpliftRate__c,
                        SBQQ__SubscriptionQuantitiesCombined__c, ShippingAddress, ShippingGeocodeAccuracy, SpecialTerms, StartDate, Status, StatusCode
                from Contract
                where id in: ids];

                system.debug('#### Contract List ' + pContract);

            }

            return pContract;
        }
    }

    */

    public static Opportunity createOpportunity(Account acct)
    {


        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty' + suffixNumber;
        oppt.AccountID = acct.Id;
     //   oppt.Distributor__c = partnercontacts[0].accountId;
    //    oppt.Distributor_Contact__c = partnercontacts[0].id;
    
        oppt.Distributor__c = partnercontactsDistributor[0].accountId;
        oppt.Distributor_Contact__c = partnercontactsDistributor[0].id;
     
        
         oppt.Reseller__c =  partnercontacts[0].accountId;
         oppt.Reseller_Contact__c = partnercontacts[0].id;
     
        
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        // new business opportunities
         oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
         oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        

        return oppt;

    }

    public static Opportunity createEmptyOpportunity(Account acct)
    {


        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty' + suffixNumber;
        oppt.AccountID = acct.Id;
     //   oppt.Distributor__c = partnercontacts[0].accountId;
    //    oppt.Distributor_Contact__c = partnercontacts[0].id;
    
        //oppt.Distributor__c = partnercontactsDistributor[0].accountId;
        //oppt.Distributor_Contact__c = partnercontactsDistributor[0].id;
     
        
         //oppt.Reseller__c =  partnercontacts[0].accountId;
         //oppt.Reseller_Contact__c = partnercontacts[0].id;
     
        
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        // new business opportunities
         oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
         oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        

        return oppt;

    }




    private static List<Opportunity> pOpportunities = null;
    public static List<Opportunity> opportunities  {

        get {

            if (pOpportunities == null){

                pOpportunities = new List <Opportunity>();
                
                for (Account acct: customers){

                    Opportunity oppt = createOpportunity(acct);


                    system.debug('#### Preliminary Opportunity: ' + oppt);
                    pOpportunities.add(oppt);
                }
                /*if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pOpportunities);
                }*/

                // address will be overwritten via PB + Flow when the opportunity is inserted
                // but just in case opportunity flow is turned off, copy here via apex as well
                for (Opportunity oppt: pOpportunities ){
                    List <Address__c> addresses = [select id, Street__c, City__c, State_Name__c, Country_Name__c, Zip_Postal_Code__c,   Type__c, Account__c from Address__c ];
                    System.debug('#### address in oppty: ' + addresses);
                    for (Address__c addr : addresses){
                        if (addr.Account__c == oppt.Distributor__c && addr.Type__c == 'Billing' ){
                            oppt.Billing_Address__c = addr.Id;
                            oppt.Street__c = addr.Street__c;
                            oppt.City__c = addr.City__c;
                            oppt.State__c = addr.State_Name__c;
                            oppt.Country__c = addr.Country_Name__c;
                            oppt.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                        } else if (addr.Account__c == oppt.Reseller__c && addr.Type__c == 'Billing' ){
                            oppt.Billing_Address__c = addr.Id;
                            oppt.Street__c = addr.Street__c;
                            oppt.City__c = addr.City__c;
                            oppt.State__c = addr.State_Name__c;
                            oppt.Country__c = addr.Country_Name__c;
                            oppt.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                        } else if  (addr.Account__c == oppt.AccountId && addr.Type__c == 'Shipping' ){
                            oppt.Shipping_Address__c = addr.Id;
                            oppt.Ship_To_Street__c = addr.Street__c;
                            oppt.Ship_To_City__c = addr.City__c;
                            oppt.Ship_To_State__c = addr.State_Name__c;
                            oppt.Ship_To_Country__c = addr.Country_Name__c;
                            oppt.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                        }
                    }
                    for (Contact c: customerContacts){
                        if (c.accountId == oppt.AccountId){
                            oppt.Primary_Contact__c = c.Id;
                        }
                    }
                }
                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pOpportunities);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Opportunity o:pOpportunities ){
                    ids.add(o.Id);
                }

                //SFDC 9016 - Adding Deal Reg related fields
                pOpportunities = [select AccountId, Amount, Billing_Address__c, Shipping_Address__c, Budget_Confirmed__c, Business_Group__c, CampaignId, City__c, CloseDate,
                            ContractId, Converted_Lead_Id__c, Country__c, CreatedById, CreatedDate, CurrencyIsoCode, Description, 
                            Discovery_Completed__c, Distributor__c, Distributor_Contact__c, Deal_Reg_Exp_Date__c, Deal_Reg_Status__c, Deal_Reg_Type__c, 
                            Deal_Reg_Tracking_No__c, ExpectedRevenue, Fiscal, FiscalQuarter, 
                            FiscalYear, ForecastCategory, ForecastCategoryName, HasOpenActivity, HasOpportunityLineItem, 
                            HasOverdueTask, Id, IsClosed, IsDeleted, IsExcludedFromTerritory2Filter, IsPrivate, IsWon, 
                            LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                            Lead_Primary_Product_Family__c, LeadSource, Closed_Lost_Reason__c, Name, NextStep, Opportunity_Type__c,
                            Override_Account_Payment_Terms__c, OwnerId, PartnerAccountId, Pricebook2Id, Primary_Contact__c, 
                            Probability, Quote_Record_Type_Name__c, RecordTypeId, Reseller__c, Reseller_Contact__c, 
                            ROI_Analysis_Completed__c, sbaa__ApprovalStatus__c, sbaa__ApprovalStep__c, sbaa__Approver__c, 
                            sbaa__StepApproved__c, sbaa__SubmittedDate__c, sbaa__SubmittedUser__c, SBQQ__AmendedContract__c, 
                            SBQQ__Contracted__c, SBQQ__CreateContractedPrices__c, SBQQ__Ordered__c, SBQQ__OrderGroupID__c, 
                            SBQQ__PrimaryQuote__c, SBQQ__QuotePricebookId__c, SBQQ__Renewal__c, SBQQ__RenewedContract__c, 
                            Select_Primary_Contact__c, Ship_To_City__c, Ship_To_Country__c, Ship_To_State__c, Ship_To_Street__c, 
                            Ship_To_Zip_Postal_Code__c, StageName, State__c, Street__c, SyncedQuoteId, SystemModstamp, 
                            Technical_Win__c, Territory2Id, TotalOpportunityQuantity, Type, Zip_Postal_Code__c from Opportunity
                        where id in: ids];
                
                system.debug('#### Opportunity List ' + pOpportunities);

            }

            return pOpportunities;
        }

    }



    private static List<SBQQ__Quote__c> pQuotes = null;
    public static List<SBQQ__Quote__c> quotes{

        get {
            if (pQuotes == null) {
                pQuotes = new List<SBQQ__Quote__c>();


                For (Opportunity oppty: opportunities){
                    SBQQ__Quote__c rec = new SBQQ__Quote__c();
                    rec.SBQQ__Opportunity2__c = oppty.Id;

                    pQuotes.add(rec);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pQuotes);
                }
                system.debug('#### Quote List ' + pQuotes);

                // add quote Item
                // addQuoteItem(pOrders);
            }
            return pQuotes;
        }


    }
    private static List<Order> pOrders = null;
    public static List<Order> orders{
 
        get {
            if (pOrders == null) {
                pOrders = new List<Order>();

                //Get Opportunities and prepare a map of Opportunities and Account
                Map<Id, Id> accountOppMap = new Map<Id,Id>();
                for(Opportunity opp: opportunities){
                    if(!accountOppMap.containsKey(opp.AccountId)){
                        accountOppMap.put(opp.AccountId, opp.Id);
                    }
                }

                For (Account acct: customers){
                    Order rec = new Order();
                    rec.AccountId = acct.id;
                    rec.EffectiveDate = Date.today();
                    rec.Pricebook2Id = TestDataFactory.priceBookId;
                    rec.description = 'Order ' + suffixNumber;
                    rec.Status = 'Draft';
                    rec.Type = 'New'; // new order
                    rec.OpportunityId = accountOppMap.get(acct.id);
                    pOrders.add(rec);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pOrders);
                }
                system.debug('#### Order List ' + pOrders);

                // add order Item
                addOrderItem(pOrders); 
            }
            return pOrders;
        }
 
    }


    public static void addOrderItem(List <Order> orders){

        Id pricebookId = Test.isRunningTest() ? null : [Select id from Pricebook2 where isStandard = true limit 1].id;
        PricebookEntry standardPrice = Test.isRunningTest() ? null : [ select id from PricebookEntry where Pricebook2Id =: pricebookId limit 1]; 
            
       /* Serial__c serial = new Serial__c();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        insert serial;         */
        

            List <OrderItem> recList = new List <OrderItem>(); 
            for (Order parentRec: orders){
                // add order item
                OrderItem rec;

                rec = new OrderItem();  
                rec.orderId = parentRec.Id;
                rec.Quantity = 1; 
                rec.UnitPrice = 1; 
                rec.PricebookEntryId = priceBookEntry[0].Id; 
               // rec.Serial__c = serial.Id;
                recList.add(rec); 
            }
            if(Test.isRunningTest() || TestDataFactory.createRealData) {
                DML.save(recList);
            }
            system.debug('#### Order Items' + recList);

    }

    private static Id pPriceBookId = null; 
    public static Id priceBookId {
        get {
                if (pPriceBookId == null){
                    pPriceBookId =Test.getStandardPricebookId(); // try to get the standard pricebook if it is in test
                    system.debug('#### Pricebook ID: ' + pPriceBookId);
                }
                if (pPriceBookId == null){
                    Pricebook2 pb = [Select id from Pricebook2 where isStandard = true limit 1]; 
                    if (pb != null){      
                        pPriceBookId = Test.isRunningTest() ? null : pb.id;
                        system.debug('#### Pricebook ID: ' + pPriceBookId);
                    }
                }
                // ok. does not exist create new one
                if (pPriceBookId == null){
                    Pricebook2 pricebook = new Pricebook2(Name = 'PriceBook' + suffIxNumber); 
                    DML.save(pricebook); 
                    pPriceBookId = pricebook.Id; 
                    system.debug('#### Pricebook ID: ' + pPriceBookId);
                }
                
                return pPriceBookId; 
        }
    }

    private static List<Product2> pProducts = null;
    public static List<Product2> products{
 
        get {
            if (pProducts == null) {
                pProducts = new List<Product2>();


                Product2 rec = new Product2();
                rec.Name = 'Prod' + suffixNumber;
                rec.is_pst_enterprise__c = true;
                pProducts.add(rec);

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pProducts);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Product2 p:pProducts ){
                    ids.add(p.Id);
                }
                pProducts = [select Allocate_POT_on_Orders__c, Barracuda_Product__c, Base_SKU__c, bc_prod_base_capacity__c, 
                            bc_prod_base_model__c, bc_prod_is_ng__c, China_Old_ID__c, Cost_Method__c, Country__c, CPQ_Product_Family__c, 
                            CreatedById, CreatedDate, CurrencyIsoCode, Description, DisplayUrl, ExternalDataSourceId, ExternalId, 
                            ExtId__c, Family, h_product_family__c, Id, Include_in_Core_Results__c, is_archiveone_enterprise__c, 
                            is_archiveone_express__c, is_demo__c, is_pst_enterprise__c, is_pst_rental__c, IsActive, IsDeleted, 
                            Item_Type__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Model_Number__c, 
                            MSP_Only__c, MSP_Product__c, Name, prod_subtype__c, prod_subtype_code__c, Product_Config_DIsplay_Name__c, 
                            Product_Model__c, product_model_bands__c, product_series_name__c, ProductCode, Purchasing_Unit__c, 
                            QuantityUnitOfMeasure, Ratio_to_OE_Standard__c, Ratio_to_PO_Standard__c, Sales_Unit__c, 
                            SBCF_ATP_Applicable_Add__c, SBCF_ATP_Applicable_Product__c, SBCF_ATP_Product__c, SBCF_Base_Product__c, 
                            SBCF_Capacity_Max__c, SBCF_Capacity_Min__c, SBCF_Capacity_Unit__c, SBCF_Config_SKU_Type__c, 
                            SBCF_Contract_Length__c, SBCF_Form_Factor__c, SBCF_Is_Bundle__c, SBCF_Is_Shipped__c, SBCF_Model_Tier__c, 
                            SBCF_Product_Code_Prefix__c, SBCF_Product_Family_Code__c, SBCF_Product_Group__c, SBCF_Product_Misc__c, 
                            SBCF_Product_Model__c, SBCF_Product_Segment__c, SBCF_Product_Upsell__c, SBQQ__AssetAmendmentBehavior__c, 
                            SBQQ__AssetConversion__c, SBQQ__BatchQuantity__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, 
                            SBQQ__BlockPricingField__c, SBQQ__ChargeType__c, SBQQ__Component__c, SBQQ__CompoundDiscountRate__c, 
                            SBQQ__ConfigurationEvent__c, SBQQ__ConfigurationFields__c, SBQQ__ConfigurationFieldSet__c, 
                            SBQQ__ConfigurationFormTitle__c, SBQQ__ConfigurationType__c, SBQQ__ConfigurationValidator__c, 
                            SBQQ__ConfiguredCodePattern__c, SBQQ__ConfiguredDescriptionPattern__c, SBQQ__CostEditable__c, 
                            SBQQ__CostSchedule__c, SBQQ__CustomConfigurationPage__c, SBQQ__CustomConfigurationRequired__c, 
                            SBQQ__CustomerCommunityAvailability__c, SBQQ__DefaultPricingTable__c, SBQQ__DefaultQuantity__c, 
                            SBQQ__DescriptionLocked__c, SBQQ__DiscountCategory__c, SBQQ__DiscountSchedule__c, SBQQ__DynamicPricingConstraint__c, 
                            SBQQ__ExcludeFromMaintenance__c, SBQQ__ExcludeFromOpportunity__c, SBQQ__ExternallyConfigurable__c, 
                            SBQQ__GenerateContractedPrice__c, SBQQ__HasConfigurationAttributes__c, SBQQ__Hidden__c, SBQQ__HidePriceInSearchResults__c, 
                            SBQQ__IncludeInMaintenance__c, SBQQ__NewQuoteGroup__c, SBQQ__NonDiscountable__c, SBQQ__NonPartnerDiscountable__c, 
                            SBQQ__Optional__c, SBQQ__OptionLayout__c, SBQQ__OptionSelectionMethod__c, SBQQ__PriceEditable__c, SBQQ__PricingMethod__c, 
                            SBQQ__PricingMethodEditable__c, SBQQ__ProductPictureID__c, SBQQ__QuantityEditable__c, SBQQ__QuantityScale__c, 
                            SBQQ__ReconfigurationDisabled__c, SBQQ__RenewalProduct__c, SBQQ__SortOrder__c, SBQQ__Specifications__c, 
                            SBQQ__SubscriptionBase__c, SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c, SBQQ__SubscriptionPricing__c, 
                            SBQQ__SubscriptionTarget__c, SBQQ__SubscriptionTerm__c, SBQQ__SubscriptionType__c, SBQQ__Taxable__c, SBQQ__TaxCode__c, 
                            SBQQ__TermDiscountLevel__c, SBQQ__TermDiscountSchedule__c, SBQQ__UpgradeCredit__c, SBQQ__UpgradeRatio__c, 
                            SBQQ__UpgradeSource__c, SBQQ__UpgradeTarget__c, sku_type__c, Sonian_Product__c, Standard_Unit__c, Lifecycle_Status__c, 
                            StockKeepingUnit, Sub_Code__c, Subscription_Conversion__c, SystemModstamp from Product2
                        where id in: ids];
                        
                system.debug('#### Product List ' + pProducts);
            }
            return pProducts;
        }
    }

    private static List<Entitlement> pEntitlements = null;
    public static List <Entitlement> entitlements {
        get {
            if (pEntitlements == null){
                pEntitlements = new List <Entitlement>();

                for (Account acc: customers){
                    Entitlement e = new Entitlement();
                    e.AccountId = acc.Id;
                    e.Name = 'Premium Support';
                    e.StartDate = Date.today();
                    e.EndDate = Date.today().addDays(366);
                    pEntitlements.add(e);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pEntitlements);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Entitlement e:pEntitlements ){
                    ids.add(e.Id);
                }
                pEntitlements = [select AccountId, AssetId, BusinessHoursId, CasesPerEntitlement, ContractLineItemId, 
                            CreatedById, CreatedDate, CurrencyIsoCode, EndDate, Id, IsDeleted, IsPerIncident, LastModifiedById, 
                            LastModifiedDate, LastReferencedDate, LastViewedDate, Name, RemainingCases, ServiceContractId, 
                            SlaProcessId, StartDate, Status, SystemModstamp, Type from Entitlement
                        where id in: ids];
                        
                system.debug('#### Entitlements' + pEntitlements);
            }

            return pEntitlements;
        }
    }


    private static List <Case> pDpaasCases = null;
    public static List <Case> dpaasCases {
        get {
            if (pDpaasCases == null){
                pDpaasCases = new List <Case>();

                for (Contact c: customerContacts) {
                    Case cse = new Case();
                    for (Asset a: assets) {
                        cse.Assetid = a.Id;
                    }
                    cse.Accountid = c.AccountId;
                    cse.Contactid = c.Id;
                    cse.Description = 'Dpaas Case ' + suffixNumber;
                    cse.Status = 'New';
                    cse.Web_First_Name__c = c.FirstName;
                    cse.Web_Last_Name__c = c.LastName;
                    cse.SuppliedEmail = c.Email;
                    cse.Subject = 'Unit Test' + suffixNumber;
                    cse.Origin = 'Email';
                    cse.Web_Language_of_correspondence__c = 'English';
                    cse.Web_Region__c = 'Americas';
                    // cse.ProductFamilyQueue__c = 'ContactCenter';   // formual value: IF( (Queue__c = 'ContactCenter' || ISBLANK(Product_Family__c)) ,Queue__c,Product_Family__c + ' ' + Queue__c)
                    cse.New_Case_Notification_Sent__c = true; // 2018-11-11: suppress email notification

                    cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('DPAAS_Cases').getRecordTypeId();
                    pDpaasCases.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pDpaasCases);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Case c:pDpaasCases ){
                    ids.add(c.Id);
                }

                pDpaasCases = [select Account_Type__c, AccountId, Alert__c, Alternate_Email__c, AssetId, Assigned_to_First_Queue__c,
                        Bug_Feature_Number__c, BusinessHoursId, Can_Access_Device__c, Case_Comment__c, Case_Re_Opened__c, CaseNumber,
                        Client__c, ClosedDate, Computer_ID__c, Computer_Name__c, Contact_Verified_Condition__c, ContactEmail, ContactFax, ContactId,
                        ContactMobile, ContactPhone, CreatedById, CreatedDate, CurrencyIsoCode, Description, Engineering_Escalation__c,
                        EntitlementId, Escalated_Date_Time__c, Escalated_End_Date_Time__c, File_or_Solution_Sent__c, Firmware_SW_version__c,
                        Fix_Version__c, Has_Enterprise_Asset__c, Hours_Since_Last_Modified__c, Id, In_Progress__c, Is_Asset_Verified__c,
                        Is_Contact_Verified__c, Is_Enterprise_Account__c, Is_MSP__c, Is_Premium_Support__c, IsClosed, IsClosedOnCreate,
                        IsDeleted, IsEscalated, IsStopped, JIRA_Status__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                        MilestoneStatus, New_Case_Notification_Sent__c, Occuring_NOW__c, Origin, Original_Assignee__c, OwnerId, ParentId, Priority,
                        ProductId, Queue_Counter__c, Reason, RecordTypeId, RecordType.Name, Region__c, Region_Theatre__c, Related_Account__c, Related_Account_Type__c,
                        Related_Contact__c, ProductFamilyQueue__c, Queue__c,
                        RMA_Comments__c, RMA_Number__c, SlaExitDate, SlaStartDate, SourceId, Status, StopStartDate, Sub_Region_Theatre__c,
                        Subject, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, SystemModstamp, Type, Username__c,
                        Web_Existing_Case__c, Web_First_Name__c, Web_Language_of_correspondence__c, Web_Last_Name__c, Web_Region__c, Web_Serial__c from Case
                where id in: ids];
                system.debug('#### Support Cases ' + pDpaasCases);
            }

            return  pDpaasCases;
        }
    }

    private static List <Case> pSupportCases = null;
    public static List <Case> supportCases {
        get {
            if (pSupportCases == null){
                pSupportCases = new List <Case>();

                for (Contact c: customerContacts) {
                    Case cse = new Case();
                    for (Asset a: assets) {
                            cse.Assetid = a.Id;
                            // cse.Serial__c = a.BNCPQ_Serial__c;
                    }
                    cse.Accountid = c.AccountId;
                    cse.Contactid = c.Id;
                    cse.Description = 'Support Case ' + suffixNumber;
                    cse.Status = 'New';
                    cse.Web_First_Name__c = c.FirstName;
                    cse.Web_Last_Name__c = c.LastName;
                    cse.SuppliedEmail = c.Email;
                    cse.Subject = 'Unit Test' + suffixNumber;
                    cse.Origin = 'Email';
                    cse.Web_Language_of_correspondence__c = 'English';
                    cse.Web_Region__c = 'Americas';
                    //10/28/2019 Adding Product Family due to the addition of a new validation rule
                    cse.Product_Family_List__c = 'Backup Server/Service';
                    cse.Missing_Serial_Number__c = 'abc';
                    // cse.Product_Family_List__c = 'Sonian';
                    // cse.ProductFamilyQueue__c = 'ContactCenter';   // formual value: IF( (Queue__c = 'ContactCenter' || ISBLANK(Product_Family__c)) ,Queue__c,Product_Family__c + ' ' + Queue__c)
                    cse.New_Case_Notification_Sent__c = true; // 2018-11-11: suppress email notification


                    cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
                    pSupportCases.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pSupportCases);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Case c:pSupportCases ){
                    ids.add(c.Id);
                }

                pSupportCases = [select  Account_Type__c, AccountId, Alert__c, Alternate_Email__c, AssetId, Assigned_to_First_Queue__c,
                        Bug_Feature_Number__c, BusinessHoursId, Can_Access_Device__c, Case_Comment__c, Case_Re_Opened__c, CaseNumber,
                        Client__c, ClosedDate, Computer_ID__c, Computer_Name__c, Contact_Verified_Condition__c, ContactEmail, ContactFax, ContactId,
                        ContactMobile, ContactPhone, CreatedById, CreatedDate, CurrencyIsoCode, Description, Engineering_Escalation__c,
                        EntitlementId, Escalated_Date_Time__c, Escalated_End_Date_Time__c, File_or_Solution_Sent__c, Firmware_SW_version__c,
                        Fix_Version__c, Has_Enterprise_Asset__c, Hours_Since_Last_Modified__c, Id, In_Progress__c, Is_Asset_Verified__c,
                        Is_Contact_Verified__c, Is_Enterprise_Account__c, Is_MSP__c, Is_Premium_Support__c, IsClosed, IsClosedOnCreate,
                        IsDeleted, IsEscalated, IsStopped, JIRA_Status__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                        MilestoneStatus, New_Case_Notification_Sent__c, Occuring_NOW__c, Origin, Original_Assignee__c, OwnerId, ParentId, Priority,
                        ProductId, Queue_Counter__c, Reason, RecordTypeId, RecordType.Name, Region__c, Region_Theatre__c, Related_Account__c, Related_Account_Type__c,
                        Related_Contact__c, ProductFamilyQueue__c, Queue__c, Serial__c,
                        RMA_Comments__c, RMA_Number__c, SlaExitDate, SlaStartDate, SourceId, Status, StopStartDate, Sub_Region_Theatre__c,
                        Subject, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, SystemModstamp, Type, Username__c,
                        Web_Existing_Case__c, Web_First_Name__c, Web_Language_of_correspondence__c, Web_Last_Name__c, Web_Region__c, Web_Serial__c from Case
                        where id in: ids];
                system.debug('#### Support Cases ' + pSupportCases);
            }

            return  pSupportCases;
        }
    }

private static List <Case> pClosedSupportCases = null;
    public static List <Case> closedSupportCases {
        get {
            if (pClosedSupportCases == null){
                pClosedSupportCases = new List <Case>();

                for (Contact c: customerContacts) {
                    Case cse = new Case();
                    for (Asset a: assets) {
                            cse.Assetid = a.Id;
                            // cse.Serial__c = a.BNCPQ_Serial__c;
                    }
                    cse.Accountid = c.AccountId;
                    cse.Contactid = c.Id;
                    cse.Description = 'Support Case ' + suffixNumber;
                    cse.Status = 'Closed';
                    cse.Web_First_Name__c = c.FirstName;
                    cse.Web_Last_Name__c = c.LastName;
                    cse.SuppliedEmail = c.Email;
                    cse.Subject = 'Unit Test' + suffixNumber;
                    cse.Origin = 'Email';
                    cse.Web_Language_of_correspondence__c = 'English';
                    cse.Web_Region__c = 'Americas';
                    //10/28/2019 Adding Product Family due to the addition of a new validation rule
                    cse.Product_Family_List__c = 'Backup Server/Service'; 
                    
                    //SFDC-10262 Adding case closed reason fields due to addition of validation rules
                    cse.Case_Closed_Reason_WM__c = 'Expired Subscriptions';
                    cse.Case_Reason__c = 'Active Directory';
                    cse.Closed_Case_Reason__c = 'Activation';


                    // cse.ProductFamilyQueue__c = 'ContactCenter';   // formual value: IF( (Queue__c = 'ContactCenter' || ISBLANK(Product_Family__c)) ,Queue__c,Product_Family__c + ' ' + Queue__c)
                    cse.New_Case_Notification_Sent__c = true; // 2018-11-11: suppress email notification


                    cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
                    pClosedSupportCases.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pClosedSupportCases);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Case c:pClosedSupportCases ){
                    ids.add(c.Id);
                }

                pClosedSupportCases = [select  Account_Type__c, AccountId, Alert__c, Alternate_Email__c, AssetId, Assigned_to_First_Queue__c,
                        Bug_Feature_Number__c, BusinessHoursId, Can_Access_Device__c, Case_Comment__c, Case_Re_Opened__c, CaseNumber,
                        Client__c, ClosedDate, Computer_ID__c, Computer_Name__c, Contact_Verified_Condition__c, ContactEmail, ContactFax, ContactId,
                        ContactMobile, ContactPhone, CreatedById, CreatedDate, CurrencyIsoCode, Description, Engineering_Escalation__c,
                        EntitlementId, Escalated_Date_Time__c, Escalated_End_Date_Time__c, File_or_Solution_Sent__c, Firmware_SW_version__c,
                        Fix_Version__c, Has_Enterprise_Asset__c, Hours_Since_Last_Modified__c, Id, In_Progress__c, Is_Asset_Verified__c,
                        Is_Contact_Verified__c, Is_Enterprise_Account__c, Is_MSP__c, Is_Premium_Support__c, IsClosed, IsClosedOnCreate,
                        IsDeleted, IsEscalated, IsStopped, JIRA_Status__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                        MilestoneStatus, New_Case_Notification_Sent__c, Occuring_NOW__c, Origin, Original_Assignee__c, OwnerId, ParentId, Priority,
                        ProductId, Queue_Counter__c, Reason, RecordTypeId, RecordType.Name, Region__c, Region_Theatre__c, Related_Account__c, Related_Account_Type__c,
                        Related_Contact__c, ProductFamilyQueue__c, Queue__c, Serial__c,
                        RMA_Comments__c, RMA_Number__c, SlaExitDate, SlaStartDate, SourceId, Status, StopStartDate, Sub_Region_Theatre__c,
                        Subject, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, SystemModstamp, Type, Username__c,
                        Web_Existing_Case__c, Web_First_Name__c, Web_Language_of_correspondence__c, Web_Last_Name__c, Web_Region__c, Web_Serial__c from Case
                        where id in: ids];
                system.debug('#### Support Cases ' + pClosedSupportCases);
            }

            return  pClosedSupportCases;
        }
    }

    private static List <Assigned_Serial__c> pAssignedSerials = null;
    public static List  <Assigned_Serial__c> assignedSerials {
        get {
            if (pAssignedSerials == null) {
                pAssignedSerials = new List <Assigned_Serial__c>();

                // to do : create SBQQ_Subscription...
                for (Asset a: assets){
                    Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
                    assignedSerial.Asset__c = a.id;
                    assignedSerial.Serial__c = a.BNCPQ_Serial__c;
                    assignedSerial.Status__c = 'Active';
                    pAssignedSerials.add(assignedSerial);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pAssignedSerials);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Assigned_Serial__c c:pAssignedSerials ){
                    ids.add(c.Id);
                }

                pAssignedSerials = [select Asset__c, Date_Of_Replacement__c, External_ID__c, Id, Name, Serial__c,
                        Serial_Number__c, Status__c, Subscription__c, Subscription_End_Date__c, Subscription_Name__c,
                        Subscription_Start_Date__c  from Assigned_Serial__c
                where id in: ids];
                system.debug('#### Assigned Serials ' + pAssignedSerials);

            }

            return pAssignedSerials;
        }
    }


    private static List <Serial__c> pSerials = null;
    public static List <Serial__c> serials {

        get {
            if (pSerials == null) {
                pSerials = new List <Serial__c>();
            }

            Serial__c serial = new Serial__c();
            serial.Activation_Date__c = Date.today();
            serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
            serial.Status__c = 'Active';
            pSerials.add(serial);

            if(Test.isRunningTest() || TestDataFactory.createRealData) {
                DML.save(pSerials);
            }

            return pSerials;
        }

    }


    private static List <Case> pWebCases = null;
    public static List <Case> webCases {
        get {
            if (pWebCases == null){
                pWebCases = new List <Case>();

                for (Contact c: customerContacts) {
                    Case cse = new Case();
                    // for (Asset a: assets) {
                    //    cse.Assetid = a.Id;
                    // }
                    // cse.Accountid = c.AccountId;
                    // cse.Contactid = c.Id;
                    cse.Description = 'Web Case ' + suffixNumber;
                    cse.Status = 'New';
                    cse.Web_First_Name__c = c.FirstName;
                    cse.Web_Last_Name__c = c.LastName;
                    cse.SuppliedEmail = c.Email;
                    cse.Subject = 'Unit Test' + suffixNumber;
                    cse.Origin = 'Web';
                    cse.Web_Language_of_correspondence__c = 'English';
                    cse.Web_Region__c = 'Americas';
                    //10/28/2019 Adding Product Family due to the addition of a new validation rule
                    cse.Product_Family_List__c = 'Backup Server/Service';
                    // cse.ProductFamilyQueue__c = 'ContactCenter';   // formual value: IF( (Queue__c = 'ContactCenter' || ISBLANK(Product_Family__c)) ,Queue__c,Product_Family__c + ' ' + Queue__c)
                    cse.New_Case_Notification_Sent__c = true; // 2018-11-11: suppress email notification
                    cse.Web_Serial__c = serials[0].Serial_Number__c;
                    cse.LiveChatTranscript_External_Id__c = String.valueOf(Math.random());

                    // For (Case sc : supportCases){
                    //     cse.Web_Existing_Case__c = sc.CaseNumber;
                    // }

                    cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
                    pWebCases.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pWebCases);
                    DML.evaluateResult(results);
                }


                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Case c:pWebCases ){
                    ids.add(c.Id);
                }

                pWebCases = [select  Account_Type__c, AccountId, Alert__c, Alternate_Email__c, AssetId, Assigned_to_First_Queue__c,
                        Bug_Feature_Number__c, BusinessHoursId, Can_Access_Device__c, Case_Comment__c, Case_Re_Opened__c, CaseNumber,
                        Client__c, ClosedDate, Computer_ID__c, Computer_Name__c, Contact_Verified_Condition__c, ContactEmail, ContactFax, ContactId,
                        ContactMobile, ContactPhone, CreatedById, CreatedDate, CurrencyIsoCode, Description, Engineering_Escalation__c,
                        EntitlementId, Escalated_Date_Time__c, Escalated_End_Date_Time__c, File_or_Solution_Sent__c, Firmware_SW_version__c,
                        Fix_Version__c, Has_Enterprise_Asset__c, Hours_Since_Last_Modified__c, Id, In_Progress__c, Is_Asset_Verified__c,
                        Is_Contact_Verified__c, Is_Enterprise_Account__c, Is_MSP__c, Is_Premium_Support__c, IsClosed, IsClosedOnCreate,
                        IsDeleted, IsEscalated, IsStopped, JIRA_Status__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                        MilestoneStatus, New_Case_Notification_Sent__c, Occuring_NOW__c, Origin, Original_Assignee__c, OwnerId, ParentId, Priority,
                        ProductId, Queue_Counter__c, Reason, RecordTypeId, Region__c, Region_Theatre__c, Related_Account__c, Related_Account_Type__c,
                        Related_Contact__c, ProductFamilyQueue__c, Queue__c,
                        RMA_Comments__c, RMA_Number__c, SlaExitDate, SlaStartDate, SourceId, Status, StopStartDate, Sub_Region_Theatre__c,
                        Subject, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, SystemModstamp, Type, Username__c,
                        Web_Existing_Case__c, Web_First_Name__c, Web_Language_of_correspondence__c, Web_Last_Name__c, Web_Region__c, Web_Serial__c,
                        LiveChatTranscript_External_Id__c from Case
                where id in: ids];
                system.debug('#### web Cases ' + pWebCases);
            }

            return  pWebCases;
        }
    }


    private static List <Compliance_Log__c> pComplianceLogs = null;
    public static List <Compliance_Log__c> complianceLogs {
        get {
            if (pComplianceLogs == null){
                pComplianceLogs = new List <Compliance_Log__c>();

                for (Contact c: customerContacts) {
                    Compliance_Log__c cse = new Compliance_Log__c();
                    cse.Contact__c = c.Id;
                    cse.Event__c = 'Contact Update';
                    cse.Number_Of_Hits__c = 1;
                    cse.Record_ID__c = c.Id;
                    cse.Log_Account__c = c.AccountId;
                    cse.Request__c = '{ "recordId": "003f200002RKGX7AAP", "parentId": "001f200001aNVb7AAG", "dplCheckInfo": { "name": "Leanne Tomlin (Sample)", "maxReturnHits": null, "address": { "street": "10 Main Rd.",  "state": "New York", "country": "US", "city": "New York" } } }';
                    cse.Result__c = '';

                    pComplianceLogs.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pComplianceLogs);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Compliance_Log__c c:pComplianceLogs ){
                    ids.add(c.Id);
                }

                pComplianceLogs = [ select Address__c, Contact__c, CreatedById, CreatedDate, CurrencyIsoCode, Event__c, Id, IsDeleted, LastActivityDate, LastModifiedById, LastModifiedDate, Log_Account__c, Max_Hits_Surpassed__c, Name, Number_Of_Hits__c, Record_ID__c, Request__c, Result__c, SystemModstamp, Transaction_Ref__c from Compliance_Log__c
                where id in: ids];
                system.debug('#### offline Compliance_Log__cs ' + pComplianceLogs);
            }

            return  pComplianceLogs;
        }
    }

    private static List <Case> pOfflineCases = null;
    public static List <Case> offlineCases {
        get {
            if (pOfflineCases == null){
                pOfflineCases = new List <Case>();

                for (Contact c: customerContacts) {
                    Case cse = new Case();
                    // for (Asset a: assets) {
                    //    cse.Assetid = a.Id;
                    // }
                    // cse.Accountid = c.AccountId;
                    // cse.Contactid = c.Id;
                    cse.Description = 'Web Case ' + suffixNumber;
                    cse.Status = 'New';
                    cse.Web_First_Name__c = c.FirstName;
                    cse.Web_Last_Name__c = c.LastName;
                    cse.SuppliedEmail = c.Email;
                    cse.Subject = 'Unit Test' + suffixNumber;
                    cse.Origin = 'Web';
                    cse.Web_Language_of_correspondence__c = 'English';
                    cse.Web_Region__c = 'Americas';
                    cse.Offline_Support_Type__c = 'Sales'; // offline chat type 
                    // cse.ProductFamilyQueue__c = 'ContactCenter';   // formual value: IF( (Queue__c = 'ContactCenter' || ISBLANK(Product_Family__c)) ,Queue__c,Product_Family__c + ' ' + Queue__c)
                    cse.New_Case_Notification_Sent__c = true; // 2018-11-11: suppress email notification
                    cse.Web_Serial__c = serials[0].Serial_Number__c;

                    cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();
                    pOfflineCases.add(cse);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    List <Database.SaveResult> results = DML.save(pOfflineCases);
                    DML.evaluateResult(results);
                }

                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Case c:pOfflineCases ){
                    ids.add(c.Id);
                }

                pOfflineCases = [select  Account_Type__c, AccountId, Alert__c, Alternate_Email__c, AssetId, Assigned_to_First_Queue__c,
                        Bug_Feature_Number__c, BusinessHoursId, Can_Access_Device__c, Case_Comment__c, Case_Re_Opened__c, CaseNumber,
                        Client__c, ClosedDate, Computer_ID__c, Computer_Name__c, Contact_Verified_Condition__c, ContactEmail, ContactFax, ContactId,
                        ContactMobile, ContactPhone, CreatedById, CreatedDate, CurrencyIsoCode, Description, Engineering_Escalation__c,
                        EntitlementId, Escalated_Date_Time__c, Escalated_End_Date_Time__c, File_or_Solution_Sent__c, Firmware_SW_version__c,
                        Fix_Version__c, Has_Enterprise_Asset__c, Hours_Since_Last_Modified__c, Id, In_Progress__c, Is_Asset_Verified__c,
                        Is_Contact_Verified__c, Is_Enterprise_Account__c, Is_MSP__c, Is_Premium_Support__c, IsClosed, IsClosedOnCreate,
                        IsDeleted, IsEscalated, IsStopped, JIRA_Status__c, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate,
                        MilestoneStatus, New_Case_Notification_Sent__c, Occuring_NOW__c, Origin, Original_Assignee__c, OwnerId, ParentId, Priority,
                        ProductId, Queue_Counter__c, Reason, RecordTypeId, Region__c, Region_Theatre__c, Related_Account__c, Related_Account_Type__c,
                        Related_Contact__c, ProductFamilyQueue__c, Queue__c,Offline_Support_Type__c, Offline_Support_Company__c,
                        RMA_Comments__c, RMA_Number__c, SlaExitDate, SlaStartDate, SourceId, Status, StopStartDate, Sub_Region_Theatre__c,
                        Subject, SuppliedCompany, SuppliedEmail, SuppliedName, SuppliedPhone, SystemModstamp, Type, Username__c,
                        Web_Existing_Case__c, Web_First_Name__c, Web_Language_of_correspondence__c, Web_Last_Name__c, Web_Region__c, Web_Serial__c from Case
                where id in: ids];
                system.debug('#### offline Cases ' + pOfflineCases);
            }

            return  pOfflineCases;
        }
    }

    private static List<PricebookEntry> pPriceBookEntry = null;
    public static List<PricebookEntry> priceBookEntry {
        get {
             if (pPriceBookEntry == null) {
                pPriceBookEntry = new List<PricebookEntry>();

                Id stdPriceBookId = Test.isRunningTest() ? Test.getStandardPricebookId() : [Select id from Pricebook2 where isStandard = true limit 1].id;

                for (Product2 parentRec: products){
                    PricebookEntry rec = new PricebookEntry();
                    rec.Pricebook2Id = pricebookId; 
                    rec.Product2Id = parentRec.Id; 
                    rec.UnitPrice = 1; 
                    rec.IsActive = true; 
                    Boolean useStandardPrice = false; 
                    if (stdPriceBookId!=null){
                        if (stdPriceBookId == pricebookId){
                            useStandardPrice = true; 
                        }
                    }
                    rec.UseStandardPrice = false; // useStandardPrice; 
                    pPriceBookEntry.add(rec);
                }
                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pPriceBookEntry);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (PricebookEntry p:pPriceBookEntry ){
                    ids.add(p.Id);
                }
                pPriceBookEntry = [select CreatedById, CreatedDate, CurrencyIsoCode, ExtId__c, Id, IsActive, IsDeleted, LastModifiedById, 
                            LastModifiedDate, Name, Pricebook2Id, Product2Id, ProductCode, SystemModstamp, UnitPrice, 
                            UseStandardPrice from PricebookEntry
                        where id in: ids];
                
                system.debug('#### Pricebook Entry' + pPriceBookEntry);
            }
            return pPriceBookEntry;
        }
    }


    private static Map<String, Country__c> pCountries = null;
    public static Map<String, Country__c> countries{

        get {
            if (pCountries == null) {
                List <Country__c> countryList = new List <Country__c>();
                pCountries = new Map<String, Country__c>();

                Country__c country = new Country__c();
                country.Country_ISO__c = 'US';
                country.Name = 'United States';
                countryList.add(country);
                pCountries.put('US', country );


                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(countryList);
                }

                system.debug('#### Country Map: ' + pCountries);
            }
            return pCountries;
        }

    }

    private static Map<String, Map<String, State__c>> pStates = null;
    public static Map<String, Map<String, State__c>> states{

        get {
            if (pStates == null) {
                List <State__c> stateList = new List <State__c> ();
                pStates = new Map<String, Map<String, State__c>>();

                Map<String, State__c> stateMap = new Map<String, State__c>();
                Country__c country = countries.get('US');
                State__c state = new State__c();
                state.Country__c = country.Id;
                state.State_ISO__c = 'CA';
                state.Name = 'California';
                stateList.add(state);
                stateMap.put('CA', state);

                pStates.put('US', stateMap);


                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(stateList);
                }

                system.debug('####  State Map: ' + pStates);
            }
            return pStates;
        }

    }

    public static UserRole createRole(String DeveloperName, String roleName){

        UserRole r = new UserRole(DeveloperName = DeveloperName, Name = roleName);
        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(r);
        }
        return r;

    }

    public static User createUser(String profileName){

        String profile = (profileName == null || profileName == '')? 'System Administrator': profileName;
        UserRole r = createRole('test_role', 'Test Role' );

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = :profile].Id,
                LastName = 'last',
                Email = 'puser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
                Username = 'puser000@barracuda.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(r);
            u.UserRoleId = r.Id;
            DML.save(u);
        }

        return u;
    }

    public static QueueSObject createQueue (String sObjectName, String queueName){
        Group g = new Group(Type='Queue', Name=queueName);
        QueueSObject q = new QueueSObject(SobjectType=sObjectName);

        if(Test.isRunningTest() || TestDataFactory.createRealData) {
            DML.save(g);
            q.QueueId =g.Id;
            DML.save(q);
        }

        return q;
    }

    //Added as part of SFDC-8683
    private static List<Hot_List__c> pHotlists = null;
    public static List <Hot_List__c> hotlists {
        get {
            if (pHotlists == null){
                pHotlists = new List <Hot_List__c>();

                for (Contact c: customerContacts){
                    Hot_List__c hl = new Hot_List__c();
                    hl.Contact__c  = c.Id;
                    hl.Type__c = 'Deal Registration';
                    hl.Deal_Reg_Status__c = 'Pending';
                    pHotlists.add(hl);
                }

                if(Test.isRunningTest() || TestDataFactory.createRealData) {
                    DML.save(pHotlists);
                }
                
                // retrieve additional fields for troubleshooting and functional testing
                Set<Id> ids = new Set<Id>();
                for (Hot_List__c hl:pHotlists ){
                    ids.add(hl.Id);
                }
                pHotlists = [select A_Authority__c, Account__c, Activity_Subject__c, Activity_Type__c, Age_of_Record__c, Annual_Revenue__c, 
                             B_Budget__c, Budget__c, Business_Group__c, BVM_Scan_Completed__c, Case__c, Case_Number__c, City__c, Competing_Against__c, 
                             Competitor_or_Existing_Solution__c, Contact__c, Convert_to_Existing_Opportunity__c, Converted_Opportunity__c, Country_ISO_Code__c, 
                             CreatedById, CreatedDate, Credit_Card_Expiration__c, Credit_Card_Token__c, CurrencyIsoCode, DB_Auth_Account_Id__c, 
                             Deal_Justification__c, Deal_Reg_Email_Notifications__c, Deal_Reg_Email_Notifications_Formula__c, Deal_Reg_Exp_Date__c, 
                             Deal_Reg_Status__c, Deal_Reg_Tracking_No__c, Deal_Reg_Type__c, Deal_Registration_Denied_Comments__c, 
                             Deal_Registration_Manager_Approval__c, Deal_Registration_Number__c, Deal_Registration_Status__c, Deal_Registration_Status_Date__c, 
                             Disposition__c, Distributor__c, Distributor_Partner_Number__c, DMR_Email__c, DMR_Phone__c, DMR_Rep__c, Employee_Count_Rep_Entered__c, 
                             Employee_Count_User_Entered__c, Employee_Range_Customer_Provided__c, Employee_Range_Lead_Contact__c, Employee_Range_User_Entered__c, 
                             Employees_Formula__c, ETS_ID__c, ETS_Scan_Completed__c, Expected_Close_Date__c, Expiration_c__c, Found_Us__c, GS_Company__c, 
                             GS_Email__c, GS_Name__c, GS_Reseller__c, Hot_List_Link__c, Hot_List_Name__c, HTTP_Referrer__c, IBU_Username__c, Id, 
                             Implementation_Date__c, Industry__c, Is_Converted__c, IsDeleted, Justification__c, Last_4_of_CC__c, Last_Activity_Date__c, 
                             LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Lead__c, Lead_Contact_Company__c, 
                             Lead_Contact_Country__c, Lead_Contact_Email__c, Lead_Contact_Name__c, Lead_Contact_Phone__c, Lead_Contact_State_Province__c, 
                             Lead_Contact_Terr_Location__c, Lead_Contact_Terr_Region__c, Lead_Contact_Terr_Sub_Territory__c, Lead_Contact_Terr_Sub_Theater__c, 
                             Lead_Contact_Terr_Territory__c, Lead_Contact_Terr_Theater__c, Lead_Contact_Zip_Postal_Code__c, Lead_Source__c, License_Key__c, 
                             Linking_Code__c, Live_Chat_Transcript__c, LiveChatTranscript_External_Id__c, Model_Series__c, Most_Recent_Medium__c, 
                             Most_Recent_Medium_Detail__c, MQL_Detail__c, MQL_Reason__c, MREFURL__c, N_Need__c, Name, Next_Activity_Date__c, num_months__c, 
                             num_of_25Mbps_bandwidth__c, Object_Type__c, Opportunity_Status__c, Other_Notes__c, Other_Notes2__c, Owner_Indicator__c, Owner_Type__c, 
                             OwnerId, Partner__c, Partner_Level__c, Partner_Number__c, Partner_Type__c, Portal_Account_ID__c, Preferred_Deployment_Method__c, 
                             Primary_On_Lead__c, Primary_Product_Family__c, Primary_Product_Family_2__c, Product_Model_Name__c, Product_Type__c, Products__c, 
                             Promo_Code__c, Quantity__c, Queue_Alignment_Run__c, Reason_Comments__c, Record_Type__c, RecordTypeId, Request_Type__c, Reseller__c, 
                             Reseller_Contact__c, Reseller_Contact_Email__c, Reseller_Contact_Phone__c, Reseller_Contact_Text__c, Reseller_Text__c, 
                             Return_Unqualified_Reason__c, Running_User__c, Serial_Number__c, Session_ID__c, SKUs__c, Source_IP__c, Status__c, Sub_Territory__c, 
                             SystemModstamp, T_Timeline__c, TEMP_Lead_ID__c, Type__c, Unlock_Flag__c, Usr_Ent_City__c, Usr_Ent_Company__c, Usr_Ent_Country__c, 
                             Usr_Ent_Currency__c, Usr_Ent_Email__c, Usr_Ent_First_Name__c, Usr_Ent_Industry__c, Usr_Ent_Last_Name__c, Usr_Ent_Phone__c, 
                             Usr_Ent_State__c, Usr_Ent_Street__c, Usr_Ent_ZipCode__c, VAT_Number__c, Web_PID__c, Website__c, Website_Visitor_ID__c 
                             from Hot_List__c
                             where id in: ids];
                        
                system.debug('#### Hotlists' + pHotlists);
            }

            return pHotlists;
        }
    }

}