public without sharing class CaseModelBeforeUpdateHelper {
    
    public class SerialWrapper {
        Id serialId {get; set;}
        String baseProductSku {get; set;}
        Product2 productObj {get; set;}
    }
    
    // All the fast field updates in before update context needs to added here
    public static void processRecords(List<Case> newList, Map<Id, Case> oldMap){
        LogModel log = LogModel.startLog('CaseModelBeforeUpdateHelper', 'processRecords');
        try {
            Map<Id, Contact> contactMap = new Map<Id, Contact>();          
            List<Case> ownerUpdatedCaseList = new List<Case>();
            Map<Id, Case> caseMap = new Map<Id, Case>();
            Map<Id, User> userMap = new Map<Id, User>();
            Map<Id, SerialWrapper> serialMap = new Map<Id, SerialWrapper>(); 
            Set<Id> emptyBaseProductSerialIdSet = new Set<Id>();
            Map<Id, Product2> serialProductMap = new Map<Id, Product2>();
            Set<String> baseProductSkuSet = new Set<String>();
            Map<String, SerialWrapper> baseProductSerialMap = new Map<String, SerialWrapper>();           
            
            for(Case caseRecord: newList){
                Case oldCase = oldMap.get(caseRecord.Id);
                if((caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID) && oldMap.get(caseRecord.Id).ContactId != CaseRecord.ContactId){
                    if(caseRecord.ContactId != null){
                        contactMap.put(caseRecord.ContactId, null);
                    }
                }
                
                System.debug(caseRecord.Serial__c+'caseRecord.Serial__c*****');
                
                if(caseRecord.Serial__c != oldCase.Serial__c && caseRecord.Serial__c != null && (caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.PROFESSIONAL_SERVICES_RECORD_TYPE_ID)){
                    serialMap.put(caseRecord.Serial__c, null);
                }  
                
                if(caseRecord.OwnerId != oldCase.OwnerId && String.valueOf(caseRecord.OwnerId).startsWith('005')){
                    caseMap.put(caseRecord.Id, null);
                    userMap.put(caseRecord.OwnerId, null);
                }
                
                if(caseRecord.OwnerId != oldCase.OwnerId && String.valueOf(oldCase.OwnerId).startsWith('00G')){
                    String previousOwnersString = caseRecord.Previous_Case_Owners_Queues__c + oldCase.OwnerId + ',';
                    if(previousOwnersString.length() <= 255){
                        caseRecord.Previous_Case_Owners_Queues__c = previousOwnersString;
                    }                     
                }
            }
            
            if(!contactMap.isEmpty()){
                contactMap = new Map<Id, Contact>([Select Id, Alternative_Email__c, Use_Alt_Email_for_Case__c from Contact where Id =: contactMap.keySet()]);
            }
            
            if(!caseMap.isEmpty()){
                caseMap = new Map<Id, Case>([Select Id, Account.Territory__c, Serial__r.Serial_Account_Territory__c from Case where Id =: caseMap.keySet()]);
            }
            
            if(!userMap.isEmpty()){
                userMap = new Map<Id, User>([Select Id, UserRole.Name from User where Id =: UserMap.keySet()]);
            }        
            
            if(!serialMap.isEmpty()){
                List<Serial__c> serialList = [Select Id, Product__c, Product__r.ProductCode, (Select Id from Assigned_Serials__r where Status__c = 'Active' Order by Subscription__c desc limit 1) from Serial__c where Id =: serialMap.keySet()];
                for(Serial__c ser:  serialList){                
                    if(String.isNotBlank(ser.Product__c) && String.isNotBlank(ser.Product__r.ProductCode)){
                        SerialWrapper serialWrapperObj = new SerialWrapper();
                        serialWrapperObj.serialId = ser.Id;
                        serialWrapperObj.baseProductSku = ser.Product__r.ProductCode;
                        baseProductSkuSet.add(ser.Product__r.ProductCode);
                        serialMap.put(ser.Id, serialWrapperObj);
                        baseProductSerialMap.put(ser.Product__r.ProductCode, serialWrapperObj);
                    } else {
                        if(ser.Assigned_Serials__r[0] != null)
                            emptyBaseProductSerialIdSet.add(ser.Assigned_Serials__r[0].Id);
                    }
                }                   
            }  
            
            if(!emptyBaseProductSerialIdSet.isEmpty()){
                for(Assigned_Serial__c assignedSerial: [Select Id, Name, Serial__c, Base_SKU__c from Assigned_Serial__c where Id =: emptyBaseProductSerialIdSet]){
                    SerialWrapper serialWrapperObj = new SerialWrapper();
                    serialWrapperObj.serialId = assignedSerial.Serial__c;
                    serialWrapperObj.baseProductSku = assignedSerial.Base_SKU__c;
                    baseProductSkuSet.add(assignedSerial.Base_SKU__c);
                    baseProductSerialMap.put(assignedSerial.Base_SKU__c, serialWrapperObj);
                    serialMap.put(assignedSerial.Serial__c, serialWrapperObj);                
                }
            }
            
            if(!baseProductSkuSet.isEmpty()){
                for(Product2 prod: [Select Id, Name, ProductCode, CPQ_Product_Family__c from Product2 where ProductCode =: baseProductSkuSet]){
                    SerialWrapper serialWrapperObj = baseProductSerialMap.get(prod.ProductCode);
                    serialWrapperObj.productObj = prod;
                    serialMap.put(serialWrapperObj.serialId, serialWrapperObj); 
                }
            }
            
            
            String emailRegex1 = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}+\\.[a-zA-Z]{2,9}$'; // source: http://www.regular-expressions.info/email.html
            String emailRegex2 = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}$';  
            Pattern pattern1 = Pattern.compile(emailRegex1);
            Pattern pattern2 = Pattern.compile(emailRegex2);          
            
            for(Case caseRecord: newList){
                Case oldCase = oldMap.get(caseRecord.Id);
                if((caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID) && oldMap.get(caseRecord.Id).ContactId != CaseRecord.ContactId){
                    if(caseRecord.ContactId != null){
                        // caseRecord.SuppliedEmail = contactMap.get(caseRecord.ContactId).Alternative_Email__c;
                        // caseRecord.Alt_Email_in_use__c = contactMap.get(caseRecord.ContactId).Use_Alt_Email_for_Case__c;
                        if(String.isNotBlank(contactMap.get(caseRecord.ContactId).Alternative_Email__c)){
                            String emailAddr = contactMap.get(caseRecord.ContactId).Alternative_Email__c;
                            if(pattern1.matcher(emailAddr).matches() || pattern2.matcher(emailAddr).matches()){
                                caseRecord.SuppliedEmail = emailAddr;
                            } else {
                                caseRecord.addError('Please ensure Contact has valid Alternative Email');
                            }                           
                        }                   
                        caseRecord.Alt_Email_in_use__c = contactMap.get(caseRecord.ContactId).Use_Alt_Email_for_Case__c;                    
                    }
                }
                                
                // When serial is changed
                 System.debug(caseRecord.Serial__c+'caseRecord.Serial__c*****');   
                    System.debug('****'+serialMap);
                    
                if(caseRecord.Serial__c != oldMap.get(caseRecord.Id).Serial__c && caseRecord.Serial__c != null && (caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.PROFESSIONAL_SERVICES_RECORD_TYPE_ID)){
                    if(serialMap.containskey(caseRecord.Serial__c) && serialMap.get(caseRecord.Serial__c) != null && serialMap.get(caseRecord.Serial__c).productObj != null){
                        caseRecord.Product_Family_List__c = serialMap.get(caseRecord.Serial__c).productObj.CPQ_Product_Family__c;
                        caseRecord.ProductId = serialMap.get(caseRecord.Serial__c).productObj.Id;   
                        
                        if(caseRecord.Product_Family_List__c == 'Essentials' && caseRecord.Pick_Product_only_if_Essentials__c != null){
                            // do nothing
                        } else if(caseRecord.Product_Family_List__c == 'Essentials' || caseRecord.Product_Family_List__c == 'Cloud Control') {
                            caseRecord.Pick_Product_only_if_Essentials__c = null;
                        } else {
                            caseRecord.Pick_Product_only_if_Essentials__c = caseRecord.Product_Family_List__c;
                        }                         
                    }
                }                   
                
                // when product family is changed
                if( caseRecord.Product_Family_List__c != oldCase.Product_Family_List__c && caseRecord.Product_Family_List__c != 'Sonian' && caseRecord.Product_Family_List__c != 'Barracuda Total Email Protection' && caseRecord.Sub_Reason__c != 'Files & Folders'){
                    if(caseRecord.Product_Family_List__c == 'Essentials' || caseRecord.Product_Family_List__c == 'Cloud Control'){
                        caseRecord.Closed_Case_Reason__c = null;
                        caseRecord.Case_Reason__c = null;
                        caseRecord.Pick_Product_only_if_Essentials__c = null;
                    } else {
                        caseRecord.Closed_Case_Reason__c = null;
                        caseRecord.Case_Reason__c = null;
                        caseRecord.Pick_Product_only_if_Essentials__c = caseRecord.Product_Family_List__c;                
                    }                
                }
                
                // when product family is essentials and pick product is changed
                if( caseRecord.Pick_Product_only_if_Essentials__c != oldCase.Pick_Product_only_if_Essentials__c && caseRecord.Product_Family_List__c == 'Essentials'){                    
                    caseRecord.Closed_Case_Reason__c = null;
                    caseRecord.Case_Reason__c = null;               
                }                
                
                if(caseMap.containsKey(caseRecord.Id)){
                    Case queriedCase = caseMap.get(caseRecord.Id);
                    User queriedUser = userMap.get(caseRecord.OwnerId);
                    if((queriedUser.UserRole.Name  == 'Technical Support - China' || queriedUser.UserRole.Name  == 'Director Support - China') && (queriedCase.Account.Territory__c != 'CHINA - TERRITORY' || (queriedCase.Serial__r.Serial_Account_Territory__c != null && queriedCase.Serial__r.Serial_Account_Territory__c != 'CHINA - TERRITORY'))){
                        caseRecord.addError('Can not assign case to user due to Territory restrictions');
                    }
                }
            }           
            
        } catch (Exception e) {
            log.addExceptionLog(e);
        }        
    }    
}