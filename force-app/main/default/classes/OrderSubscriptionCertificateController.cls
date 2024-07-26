/*
 *Author: Bhavesh Jha
 * 
 * 
 */
public class OrderSubscriptionCertificateController{
    
    //Instance of current order object.
    private Order mOrder;
    
    //Initial Variable Wrap
    public List<SerialWrapper> mSerialWrapperList{get;set;}
    Map<String, List<Serial__c>> skuVsSerialsMap = new Map<String, List<Serial__c>>();
    
    public Integer curserIndex{get;set;}
    public Integer pageSize{get;set;}
    
    public  OrderSubscriptionCertificateController(ApexPages.StandardController controller) {
        System.debug('OrderSubscriptionCertificateController ::  MODE :: ENTER :: 15');
        //For the query field on ApexPages.StandardController
        if(!Test.isRunningTest())controller.addFields(new List<String>{'PoNumber', 'Bill_To_Account__r.Name','Active_Contract__r.Reseller__r.Name','Active_Contract__r.SBQQ__Quote__r.Name'});
        
        //for get curserIndex for getting where to start 
        curserIndex  = Apexpages.currentpage().getParameters().get('curserIndex') != null ? Integer.valueOf(Apexpages.currentpage().getParameters().get('curserIndex')) : 0;
        //for get pageSize for set the size of page       
        pageSize = Apexpages.currentpage().getParameters().get('pageSize') != null ? Integer.valueOf(Apexpages.currentpage().getParameters().get('pageSize')) : 0;
        System.debug(':::::curserIndex:::::'+curserIndex);
        System.debug(':::::pageSize::::::'+pageSize);
        mOrder = (Order)controller.getRecord();
        System.debug('OrderSubscriptionCertificateController ::  mOrder '+JSON.serialize(mOrder));
        
        mSerialWrapperList = new List<SerialWrapper>();
       
        if(mOrder != null){
            List<Serial__c> serialList = [Select 
                        id,Serial_Number__c,Activation_Date__c,Base_Product_SKU__c,
                        (Select id,Subscription__r.SBQQ__ProductName__c,
                                Subscription__r.Name,
                                Subscription__r.SBQQ__SubscriptionStartDate__c,
                                Subscription__r.SBQQ__SubscriptionEndDate__c,
                                Subscription__r.Current_Quantity__c from Assigned_Serials__r)
                         from Serial__c where Order__c =: mOrder.id and Activation_Date__c!= null];
            for(Serial__c serial: serialList){
                if(!skuVsSerialsMap.containsKey(serial.Base_Product_SKU__c))
                    skuVsSerialsMap.put(serial.Base_Product_SKU__c,new List<Serial__c>());
                skuVsSerialsMap.get(serial.Base_Product_SKU__c).add(serial);
            }
            Map<String,Product2> productCodeVsProductMap = new map<String,Product2>();
            
            for(Product2 prod: [Select Name, ProductCode from product2 where ProductCode in:skuVsSerialsMap.keySet() ]){
                productCodeVsProductMap.put(prod.ProductCode,prod);
            }
            
            // Select Name, ProductCode from product2 where ProductCode in serialSkumap.keyset()
            
            for(Serial__c serial: serialList){
                SerialWrapper mSerialWrapper = new SerialWrapper();
                List<SubscriptionWrapper> tmpSerialWrapperList = new List<SubscriptionWrapper>();
                System.debug('OrderSubscriptionCertificateController ::  serial.Assigned_Serials__r '+JSON.serialize(serial.Assigned_Serials__r));
                if(serial.Assigned_Serials__r != null && !serial.Assigned_Serials__r.isEmpty()){
                    System.debug('serial.Assigned_Serials__r :: '+JSON.serialize(serial.Assigned_Serials__r));
                    System.debug('serial.Assigned_Serials__r :: Size :: '+serial.Assigned_Serials__r.size());
                    for(Assigned_Serial__c assignedSerial: serial.Assigned_Serials__r){
                        
                        SubscriptionWrapper mSubscriptionWrapper = new SubscriptionWrapper();
                        mSubscriptionWrapper.mStartDate = assignedSerial.Subscription__r.SBQQ__SubscriptionStartDate__c != null ? assignedSerial.Subscription__r.SBQQ__SubscriptionStartDate__c.format() : '';
                        mSubscriptionWrapper.mEndDate = assignedSerial.Subscription__r.SBQQ__SubscriptionEndDate__c != null ? assignedSerial.Subscription__r.SBQQ__SubscriptionEndDate__c.format() : '';
                        mSubscriptionWrapper.mCapacity = String.valueOf(assignedSerial.Subscription__r.Current_Quantity__c) ;
                        mSubscriptionWrapper.mSubscription = assignedSerial.Subscription__r.SBQQ__ProductName__c;
                        // 
                        tmpSerialWrapperList.add(mSubscriptionWrapper);
                    }
                    mSerialWrapper.mProductName = productCodeVsProductMap.get(serial.Base_Product_SKU__c) != null ? productCodeVsProductMap.get(serial.Base_Product_SKU__c).Name : '';
                    mSerialWrapper.mFullfillmentDate = serial.Activation_Date__c != null ? serial.Activation_Date__c.format() : '';
                    mSerialWrapper.mSubscriptionWrapperList = tmpSerialWrapperList;
                    mSerialWrapper.mSN = String.valueOf(serial.Serial_Number__c);
                    
                    mSerialWrapperList.add(mSerialWrapper);
                }
            }
            System.debug('mSerialWrapperList :::: '+JSON.serialize(mSerialWrapperList));
        }
    }
    
    
    private class SerialWrapper {
        public String mProductName{get;set;}
        public String mSN{get;set;}
        public String mFullfillmentDate{get;set;}
        public List<SubscriptionWrapper> mSubscriptionWrapperList{get;set;}
    }

    private class SubscriptionWrapper {
        public String mStartDate{get;set;}
        public String mEndDate{get;set;}
        public String mCapacity{get;set;}
        public String mSubscription{get;set;}
    }
}