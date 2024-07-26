/**
* @author Dilowar Hussain
* @date 2022-03-24
*
* @description 
* This Apex Class gets invoked by by the aura component, VoidOrderComponent. 
* This is the controller class.
*
* This has been added as a part of SFDC-15817
*/
public class VoidOrderController {
    
    /***************************
     * Method Description: 
     *  This method contains all validations required for vois order functionality.
     * 
     * @Param: String recordId
     * @return boolean
     */
    @AuraEnabled
    public static boolean checkVoidOrderCriteria(String recordId){
        boolean isOrder = true;
        //try{
            if(String.isNotBlank(recordId)){
                
                for(OrderItem eachOI : [Select Id, Serial__c, SBCF_Serial_Number__c, Serial_Available_For_Core__c, Order.Quote_Business_Group__c, Order.Status, Order.Pending_Cancellation__c, Order.Is_Order_Cancelled__c From OrderItem Where OrderId =: recordId]){
                    //Check if the Order is already Cancelled.
                    //if(String.isNotBlank(eachOI.Order.Status) && String.valueOf(eachOI.Order.Status).equalsIgnoreCase('Cancelled')){
                    if(eachOI.Order.Is_Order_Cancelled__c == TRUE){
                        isOrder = false;
                        AuraHandledException e = new AuraHandledException('You can only attempt to Cancel Placed or Activated Orders');
                        e.setMessage('You can only attempt to Cancel Placed or Activated Orders');
                        //system.debug(e);
                        throw e;
                        //throw new AuraHandledException('You can only attempt to Cancel Placed or Activated Orders');
                    }
                    //Check if the Order is already Draft.
                    else if(String.isNotBlank(eachOI.Order.Status) && String.valueOf(eachOI.Order.Status).equalsIgnoreCase('Draft')){
                        isOrder = false;
                        //throw new AuraHandledException('Cannot Cancel Draft orders');
                        AuraHandledException e = new AuraHandledException('Cannot Cancel Draft orders');
                        e.setMessage('Cannot Cancel Draft orders');
                        //system.debug(e);
                        throw e;
                    }
                    //Check if Quote Business Group of the order is Core or not.
                    else if(String.isNotBlank(eachOI.Order.Quote_Business_Group__c) && !eachOI.Order.Quote_Business_Group__c.equalsIgnoreCase('Barracuda')) {
                        isOrder = false;
                        //throw new AuraHandledException('This feature is available for core order only');
                        AuraHandledException e = new AuraHandledException('This feature is available for core order only');
                        e.setMessage('This feature is available for core order only');
                        //system.debug(e);
                        throw e;
                    }
                    //Checking for serials availability.
                    //else if(String.isNotBlank(eachOI.Serial__c) ) {
                    else if(String.isNotBlank(eachOI.SBCF_Serial_Number__c) /*&& eachOI.Serial_Available_For_Core__c == TRUE*/){
                        isOrder = false;
                        //throw new AuraHandledException('Order cannot be Cancelled as Serial has been generated');
                        AuraHandledException e = new AuraHandledException('Order cannot be Cancelled as Serial has been generated');
                        e.setMessage('Order cannot be Cancelled as Serial has been generated');
                        //system.debug(e);
                        throw e;
                    }
                    //Checking if the Order has already been placed for Cancellation.
                    else if(String.isNotBlank(eachOI.Order.Status) && eachOI.Order.Pending_Cancellation__c == TRUE){
                        isOrder = false;
                        //throw new AuraHandledException('This Order is already submitted for cancellation.');
                        AuraHandledException e = new AuraHandledException('This Order is already submitted for cancellation');
                        e.setMessage('This Order is already submitted for cancellation.');
                        //system.debug(e);
                        throw e;
                    }
                }
            }
        system.debug('isOrder ***'+ isOrder);
        /*}Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }*/
        return isOrder;
        
    }
    
    /***************************
     * Method Description: 
     *  This method contains the actual logic.
     *  1. If the order is with activated status and user clicks on "void Order" button,
     *     status gets updated to "Cancelled". The checkbox SBQQ__Contracted__c is turned off.
     *     The field, Cancellation_Attempt_Date__c gets updated to current date & time.
     *  2. If the Order us with Placed status and user submits for void order, status remains same. 
     *     But the chckbox, "Pending Cancellation" gets checked. Also, platform event gets published.
     * 
     * @Param: String recordId
     * @return String
     */
    
    @AuraEnabled
    public static string updateOrderStatus(String recordId){
        
        String msg;
        String orderStatus;
        Order order = new Order();
        List<Order> lstOrderToPublish = new List<Order>();
        try{
            
            if(String.isNotBlank(recordId)){
                
                order = [Select Id, Status, Pending_Cancellation__c From Order Where Id =: recordId];
                System.debug('voidOrder1'+order.Status);
               /*if(order != null && order.Status.equalsIgnoreCase('Draft')) {
                   throw new AuraHandledException('Cannot cancel draft order.'); 
                }*/
                if(order != null && order.Status.equalsIgnoreCase('Activated')){
                    order o = new Order();
                    o.id =recordId;
                    orderStatus = 'Cancelled';
                    //o.Status = 'Cancelled';
                    o.Is_Order_Cancelled__c = TRUE;
                    o.Cancellation_Attempt_Date__c = system.now();
                    o.SBQQ__Contracted__c = false;
                    list<OrderItem> lstorditem = [Select id,SBQQ__Activated__c,SBQQ__Contracted__c from OrderItem where orderId = : recordId];
                    list<OrderItem> lstorditemtoupd = new list<OrderItem>();
                    System.debug('voidOrder1'+lstorditem);
                    if(lstorditem.size() >0){
                        for(OrderItem od:lstorditem){
                            od.SBQQ__Activated__c = false;
                            od.SBQQ__Contracted__c = false;
                            lstorditemtoupd.add(od);
                        }
                    }
                    //lstOrderToPublish.add(o);
                    update lstorditemtoupd;
                    System.debug('voidOrder'+o);
                    update o;
                }
                else if(order != null && order.Status.equalsIgnoreCase('Placed')){
                    order o = new Order();
                    o.id =recordId;
                    //o.SBQQ__Contracted__c = false;
                    orderStatus = 'Pending Cancellation'; 
                    /*list<OrderItem> lstorditem = [Select id,SBQQ__Activated__c,SBQQ__Contracted__c from OrderItem where orderId = : recordId];
                    list<OrderItem> lstorditemtoupd = new list<OrderItem>();
                    if(lstorditem.size() >0){
                        for(OrderItem od:lstorditem){
                            OrderItem oi = new OrderItem();
                            oi.Id = od.id;
                            oi.SBQQ__Activated__c = false;
                            oi.SBQQ__Contracted__c = false;
                            lstorditemtoupd.add(oi);
                        }
                    }*/
                    lstOrderToPublish.add(o);
                    //update lstorditemtoupd;
                    o.Pending_Cancellation__c = TRUE;
                    o.Do_not_lock_Order_record__c = TRUE;
                     o.Cancellation_Attempt_Date__c = system.now();
                    update o;
                }    
                /*if(order != null && order.Pending_Cancellation__c == TRUE){
                    throw new AuraHandledException('This Order '+ recordId+' is already submitted for cancellation.');
                }*/
               /****
                * Invoke PlatformEventHelper and call the method "publishObject".
                */
                System.debug('lstOrderToPublish is:'+lstOrderToPublish);
                if(!lstOrderToPublish.isEmpty()){
                    new PlatformEventHelper().publishObject('VOID_ORDER',lstOrderToPublish);
                }
            }  
            
        }catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
      return orderStatus;  
    }
    
}