public without sharing class CaseModelBeforeInsertHelper {
    
    public class SerialWrapper {
        Id serialId {get; set;}
        String baseProductSku {get; set;}
        Product2 productObj {get; set;}
    }
    
    // All the fast field updates in before insert context needs to added here
    public static void processRecords(List<Case> newList){
        
        LogModel log = LogModel.startLog('CaseModelBeforeInsertHelper', 'processRecords');
        try {
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            Map<Id, SerialWrapper> serialMap = new Map<Id, SerialWrapper>(); 
            Set<Id> emptyBaseProductSerialIdSet = new Set<Id>();
            Map<Id, Product2> serialProductMap = new Map<Id, Product2>();
            Set<String> baseProductSkuSet = new Set<String>();
            Map<String, SerialWrapper> baseProductSerialMap = new Map<String, SerialWrapper>(); 
            Set<Id> opptyIdSet = new Set<Id>();       
            List<Case> listrequestquotecase = new List<Case>(); //SFDC-19161            
            
            for(Case caseRecord: newList){
                if(caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID){
                    if(caseRecord.ContactId != null){
                        contactMap.put(caseRecord.ContactId, null);
                    }
                }
                
                System.debug(caseRecord.Serial__c+'caseRecord.Serial__c*****');
                
                if(caseRecord.Serial__c != null && (caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.PROFESSIONAL_SERVICES_RECORD_TYPE_ID)){
                    serialMap.put(caseRecord.Serial__c, null);
                }            
            }
            
            if(!contactMap.isEmpty()){
                contactMap = new Map<Id, Contact>([Select Id, Alternative_Email__c, Use_Alt_Email_for_Case__c from Contact where Id =: contactMap.keySet()]);
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
                if(caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID){
                    if(caseRecord.ContactId != null && contactMap.get(caseRecord.ContactId).Use_Alt_Email_for_Case__c){
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
                    System.debug(caseRecord.Serial__c+'caseRecord.Serial__c*****');   
                    System.debug('****'+serialMap);
                            
                If(caseRecord.RecordTypeId == CaseModel.TECH_SUPPORT_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.WEB_MESSAGE_RECORD_TYPE_ID || caseRecord.RecordTypeId == CaseModel.PROFESSIONAL_SERVICES_RECORD_TYPE_ID){
                    if(caseRecord.Serial__c != null){                    
                        if(serialMap.containskey(caseRecord.Serial__c) && serialMap.get(caseRecord.Serial__c) != null && serialMap.get(caseRecord.Serial__c).productObj != null){
                            caseRecord.Product_Family_List__c = serialMap.get(caseRecord.Serial__c).productObj.CPQ_Product_Family__c;
                            caseRecord.ProductId = serialMap.get(caseRecord.Serial__c).productObj.Id;                                             
                        }                   
                    }
                    
                    if(caseRecord.Product_Family_List__c == 'Essentials' && caseRecord.Pick_Product_only_if_Essentials__c != null){
                        // do nothing
                    } else if(caseRecord.Product_Family_List__c == 'Essentials' || caseRecord.Product_Family_List__c == 'Cloud Control') {
                        caseRecord.Pick_Product_only_if_Essentials__c = null;
                    } else {
                        caseRecord.Pick_Product_only_if_Essentials__c = caseRecord.Product_Family_List__c;
                    }                     
                }  
                
                //Request Quote Creation from Opportunity - SFDC-19161
                if(caseRecord.RecordTypeId == CaseModel.REQUEST_QUOTE_RECORD_TYPE_ID && caseRecord.Opportunity_for_SE_Cases__c != NULL){
                    opptyIdSet.add(caseRecord.Opportunity_for_SE_Cases__c);
                    listrequestquotecase.add(caseRecord);
                }                
            }  
            
            if(opptyIdSet != null && opptyIdSet.size()>0){
                List<User> lstUser = [select id, name, email, username, profile.Name from User where name like '%Admin Salesforce%' and profile.Name like '%System Administrator%'];
                Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT Id,AccountId,Deal_Reg_Tracking_No__c,Deal_Reg_Type__c,Distributor__c,Terr_Theater__c,Payment_Terms__c,OwnerId,owner.isActive, Owner_s_Manager__c,Owner_s_Manager__r.isActive,Owner_s_Manager__r.Id,Reseller__c,Reseller_Contact_Email__c FROM Opportunity WHERE Id IN :opptyIdSet]);
                for(Case caseRecord : listrequestquotecase){
                  //  if(caseRecord.RecordTypeId == CaseModel.REQUEST_QUOTE_RECORD_TYPE_ID && caseRecord.Opportunity_for_SE_Cases__c != NULL){
                        caseRecord.AccountId = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).AccountId;
                        caseRecord.Deal_Reg_Tracking__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Deal_Reg_Tracking_No__c;
                        caseRecord.Deal_Registration__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Deal_Reg_Type__c;
                        caseRecord.Distributor__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Distributor__c;
                        caseRecord.Opportunity_Theatre__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Terr_Theater__c;
                        caseRecord.Payment_Terms__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Payment_Terms__c;
                        //caseRecord.Requested_By__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).OwnerId;
                        caseRecord.Requested_By__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Owner.isActive==true ? opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).OwnerId : ((opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Owner_s_Manager__c!=null && opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Owner_s_Manager__r.isActive)==true ? opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Owner_s_Manager__r.Id :lstUser[0].id);
                        caseRecord.Reseller__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Reseller__c;
                        caseRecord.Send_Quote_to__c = opptyMap.get(caseRecord.Opportunity_for_SE_Cases__c).Reseller_Contact_Email__c;
                        caseRecord.OwnerId = caseRecord.Opportunity_Theatre__c == 'AMERICAS' ? System.Label.AMERICAS_DEAL_Desk : caseRecord.Opportunity_Theatre__c == 'EMEA' ? System.Label.EMEA_DEAL_Desk : caseRecord.Opportunity_Theatre__c == 'APAC' ? System.Label.APAC_Deal_Desk : UserInfo.getUserId(); 
                    	//Added one extra assignment for Sales Review field for new RQ case insertion.
                    	//caseRecord.Sales_Review__c = caseRecord.Opportunity_Theatre__c == 'EMEA' || caseRecord.Opportunity_Theatre__c == 'APAC' ? 'Yes': NULL;
                    	caseRecord.Sales_Review__c = (caseRecord.Opportunity_Theatre__c == 'EMEA' || caseRecord.Opportunity_Theatre__c == 'APAC') ? 'Yes' : (caseRecord.Opportunity_Theatre__c != null ? caseRecord.Sales_Review__c : caseRecord.Sales_Review__c);

                    //}
                }
            }             
            
        } catch (Exception e) {
            log.addExceptionLog(e);
        }        
    }
    
}