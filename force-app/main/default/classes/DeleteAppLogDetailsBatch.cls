/**
* Created by aditya on 2023/5/18.
*
*  @Date 2023/5/18
*  @group Batchable

*/
global with sharing  class DeleteAppLogDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 500;
    private Integer defaultLoadSize = null;   
    
    public String queryString = '';
    
    public DeleteAppLogDetailsBatch() {
        
        
        String deleteFromDate  ;
        String deleteToDate  ;
        //String apexClassMessageClause;
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
            
            /*if ((prop.DeveloperName == 'App_Logs_Class_Message_Clause' && String.isNotBlank(prop.Value__c)) ) {                

apexClassMessageClause = String.valueOf(prop.Value__c);               
}*/  
            
            if ((prop.DeveloperName == 'App_Logs_Retainment_Months' && String.isNotBlank(prop.Value__c)) ) {               
                
                retainMonths = Integer.valueOf(prop.Value__c);               
            }   
        }       
        
        System.debug('Delete From Date : ' + deleteFromDate);
        System.debug('Delete To Date : ' + deleteToDate);        
        //System.debug('Delete From Apex Class : ' + apexClassMessageClause); 
        System.debug('Retainment Months : ' + retainMonths);            
        
        
        /*if(String.isNotBlank(apexClassMessageClause) && String.isNotBlank(deleteFromDate) 
&& String.isNotBlank(deleteToDate)) {

queryString=  'Select Id,(select Id from AppLogDetails__r) from AppLog__c WHERE (' +                                    
' DAY_ONLY(CreatedDate)   >=' + String.valueOf(deleteFromDate) +'  AND ' + 
' DAY_ONLY(CreatedDate) <=' + String.valueOf(deleteToDate) + ') ' +
+ apexClassMessageClause ;      

}*/        
        if(String.isNotBlank(deleteFromDate) && String.isNotBlank(deleteToDate)){          
            
            queryString=    'Select Id from AppLogDetail__c WHERE (' +                                    
                ' DAY_ONLY(CreatedDate)   >=' + String.valueOf(deleteFromDate) +'  AND ' + 
                ' DAY_ONLY(CreatedDate) <=' + String.valueOf(deleteToDate) + ')' ; 
        }    
        
        if(!test.isRunningTest() && String.isNotBlank(String.valueOf(retainMonths))) {    //If retainMonths is filled, it will take precedence
            Date retainDate= Date.today().addMonths(-retainMonths);
            System.debug('Retainment Date : ' + retainDate);  
            queryString= 'Select Id from AppLogDetail__c WHERE (' + 
                ' DAY_ONLY(CreatedDate) <' + String.valueOf(retainDate) + ')' ;
        }else{
            queryString= 'Select Id from AppLogDetail__c' ;
        }     
        
        if(String.isEmpty(queryString))
            System.debug('Related Metadata cannot be Blank !');  
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** queryString ' + queryString);
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<AppLogDetail__c > applogDetailList){     
        
        System.debug('## deleting ' +applogDetailList.size() + ' AppLogs Records');
        
        delete applogDetailList; 
        Database.emptyRecycleBin(applogDetailList);             
    }
    
    global void finish(Database.BatchableContext BC){
        Database.executeBatch(new DeleteAppLogsBatch());
    }    
}