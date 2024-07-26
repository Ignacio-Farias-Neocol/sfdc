public class SearchAndReplace implements Database.Batchable<sObject>{
    
    public String query;
    public String Entity;
    public String Field;
    public String Value;
    public String fieldType;
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        for(sobject s : scope){
            if(fieldType == 'BOOLEAN'){
                s.put(Field, Boolean.valueOf(Value));
            }      
        }
        Database.SaveResult[] srList = Database.update(scope, false); 
        
        Integer index = 0;
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess() || Test.isRunningTest()) {
                LogModel log = LogModel.startLog('SearchAndReplace', 'execute');
                String errorStr = 'Record Id: ' + scope[index].Id;
                
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {                        
                    errorStr = errorStr + ' ' + err.getStatusCode() + ' ' + err.getMessage() + ' ' + err.getFields();                        
                }
                if(errorStr.length() > 32767){
                    errorStr = errorStr.substring(0, 32767);
                }                    
                log.endLog(errorStr);
            }
            
            index++;
        }  
    }
    
    public void finish(Database.BatchableContext BC){
    }
}