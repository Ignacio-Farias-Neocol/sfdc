/**
 * Created by iyeung on 2019-04-26.
 */
@IsTest
public class TerritoryPreprocessorBatchTest {


    @IsTest
    static void setup() {

        // to do: add setup on data
    }


    @isTest(SeeAllData=true)
    static void unitTest() {


        TerritoryPreprocessorBatch.executeBatch();

    }

    @isTest static void unitTestSchedueable() {

        Test.StartTest();
        TerritoryPreprocessorBatch m = new TerritoryPreprocessorBatch();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('Territory Update Job', sch, m);
        Test.StopTest();
        m.finish(null);
        system.debug('Job ID: ' + jobID);

    }


}