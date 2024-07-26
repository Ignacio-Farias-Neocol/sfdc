@IsTest
private class DynamicPicklistValues_utilityTest{

    @IsTest
    public static void unitTest() {
        DynamicPicklistValues_utility.getPickValues('Case','Status','-None-');
        DynamicPicklistValues_utility.getPickValuesMap('Case','Status','-None-');
        DynamicPicklistValues_utility.getPickValuesMapApiasKey('Case','Status','-None-');
    }
}