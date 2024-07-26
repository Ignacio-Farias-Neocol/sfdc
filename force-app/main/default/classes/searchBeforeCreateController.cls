public class searchBeforeCreateController {

    @AuraEnabled(cacheable=true)
    public static String  getCountryList(){

        Map<String,String> mapofCountryNameValue=new Map<String,String>();
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        // System.debug('Picklist::'+ple);
        System.debug(' User.Countrycode.getDescribe() List<Schema.PicklistEntry> ple = '+ple);
        for( Schema.PicklistEntry f : ple){
        System.debug(f.getLabel() +'::'+ f.getValue());

        mapofCountryNameValue.put(f.getLabel(),f.getValue());
        }

        return JSON.serialize(mapofCountryNameValue);

    }

    @AuraEnabled(cacheable=true)
    public static List<Account> findAccountByName(string accString){

        try{
            System.debug('searchBeforeCreateController::'+ accString);
            Map<String,Object> accRecordMap =
                (Map<String,Object>)JSON.deserializeUntyped(accString);

                System.debug('findAccountByName::'+ accRecordMap);

            Account accRecord=new Account(); // New Instance because Lead and Accounts Field API names differ
            accRecord.Name= String.valueOf(accRecordMap.get('Name')) == null? String.valueOf(accRecordMap.get('Company')) : String.valueOf(accRecordMap.get('Name'));
            accRecord.Website=String.valueOf(accRecordMap.get('Website'));
            accRecord.D_B_DUNS_Number__c =String.valueOf(accRecordMap.get('D_B_DUNS_Number__c'));
          //accRecord.BillingCountry=String.valueOf(accRecordMap.get('Country')) == null? String.valueOf(accRecordMap.get('BillingCountry')) : String.valueOf(accRecordMap.get('Country')) ;
            accRecord.BillingCountryCode=String.valueOf(accRecordMap.get('CountryCode')) == null? String.valueOf(accRecordMap.get('Country')) : String.valueOf(accRecordMap.get('CountryCode')) ;

            List<Account> accountService = AccountService.findAccountByName(accRecord);
            return AccountService;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> findAccountSBCByName(string accString){

        try{
            System.debug('searchBeforeCreateController::'+ accString);
            Map<String,Object> accRecordMap =
                (Map<String,Object>)JSON.deserializeUntyped(accString);

                System.debug('findAccountSBCByName::'+ accRecordMap);

            Account accRecord=new Account(); // New Instance because Lead and Accounts Field API names differ
            accRecord.Name= String.valueOf(accRecordMap.get('Name')) == null? String.valueOf(accRecordMap.get('Company')) : String.valueOf(accRecordMap.get('Name'));
            accRecord.Website=String.valueOf(accRecordMap.get('Website'));
            accRecord.D_B_DUNS_Number__c =String.valueOf(accRecordMap.get('D_B_DUNS_Number__c'));
            accRecord.BillingCountryCode=String.valueOf(accRecordMap.get('BillingCountryCode')) != null? String.valueOf(accRecordMap.get('BillingCountryCode')) : String.valueOf(accRecordMap.get('BillingCountryCode')) ;

            List<Account> accountService = AccountService.findAccountByName(accRecord);
            return AccountService;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    // Contacts Results
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByEmail (string emailString){

        try{
            System.debug('getContactsByEmail::'+ emailString); // To Be Removed

            List<Contact> contactService = ContactService.getContactsByEmail(emailString);
            return contactService;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Contacts Results

    //For Opportunity Result Page
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(String accountId) {
        try{
            List<Opportunity> listOfOpportunity = OpportunityService.getOpportunitysByAccount(accountId);
            return listOfOpportunity;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //For Opportunity Result Page
    //For Confirmation Page
    @AuraEnabled(cacheable=false)
    public static String convertLead(String leadId,String account,String originalAccount, String contact, String opportunity, String donotCreateOpp) {
        System.debug('accountString::'+ account);
        System.debug('originalAccount::'+ originalAccount);
        System.debug('donotCreateOpp::'+ donotCreateOpp);
        Account acc = (Account) JSON.deserialize(account, Account.class);
        Account orginalAcc = originalAccount!=null ? (Account) JSON.deserialize(originalAccount, Account.class) : null;
        Contact con = (Contact) JSON.deserialize(contact, Contact.class);
        Opportunity opp = (opportunity != null) ? (Opportunity) JSON.deserialize(opportunity, Opportunity.class) : null;

        if(acc.BillingCountryCode == NULL && String.isNotBlank(acc.BillingCountry)) {
            acc.BillingCountryCode = getIsoCodeByCountryName(acc.BillingCountry);
        }

        if(acc.BillingStateCode == NULL && String.isNotBlank(acc.BillingState)) {
            acc.BillingStateCode = getIsoCodeByStateName(acc.BillingState);
            System.debug('acc.BillingState::' + acc.BillingState);
            System.debug('acc.BillingStateCode::' + acc.BillingStateCode);
        }

        if(acc.BillingState!= NULL && acc.BillingStateCode!=NULL) {
            acc.BillingState = NULL;
        }

        if (acc.D_B_DUNS_Number__c != null) {
            acc.DUNS_Number__c = acc.D_B_DUNS_Number__c;
        } else if (acc.DUNS_Number__c != null) {
            acc.D_B_DUNS_Number__c = acc.DUNS_Number__c;
        }

        try {
            System.debug('searchBeforeCreateController.convertLead::'+ acc);
            LeadService.ConversionResult leadConvertResult = LeadService.convertLead(leadId,acc,orginalAcc, con, opp,donotCreateOpp);
            return (leadConvertResult != null) ? JSON.serialize(leadConvertResult) : null;
        } catch(Exception ex) {
            // Log the exception as per your logging mechanism
            throw new AuraHandledException('Error converting lead: ' + ex.getMessage());
        }
    }
    //For Confirmation Page

    @AuraEnabled(cacheable=true)
    public static Account  getDnBDataBlocksInfo(string duns){

        try{

            System.debug('duns#::'+ duns); // To Be Removed

            DnbResult dbinfo = AccountService.getDnBDataBlocksInfo(duns);
            // String db = JSON.serialize(dbinfo,true);
            // System.debug('dbinfo:: ' + db);

            Account acc =new Account();
            acc.Industry=dbinfo.Industry;
            acc.NumberOfEmployees=dbinfo.NumberofEmployees;
            return acc;
            //return db;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getMatchResults(string accEnrichString){

        try{
            System.debug('accEnrichString::'+ accEnrichString); // To Be Removed
            Map<String,Object> accRecordMap =
                (Map<String,Object>)JSON.deserializeUntyped(accEnrichString);

            List<Account> enrichAccWrapList=new List<Account>();

            List<DnbResult> enrichmentService = AccountService.getMatchResults(accRecordMap);

            for(DnbResult dnb: enrichmentService){

                Account acc =new Account();

                acc.Name=dnb.Name;
                acc.Website=dnb.Website;
                acc.Description=dnb.corporateLinkage;
                acc.D_B_DUNS_Number__c=dnb.DUNS_Number;
                acc.DUNS_Number__c=dnb.DUNS_Number;
                acc.BillingCountry=dnb.BillingCountry;
                acc.BillingState=dnb.BillingState;
                acc.BillingStateCode = dnb.BillingStateCode;
                acc.BillingCity=dnb.BillingCity;
                acc.BillingPostalCode=dnb.BillingPostalCode;
                acc.BillingStreet=dnb.BillingStreet;
                acc.DNBConnect__D_B_Match_Confidence_Code__c=dnb.ConfidenceCode;

                enrichAccWrapList.add(acc);
            }

           return enrichAccWrapList;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String CreateAccount(String newAccountString, String originalAccString){
        String accId;
        Account newAcc = (Account)JSON.deserialize(newAccountString,Account.class);

        if (String.isBlank(newAcc.BillingCountryCode) && String.isNotBlank(newAcc.BillingCountry)) {
            newAcc.BillingCountryCode = getIsoCodeByCountryName(newAcc.BillingCountry);
        }
        System.debug('CreateAccount() newAcc = ' + newAcc);

        try {
            if (String.isNotBlank(originalAccString)) {
                Account originalAcc = (Account)JSON.deserialize(originalAccString,Account.class);
                if(originalAcc!=null){
                    /// cloning
                    Account clonedAccount=   AccountService.cloneAccount(originalAcc,newAcc);
                    System.debug('clonedAccountId::'+ clonedAccount.Id);
                    /// cloning
                    if(clonedAccount.Id!=null) {
                        newAcc = AccountService.reParentAccounts(clonedAccount,originalAcc);
                    }
                }
            // if (originalAcc.ParentId == null) {
            //     Account parentAcc = originalAcc.clone();
            //     Insert parentAcc;

            //     originalAcc.ParentId = parentAcc.Id;
            //     newAcc.ParentId = parentAcc.Id;

            //     Update originalAcc;
            // }
            // else {
            //     newAcc.ParentId = originalAcc.ParentId;
            // }
            }else if(newAcc != NULL && newAcc.Id == NULL) {
                insert newAcc;
            }

            //insert newAcc;
            return   newAcc.Id;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void activateSessionPermSet(){

        SessionPermSetActionHelper.newInstance('Access_to_Account_Exclude_from_Duplicate_Rules').activate();

    }

    @AuraEnabled
    public static void deactivateSessionPermSet(){

        SessionPermSetActionHelper.newInstance('Access_to_Account_Exclude_from_Duplicate_Rules').deactivate();
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordTypeId(String leadId){
        String recordTypeId;
		Lead olead = [SELECT RecordType.Name, Business_Group__c FROM Lead WHERE Id = :leadId LIMIT 1];
        System.debug('RecordTypeName::'+ olead.RecordType.Name);
        // Determine the RecordTypeId for the Account
        if(olead.RecordType.Name == 'Partner Application') {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        } else if(olead.Business_Group__c == 'MSP') {
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        }else if(olead.Business_Group__c == 'Sonian' || olead.Business_Group__c == 'Core' || olead.Business_Group__c == null){
            recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        }
		System.debug('RecordTypeId::'+ recordTypeId);

        return recordTypeId;

    }

    final static Map<String, String> COUNTRY_CODE_MAP {
        get {
            Map<String, String> countryCodeMap = new Map<String, String>();
            for(Schema.PicklistEntry countryPicklist : User.CountryCode.getDescribe().getPicklistValues()) {
                String name = countryPicklist.getLabel().toLowerCase();
                String code = countryPicklist.getValue();
                countryCodeMap.put(name, code);
            }
            return countryCodeMap;
        }
    }

    @TestVisible
    private static String getIsoCodeByCountryName(String countryName) {
        return (String.isNotBlank(countryName) ?
            COUNTRY_CODE_MAP.get(countryName.toLowerCase()) :
            null
        );
    }


    final static Map<String, String> STATE_CODE_MAP {
        get {
            Map<String, String> stateCodeMap = new Map<String, String>();
            for(Schema.PicklistEntry statePicklist :  User.statecode.getDescribe().getPicklistValues()) {
                String statename = statePicklist.getLabel().toLowerCase();
                String statecode = statePicklist.getValue();
                stateCodeMap.put(statename, statecode);
            }
            return stateCodeMap;
        }
    }

    @TestVisible
    public static String getIsoCodeByStateName(String stateName) {
        return (String.isNotBlank(stateName) ?
            STATE_CODE_MAP.get(stateName.toLowerCase()) :
            null
        );
    }



    // @AuraEnabled(cacheable=true)
    // public static List<String> getPicklistValues(String recordTypeId) {
    //     List<String> picklistValues = new List<String>();

    //     // Get the Account object's Type field
    //     Schema.DescribeFieldResult fieldResult = Account.Type.getDescribe();

    //     // Loop through and add picklist values
    //     for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
    //         if (entry.isActive()) {
    //             picklistValues.add(entry.getLabel());
    //         }
    //     }
    //     System.debug('picklistValues:: '+ picklistValues);
    //     return picklistValues;
    // }

    // @AuraEnabled(cacheable=true)
    // public static List<String> getPicklistValues(String recordTypeId) {
    //     List<String> picklistValues = new List<String>();

    //     // Describe the Account object
    //     Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();

    //     // Get the describe result of the 'Type' field
    //     Schema.DescribeFieldResult fieldResult = dsr.fields.getMap().get('Type').getDescribe();

    //     // Check if the field is a picklist
    //     if(fieldResult.getType() == Schema.DisplayType.PICKLIST) {
    //         // Get the picklist values
    //         List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

    //         // Iterate over the picklist values
    //         for(Schema.PicklistEntry pe : picklistEntries) {
    //             if(pe.isActive()) {
    //                 picklistValues.add(pe.getLabel());
    //             }
    //         }
    //     }

    //     return picklistValues;
    // }

}