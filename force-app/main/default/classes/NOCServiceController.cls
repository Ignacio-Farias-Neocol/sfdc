/**
 * @description Class used for various apex methods connected with NOC (object, buttons, triggers, ..) 
*/ 
public with sharing class NOCServiceController {
	/**
    * @description Controller class method which generates number between 0000 and 9999 which is unique against already used PINs
  	* Returns 'success' to determine valid progress of generating random unique number
  	* Returns exception message if exception occurs. (Eg: Limit of all possible combinations already reached)
    */ 
    @AuraEnabled
    public static String getRandomUniquePIN(Id nocSiId){
        try{
            System.debug('NOC Handler, getRandomUniquePIN started');
            List<NOC_Service_Information__c> nocList = [SELECT Phone_PIN__c FROM NOC_Service_Information__c WHERE Phone_PIN__c != null ORDER BY Phone_PIN__c ASC Limit 10000]; 
            
            if(nocList.size() < 9000){
            
                //get SET of already used PINs
                Set<Decimal> usedPins = new Set<Decimal>();
                for(NOC_Service_Information__c noc: nocList){
                    usedPins.add(noc.Phone_PIN__c);
                }
                
                //generate list of all possible new PINs
                List<Decimal> availablePins = new List<Decimal>();
                for(Decimal i=1000; i<=9999; i++){
                    if(!usedPins.contains(i)){
                        availablePins.add(i);
                    }
                }
                
                Decimal randomPin = availablePins[Math.mod(Math.abs(Crypto.getRandomLong().intValue()),availablePins.size())];
                
                List<NOC_Service_Information__c> nocsi = [SELECT Id, Phone_PIN__c FROM NOC_Service_Information__c WHERE Id = :nocSiId];
                nocsi[0].Phone_PIN__c = randomPin;
                update nocsi[0];
                
                return 'PIN has been successfully generated';
            }
            else{
                return 'All available PINs were already used (1000-9999).';
            }
        }
        catch ( Exception e ){
            throw e;
        }
    } 
}