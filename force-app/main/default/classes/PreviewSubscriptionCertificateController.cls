public class PreviewSubscriptionCertificateController {

    private final Order OrderRec;

    public PreviewSubscriptionCertificateController() {
        System.debug('Order id in preview class...'+ApexPages.currentPage().getParameters().get('id'));
        OrderRec = [SELECT Id, 
        Account.Name, 
        PoNumber, 
        SBQQ__Quote__r.Name,
        TotalAmount,
        Bill_To_Contact__c,
        Active_Contract__r.Reseller__r.Name,
        Active_Contract__r.Distributor__r.Name,
        End_User_Contact__r.Name FROM Order WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
    }

    public Order getOrderRec() {
        return OrderRec;
    }

}