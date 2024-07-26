/**
* @author       Rajesh Wani     
* @date          2024-01-23
*                
* @description   Schedule Class for Apex class :LegacySerialDataFixBatch, Legacy serial data which are RMA with new Serial in BOSS
*
*/
global class LegacySerialDataFixBatchSchd implements Schedulable{
    global void execute(SchedulableContext sc) {
        LegacySerialDataFixBatch leObj =  new LegacySerialDataFixBatch();
		database.executeBatch(leObj,1);
    }
}