public class Task_TakeOwnershipController {
    
    public static Boolean isTestRunning = false;
	
    @auraEnabled
    public static Map<String, String> takeOwnership(Id taskId){
        Map<String, String> returnMap = new Map<String, String>();
        try {
            Task taskRecord = new Task();
            taskRecord.Id = taskId;
            taskRecord.Status = 'In Progress';
            taskRecord.OwnerId = UserInfo.getUserId();
            update taskRecord;
            returnMap.put('isSuccess', 'true');
            if(isTestRunning){
                Throw new CustomException('Test');
            }
        } catch(Exception e) {
            returnMap.put('isSuccess', 'false');
            returnMap.put('errorMessage', e.getMessage());
        } 
        
        return returnMap;
    }
}