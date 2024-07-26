/**
* @author NRS
* @date 2024-05-21
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-21134
*/

public class UpdContactonLeadConvert implements Queueable {
    private Contact Contacttobeupd = new Contact();
    
    public UpdContactonLeadConvert(Contact updContact) {
        this.Contacttobeupd = updContact;
    }
   
    public void execute(QueueableContext context) {
        try{
            if(Contacttobeupd!=null){
                Database.update(Contacttobeupd,false);            
            }
        
        }catch(Exception ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'UpdContactonLeadConv',endTime__c = System.now());
            Insert log;
        }
    
    }


}