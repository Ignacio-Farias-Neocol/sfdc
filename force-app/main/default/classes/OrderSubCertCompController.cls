/**
* @author Salesforce Services
* @date 02/14/2021
*
* @group VF component controller
*
* @description SFDC-14048: controller for the VF component used to render subscription certificate for an order
*
*/
public /*with sharing*/ class OrderSubCertCompController {
  //Order passed by the parent
  public Order certOrder{get;set;}

  //List of serials associated with this order
  public List<SerialWrapper> serialList{
    get{
      return buildSerialList();
    }
    set;}
  
  //Method to build serial list for table display
  public List<SerialWrapper> buildSerialList() {
    if(certOrder!=null){
		System.debug('certOrder.Id...'+certOrder.Id);
      Order fetchedOrder = [Select OrderNumber from Order where id =: certOrder.Id LIMIT 1];

      //List of serialwrapper to be returned
      List<SerialWrapper> serialListToBeReturned = new List<SerialWrapper>();

      //Map of Serial Id and Sub Ids to be displayed for the serial.
      //This map is used to determine if a parent sub has been added or not based on child's quotline visibility
      Map<Id,Set<Id>> serialSubMap = new Map<Id,Set<Id>>();

      /*If the parent passes an order, get the serial list along with assigned serials for each serial
        When fetching assigned serials, we pull in required subscription information*/
      for(Serial__c serial: [SELECT Id, 
                                    Serial_Number__c,
                                    Base_Product_SKU__c,
                                    Product__r.Name,
                                    Product__r.Description,
                                    Fulfillment_Date__c,
                                    (SELECT Name,
                                            Subscription__c,
                                            Subscription__r.OrderNumber__c,
                                            Subscription__r.SBQQ__SubscriptionStartDate__c,
                                            Subscription__r.SBQQ__SubscriptionEndDate__c,
                                            Subscription__r.Current_Quantity__c,
                                            Subscription__r.SBQQ__Quantity__c,
                                            Subscription__r.SBQQ__ProductName__c,
                                            Subscription__r.SBQQ__Product__r.Description,
                                            Subscription__r.SBQQ__ProductOption__c,
                                            Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c,
                                            Subscription__r.SBQQ__RequiredById__c,
                                            Subscription__r.SBQQ__RequiredByProduct__r.Name,
                                            Subscription__r.SBQQ__RequiredByProduct__r.Description,
                                            Subscription__r.SBQQ__OrderProduct__r.EndDate,
                                            Subscription__r.SBQQ__OrderProduct__r.ServiceDate,
                                            Subscription__r.SBQQ__Contract__r.ContractTerm,
                                     		Subscription__r.SBQQ__Contract__r.Distributor__r.Name,
                                    		Subscription__r.SBQQ__Contract__r.Reseller__r.Name,
                                            Subscription__r.SBQQ__OrderProduct__r.SBCF_Order_Line_Type__c,
                                            Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c
                                    FROM Assigned_Serials__r 
                                    WHERE Subscription__c != null AND Subscription__r.OrderNumber__c = :fetchedOrder.OrderNumber) 
                            FROM  Serial__c 
                            WHERE Order__c = :certOrder.Id]){

        //Create an entry in the serialSubMap
        serialSubMap.put(serial.Id, new Set<Id>()); 

        //Instantiate SerialWrapper and set its fields
        SerialWrapper sw = new SerialWrapper();
        sw.serialNumber  = serial.Serial_Number__c;
        //sw.productName   = serial.Product__r.Name;
        sw.productDes    = serial.Product__r.Description;
        sw.subList       = new List<SubscriptionWrapper>();

        //populate sublist by looping through assigned serials
        for(Assigned_Serial__c currentAS: serial.Assigned_Serials__r){
          
            //Determine the quoteline visibility via product options
            Boolean quoteLineVisibility = String.isNotBlank(currentAS.Subscription__r.SBQQ__ProductOption__c) && 
                                          currentAS.Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c == 'Never' ? false : true;
            
            //Show the subscription on certificate if quotelineVisibility is true OR
            //If quotelinevisibility is false, show information of the sub in requiredby field. Make sure that the requiredby sub is added only once.
            if(quoteLineVisibility || 
              (!quoteLineVisibility && !serialSubMap.get(serial.Id).contains(currentAS.Subscription__r.SBQQ__RequiredById__c))){

              //Add this requiredbyId to the map so that it is not added to the sublist again
              serialSubMap.get(serial.Id).add(currentAS.Subscription__r.SBQQ__RequiredById__c);

              //Create SubscriptionWrapper instance and set its fields
              SubscriptionWrapper sub = new SubscriptionWrapper();
              //if this instance is for the requiredby sub then add information related to that. Else add information for the sub
              sub.subId       = quoteLineVisibility?currentAS.Subscription__c:currentAS.Subscription__r.SBQQ__RequiredById__c;
              //sub.startDate   = currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c;
              //sub.endDate     = currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c;
              if(currentAS.Subscription__r.SBQQ__OrderProduct__r.SBCF_Order_Line_Type__c != 'New' || currentAS.Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Amendment'){
                sub.startDate   = currentAS.Subscription__r.SBQQ__OrderProduct__r.ServiceDate;
                sub.endDate   = currentAS.Subscription__r.SBQQ__OrderProduct__r.EndDate;
              }
              else{
                sub.startDate = serial.Fulfillment_Date__c;
                Date endDate = sub.startDate.addMonths(currentAS.Subscription__r.SBQQ__Contract__r.ContractTerm);
                endDate = endDate.addDays(-1);
                sub.endDate = endDate;
              }
              sub.quantity    = currentAS.Subscription__r.SBQQ__Quantity__c == null? currentAS.Subscription__r.Current_Quantity__c : currentAS.Subscription__r.SBQQ__Quantity__c;
            //  sub.productName = quoteLineVisibility?currentAS.Subscription__r.SBQQ__ProductName__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Name;
              sub.productDes = quoteLineVisibility?currentAS.Subscription__r.SBQQ__Product__r.Description:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Description;
              
              //Add Sub wrapper instance to the list
              sw.subList.add(sub);
            }
        } //END OF ASSIGNED SERIAL LOOP

        //Add SerialWrapper instance to the list
        serialListToBeReturned.add(sw);
      } //END OF SERIAL LOOP
      return serialListToBeReturned;
    }
    else{
      return null;
    }
  }

  //Wrapper class for Serial information
  public class SerialWrapper {
    public String serialNumber {get;set;}
    //public String productName {get;set;}
    public String productDes {get;set;}
    public List<SubscriptionWrapper> subList {get;set;}        
  }

  //Wrapper class for Subscription Information
  public class SubscriptionWrapper {
    public Id subId {get;set;}
    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public Decimal quantity {get;set;}
    //public String productName {get;set;}    
    public String productDes {get;set;} 
  }
}