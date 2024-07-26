@isTest
public class DynamicRelatedListControllerTest {
 
    @isTest public static void testInit(){
        Account acc = new Account(Name = 'test');
        insert acc;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;
                
        Map<String, Object> requestMap = new Map<String, Object>(); 
        requestMap.put(DynamicRelatedListController.FIELDS_PARAM, 'Name, Title, Email, Phone');
        requestMap.put(DynamicRelatedListController.RELATED_FIELD_API_NAME_PARAM, 'AccountId');
        requestMap.put(DynamicRelatedListController.RECORD_ID_PARAM, acc.Id);
        requestMap.put(DynamicRelatedListController.NUMBER_OF_RECORDS_PARAM, 1);
        requestMap.put(DynamicRelatedListController.SOBJECT_API_NAME_PARAM, 'Contact');
        requestMap.put(DynamicRelatedListController.SORTED_BY_PARAM, 'Name');
        requestMap.put(DynamicRelatedListController.SORTED_DIRECTION_PARAM, 'ASC');
                
        String jsonData = DynamicRelatedListController.initData(JSON.serialize(requestMap));
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        List<Object> records = (List<Object>)responseMap.get(DynamicRelatedListController.RECORDS_PARAM);
        System.assert(!records.isEmpty());
        String iconName = (String)responseMap.get(DynamicRelatedListController.ICON_NAME_PARAM);
        System.assert(String.isNotBlank(iconName));
    }


}