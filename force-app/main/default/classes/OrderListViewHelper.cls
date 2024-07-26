public without sharing class OrderListViewHelper {

  @AuraEnabled(cacheable = true)
  public static List<OrderDetail> getOrders(String userId, String fromDate, String toDate) {
  
    System.debug('Retrieving Orders');
    //Retrieve AccountId
    User currUser = [SELECT
              Id,
              ContactId
              FROM User 
              WHERE Id = :userId];

    String contactId = currUser.ContactId;

    Contact currContact = [SELECT 
                Id,
                AccountId
                FROM Contact
                WHERE Id = :contactId];

    String accountId = currContact.AccountId;

    List<OrderDetail> data = new List<OrderDetail>();

    //Need to format  to standard date format “yyyy-MM-dd HH:mm:ss”
    Datetime fromDT = Datetime.valueOf(fromDate + ' 00:00:00');
    Datetime toDT = Datetime.valueOf(toDate + ' 23:59:59');

    List<Order> orders = [SELECT 
                Id,
                CreatedDate,
                Order_Fulfillment_Date__c,
                PoNumber,
                SBQQ__Quote__r.Name,
                TotalAmount,
                Bill_To_Contact__c,
                Active_Contract__r.Reseller__r.Name,
                End_User_Contact__r.Name,
                Account.Name,
                AccountId,
                (SELECT 
                Id,
                SBCF_Serial_Number__c
                FROM OrderItems
                )
                FROM Order
                WHERE Bill_To_Account__c = :accountId 
                AND CreatedDate >= :fromDT
                AND CreatedDate <= :toDT
                ORDER BY CreatedDate DESC];
                   
    // List<Order> orders = Database.query(query);

    for(Order currentOrder: orders){
      OrderDetail newOrderInstance = new OrderDetail();
      newOrderInstance.orderDate = (currentOrder.createdDate == null) ? null : currentOrder.createdDate.date();
      newOrderInstance.fulfillmentDate = currentOrder.Order_Fulfillment_Date__c;
      newOrderInstance.orderNumber = currentOrder.Id;
      newOrderInstance.poNumber = currentOrder.PoNumber;
      newOrderInstance.quoteNumber = currentOrder.SBQQ__Quote__r.Name;
      newOrderInstance.orderAmount = currentOrder.TotalAmount;
      newOrderInstance.billToContact = currentOrder.Bill_TO_Contact__c;
      newOrderInstance.partner = currentOrder.Active_Contract__r?.Reseller__r?.Name != null ? currentOrder.Active_Contract__r.Reseller__r.Name : '';
      newOrderInstance.endUser = currentOrder.Account.Name != null ? currentOrder.Account.Name : '';
      newOrderInstance.url = '/PreviewSubscriptionCertificate?id={!'+currentOrder.Id+'}';
      List<String> serialNumbers = new List<String>();
      for(OrderItem orderItem: currentOrder.OrderItems) {
        if(orderItem.SBCF_Serial_Number__c != null) {
          serialNumbers.add(orderItem.SBCF_Serial_Number__c);
        }
      }
      Set<String> filterSerialNumbers = new Set<String>(serialNumbers);
      filterSerialNumbers.remove('');
      newOrderInstance.serialNumbers = String.join(new List<String>(filterSerialNumbers), ', ');
      data.add(newOrderInstance);
    }

    System.debug('data: ' + data);
    return data;
  }

  public class OrderDetail{

    @AuraEnabled
    public Date orderDate;

    @AuraEnabled
    public Date fulfillmentDate;

    @AuraEnabled
    public String orderNumber;

    @AuraEnabled
    public String poNumber;

    @AuraEnabled
    public String quoteNumber;

    @AuraEnabled
    public Double orderAmount;

    @AuraEnabled
    public String billToContact;
    
    @AuraEnabled
    public String partner;

    @AuraEnabled
    public String endUser;

    @AuraEnabled
    public String serialNumbers;

    @AuraEnabled
    public String url;

    public OrderDetail() {}
  }
}