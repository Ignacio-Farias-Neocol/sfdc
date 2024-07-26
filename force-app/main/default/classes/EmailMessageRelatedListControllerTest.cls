@isTest
public with sharing class EmailMessageRelatedListControllerTest {
    @isTest public static void testInit(){
       
        Account acc = new Account();
        acc.name ='Test Account';
        insert acc;
                
        Map<String, Object> requestMap = new Map<String, Object>(); 
        requestMap.put(EmailMessageRelatedListController.FIELDS_PARAM, 'Subject');
        requestMap.put(EmailMessageRelatedListController.RELATED_FIELD_API_NAME_PARAM, 'RelatedToId');
        requestMap.put(EmailMessageRelatedListController.RECORD_ID_PARAM, acc.Id);
        requestMap.put(EmailMessageRelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap.put(EmailMessageRelatedListController.SOBJECT_API_NAME_PARAM, 'EmailMessage');
        requestMap.put(EmailMessageRelatedListController.SORTED_BY_PARAM, 'Subject');
        requestMap.put(EmailMessageRelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData = EmailMessageRelatedListController.initData(JSON.serialize(requestMap));
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        List<Object> records = (List<Object>)responseMap.get(EmailMessageRelatedListController.RECORDS_PARAM);
    }
}