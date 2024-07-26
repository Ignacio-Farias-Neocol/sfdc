public class FlowActionQueuableHandler implements Queueable {
    public Map<string,sObject> payLoadMap ; 
    public FlowActionQueuableHandler(Map<string,sObject> payLoadMap){
        this.payLoadMap = payLoadMap;   
    }
    public void execute(QueueableContext context) {
        try{ 
            System.debug('Case:: # '+payLoadMap.values());
        	Upsert payLoadMap.values();
        }catch(Exception ex){
            System.debug('Error: '+ex.getMessage ()+' Line No: '+ex.getLineNumber());
        }
       
    }
}