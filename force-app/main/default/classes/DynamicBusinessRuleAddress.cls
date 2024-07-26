/**
* @author Bhavesh Jha
* @date 2020-03-11
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface & call Address changes after insert/update.
*/
public class DynamicBusinessRuleAddress implements DynamicBusinessRuleAction{
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerOrder == 'POST') {
            if(triggerContext.contains('Insert') || triggerContext.contains('Update')){
                Set<Id> addressIds = new Set<Id>();
                Set<Id> accountIds = new Set<Id>();
                List<AddressWrapper> PrimayBillingAddressList = new List<AddressWrapper>();
                System.debug('::::::::::records::::::::::::'+JSON.serialize(records));
                for(Address__c newAddressObject: (List<Address__c>)records){
                    Address__c oldAddressObject = (Address__c) oldRecordMap.get(newAddressObject.Id);
                    System.debug('::::::::::newAddressObject.Primary__c::::::::::::'+newAddressObject.Primary__c);
                    if(newAddressObject.Business_Group__c=='MSP' && (newAddressObject.Type__c=='Billing' || newAddressObject.Type__c=='Shipping')){
                        if(triggerContext.contains('Insert') && newAddressObject.Primary__c){
                            addressIds.add(newAddressObject.Account__c);
                        }else if(triggerContext.contains('Update')){
                            if(newAddressObject.Primary__c){
                                if(newAddressObject.Primary__c!=oldAddressObject.Primary__c ||
                                  newAddressObject.Street__c != oldAddressObject.Street__c || 
                                  newAddressObject.City__c != oldAddressObject.City__c || 
                                  newAddressObject.State_ISO__c != oldAddressObject.State_ISO__c || 
                                  newAddressObject.Country_ISO__c != oldAddressObject.Country_ISO__c || 
                                  newAddressObject.Zip_Postal_Code__c != oldAddressObject.Zip_Postal_Code__c)
                                {
                                    addressIds.add(newAddressObject.Account__c);
                                } 
                            }
                        }
                    }
                    //SFDC-20024: Move primary Address flow in the apex class. Updating billing address on all open contract and opportunity
                    if(newAddressObject.IsAccountPrimaryBillingAddress__c && newAddressObject.Type__c=='Billing' && newAddressObject.Primary__c && newAddressObject.Account__c!=null){
                        if(triggerContext.contains('Insert')){
                            AddressWrapper aw = GetBillingAddressInfo(newAddressObject);
                            PrimayBillingAddressList.add(aw);
                            accountIds.add(newAddressObject.Account__c);
                        }
                        else if(triggerContext.contains('Update') && 
                        (newAddressObject.Primary__c!=oldAddressObject.Primary__c ||
                        newAddressObject.Type__c!=oldAddressObject.Type__c || 
                        newAddressObject.Account__c!=oldAddressObject.Account__c ||
                        newAddressObject.Street__c != oldAddressObject.Street__c || 
                        newAddressObject.City__c != oldAddressObject.City__c || 
                        newAddressObject.State_ISO__c != oldAddressObject.State_ISO__c || 
                        newAddressObject.Country_ISO__c != oldAddressObject.Country_ISO__c || 
                        newAddressObject.Zip_Postal_Code__c != oldAddressObject.Zip_Postal_Code__c)){
                            AddressWrapper aw = GetBillingAddressInfo(newAddressObject);
                            PrimayBillingAddressList.add(aw);
                            accountIds.add(newAddressObject.Account__c);
                        }
                    }//End of SFDC-20024
                }
                System.debug('::::::::::addressIds::::::::::::'+JSON.serialize(addressIds));
                
                if(!addressIds.isEmpty()){
                    string queryAllAccountFieldsForPayload = QueryUtil.getWholeFieldsQuery('Account','id in: addressIds','(Select id,Street__c,City__c,State_ISO__c,Country_Name__c,Country_ISO__c,Zip_Postal_Code__c, Primary__c, Type__c from Addresses__r where (Type__c = \'Billing\' OR Type__c = \'Shipping\') AND Primary__c = true)');
                    
                    System.debug('::::::::::queryAllAccountFieldsForPayload::::::::::::'+queryAllAccountFieldsForPayload);
                    
                    List<Account> accountListForPENotify = Database.query(queryAllAccountFieldsForPayload);
                    
                    System.debug('::::::::::accountListForPENotify::::::::::::'+JSON.serialize(accountListForPENotify));
                    
                    if(accountListForPENotify != null && !accountListForPENotify.isEmpty()){
                        if(triggerContext.contains('Insert')){
                            new PlatformEventHelper().publishObject('INSERT',accountListForPENotify);
                        }else if(triggerContext.contains('Update')){
                            new PlatformEventHelper().publishObject('UPDATE',accountListForPENotify);
                        }
                    }
                }
                //SFDC-20024: Move primary Address flow in the apex class. Updating billing address on all open contract and opportunity
                if(accountIds.size()>0){
                    if(!System.isFuture() && !System.isBatch() && !System.isQueueable() && !System.isScheduled()){
                        String jsonString = PrimayBillingAddressList.size()>0?json.serialize(PrimayBillingAddressList):'';
                       system.debug('--jsonString---'+jsonString);
                       UpdOppContractMethod(new List<Id>(accountIds),jsonString);
                    }
                }
                
            }
        }
    }
    //SFDC-20024: Move primary Address flow in the apex class. Updating billing address on all open contract and opportunity
    public class AddressWrapper {
        public Id Addid;
        public Id Accountid;
        public String StateName;
        public String CityName;
        public String CountryName;
        public String Street;
        public String ZipPostalCode;
        public String CountryISO;
        public Decimal LatitudeLatitude;
        public Decimal LongitudeLatitude;
    }
    public AddressWrapper GetBillingAddressInfo(Address__c add){
        AddressWrapper a = new AddressWrapper();
        a.Addid = add.id;
        a.Accountid = add.Account__c;
        a.StateName = add.State_Name__c;
        a.CityName = add.City__c;
        a.CountryName =add.Country_Name__c;
        a.Street =add.Street__c;
        a.ZipPostalCode =add.Zip_Postal_Code__c;
        a.CountryISO = add.Country_ISO__c;
        a.LatitudeLatitude =add.Latitude__Latitude__s;
        a.LongitudeLatitude = add.Longitude__Latitude__s;
        return a;
    }
    public static contract UpdateContractBillingAddressInfo(id contractid, AddressWrapper add){
        contract con = new contract();
        con.id= contractid;
        con.Billing_Address__c = add.Addid;
        con.BillingState = add.StateName;
        con.BillingCity = add.CityName;
        //con.BillingCountry =add.CountryName;
        con.BillingStreet =add.Street;
        con.BillingPostalCode =add.ZipPostalCode;
        con.BillingCountryCode = add.CountryISO;
        con.BillingLatitude =add.LatitudeLatitude;
        con.BillingLongitude = add.LongitudeLatitude;
        return con;
    }
    public static Opportunity UpdateOppBillingAddressInfo(id Oppid, AddressWrapper add){
        Opportunity op = new Opportunity();
        op.id = Oppid;
        op.Billing_Address__c = add.Addid;
        op.Street__c = add.Street;
        op.State__c = add.StateName;
        op.Zip_Postal_Code__c = add.ZipPostalCode;
        op.Country__c = add.CountryName;
        op.Country_ISO_Code__c = add.CountryISO;
        op.City__c = add.CityName;
        return op;
    }
    @future
    public static void UpdOppContractMethod(List<ID> accountIds, String jsonString){
     Map<id,AddressWrapper> AccountPrimayBillingMap = new Map<id,AddressWrapper>();
        try{
            if(String.IsNotBlank(jsonString)){
                List<AddressWrapper> AddressList = (List<AddressWrapper>)Json.deserialize(jsonString,List<AddressWrapper>.class);
                if(AddressList.size()>0 && accountIds.size()>0){
                    for(AddressWrapper aw: AddressList){
                        AccountPrimayBillingMap.put(aw.Accountid,aw);
                    }
                    List<Contract> ContractList = [Select id,AccountId,Business_Group__c,Distributor__c,Reseller__c from Contract where AccountId!=null  and SBQQ__ActiveContract__c=1 and (not account.Type like '%Distributor%') and Business_Group__c in ('MSP', 'Core') and (Distributor__c in: accountIds or Reseller__c in: accountIds or AccountId in: accountIds) order by LastModifiedDate desc];
                    List<Contract> UpdContractList = new List<Contract>();
                    for(Contract c: ContractList){
                        if(c.Business_Group__c=='MSP' && c.AccountId!=null && accountIds.contains(c.AccountId) && AccountPrimayBillingMap.containsKey(c.AccountId)){
                            UpdContractList.add(UpdateContractBillingAddressInfo(c.id, AccountPrimayBillingMap.get(c.AccountId)));
                        }
                        else if(c.Business_Group__c=='Core'){
                            if(AccountPrimayBillingMap.containsKey(c.Distributor__c)){
                              UpdContractList.add(UpdateContractBillingAddressInfo(c.id, AccountPrimayBillingMap.get(c.Distributor__c)));  
                            }
                            else if(c.Distributor__c==null && AccountPrimayBillingMap.containsKey(c.Reseller__c)){
                              UpdContractList.add(UpdateContractBillingAddressInfo(c.id, AccountPrimayBillingMap.get(c.Reseller__c))); 
                            }
                            else if(c.Distributor__c==null && c.Reseller__c==null && AccountPrimayBillingMap.containsKey(c.AccountId)){
                              UpdContractList.add(UpdateContractBillingAddressInfo(c.id, AccountPrimayBillingMap.get(c.AccountId)));
                            }
                        }    
                    }
                    List<Opportunity> OppList = [Select id,AccountId,Bill_To_Account__c,Business_Group__c from Opportunity where Oppty_Status__c = 'Open' and SBQQ__Ordered__c=false and CloseDate >=TODAY and ((Business_Group__c='Core' and Bill_To_Account__c!=null and Bill_To_Account__c in : accountIds) or (Business_Group__c ='MSP' and AccountId!=null and AccountId in : accountIds)) order by LastModifiedDate desc];
                    List<Opportunity> UpdOppList = new List<Opportunity>();
                    for(Opportunity opp: oppList){
                        if(opp.Business_Group__c=='Core' && opp.Bill_To_Account__c!=null && AccountPrimayBillingMap.containsKey(opp.Bill_To_Account__c)){
                            Opportunity o = UpdateOppBillingAddressInfo(opp.id, AccountPrimayBillingMap.get(opp.Bill_To_Account__c));
                            UpdOppList.add(o);
                        }
                        else if(opp.Business_Group__c=='MSP' && opp.AccountId!=null && AccountPrimayBillingMap.containsKey(opp.AccountId)){
                            Opportunity o = UpdateOppBillingAddressInfo(opp.id, AccountPrimayBillingMap.get(opp.AccountId));
                            UpdOppList.add(o);
                        }
                    }
                    if(UpdContractList.size()>0){
                      update UpdContractList;
                    }
                    if(UpdOppList.size()>0){
                      update UpdOppList;
                    }
                }
            }
        }
        Catch(exception e){
            system.debug('Update exception***'+e);
        }
    }
}