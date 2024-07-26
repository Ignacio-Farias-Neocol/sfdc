/**
* Apex Controller for OpportunityAddressSelector Lighting component
*
* @Author Ivan Yeung
* @Date 2018/10/15
* @description
*       2019/02/10: internal error with action.setCallback. issue being latidue and longtidue field can't be serialized
*       https://salesforce.stackexchange.com/questions/189172/lightning-components-why-geolocation-fields-in-soql-lead-to-an-internal-server
*       remove from SOQL
*       refactor this controller to use AccountDTO and
*       OpportunityDTO to have better control of the serialization structure (instead of standard account and opportunity)
* @group Controller
*
*
*/
public with sharing class OpportunityAddressSelectorController {


    public class AddressOption {
        @AuraEnabled
        Public String optionName; // display in drop down
        @AuraEnabled
        Public string optionType; // expected: account, billTo, shipTo
    }

    // opportunity associated with the opportunity record in context
    private  Id opptyId = null; // set whenever the first call is made

    @AuraEnabled
    public static OpportunityAddressSelectorController getClass(Id recordId){

        system.debug('~~~~ Init Started for Id= ' + recordId);

        //create class instance
        OpportunityAddressSelectorController obj = new OpportunityAddressSelectorController();
        obj.opptyId = recordId;
        system.debug('obj val'+obj.oppty);
        // populate all properties before the class is serialized back to lightning
        OpportunityDTO o = obj.oppty;
        AccountDTO acc = obj.opptyAccount;
        AccountDTO distributor = obj.opptyDistributor;
        AccountDTO reseller = obj.opptyReseller;

        List<AddressOption> bOptions = obj.billToOptions;
        List <Address__c> bAccAddresses = obj.opptyAccountAddressesBT;
        List <Address__c> bDisAddresses = obj.opptyDistributorAddressesBT;
        List <Address__c> bRsAddresses = obj.opptyResellerAddressesBT;

        List<AddressOption> sOptions = obj.shipToOptions;
        List <Address__c> sAccAddresses = obj.opptyAccountAddressesST;
        List <Address__c> sDisAddresses = obj.opptyDistributorAddressesST;
        List <Address__c> sRsAddresses = obj.opptyResellerAddressesST;

        List<Account> billToAccount = obj.opptyBillToAccount;
        List<Account> shipToAccount = obj.opptyShipToAccount;
        Boolean billShipEditable = obj.billShipEditable;

        system.debug('~~~~ Init Completed for Id= ' + recordId);
        system.debug('obj val2'+obj.opptyBillToAccount);
        system.debug('obj val2'+obj.opptyShipToAccount);
        system.debug('obj val2'+obj.billShipEditable);
        // return class instance
        return obj ;
    }


    /*******************************************************************************************************
    * @description
    *
    *   operation
    *
    * @param
    *
    *           recordId: opportuity ID
                operation: "update", "createUpdate"
                accountType: "account", "distributor", "distributor"
                addressType: billTo, "shipTo"
                addressObj: theAddress Address__c structure in JSON
    *
    * @return list of Sobject
    */
    @AuraEnabled
    public static OpportunityAddressSelectorController createUpdateAddress(Id recordId, String operation, String accountType,  String addressType, String addressObj ){


        //create class instance
        OpportunityAddressSelectorController obj = new OpportunityAddressSelectorController();

        system.debug('~~~~ record Id= ' + recordId);
        system.debug('~~~~ operation = ' + operation);
        system.debug('~~~~ accountType = ' + accountType);
        system.debug('~~~~ addressJSON = ' + addressObj);

        Address__c newAddress;

        try {
            newAddress = (Address__c) JSON.deserialize(addressObj, Address__c.class);
        }    catch (Exception ex) {
            system.debug('~~~~ Exception : ' + ex);
        }
        system.debug('~~~~ addressObj = ' + newAddress);

        obj.opptyId = recordId;

        // populate all properties before the class is serialized back to lightning
        OpportunityDTO o = obj.oppty;
        AccountDTO acc = obj.opptyAccount;
        AccountDTO distributor = obj.opptyDistributor;
        AccountDTO reseller = obj.opptyReseller;

        // create new address
        if (operation == 'createUpdate') {

            Id targetId;
            if(accountType == 'distributor' && distributor != null){
                targetId = distributor.Id;
            } else if (accountType == 'reseller' && reseller != null){
                targetId = reseller.Id;
            } else if (accountType == 'account' && acc != null) {
                targetId = acc.Id;
            }
            String addrTypeLabel;
            if (addressType == 'shipTo'){
                addrTypeLabel = 'Shipping';
            } else if (addressType == 'billTo'){
                addrTypeLabel = 'Billing';
            }
            if (targetId != null && addrTypeLabel != null){
                newAddress.Account__c = targetId;
                newAddress.Type__c = addrTypeLabel;
                DML.save(newAddress);

                // refresh new address with link
                // to do: get al the info from lighnting component
                if (newAddress.Id != null){
                    List <Address__c> addrList = [select Account__c, Account_External_ID__c, City__c, Country_ISO__c, Country__c, Country__r.Name,  Id,  Name, Primary__c, State__c, State__r.Name, Street__c, Type__c, Zip_Postal_Code__c from Address__c where  (Status__c != 'Inactive' and Status__c != 'Banned' and Status__c != 'Suspect') and Id = : newAddress.Id];
                    if (addrList.size() > 0 ){
                        newAddress = addrList[0];
                    }
                }

            }
            System.debug('~~~~ New Address Inserted' + newAddress );
        }

        // udpate opportunity address
        if (operation == 'update' || operation == 'createUpdate' ) {
            // update address
            if (addressType == 'billTo' && newAddress != null) {
                o.Billing_Address = newAddress.Id;
                o.Street = newAddress.Street__c;
                o.City = newAddress.City__c;
                o.Country = newAddress.Country__r.Name;
                o.Country_ISO_Code = newAddress.Country_ISO__c;
                o.Zip_Postal_Code = newAddress.Zip_Postal_Code__c;
                o.State = newAddress.State__r.Name;
                DML.save(o.toOpportunity());
                // reset opportunity
                obj.pOppty = o;
            } else if (addressType == 'shipTo' && newAddress != null) {
                o.Shipping_Address = newAddress.Id;
                o.Ship_To_Street = newAddress.Street__c;
                o.Ship_To_City = newAddress.City__c;
                o.Ship_To_Country = newAddress.Country__r.Name;
                o.Shipping_Country_ISO_Code = newAddress.Country_ISO__c;
                o.Ship_To_Zip_Postal_Code = newAddress.Zip_Postal_Code__c;
                o.Ship_To_State = newAddress.State__r.Name;

                DML.save(o.toOpportunity());
                // reset opportunity
                obj.pOppty = o;
            }
        }


        List<AddressOption> bOptions = obj.billToOptions;
        List <Address__c> bAccAddresses = obj.opptyAccountAddressesBT;
        List <Address__c> bDisAddresses = obj.opptyDistributorAddressesBT;
        List <Address__c> bRsAddresses = obj.opptyResellerAddressesBT;

        List<AddressOption> sOptions = obj.shipToOptions;
        List <Address__c> sAccAddresses = obj.opptyAccountAddressesST;
        List <Address__c> sDisAddresses = obj.opptyDistributorAddressesST;
        List <Address__c> sRsAddresses = obj.opptyResellerAddressesST;

        system.debug('~~~~ Init Completed for Id= ' + recordId);


        // return class instance
        return obj ;
    }

    // address country and state list
    @AuraEnabled public  Map<Id, Country__c>  countryMap = AddressModel.countryMap;
    @AuraEnabled public  Map<Id , Map <Id, State__c>>   countryStateMap = AddressModel.countryStateMap;


    public class OpportunityDTO {

        @AuraEnabled Public String Id;
        @AuraEnabled Public String Name;
        @AuraEnabled Public String AccountId;
        @AuraEnabled Public String DistributorId;
        @AuraEnabled Public String ResellerId;


        @AuraEnabled Public string Billing_Address;
        @AuraEnabled Public string Street;
        @AuraEnabled Public string City;
        @AuraEnabled Public string Country;
        @AuraEnabled Public string Country_ISO_Code;
        @AuraEnabled Public string State;
        @AuraEnabled Public string Zip_Postal_Code;

        @AuraEnabled Public string Shipping_Address;
        @AuraEnabled Public string Ship_To_Street;
        @AuraEnabled Public string Ship_To_City;
        @AuraEnabled Public string Ship_To_Country;
        @AuraEnabled Public string Shipping_Country_ISO_Code;
        @AuraEnabled Public string Ship_To_State;
        @AuraEnabled Public string Ship_To_Zip_Postal_Code;

        public Opportunity toOpportunity (){
            Opportunity o = new Opportunity();
            o.Id = Id;
            o.Name = Name;
            o.AccountId = AccountId;
            o.Distributor__c = DistributorId;
            o.Reseller__c = ResellerId;

            o.Billing_Address__c = Billing_Address;
            o.Street__c = Street;
            o.City__c = City;
            o.Country__c = Country;
            o.Country_ISO_Code__c = Country_ISO_Code;
            o.State__c = State;
            o.Zip_Postal_Code__c = Zip_Postal_Code;

            o.Shipping_Address__c = Shipping_Address;
            o.Ship_To_Street__c = Ship_To_Street;
            o.Ship_To_City__c = Ship_To_City;
            o.Ship_To_Country__c = Ship_To_Country;
            o.Shipping_Country_ISO_Code__c = Shipping_Country_ISO_Code;
            o.Ship_To_State__c = Ship_To_State;
            o.Ship_To_Zip_Postal_Code__c = Ship_To_Zip_Postal_Code;
            return o;
        }

    }


    private  OpportunityDTO pOppty = null;
    @AuraEnabled public OpportunityDTO oppty{
        get {
            if (pOppty == null && opptyId != null) {
                for (Opportunity o: [select Shipping_Address__c, Billing_Address__c, AccountId,  Business_Group__c,
                        City__c, CloseDate,  Converted_Lead_Id__c, Country__c, Country_ISO_Code__c, CurrencyIsoCode, Distributor__c,
                        Distributor_Contact__c,  Id, IsClosed, IsDeleted,
                        IsExcludedFromTerritory2Filter, IsPrivate, IsWon, Name,
                        Opportunity_Type__c,  OwnerId, PartnerAccountId, Pricebook2Id,
                        Primary_Contact__c, RecordTypeId, Reseller__c, Reseller_Contact__c, Ship_To_City__c, Ship_To_Country__c, Shipping_Country_ISO_Code__c,
                        Ship_To_State__c, Ship_To_Street__c, Ship_To_Zip_Postal_Code__c, StageName,
                        State__c, Street__c,  Territory2Id, TotalOpportunityQuantity,
                        Type, Zip_Postal_Code__c from Opportunity where id = :opptyId limit 1 ]){
                    pOppty = new OpportunityDTO();
                    pOppty.Id = o.Id;
                    pOppty.Name = o.Name;
                    pOppty.AccountId = o.AccountId;
                    pOppty.DistributorId = o.Distributor__c;
                    pOppty.ResellerId = o.Reseller__c;

                    pOppty.Billing_Address = o.Billing_Address__c;
                    pOppty.Street = o.Street__c;
                    pOppty.City = o.City__c;
                    pOppty.Country = o.Country__c;
                    pOppty.Country_ISO_Code = o.Country_ISO_Code__c;
                    pOppty.State = o.State__c;
                    pOppty.Zip_Postal_Code = o.Zip_Postal_Code__c;

                    pOppty.Shipping_Address = o.Shipping_Address__c;
                    pOppty.Ship_To_Street = o.Ship_To_Street__c;
                    pOppty.Ship_To_City = o.Ship_To_City__c;
                    pOppty.Ship_To_Country = o.Ship_To_Country__c;
                    pOppty.Shipping_Country_ISO_Code = o.Shipping_Country_ISO_Code__c;
                    pOppty.Ship_To_State = o.Ship_To_State__c;
                    pOppty.Ship_To_Zip_Postal_Code = o.Ship_To_Zip_Postal_Code__c;
                }

                system.debug('~~~~ Opportunity:  ' + pOppty);
            }
            return pOppty;
        }
    }


    public class AccountDTO {

        @AuraEnabled Public String Id;
        @AuraEnabled Public String Name;

    }

    // account associated with the opportunity record in context. typically this is the customer account
    private  AccountDTO pOpptyAccount = null;
    @AuraEnabled public  AccountDTO opptyAccount{

        get {
            if (pOpptyAccount == null && oppty != null && oppty.AccountId != null) {

                /*
                pOpptyAccount = [select AccountNumber, BillingAddress, Business_Group__c,
                        Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry,
                        IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Master_Agreement_Number__c,
                        Name, Named_Account__c, NumberOfEmployees, OwnerId,  ParentId, Partner_Birthdate__c,
                        Partner_Level__c, Partner_Number__c, Phone,
                        RecordTypeId, Ship_To_Email__c, ShippingAddress, Sic, SicDesc, Status__c, Type,
                        Website
                        from Account where Id = :oppty.AccountId limit 1 ];
                        */
                /*
                pOpptyAccount = [select AccountNumber, BillingAddress, Business_Group__c,
                         Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry,
                        IsCustomerPortal,  IsPartner,
                        Name,  NumberOfEmployees,  ParentId, Partner_Level__c, Partner_Number__c, Phone,
                        RecordTypeId, Ship_To_Email__c, ShippingAddress, Sic, SicDesc, Status__c, Type
                from Account where Id = :oppty.AccountId limit 1 ]; */
                for (Account a:[select Name , Id from Account where Id = :oppty.AccountId limit 1 ] ){
                    pOpptyAccount = new AccountDTO();
                    pOpptyAccount.Id = a.Id;
                    pOpptyAccount.Name = a.Name;
                }

                system.debug('~~~~ Opportunity Account:  ' + pOpptyAccount);
            }
            return pOpptyAccount;
        }
    }


    // distributor associated with the opportunity record in context.
    private  AccountDTO pOpptyDistributor = null;
    @AuraEnabled public  AccountDTO opptyDistributor{

        get {
            if (pOpptyDistributor == null && oppty != null && oppty.DistributorId != null) {

                /*
                pOpptyDistributor = [select AccountNumber, BillingAddress, Business_Group__c,   Escalated_to_Engineering__c, Fax, Global_Account__c, Global_Account_Indicator__c, Id, Industry, IsCustomerPortal, IsDeleted, IsExcludedFromRealign, IsPartner, Master_Agreement_Number__c, Name, Named_Account__c, NumberOfEmployees, OwnerId,  ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone,
                        RecordTypeId, Ship_To_Email__c, ShippingAddress, Sic, SicDesc, Status__c, Type, Website
                from Account where Id = :oppty.DistributorId limit 1 ];
                */
                For (Account a: [select Id, Name from Account where Id = :oppty.DistributorId limit 1 ]){
                    pOpptyDistributor = new AccountDTO();
                    pOpptyDistributor.Id = a.Id;
                    pOpptyDistributor.Name = a.Name;
                }


                system.debug('~~~~ Opportunity Distributor:  ' + pOpptyDistributor);
            }
            return pOpptyDistributor;
        }
    }

    // distributor associated with the opportunity record in context.
    private  AccountDTO pOpptyReseller = null;
    @AuraEnabled public  AccountDTO opptyReseller{

        get {
            if (pOpptyReseller == null && oppty != null && oppty.ResellerId != null) {

                /*
                pOpptyReseller = [select AccountNumber, BillingAddress, Business_Group__c,  Escalated_to_Engineering__c, Fax,
                        Global_Account__c, Global_Account_Indicator__c, Id, Industry, IsCustomerPortal, IsDeleted, IsExcludedFromRealign,
                        IsPartner, Master_Agreement_Number__c,
                        Name, Named_Account__c, NumberOfEmployees, OwnerId,  ParentId, Partner_Birthdate__c, Partner_Level__c, Partner_Number__c, Phone,
                        RecordTypeId, Ship_To_Email__c, ShippingAddress, Sic, SicDesc, Status__c, Type, Website
                from Account where Id = :oppty.ResellerId limit 1 ];
                */
                for (Account a: [select Id, Name
                from Account where Id = :oppty.ResellerId limit 1 ] ) {
                    pOpptyReseller = new AccountDTO();
                    pOpptyReseller.Id = a.Id;
                    pOpptyReseller.Name = a.Name;
                }
                system.debug('~~~~ Opportunity Reseller:  ' + pOpptyReseller);
            }
            return pOpptyReseller;
        }
    }

    private List<Address__c> pOpptyResellerAddressesBT = null;
    @AuraEnabled public  List<Address__c> opptyResellerAddressesBT {
        get {
            if (pOpptyResellerAddressesBT == null ){
                retrieveAssociatedAddresses();
            }
            return pOpptyResellerAddressesBT;
        }
    }
    private  List<Address__c> pOpptyDistributorAddressesBT = null;
    @AuraEnabled public  List<Address__c> opptyDistributorAddressesBT {
        get {
            if (pOpptyDistributorAddressesBT == null){
                retrieveAssociatedAddresses();
            }
            return pOpptyDistributorAddressesBT;
        }
    }
    private  List<Address__c> pOpptyAccountAddressesBT = null;
    @AuraEnabled public  List<Address__c> opptyAccountAddressesBT {
        get {
            if (pOpptyAccountAddressesBT == null){
                retrieveAssociatedAddresses();
            }
            return pOpptyAccountAddressesBT;
        }
    }

    private List<Address__c> pOpptyResellerAddressesST = null;
    @AuraEnabled public  List<Address__c> opptyResellerAddressesST {
        get {
            if (pOpptyResellerAddressesST == null ){
                retrieveAssociatedAddresses();
            }
            return pOpptyResellerAddressesST;
        }
    }
    private  List<Address__c> pOpptyDistributorAddressesST = null;
    @AuraEnabled public  List<Address__c> opptyDistributorAddressesST {
        get {
            if (pOpptyDistributorAddressesST == null){
                retrieveAssociatedAddresses();
            }
            return pOpptyDistributorAddressesST;
        }
    }
    private  List<Address__c> pOpptyAccountAddressesST = null;
    @AuraEnabled public  List<Address__c> opptyAccountAddressesST {
        get {
            if (pOpptyAccountAddressesST == null){
                retrieveAssociatedAddresses();
            }
            return pOpptyAccountAddressesST;
        }
    }

private  List<Account> pOpptyBillToAccount = null;
    @AuraEnabled public  List<Account> opptyBillToAccount {
        get {
            String billToAccountId = [Select Bill_To_Account__c FROM Opportunity WHERE Id =: opptyId LIMIT 1].Bill_To_Account__c;
            pOpptyBillToAccount = [Select Bill_To_Email__c,Bill_To_Contact__c FROM Account WHERE Id =: billToAccountId];
            return pOpptyBillToAccount;
        }
    }
    
    private  List<Account> pOpptyShipToAccount = null;
    @AuraEnabled public  List<Account> opptyShipToAccount {
        get {
            String shipToAccountId = [Select Ship_To_Account__c FROM Opportunity WHERE Id =: opptyId LIMIT 1].Ship_To_Account__c;
            pOpptyShipToAccount = [Select Ship_To_Contact__c,Ship_To_Email__c FROM Account WHERE Id =: shipToAccountId];
            return pOpptyShipToAccount;
        }
    }
    
    private  Boolean pOpptyShipEditable = null;
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
    }

    
    /*******************************************************************************************************
    * @description  populate the address array for the
    *
    * @param  void
    * @return void
    */
    private void retrieveAssociatedAddresses(){

        pOpptyAccountAddressesBT = new List<Address__c>();
        pOpptyResellerAddressesBT = new List<Address__c>();
        pOpptyDistributorAddressesBT = new List<Address__c>();
        pOpptyAccountAddressesST = new List<Address__c>();
        pOpptyResellerAddressesST = new List<Address__c>();
        pOpptyDistributorAddressesST = new List<Address__c>();


        Id acctId = opptyAccount != null ?  opptyAccount.Id: null;
        Id resellerId = opptyReseller != null ? opptyReseller.Id : null;
        Id distributorId = opptyDistributor != null ? opptyDistributor.Id : null;

        Set <Id> ids = new Set<Id>();
        if (acctId != null) { ids.add(acctId); }
        if (resellerId != null) { ids.add(resellerId); }
        if (distributorId != null) { ids.add(distributorId); }


        for (Address__c addr: [select Account__c, Account_External_ID__c, City__c, Country_ISO__c, Country__c, Country__r.Name,  Id,
                Name, Primary__c, State__c, State__r.Name, Street__c, Type__c,
                Zip_Postal_Code__c, Status__c from Address__c
        where (Status__c = 'Active' and Status__c != NULL) and Account__c in :ids ]){
            // same account can be reseller and distributor
            if (addr.Account__c == distributorId ){
                if (addr.Type__c == 'Billing' && addr.Primary__c == true ){
                    pOpptyDistributorAddressesBT.add(addr);
                }
                if (addr.Type__c == 'Shipping' || addr.Type__c == null){
                    pOpptyDistributorAddressesST.add(addr);
                }
            }
            if (addr.Account__c == resellerId ){
                if (addr.Type__c == 'Billing' && addr.Primary__c == true ){
                    pOpptyResellerAddressesBT.add(addr);
                }
                if (addr.Type__c == 'Shipping' || addr.Type__c == null){
                    pOpptyResellerAddressesST.add(addr);
                }
            }
            if (addr.Account__c == acctId ){
                if (addr.Type__c == 'Billing' && addr.Primary__c == true ){
                    pOpptyAccountAddressesBT.add(addr);
                }
                if (addr.Type__c == 'Shipping' || addr.Type__c == null){
                    pOpptyAccountAddressesST.add(addr);
                }
            }

        }

        System.debug('~~~~ account billing Addresss: ' + pOpptyAccountAddressesBT);
        System.debug('~~~~ account shipping Addresss: ' + pOpptyAccountAddressesST);
        System.debug('~~~~ reseller billing Addresss: ' + pOpptyResellerAddressesBT);
        System.debug('~~~~ reseller shipping Addresss: ' + pOpptyResellerAddressesST);
        System.debug('~~~~ distributor billing Addresss: ' + pOpptyDistributorAddressesBT);
        System.debug('~~~~ distributor shipping Addresss: ' + pOpptyDistributorAddressesST);
    }




    /*******************************************************************************************************
    * @description get the list of bill to Account options
    *
    * SFDC-167: The 'ShipToAddressType' value selection (Account / Distributor / Reseller)
    * will drive the Account to use when filtering the available list of Addresses to select from.
    *
    * @param  void
    * @return list of Sobject
    */
    private List<AddressOption> pShipToOptions = null;
    @AuraEnabled public  List<AddressOption> shipToOptions {

        get {

            if (pShipToOptions == null){

                pShipToOptions = new List <AddressOption>();
                if (oppty != null && opptyDistributor != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Distributor: ' + opptyDistributor.name  ;
                    option.optionType = 'distributor';
                    pShipToOptions.add(option);
                }
                if (oppty != null && opptyReseller != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Reseller: ' + opptyReseller.name;
                    option.optionType = 'reseller';
                    pShipToOptions.add(option);
                }
                if (oppty != null && opptyAccount != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Account: ' + opptyAccount.name;
                    option.optionType = 'account';
                    pShipToOptions.add(option);
                }
            }
            return pShipToOptions;
        }

    }


    /*******************************************************************************************************
    * @description get the list of bill to Account options
    *
    * SFDC-167: For Bill To address: If there's a distributor added to the opportunity then default the primary address based on the distributor account.
    * If there's a reseller added to the opportunity then default to the reseller account,
    * otherwise the primary business address is defaulted based on the standard account tied to the opportunity.
    *
    * @param  void 
    * @return list of Sobject
    */
    private List<AddressOption> pBillToOptions = null ;
    @AuraEnabled public  List<AddressOption> billToOptions {

        get {

            if (pBillToOptions == null){

                pBillToOptions = new List <AddressOption>();
                if (oppty != null && opptyDistributor != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Distributor: ' + opptyDistributor.name  ;
                    option.optionType = 'distributor';
                    pBillToOptions.add(option);
                } else if (oppty != null && opptyReseller != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Reseller: ' + opptyReseller.name;
                    option.optionType = 'reseller';
                    pBillToOptions.add(option);
                } else if (oppty != null && opptyAccount != null) {
                    AddressOption option = new AddressOption();
                    option.optionName = 'Account: ' + opptyAccount.name;
                    option.optionType = 'account';
                    pBillToOptions.add(option);
                }
            }
            return pBillToOptions;
        }

    }
    
    @AuraEnabled
    public static void UpdateBillDetails(List<Account> acctList){
        update acctList;
    }
    
    @AuraEnabled
    public static void UpdateShipDetails(List<Account> acctList){
        update acctList;
    }   
    

    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id accountId) {
        // Query Contacts related to the provided Account Id
        List<Contact> contacts = [
            SELECT Id, Name, Email, AccountId, Account.Name, Phone, MailingAddress, Contact_Type__c, MSP_End_Customer__c
            FROM Contact
            WHERE Contact_Status__c IN ('Active', 'Pending','Suspect')
            AND Id IN (
                SELECT ContactId
                FROM AccountContactRelation
                WHERE AccountId = :accountId
                AND IsActive = true
            )
            ORDER BY Contact_Status__c ASC
        ];
        return contacts;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasCustomPermission(){
        return !FeatureManagement.checkPermission('Update_Bill_to_Email');
    }
}