//SFDC-17142
//Custom Queueable Object to update Contract
public without sharing class RenewalCheckoutOrderActivatedQueueable implements Queueable{
    //Member variables
    private String orderId;
    private String opptyId;
    private Boolean autoRenew;
    
    public RenewalCheckoutOrderActivatedQueueable(String recId, Boolean autoRenew) {
        if(recId.startsWithIgnoreCase('006')) {
            this.opptyId = recId;
            this.orderId = [SELECT Id FROM Order WHERE OpportunityId = :recId LIMIT 1].Id;
        } else if(recId.startsWithIgnoreCase(Order.SObjectType.getDescribe().getKeyPrefix())) {
            this.orderId = recId;
        }
        this.autoRenew = autoRenew == true ? true : false;
    }
    
    public void execute(QueueableContext context) {
        try {
            orderActivated();
        } catch (Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
            LogModel.singleLog('RenewalCheckoutHelper', 'processOrderAsync. Error: ' + e.getStackTraceString(), LogModel.LOG_CATEGORY_APEX);
        }
    }
    
    public void orderActivated() {
        System.debug('OrderId: ' + this.orderId);
        
        Order order =   [
            SELECT
            Id,
            Status,
            Active_Contract__c,
            SBQQ__Contracted__c,
            Bill_To_Account__c,
            Bill_To_Contact__c,
            Bill_To_Contact_Email__c,
            BillingStreet,
            BillingCity,
            BillingCountry,
            BillingCountryCode,
            BillingPostalCode,
            Ship_To_Account__c,
            Ship_To_Contact__c,
            Ship_To_Contact_Email__c,
            ShippingStreet,
            ShippingCity,
            ShippingCountry,
            ShippingCountryCode,
            ShippingPostalCode,
            OpportunityId,
            Opportunity.OwnerId,
            Billing_Address__c,
            PoNumber,
            Opportunity.Billing_Address__c,
            Opportunity.Billing_Address__r.Street__c,
            Opportunity.Billing_Address__r.City__c,
            Opportunity.Billing_Address__r.Country_Name__c,
            Opportunity.Billing_Address__r.Country_ISO__c,
            Opportunity.Billing_Address__r.Zip_Postal_Code__c,
            Opportunity.Bill_To_Account__c,
            Opportunity.Bill_To_Account__r.Bill_To_Email__c,
            Opportunity.Bill_To_Account__r.Bill_To_Contact__c,
            Opportunity.Shipping_Address__c,
            Opportunity.Shipping_Address__r.Street__c,
            Opportunity.Shipping_Address__r.City__c,
            Opportunity.Shipping_Address__r.Country_Name__c,
            Opportunity.Shipping_Address__r.Country_ISO__c,
            Opportunity.Shipping_Address__r.Zip_Postal_Code__c,
            Opportunity.Ship_To_Account__c,
            Opportunity.Ship_To_Account__r.Ship_To_Email__c,
            Opportunity.Ship_To_Account__r.Ship_To_Contact__c,
            Opportunity.PurchaseOrderID__c,
            SBQQ__Quote__r.SBCF_Order_Type__c
            FROM Order
            WHERE Id = :this.orderId
            LIMIT 1
        ];

        if (order.Opportunity.PurchaseOrderID__c != null) {
            order.PoNumber = order.Opportunity.PurchaseOrderID__c;
        }
        //Added logic to populate Bill to and ship to info on order from oppty
        
        order.Billing_Address__c = order.Opportunity.Billing_Address__c;
        order.Shipping_Address__c = order.Opportunity.Shipping_Address__c;
        order.Bill_To_Account__c = order.Opportunity.Bill_To_Account__c;
        order.Bill_To_Contact__c = order.Opportunity.Bill_To_Account__r.Bill_To_Contact__c;
        order.Bill_To_Contact_Email__c = order.Opportunity.Bill_To_Account__r.Bill_To_Email__c;
        order.BillingStreet = order.Opportunity.Billing_Address__r.Street__c;
        order.BillingCity = order.Opportunity.Billing_Address__r.City__c;
        order.BillingCountry = order.Opportunity.Billing_Address__r.Country_Name__c;
        order.BillingCountryCode = order.Opportunity.Billing_Address__r.Country_ISO__c;
        order.BillingPostalCode = order.Opportunity.Billing_Address__r.Zip_Postal_Code__c;
        
        order.Ship_To_Account__c = order.Opportunity.Ship_To_Account__c;
        order.Ship_To_Contact__c = order.Opportunity.Ship_To_Account__r.Ship_To_Contact__c;
        order.Ship_To_Contact_Email__c = order.Opportunity.Ship_To_Account__r.Ship_To_Email__c;
        order.ShippingStreet = order.Opportunity.Shipping_Address__r.Street__c;
        order.ShippingCity = order.Opportunity.Shipping_Address__r.City__c;
        order.ShippingCountry = order.Opportunity.Shipping_Address__r.Country_Name__c;
        order.ShippingCountryCode = order.Opportunity.Shipping_Address__r.Country_ISO__c;
        order.ShippingPostalCode = order.Opportunity.Shipping_Address__r.Zip_Postal_Code__c;
        order.OwnerId = order.Opportunity.OwnerId;
        order.SBCF_Order_Type__c = order.SBQQ__Quote__r.SBCF_Order_Type__c;
        order.Status = 'Activated';
        order.Portal_Placed_Order__c = true;
        order.Auto_Renewal_Flag__c = this.autoRenew;
        update order;
        
        //Unable to see the managed package SBQQ.QueueableJobChckerExt. However it seems order.SBQQ__Contracted__c
        //cannot be set to true unless the order.Status was originally = 'Activated'
        //order.SBQQ__Contracted__c = true;
        //update order;
        //Can't update the contract. Async process creates the Contract when order.SBQQ__Contracted__c is set to true
        // Contract contract = [
        //     SELECT Id
        //     FROM Contract
        //     WHERE SBQQ__Order__c =: order.Id
        //     LIMIT 1
        // ];
        
        // contract.OwnerId = order.Opportunity.OwnerId;
        // update contract;
    }
    
}