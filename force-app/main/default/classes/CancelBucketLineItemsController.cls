public with sharing class CancelBucketLineItemsController {
    private Id quoteId;
  
    private Map<Id, SBQQ__QuoteLine__c> quoteLines; 
   
    private Map<Id, List<SBQQ__QuoteLine__c>> quoteLineBundleMap;
  
    public List<CancelBucketLineItemsController.QuoteLineSelection> quoteLineIds{get;set;}
  
    public String message {get;set;}
  
    transient List<Schema.FieldSetMember> fsmList;
  
    public Boolean testRunningFlag = false;
  
    public Map<Id, SBQQ__QuoteLine__c> getCancelBucketQL(){
        return quoteLines;
    }
  
    public List<Schema.FieldSetMember> getFSMList() {
      if(fsmList == null) {
        fsmList = SObjectType.SBQQ__QuoteLine__c.FieldSets.Cancel_Bucket_FieldSet.getFields();
      }
      return fsmList;
    }  
  
    public CancelBucketLineItemsController(ApexPages.StandardController controller) {
  
      try{        
        quoteId = controller.getId();  
      
        if(String.isBlank(quoteId)) {
       
          message = System.Label.Cancel_Bucket_Missing_QuoteId;
          return ;
        }
        
          if(quoteId != null) {
          quoteLines = new Map<Id, SBQQ__QuoteLine__c>();
          quoteLineBundleMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
  
        String query = 'SELECT Id,'+
        'SBQQ__Bundle__c,SBQQ__ProductName__c,SBQQ__ProductCode__c,SBQQ__Quantity__c,SBCF_Capacity_Unit__c,' +
        'SBQQ__ListPrice__c,ECHO_Unique_Identifier_Value__c,Terminate_Serials__c,SBQQ__RequiredBy__c,SBCF_Serial_Number__c';
  
        List<String> fieldsList = new List<String>();
  

        query +=  ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId';
  
          for(Cancel_Bucket_Lines_Filter__mdt additionalFilter : [SELECT QuoteLine_FieldName__c,
                                                                              Operator__c,
                                                                              Value__c 
                                                                      FROM Cancel_Bucket_Lines_Filter__mdt]){
            query += ' AND ' + additionalFilter.QuoteLine_FieldName__c + ' ' + additionalFilter.Operator__c + ' ' + additionalFilter.Value__c;
          }          
        
          query+= ' ORDER BY Name';
  
          system.debug('QUERY' +  query);  
        
          quoteLineIds = new List<CancelBucketLineItemsController.QuoteLineSelection>();  
      
          for(SBQQ__QuoteLine__c quoteLineRecord : Database.query(query)) {
            quoteLines.put(quoteLineRecord.Id, quoteLineRecord);
            quoteLineIds.add(new CancelBucketLineItemsController.QuoteLineSelection(false, quoteLineRecord.Id));  
          
            if(quoteLineBundleMap!=null && quoteLineRecord.SBQQ__RequiredBy__c!=null){
              if(quoteLineBundleMap.containsKey(quoteLineRecord.SBQQ__RequiredBy__c)){
                quoteLineBundleMap.get(quoteLineRecord.SBQQ__RequiredBy__c).add(quoteLineRecord);
              }
              else{
                quoteLineBundleMap.put(quoteLineRecord.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>{quoteLineRecord});
              }
            }
          } 
  
          if(quoteLineIds==null || quoteLineIds.isEmpty()){
            message = System.Label.Cancel_Bucket_No_Quote_Lines;
          }
        }     
      }
      catch(Exception e){
        message = System.Label.Cancel_Bucket_Fetch_Error + e.getMessage();
      }
    }
 
    public PageReference cancelBucketLineItems() {  
    
        try{

          List<SBQQ__QuoteLine__c> originalQuoteLinesToBeUpdated = new List<SBQQ__QuoteLine__c>();
        
          for(CancelBucketLineItemsController.QuoteLineSelection qlSelected: quoteLineIds){
            if(qlSelected.checkBox){
            
            SBQQ__QuoteLine__c ql_bucket = quoteLines.get(qlSelected.id);
                       
            System.debug('Bucket::' + ql_bucket );
            originalQuoteLinesToBeUpdated.add(new SBQQ__QuoteLine__c(Id = qlSelected.id,
                                                                       SBQQ__Quantity__c = 0,
                                                                       Terminate_Serials__c=true
                                                                        ));    
                                                                      
            if(quoteLineBundleMap!=null){
                System.debug('***BundleMAp: ' + quoteLineBundleMap.size());
                for(SBQQ__QuoteLine__c itemQuoteLine: quoteLineBundleMap.get(qlSelected.id)){
                
                  originalQuoteLinesToBeUpdated.add(new SBQQ__QuoteLine__c(Id = itemQuoteLine.id,
                                                                          
                                                                           Terminate_Serials__c = true));
                }
              }              
            }
          }    
          
          if(originalQuoteLinesToBeUpdated!=null && !originalQuoteLinesToBeUpdated.isEmpty()){
            update originalQuoteLinesToBeUpdated;
          }
    
          if(Test.isRunningTest() && testRunningFlag){
            throw new CustomException('Error message in Test Class.');
          }

          return this.goToQLE();    
        }
        catch(Exception ex) {      
          message = System.Label.Cancel_Bucket_DML_Error + ex.getMessage() + '\nStack Trace:' + ex.getStackTraceString();       
          return null;
        }
      }  
 
    public PageReference goToQLE() {
      return new PageReference('/apex/SBQQ__sb?id=' + quoteId + '#quote/le?qId=' + quoteId);
    }  
  
    public class CustomException extends Exception {        
    }
 
    public class QuoteLineSelection{
  
      public Boolean checkBox{get;set;}
      public Id id {get;set;}
  
      public QuoteLineSelection(Boolean checkBox,Id id){  
        this.checkBox = checkBox;
        this.id = id;
      }  
    } 
  }