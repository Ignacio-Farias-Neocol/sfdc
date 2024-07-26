/**
 * @description       : 
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 06-28-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public class TimeMeasurementTest {

    @isTest(SeeAllData= true)
    public static void testMethodExecutionTime() {
        // Start time
        Datetime startTime = Datetime.now();

        // The method or code block you want to test
        //testMethodFlow();

        // End time
        Datetime endTime = Datetime.now();

        // Calculate the time difference in milliseconds
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();


        // Output the execution time
        System.debug('Execution time: ' + executionTimeInMillis/1000 + ' s');
    }

    // @isTest(SeeAllData= true)
    // public static void testMethodFlow() {

    //     List<Opportunity> oppList = [SELECT Id, AccountId, CloseDate FROM Opportunity Where AccountId != null LIMIT 10];
    //     for(Opportunity opp : oppList){
    //         Map<String, Object> params = new Map<String, Object>();
    //         params.put('Opportunity_Id', opp.Id);
    //         params.put('Account_Id', opp.AccountId);
    //         params.put('Curr_Oppty_Closed_Date', opp.CloseDate);
    //         Flow.Interview.Default_Opportunity_Type Send_Sub_Cert_Update = new Flow.Interview.Default_Opportunity_Type(params);
    //     }

    // }
}
