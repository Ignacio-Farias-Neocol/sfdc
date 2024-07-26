/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-09
* @description   Unit Test class for RelatedObjectPicklist
* @group         Test
*
*/

@isTest
public with sharing class RelatedObjectPicklistTest {

    @isTest static void unitTest() {

        VisualEditor.DesignTimePageContext context  = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Account';
        RelatedObjectPicklist  picklist = new RelatedObjectPicklist(context);
        VisualEditor.DataRow row = picklist.getDefaultValue();
        VisualEditor.DynamicPickListRows rows = picklist.getValues();

        Object attr = 'Name';
        String label = picklist.getLabel(attr);
        Boolean isValid = picklist.isValid(attr);



    }


}