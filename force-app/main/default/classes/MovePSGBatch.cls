/**
 * Created by rmigwani on 2022/7/5.
 *
 *  @Date 2022/7/5
 *  @group Batchable
 
 */
global with sharing  class MovePSGBatch {
    /*
    public Integer defaultBatchSize = 200;
    private Integer defaultLoadSize = null;   
    private String PSG = '';  
   
    public String  queryString=  'Select Id , name,SBQQ__Quote__r.Id, Product_Sales_Grouping__c,'+
    +' Product_Sales_Grouping_m__c from SBQQ__QuoteLine__c where SBQQ__Quote__r.SBQQ__Primary__c =true' +
    +' and Product_Sales_Grouping_m__c=\'\''   ;
*/

    public MovePSGBatch() {       
    }
        
/*        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'MovePSG_Load_Size' && String.isNotBlank(prop.Value__c)) ) {
               
                    defaultLoadSize = Integer.valueOf(prop.Value__c);               
            }
            
            if ((prop.DeveloperName == 'MovePSG_Batch_Size' && String.isNotBlank(prop.Value__c)) ) {
               
                    defaultBatchSize = Integer.valueOf(prop.Value__c);               
            }

            if ((prop.DeveloperName == 'MovePSG_Value' && String.isNotBlank(prop.Value__c)) ) {
               
                    PSG = String.valueOf(prop.Value__c);               
      }
        }       

        if(string.isNotBlank(PSG))
         queryString+= ' and Product_Sales_Grouping__c =\'' + String.valueOf(PSG) + '\'';

        if (defaultLoadSize != null)
         queryString+= ' LIMIT ' + String.valueOf(defaultLoadSize);       
         
         System.Debug('*** queryString ' + queryString);
  
     }        
         
    

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** queryString ' + queryString);
        //return Database.getQueryLocator(queryString);
        return null;
    }

    global void execute(Database.BatchableContext BC, List<SBQQ__QuoteLine__c > qlList){     
 
      System.debug('## qlList Records ' +qlList.size());
      List<SBQQ__QuoteLine__c> qltoUpdate=new List<SBQQ__QuoteLine__c>();
      for (SBQQ__QuoteLine__c ql: qlList){

        if(String.isEmpty(ql.Product_Sales_Grouping_m__c)) {
          ql.Product_Sales_Grouping_m__c=ql.Product_Sales_Grouping__c;

          qltoUpdate.add(ql);
        }
      }

      System.Debug('***  qltoUpdate ' + qltoUpdate);

      Database.DMLOptions dml = new Database.DMLOptions();
      dml.allowFieldTruncation = true;
      
      Database.SaveResult[] srList = Database.update(qltoUpdate, false);
      for (Integer i = 0; i < srList.size(); i++) {
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(ID = qltoUpdate[i].Id);

          Database.SaveResult sr = srList[i];
          if (!sr.isSuccess()) {
              String errorMsg = '';
              for(Database.Error err : sr.getErrors()) {
                  errorMsg = errorMsg + err.getMessage() + '\n';
              }

              System.Debug('*** error updating QuoteLine ' + ql.Id + ', errorMsg ' + errorMsg);
              ql.setOptions(dml);
           
          } else {
              System.Debug('*** success Updating QuoteLine ' + ql.Id);
          }
      }         
    }

    global void finish(Database.BatchableContext BC){
        
    }    */
}