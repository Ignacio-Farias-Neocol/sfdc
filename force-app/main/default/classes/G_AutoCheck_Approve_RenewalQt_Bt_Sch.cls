/**
 * Created by Dilowar Hussain on 08/06/2011.
 *
 *  @Date 2022/06/08
 *  @group Schedulable
 *
 *  Description:
 *  This is Scheduler class for the batch G_AutoCheck_Approve_RenewalQuote_Batch.
 *  
 *  
 *  Added as a part of SFDC-16741 and SFDC-17358
 */
global with sharing class G_AutoCheck_Approve_RenewalQt_Bt_Sch implements Schedulable{
    /******
     * Method: Execute
     */
    global void execute(SchedulableContext ctx) {
        G_AutoCheck_Approve_RenewalQuote_Batch bt = new G_AutoCheck_Approve_RenewalQuote_Batch();
          database.executeBatch(bt, 1);
     }   
}