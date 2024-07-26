@isTest
private class MergePatternConfigControllerTest
{
    @isTest static void testMergePatternConfig()
    {
        MergePatternConfigController controller = new MergePatternConfigController();
        controller.initMergePatterns();
        controller.saveMergePatterns();

        Integer total = controller.Patterns.size();
        delete [select Id from MergePattern__c limit 1];
        controller.initMergePatterns();
        controller.saveMergePatterns();
        System.assertEquals(total, controller.Patterns.size());
    }
}