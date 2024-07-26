global class ReCalculateQuotePricesSched implements Schedulable {
    global void execute(SchedulableContext ctx) {
       ReCalculateQuotePrices batch=new ReCalculateQuotePrices();
       
       Id batchId = Database.executeBatch(batch,1);
       
       System.debug('ReCalculateQuotePrices with batch Id' + batchId + 'executed');
       
    }
}