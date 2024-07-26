/**
 * Created by rmigwani on 2022/7/5.
 *
 *  @Date 2022/7/5
 *  @group Batchable
 
 */
global with sharing  class DeleteAppLogsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 2000;
    private Integer defaultLoadSize = null;   
   
    public String queryString = '';

    public DeleteAppLogsBatch() {
        

         String deleteFromDate  ;
         String deleteToDate  ;
         String apexClassMessageClause;
         Integer retainMonths;
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'App_Logs_Delete_Load_Size' && String.isNotBlank(prop.Value__c)) ) {
               
                    defaultLoadSize = Integer.valueOf(prop.Value__c);               
            }
            
            if ((prop.DeveloperName == 'App_Logs_Delete_Batch_Size' && String.isNotBlank(prop.Value__c)) ) {
               
                    defaultBatchSize = Integer.valueOf(prop.Value__c);               
            }
           
            if ((prop.DeveloperName == 'App_Logs_Delete_From_Date' && String.isNotBlank(prop.Value__c)) ) {                
               
                    deleteFromDate = String.valueOf(prop.Value__c);               
            }   

            if ((prop.DeveloperName == 'App_Logs_Delete_To_Date' && String.isNotBlank(prop.Value__c)) ) {                
               
                    deleteToDate = String.valueOf(prop.Value__c);               
            }   

            if ((prop.DeveloperName == 'App_Logs_Class_Message_Clause' && String.isNotBlank(prop.Value__c)) ) {                
               
                    apexClassMessageClause = String.valueOf(prop.Value__c);               
            }   

            if ((prop.DeveloperName == 'App_Logs_Retainment_Months' && String.isNotBlank(prop.Value__c)) ) {               
               
                    retainMonths = Integer.valueOf(prop.Value__c);               
            }   
        }       

        System.debug('Delete From Date : ' + deleteFromDate);
        System.debug('Delete To Date : ' + deleteToDate);        
        System.debug('Delete From Apex Class : ' + apexClassMessageClause); 
        System.debug('Retainment Months : ' + retainMonths);            

      
        if(String.isNotBlank(apexClassMessageClause) && String.isNotBlank(deleteFromDate) 
           && String.isNotBlank(deleteToDate)) {

            queryString=  'Select Id from AppLog__c WHERE (' +                                    
                          ' DAY_ONLY(CreatedDate)   >=' + String.valueOf(deleteFromDate) +'  AND ' + 
                          ' DAY_ONLY(CreatedDate) <=' + String.valueOf(deleteToDate) + ') ' +
                            + apexClassMessageClause ;      
 
         }        
          if(String.isEmpty(apexClassMessageClause)
                  && String.isNotBlank(deleteFromDate) && String.isNotBlank(deleteToDate)){          

            queryString=    'Select Id from AppLog__c WHERE (' +                                    
                            ' DAY_ONLY(CreatedDate)   >=' + String.valueOf(deleteFromDate) +'  AND ' + 
                            ' DAY_ONLY(CreatedDate) <=' + String.valueOf(deleteToDate) + ')' ; 
         }    
                 
          if(String.isNotBlank(String.valueOf(retainMonths))) {    //If retainMonths is filled, it will take precedence

            Date retainDate= Date.today().addMonths(-retainMonths);
            System.debug('Retainment Date : ' + retainDate);  
 
            queryString= 'Select Id from AppLog__c WHERE (' + 
                             ' DAY_ONLY(CreatedDate) <' + String.valueOf(retainDate) + ')' ; 
         }       
         
         if(String.isEmpty(queryString))
             System.debug('Related Metadata cannot be Blank !');  
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** queryString ' + queryString);
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<AppLog__c > applogList){     
 
      System.debug('## deleting ' +applogList.size() + ' AppLogs Records');
     
         delete applogList; 
         Database.emptyRecycleBin(applogList);             
    }

    global void finish(Database.BatchableContext BC){
        
    }    
}