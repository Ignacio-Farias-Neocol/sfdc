/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 02-25-2021
 * @last modified by  : 
 * Modifications Log 
**/
public without sharing class ContractViewCon {
    
    @auraEnabled public static List<ContractWrapper> contractWrapperList{get;set;}
    
    @AuraEnabled(cacheable = true)
    public static List<ContractWrapper> getContractList() {
        List<ContractWrapper> mContractWrapperList = new List<ContractWrapper>();
      Boolean hasCustomPermission = FeatureManagement.checkPermission('Permission_to_Reseller_Level_on_Serial_Exipry_Report');
        Boolean hasSerialExpiryReportPermission = FeatureManagement.checkPermission('Access_to_Export_Serial_Expiry_Report');
        List<User> uList = [Select id,ContactId from User where id=: UserInfo.getUserId()];
        Map<String,SBQQ__Subscription__c> idVsSubMap = new Map<String,SBQQ__Subscription__c>();
        if(!uList.isEmpty()){
           List<Contact> con = [Select id, AccountId from Contact Where id =: uList.get(0).ContactId];
           System.debug(LoggingLevel.INFO, 'con::'+JSON.serialize(con));
           System.debug('$$$$ Cont Acc Id...'+con[0].AccountId);
            if(!con.isEmpty()){ // Added Business Group = 'Marketplace' for Marketplace order By Jade Global on 14/July/2023
                List<Contract> contractList = [Select id, Name, Status, Business_Group__c, AccountId, Reseller__c, EndDate from Contract 
                where (AccountId =: con[0].AccountId OR Reseller__c =: con[0].AccountId OR Distributor__c =: con[0].AccountId) And (Business_Group__c = 'Core' Or Business_Group__c = 'Marketplace')
                And (EndDate = Next_90_Days OR EndDate = Last_n_Days:30) Order By EndDate Asc];
                System.debug('$$$$ contractList::'+contractList);
                Map<String,List<SubscriptionViewWrapper>> serialVsSubMap = new Map<String,List<SubscriptionViewWrapper>>();
                Map<String,Set<String>> contractNumberVsSerialListNumberMap = new Map<String,Set<String>>();
                Map<String,List<SubscriptionViewWrapper>> contractVsSubMap = new Map<String,List<SubscriptionViewWrapper>>();
                // Added SBQQ__Contract__r.Business_Group__c = 'Marketplace' for Marketplace order By Jade Global on 14/July/2023
                //Modified as part of SFDC-20236. Replaced the field, Fulfillment_Date__c with new Date field, Fulfillment_Date2__c.
                for(SBQQ__Subscription__c sub: [Select id,SBQQ__Contract__r.Account.name,Parent_Product__c,SBQQ__ProductName__c,SBQQ__StartDate__c,
                    SBQQ__EndDate__c,SBQQ__Contract__r.PO_Number__c,SBQQ__Contract__r.Quote_Number__c,SBQQ__Contract__r.ContractTerm,SBQQ__Quantity__c,
                    SBQQ__Contract__r.Distributor_Account_Name__c,SBQQ__Contract__r.Reseller_Account_Name__c,SBQQ__Contract__r.Reseller_Level__c,SBCF_Serial_Number__c,SBQQ__Contract__r.Contract_Number_Text__c,
                    SBQQ__Contract__r.Account.BillingCountry,SBQQ__Contract__r.Account.BillingState,Parent_Serial_Number__c, (Select Id, Fulfillment_Date2__c  FROM Assigned_Serials__r) from SBQQ__Subscription__c WHERE 
                    (SBQQ__Contract__r.AccountId =: con[0].AccountId OR SBQQ__Contract__r.Reseller__c =: con[0].AccountId OR SBQQ__Contract__r.Distributor__c =: con[0].AccountId) And (SBQQ__Contract__r.Business_Group__c = 'Core' Or SBQQ__Contract__r.Business_Group__c = 'Marketplace')
                    And (SBQQ__EndDate__c = Next_90_Days OR SBQQ__EndDate__c = Last_n_Days:30) AND Renewed_By_Subscription__c = null AND AnnotationReason__c = NULL AND Current_Quantity__c != 0 AND SBQQ__RequiredByProduct__r.Document_Bundle__c = False  Order By SBQQ__EndDate__c Asc])
                {
                    system.debug('$$$$ sub.SBCF_Serial_Number__c---' +  sub.SBCF_Serial_Number__c);
                    if(sub.SBCF_Serial_Number__c == null){
                         if(sub.Parent_Serial_Number__c != null && sub.Parent_Serial_Number__c != '') {
                            sub.SBCF_Serial_Number__c = sub.Parent_Serial_Number__c;
                            system.debug('$$$$ serial after parent serial ----' + sub.SBCF_Serial_Number__c );
                        }
                        else{
                            sub.SBCF_Serial_Number__c = '-';
                        }
                    }
                    

                    //if(sub.SBCF_Serial_Number__c==null){sub.SBCF_Serial_Number__c = '-';}

                    if(!contractNumberVsSerialListNumberMap.containsKey(sub.SBQQ__Contract__r.Contract_Number_Text__c)){
                        contractNumberVsSerialListNumberMap.put(sub.SBQQ__Contract__r.Contract_Number_Text__c,new Set<String>());
                    }
                    contractNumberVsSerialListNumberMap.get(sub.SBQQ__Contract__r.Contract_Number_Text__c).add(sub.SBCF_Serial_Number__c);

                    if(sub.SBCF_Serial_Number__c != '-'){
                        if(!serialVsSubMap.containsKey(sub.SBCF_Serial_Number__c)){
                            serialVsSubMap.put(sub.SBCF_Serial_Number__c,new List<SubscriptionViewWrapper>());
                        }
                    }else{
                        if(!contractVsSubMap.containsKey(sub.SBQQ__Contract__r.Contract_Number_Text__c)){
                            contractVsSubMap.put(sub.SBQQ__Contract__r.Contract_Number_Text__c,new List<SubscriptionViewWrapper>());
                        }
                    }
                    
					System.debug('$$$$ contractNumberVsSerialListNumberMap::'+contractNumberVsSerialListNumberMap);
                    System.debug('$$$$ contractVsSubMap::'+contractVsSubMap);
                    SubscriptionViewWrapper subWrapper = new SubscriptionViewWrapper();
                    subWrapper.id = sub.id;
                    subWrapper.accountName = sub.SBQQ__Contract__r.Account.name;
                    subWrapper.parentProduct = sub.Parent_Product__c;
                    subWrapper.productName = sub.SBQQ__ProductName__c;
                    subWrapper.contractStartDate = String.valueof(sub.SBQQ__StartDate__c);
                    subWrapper.contractEndDate = String.valueOf(sub.SBQQ__EndDate__c);
                    subWrapper.mPOnumber = sub.SBQQ__Contract__r.PO_Number__c;
                    subWrapper.quoteNumber = sub.SBQQ__Contract__r.Quote_Number__c;
                    subWrapper.terms = String.valueOf(sub.SBQQ__Contract__r.ContractTerm);
                    subWrapper.mQuantity = String.valueOf(sub.SBQQ__Quantity__c);
                    subWrapper.country = sub.SBQQ__Contract__r.Account.BillingCountry;
                    subWrapper.state = sub.SBQQ__Contract__r.Account.BillingState;
                    subWrapper.distAccountName = sub.SBQQ__Contract__r.Distributor_Account_Name__c;
                    subWrapper.resellerAccountName = sub.SBQQ__Contract__r.Reseller_Account_Name__c;
                    subWrapper.resellerLevel = sub.SBQQ__Contract__r.Reseller_Level__c;
                    //Modified as part of SFDC-20236. Replaced the field, Fulfillment_Date__c with new Date field, Fulfillment_Date2__c.
                    if(sub.Assigned_Serials__r.size() > 0 && sub.Assigned_Serials__r[0].Fulfillment_Date2__c != null){
                    subWrapper.fulfillmentDate = String.valueOf(sub.Assigned_Serials__r[0].Fulfillment_Date2__c);
                    }else
                    { 
                    subWrapper.fulfillmentDate = '';
                    }
                    if(sub.SBCF_Serial_Number__c != '-'){
                        serialVsSubMap.get(sub.SBCF_Serial_Number__c).add(subWrapper);
                    }else{
                        contractVsSubMap.get(sub.SBQQ__Contract__r.Contract_Number_Text__c).add(subWrapper);
                    }
                    
                }


             //   System.debug(LoggingLevel.INFO,'contractNumberVsSerialListNumberMap:::'+ JSON.serialize(contractNumberVsSerialListNumberMap));
              //  System.debug(LoggingLevel.INFO,'serialVsSubMap:::'+ JSON.serialize(serialVsSubMap));

                if(!serialVsSubMap.isEmpty()){
                    for(String contractNumber: contractNumberVsSerialListNumberMap.keyset()){

                        ContractWrapper contractWrap = new ContractWrapper();
                        contractWrap.contractNumber = contractNumber;
                        if(hasSerialExpiryReportPermission){
                            contractWrap.showDownloadReportButton = true;
                        }
                        else{
                           contractWrap.showDownloadReportButton = false; 
                        }
                        List<SerialWrapper> mSerialWrapperList = new List<SerialWrapper>();
                        for(String serial: contractNumberVsSerialListNumberMap.get(contractNumber)){
                            SerialWrapper mSerialWrapper = new SerialWrapper();
                            mSerialWrapper.serialNumber = serial;
                            if(hasCustomPermission){
                              mSerialWrapper.showField = true;
                         }
                        else{
                          mSerialWrapper.showField = false;
                        }
                            if(serial == '-'){
                                mSerialWrapper.subWrapList = contractVsSubMap.get(contractNumber);
                            }else{
                                mSerialWrapper.subWrapList = serialVsSubMap.get(serial);
                            }
                            mSerialWrapperList.add(mSerialWrapper);
                        }
                        contractWrap.serialWrapList = mSerialWrapperList;
                        mContractWrapperList.add(contractWrap);
                      //  system.debug('R mContractWrapperList'+mContractWrapperList);
                    }
                   // System.debug(LoggingLevel.INFO, 'mContractWrapperList::'+JSON.serialize(mContractWrapperList));
                    contractWrapperList = new List<ContractWrapper>();
                    contractWrapperList = mContractWrapperList ;
                    return mContractWrapperList;
                }else{
                    return new List<ContractWrapper>();
                }
            }
            return new List<ContractWrapper>();
        }else{
            return new List<ContractWrapper>();
        }
        
    }
  
    @auraEnabled
    public static string prepareSerialReport(String contractWrapperJSONStringify){
        System.Debug('--++-- contractWrapperJSONStringify: ' + contractWrapperJSONStringify);
        Boolean showResellerLevelField = false;
        List<ContractWrapper> contractList = (List<ContractWrapper>) JSON.deserialize(contractWrapperJSONStringify, List<ContractWrapper>.class );
        List<String> csvRowValues = new List<String>();

        //Instantiate the log class to capture logs
            LogModel log = LogModel.startLog('ContractViewCon', 
            'prepareSerialReport',
            LogModel.LOG_CATEGORY_APEX);

            System.Debug('--++-- contractList Size: ' + contractList.size());
        for(ContractWrapper eachContract : contractList){
            if(eachContract.contractNumber.equalsIgnoreCase('00424765')){
                log.addLog('-++-- Contract Found ' + eachContract.contractNumber);
                System.Debug('-++-- Contract Found ' + eachContract.contractNumber);
            }
            for(SerialWrapper eachSerial : eachContract.serialWrapList){
                showResellerLevelField = eachSerial.showField;
                for(SubscriptionViewWrapper eachSubscription : eachSerial.subWrapList){
                    String contractNumber = eachContract.contractNumber;
                    String serialNumber;
                   if(eachSerial.serialNumber!= NULL){
                   serialNumber = eachSerial.serialNumber.replace(',','/');
                   }else{
                   serialNumber = eachSerial.serialNumber;
                   }
                    String accountName; 
                    if(eachSubscription.accountName!= NULL){
                    accountName = eachSubscription.accountName.replace(',','-');
                    }else{
                   accountName = eachSubscription.accountName;
                    }
                    String parentProduct;
                    if(eachSubscription.parentProduct!= NULL){
                        parentProduct = eachSubscription.parentProduct.replace(',','-');
                    }else{
                        parentProduct = eachSubscription.parentProduct;
                    }
                    String productName;
                    if(eachSubscription.productName != NULL){
                   productName = eachSubscription.productName.replace(',','-');
                    }else{
                    productName = eachSubscription.productName;
                    }
                    String contractStartDate = eachSubscription.contractStartDate;
                    String contractEndDate = eachSubscription.contractEndDate;
                    String mPOnumber = eachSubscription.mPOnumber;
                    String quoteNumber = eachSubscription.quoteNumber;
                    String terms = eachSubscription.terms;
                    String mQuantity = eachSubscription.mQuantity;
                    String country = eachSubscription.country;
                    String state = eachSubscription.state;
                    String distAccountName;
                    String resellerAccountName;
                    if(eachSubscription.distAccountName != NULL){
                        distAccountName = eachSubscription.distAccountName.replace(',','-');
                    }else{
                        distAccountName = eachSubscription.distAccountName;
                    }
                    if(eachSubscription.resellerAccountName != NULL){
                        resellerAccountName = eachSubscription.resellerAccountName.replace(',','-');
                    }
                    else{
                        resellerAccountName = eachSubscription.resellerAccountName;
                    }
                    String resellerLevel = '';
                    if(showResellerLevelField){
                        resellerLevel =  eachSubscription.resellerLevel;
                    }
                    String fulfillmentDate = eachSubscription.fulfillmentDate;
                    String rowStr =  contractNumber+','+serialNumber+','+accountName+','+ parentProduct + ',' + productName + ',' + contractStartDate + ','+ contractEndDate +','+ mPOnumber +','+ quoteNumber +','+ terms +',' + mQuantity + ','+ country + ','+ state + ','+ distAccountName + ','+ resellerAccountName +','+ fulfillmentDate;
                    if(showResellerLevelField){
                        rowStr += ','+resellerLevel;
                    }
                    csvRowValues.add(rowStr);
                }
            }
        }
        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Type = 'Document' ];
        String documentName = 'SerialReport';
        String csvColumnHeader = 'Contract Number,Serial Number,Account Name,Parent Product,Product Name,Subscription Start Date,Subscription End Date,PO Number,Quote Number,Terms (In Months),Quantity,Country,State,Distributor,Reseller,Fulfillment Date';
        if(showResellerLevelField){
            csvColumnHeader += ',Reseller Level \n';
        }
        else{
            csvColumnHeader += '\n';
        }
        system.debug('++++ csvRowValues +++++ : ' + csvRowValues.size());
        String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        //Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
        //insert doc;
        return csvFile;
    }
    
    public class SubscriptionViewWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String accountName;
        @AuraEnabled public String parentProduct;
        @AuraEnabled public String productName;
        @AuraEnabled public String contractStartDate;
        @AuraEnabled public String contractEndDate;
        @AuraEnabled public String mPOnumber;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String terms;
        @AuraEnabled public String mQuantity;
        @AuraEnabled public String country;
        @AuraEnabled public String state;
        @AuraEnabled public String distAccountName;
        @AuraEnabled public String resellerAccountName;
        @AuraEnabled public String resellerLevel;
        @AuraEnabled public String fulfillmentDate;
         }

    public class SerialWrapper{
        @AuraEnabled public String serialNumber;
        @AuraEnabled public List<SubscriptionViewWrapper> subWrapList;
        @AuraEnabled public Boolean showField;
    }

    public class ContractWrapper{
        @AuraEnabled public String contractNumber;
        @AuraEnabled public Boolean showDownloadReportButton;
        @AuraEnabled public List<SerialWrapper> serialWrapList;
    }
}