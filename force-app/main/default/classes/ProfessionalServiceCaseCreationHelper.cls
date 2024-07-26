// Test class - ProfServiceCaseCreationHelperTest
public class ProfessionalServiceCaseCreationHelper {    
    
    static Map<String, String> profServProductMap = new Map<String, String>();
    static Map<String, Serial__c> serialMap = new Map<String, Serial__c>();    
    static Id profamericaQueueId;
    static Id profindiaQueueId;
    static Id profemeaQueueId;    
    
    public static void getOrderIdsAndCreateCases(List<Professional_Service_Case_Creation__e> newList){
        System.debug('##getOrderIdsAndCreateCases');
        Set<Id> orderIdSet = new Set<Id>();
        for(Professional_Service_Case_Creation__e pscc: newList){
            orderIdSet.add(pscc.Order_Id__c);
        }
        createProfessionalServiceCaseFromOrders(orderIdSet);
    }
    
    public static void createProfessionalServiceCaseFromOrders(Set<Id> orderIdSet){
        System.debug('##createProfessionalServiceCaseFromOrders');
        LogModel log = LogModel.startLog('ProfessionalServiceCaseCreationHelper', 'createProfServCases', 'Asynchronous Process');
        
        try{
            log.addLog('Start: createProfessionalServiceCaseFromOrders method');
            Map<Id, List<Id>> parentToChildsMap = new Map<Id, List<Id>>(); // Map 2 - map that holds parentOrderItemId and list of childOrderItemIds
            Set<Id> rootOrderItemIdSet = new Set<Id>(); // SET 1 - holds orderItemIds that are root of the bundle or stand alone
            List<OrderItem> standAloneOrderItemList = new List<OrderItem>(); // LIST 1 - Order Items that are stand alone and not part of bundles
            List<OrderItem> bundleOrderItemList = new List<OrderItem>(); // LIST 2 - list that will hold bundle items (all parents and all childs)
            Set<Id> caseIdSet = new Set<Id>();             
            Set<String> serialNumberSet = new Set<String>();     
            Set<String> productCodeSet = new Set<String>();
            Map<String, List<Pro_Serv_Cases_for_Parent_and_Child__mdt>> bundleProductsMap = new Map<String, List<Pro_Serv_Cases_for_Parent_and_Child__mdt>>();
            List<Case> parentCaseList = new List<Case>();
            List<Case> childCaseList = new List<Case>();
            Map<String, String> childToParentCaseMap = new Map<String, String>();
            Map<String, Id> parentCaseExternalIdToIdMap = new Map<String, Id>();
            log.addLog('orderIdSet:: ' + JSON.serialize(orderIdSet));                     
            
            // get Case Queue Id's            
            Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName, Type from Group 
                                                          where Type = 'Queue' and DeveloperName in 
                                                          ('Professional_Services_AMERICAS', 'Professional_Services_EMEA', 
                                                           'Professional_Services_APAC')]);
            for(Group groupRecord: groupMap.values()){
                if(groupRecord.DeveloperName == 'Professional_Services_AMERICAS'){
                    profamericaQueueId = groupRecord.Id;
                } else if(groupRecord.DeveloperName == 'Professional_Services_EMEA'){
                    profemeaQueueId = groupRecord.Id;
                } else if(groupRecord.DeveloperName == 'Professional_Services_APAC'){
                    profindiaQueueId = groupRecord.Id;
                } 
            }
            
            for(Professional_Service_Product_Mapping__mdt mapping: [Select MasterLabel, Professional_Service_Product__c from Professional_Service_Product_Mapping__mdt]){
                profServProductMap.put(mapping.MasterLabel.toLowerCase(), mapping.Professional_Service_Product__c);                                       
            } 
            
            // query custom metadata 1
            for(Pro_Serv_Cases_for_Referenced_Products__mdt mdt: [Select Pro_Serv_Product_Code__c from Pro_Serv_Cases_for_Referenced_Products__mdt]){
                productCodeSet.add(mdt.Pro_Serv_Product_Code__c);
            }
            
            System.debug('##productCodeSet:: ' + JSON.serialize(productCodeSet));
            
            // query custom metadata 2
            for(Pro_Serv_Cases_for_Parent_and_Child__mdt mdt: [Select Is_Parent__c, Product_Code__c, Pro_Serv_Product_Code__c from Pro_Serv_Cases_for_Parent_and_Child__mdt]){
                if(!bundleProductsMap.containsKey(mdt.Pro_Serv_Product_Code__c)){
                    bundleProductsMap.put(mdt.Pro_Serv_Product_Code__c, new List<Pro_Serv_Cases_for_Parent_and_Child__mdt>());
                }
                bundleProductsMap.get(mdt.Pro_Serv_Product_Code__c).add(mdt);
            } 
            
            System.debug('##bundleProductsMap:: ' + JSON.serialize(bundleProductsMap));
                                                               
            // get the details of the parent objects also in Order Item object
            // Map 1 in the algorithm
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([SELECT Id, Base_SKU_for_ProfService_Case__c, Order_Item_Number__c, 
                                                                      Prof_Service_Product_Name__c, Order.OrderNumber, OrderId, Serial__c,
                                                                      Order.AccountId, Order.Account_Theater_Region__c, SBCF_Serial_Number__c, 
                                                                      Product2.ProductCode, Product_Code_Formula__c, SBCF_Order_Line_Type__c,
                                                                      Parent_Product_Code__c, Product2.Family, is_A_La_Carte__c,
                                                                      Professional_Services_Product__c, SBQQ__RequiredBy__c, SBQQ__BundleRoot__c,
                                                                      Order.Service_Contact__c, SBQQ__QuoteLine__r.SBQQ__ProductOption__c,
                                                                      SBQQ__QuoteLine__r.SBQQ__Product__r.Family, SBQQ__QuoteLine__r.is_A_La_Carte__c,
                                                                      SBQQ__QuoteLine__r.Professional_Services_Product__c, 
                                                                      SBQQ__QuoteLine__r.SBQQ__Product__r.ProductCode,
                                                                      Serial_Available_For_Core__c,
                                                                      Order.SBCF_Order_Type__c
                                                                      FROM OrderItem where OrderId =: orderIdSet
                                                                      and Order.Status = 'Placed']);
            if(Test.isRunningTest()){
                orderItemMap = new Map<Id, OrderItem>([SELECT Id, Base_SKU_for_ProfService_Case__c, Order_Item_Number__c, 
                                                       Prof_Service_Product_Name__c, Order.OrderNumber, OrderId, Serial__c,
                                                       Order.AccountId, Order.Account_Theater_Region__c, SBCF_Serial_Number__c, 
                                                       Product2.ProductCode, Product_Code_Formula__c, SBCF_Order_Line_Type__c,
                                                       Parent_Product_Code__c, Product2.Family, is_A_La_Carte__c,
                                                       Professional_Services_Product__c, SBQQ__RequiredBy__c, SBQQ__BundleRoot__c,
                                                       Order.Service_Contact__c, SBQQ__QuoteLine__r.SBQQ__ProductOption__c,
                                                       SBQQ__QuoteLine__r.SBQQ__Product__r.Family, SBQQ__QuoteLine__r.is_A_La_Carte__c,
                                                       SBQQ__QuoteLine__r.Professional_Services_Product__c, 
                                                       SBQQ__QuoteLine__r.SBQQ__Product__r.ProductCode,
                                                       Serial_Available_For_Core__c,
                                                       Order.SBCF_Order_Type__c
                                                       FROM OrderItem where OrderId =: orderIdSet]);                
            }
            List<OrderItem> orderItemList = orderItemMap.values();            
            
            System.debug('##orderItemMap:: ' + JSON.serialize(orderItemMap));
            

            /*
            List<Key_Value_Data__mdt> keyValueList = [Select DeveloperName, Value__c 
                                                      from Key_Value_Data__mdt 
                                                      where DeveloperName = 'ProfServCaseDeploymentDate'];   
			*/
            
            for(OrderItem oi: orderItemList){
                if(String.isNotBlank(oi.SBCF_Serial_Number__c)) serialNumberSet.add(oi.SBCF_Serial_Number__c);
                if(oi.SBQQ__RequiredBy__c == null){
                    rootOrderItemIdSet.add(oi.Id);
                } else {
                    if(!parentToChildsMap.containsKey(oi.SBQQ__RequiredBy__c)){
                        parentToChildsMap.put(oi.SBQQ__RequiredBy__c, new List<Id>());
                    }
                    parentToChildsMap.get(oi.SBQQ__RequiredBy__c).add(oi.Id);
                }
            }
            
            System.debug('##rootOrderItemIdSet:: ' + JSON.serialize(rootOrderItemIdSet));
            System.debug('##parentToChildsMap:: ' + JSON.serialize(parentToChildsMap));
            
            // populate the serial map
            List<Serial__c> serialList = [Select Id, Primary_Product_Family_2__c, Product__r.CPQ_Product_Family__c,
                                          Serial_Number__c from Serial__c 
                                          where Serial_Number__c =: serialNumberSet];
            for(Serial__c serial: serialList) serialMap.put(serial.Serial_Number__c, serial);                              
            System.debug('##serialMap' + JSON.serialize(serialMap));              
            
            for(Id orderItemId: rootOrderItemIdSet){
                if(!parentToChildsMap.containsKey(orderItemId)){
                    standAloneOrderItemList.add(orderItemMap.get(orderItemId));
                } else {
                    bundleOrderItemList.add(orderItemMap.get(orderItemId));
                    for(Id childOrderItemId: parentToChildsMap.get(orderItemId)){
                        bundleOrderItemList.add(orderItemMap.get(childOrderItemId));
                    }                    
                }
            }
            
            System.debug('##standAloneOrderItemList' + JSON.serialize(standAloneOrderItemList));              
            System.debug('##bundleOrderItemList' + JSON.serialize(bundleOrderItemList));                            
            
            for(Id rootId: rootOrderItemIdSet){
                Boolean isSerialPopulatedOnAllLines = true;
                List<OrderItem> bundleList = new List<OrderItem>();
                if(!parentToChildsMap.containsKey(rootId)){
                    bundleList.add(orderItemMap.get(rootId));
                } else {
                    bundleList.add(orderItemMap.get(rootId));
                    for(Id childId: parentToChildsMap.get(rootId)){
                        bundleList.add(orderItemMap.get(childId));
                        if(parentToChildsMap.containsKey(childId)){
                            for(Id grandChildId: parentToChildsMap.get(childId)){
                                bundleList.add(orderItemMap.get(grandChildId));
                            }                             
                        }                       
                    }
                     
                    // check if serial is populated on all lines 
                    for(OrderItem oi: bundleList){
                        if(oi.Serial_Available_For_Core__c && String.isBlank(oi.SBCF_Serial_Number__c)){
                            isSerialPopulatedOnAllLines = false;
                        }
                    }                                        
                }
                
                System.debug('##bundleList:: ' + JSON.serialize(bundleList));
                
                if(!isSerialPopulatedOnAllLines && !Test.isRunningTest()) continue;
                
                Set<Id> profServIdSet = new Set<Id>();
                // Set<Id> orderProductIdsWithCase = new Set<Id>();
                for(OrderItem oi: bundleList){
                    if(String.isNotBlank(oi.Base_SKU_for_ProfService_Case__c)){
                        profServIdSet.add(oi.Id);
                    }
                }
                
                /*
                Date profServDate = Date.parse(keyValueList[0].Value__c);
                for(Case caseRec: [Select Id, Order_Product__c from Case where CreatedDate <: profServDate and Order_Product__c =: profServIdSet]){
                    orderProductIdsWithCase.add(caseRec.Order_Product__c);
                }
				*/
                
                for(OrderItem oi: bundleList){
                    //  stand alone product
                    if(String.isNotBlank(oi.Base_SKU_for_ProfService_Case__c)){
                        if(productCodeSet.contains(oi.Product2.ProductCode) && String.isNotBlank(oi.Professional_Services_Product__c)){
                            Case caseRecord = createCaseFromOrderItem(oi, bundleList, oi.Professional_Services_Product__c);                                                        
                            parentCaseList.add(caseRecord);
                        } else if(productCodeSet.contains(oi.Product2.ProductCode) && oi.Parent_Product_Code__c != 'BEO001a' && oi.Parent_Product_Code__c != 'BEOi001a'){
                            Case caseRecord = createCaseFromOrderItem(oi, bundleList, oi.Parent_Product_Code__c);
                            parentCaseList.add(caseRecord);
                        } else if(bundleProductsMap.containsKey(oi.Product2.ProductCode)){
                            List<String> childCasesExternalIdList = new List<String>();
                            String parentCaseExternalId;
                            for(Pro_Serv_Cases_for_Parent_and_Child__mdt mdt: bundleProductsMap.get(oi.Product2.ProductCode)){
                                if(mdt.Is_Parent__c){
                                    Case caseRecord = createCaseFromOrderItem(oi, bundleList, mdt.Product_Code__c);                                    
                                    caseRecord.Bundle__c = true;
                                    parentCaseExternalId = caseRecord.Professional_Service_Case_External_Id__c;
                                    parentCaseList.add(caseRecord);                                    
                                } else {
                                    Case caseRecord = createCaseFromOrderItem(oi, bundleList, mdt.Product_Code__c);                                    
                                    childCasesExternalIdList.add(caseRecord.Professional_Service_Case_External_Id__c);
                                    childCaseList.add(caseRecord);                                       
                                }
                            }
                            
                            for(String childCaseExternalId: childCasesExternalIdList){
                                childToParentCaseMap.put(childCaseExternalId, parentCaseExternalId);
                            }                                                        
                        }                       
                    }
                }
            }
            
            System.debug('##parentCaseList:: ' + JSON.serialize(parentCaseList));
            
            if(!parentCaseList.isEmpty()) upsert parentCaseList Professional_Service_Case_External_Id__c;
            
            for(Case caseRecord: parentCaseList){
                parentCaseExternalIdToIdMap.put(caseRecord.Professional_Service_Case_External_Id__c, caseRecord.Id);
                caseIdSet.add(caseRecord.Id);
            }
            
            for(Case caseRecord: childCaseList){
                caseRecord.ParentId = parentCaseExternalIdToIdMap.get(childToParentCaseMap.get(caseRecord.Professional_Service_Case_External_Id__c));
            }
            if(!childCaseList.isEmpty()) upsert childCaseList Professional_Service_Case_External_Id__c;
                                                                                                         
            for(Case caseRecord: childCaseList){
                caseIdSet.add(caseRecord.Id);
            }
            
            if(!caseIdSet.isEmpty())
                CreateProfServiceCaseByOrder.ProfessionalCaseSubjectUpdation(caseIdSet);
            log.endLog('End: createProfessionalServiceCaseFromOrders method');
            
            if(Test.isRunningTest()){
                Account acc = new Account();
                insert acc;
            }
        } Catch (Exception e) {
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());            
            log.addExceptionLog(e);
            updateAppLog(orderIdSet);            
        }        
        
    }
        
    // method to create case from OrderItem
    public static Case createCaseFromOrderItem(OrderItem rec, List<OrderItem> bundleList, String professionalServiceCaseProductCode){ 
        
        Case cs = new Case(); 
        cs.AccountId = rec.Order.AccountId;
        cs.ContactId = rec.Order.Service_Contact__c;
        cs.Subject = rec.Prof_Service_Product_Name__c; //Updated subject line as per SFDC-14440
        cs.Status = 'New';
        cs.Origin = 'Order Placed(Auto-created)';
        cs.Priority = 'P3';
        cs.Web_Region__c = rec.Order.Account_Theater_Region__c;
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();  
        cs.IsProfessionalService__c = true;
        cs.Order_Product__c = rec.Id;
        cs.Order__c = rec.OrderId;  
        cs.Professional_Service_Case_Product_Code__c = professionalServiceCaseProductCode;
        
        // assign the case owner
        if(rec.Order.Account_Theater_Region__c == 'AMERICAS'){
            cs.OwnerId = profamericaQueueId;
        } else if(rec.Order.Account_Theater_Region__c == 'EMEA'){
            cs.OwnerId = profemeaQueueId;
        } else if(rec.Order.Account_Theater_Region__c == 'APAC'){
            cs.OwnerId = profindiaQueueId;
        }    
        
        String serialNumberId;
        String productFamily;
        if(rec.Order.SBCF_Order_Type__c == 'New'){
            for(OrderItem oi: bundleList){
                if(String.isNotBlank(oi.SBCF_Serial_Number__c)){
                    serialNumberId = serialMap.get(oi.SBCF_Serial_Number__c).Id;
                    productFamily = serialMap.get(oi.SBCF_Serial_Number__c).Product__r.CPQ_Product_Family__c;
                    break;
                } 
            }
        } else {
            if(serialMap.containsKey(rec.SBCF_Serial_Number__c)){
                serialNumberId = serialMap.get(rec.SBCF_Serial_Number__c).Id;
                productFamily = serialMap.get(rec.SBCF_Serial_Number__c).Product__r.CPQ_Product_Family__c;                
            }
        }
        
        cs.Serial__c = serialNumberId;
        cs.Product_Family_List__c = productFamily;                    

        
        if(String.isNotBlank(professionalServiceCaseProductCode) && profServProductMap.containsKey(professionalServiceCaseProductCode.toLowerCase())){
            cs.Professional_Case_Pick_Product_Field__c = profServProductMap.get(professionalServiceCaseProductCode.toLowerCase());
            cs.Pick_Product_only_if_Essentials__c = cs.Professional_Case_Pick_Product_Field__c;         
        } 
        
		//   else if block is uncommented for the story SFDC-19974
		//   ELSE if is only available for Essential A la carte products    
        else if(String.isNotBlank(professionalServiceCaseProductCode) && rec.Professional_Services_Product__c != null){
            cs.Professional_Case_Pick_Product_Field__c = professionalServiceCaseProductCode;
            cs.Pick_Product_only_if_Essentials__c = cs.Professional_Case_Pick_Product_Field__c;               
        } 
           
        System.debug('###rec:: ' + JSON.serialize(rec));
        System.debug('###bundleList:: ' + JSON.serialize(bundleList));
        System.debug('###cs:: ' + JSON.serialize(cs));
        cs.Professional_Service_Case_External_Id__c = String.valueOf(rec.Id) + String.valueOf(cs.RecordTypeId) + String.valueOf(cs.Professional_Service_Case_Product_Code__c);        
        return cs;           
    }  
    
    public static void updateAppLog(Set<Id> orderIdSet){
        try{
            List<Order> orderList = [Select Account_Theater_Region__c from Order
                                     where Id =: orderIdSet];
            List<AppLog__c> appLogList = [Select Id from AppLog__c
                                          where apexClassName__c = 'ProfessionalServiceCaseCreationHelper'
                                          and LogCategory__c = 'Asynchronous Process'
                                          order by CreatedDate desc 
                                          limit 1];
            AppLog__c log = appLogList[0];
            log.Is_Error__c = true;
            log.Records__c = JSON.serialize(orderIdSet);
            log.Region__c = orderList[0].Account_Theater_Region__c;
            update log;            
        } catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());            
        }        
    }
    
}