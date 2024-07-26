/****SFDC-18733****/
public without sharing class SerialSharinghelper{
    
    @future
    public static void CreateSerialSharing(List<Id> SerialIds,String Operation){
        Map<ID,Set<Id>> mapSerialaccounts = new Map<ID,Set<Id>>();
        Set<Id> setaccountIds = new Set<Id>();
        Set<Id> setuserIds = new Set<Id>();
        Map<Id,Set<Id>> mapAccUserIds = new Map<Id,Set<Id>>();
        List<Serial__share> listshareupds = new List<Serial__share>();
        List<Serial__share> delshareslist = new List<Serial__share>();
        Set<String> statusset = new Set<String>{'Draft','In Approval Process','Activated'};
        
        System.debug('&&&&&'+SerialIds);
        try{
            for(Assigned_Serial__c oserial : [Select Id,Serial__c,Subscription__r.SBQQ__Contract__r.Distributor__c, Subscription__r.SBQQ__Contract__r.Reseller__c, Subscription__r.SBQQ__Contract__r.Status,
                                              Subscription__r.SBQQ__Contract__r.AccountId from Assigned_Serial__c where Serial__c  IN : SerialIds and Subscription__r.SBQQ__Contract__r.NOC_Expired__c = false]){
                                                 System.debug(oserial.Serial__c+'%%%%%');
            									System.debug(oserial.Subscription__r.SBQQ__Contract__r.Status+'&&&&');
                                                  if(!mapSerialaccounts.containskey(oserial.Serial__c)){
                                                      Set<Id> AccIds = new Set<Id>();
                                                      AccIds.add(oserial.Subscription__r.SBQQ__Contract__r.AccountId);
                                                      
                                                      if(oserial.Subscription__r.SBQQ__Contract__r.Distributor__c !=null )
                                                          AccIds.add(oserial.Subscription__r.SBQQ__Contract__r.Distributor__c);
                                                      
                                                      if(oserial.Subscription__r.SBQQ__Contract__r.Reseller__c !=null)
                                                          AccIds.add(oserial.Subscription__r.SBQQ__Contract__r.Reseller__c);
                                                      
                                                      mapSerialaccounts.put(oserial.Serial__c,AccIds);
                                                      setaccountIds.addall(AccIds);
                                                      
                                                  }
                                                  
                                              }
         System.debug('***'+setaccountIds);
         System.debug('***'+mapSerialaccounts);
            
            for(User ouser : [Select Id,Contact.AccountId from User where Contact.AccountId IN : setaccountIds and IsActive=true]){
                if(mapAccUserIds.containskey(ouser.Contact.AccountId))
                    mapAccUserIds.get(ouser.Contact.AccountId).add(ouser.Id);
                else
                    mapAccUserIds.put(ouser.Contact.AccountId,new Set<Id>{ouser.Id});
                
                setuserIds.add(ouser.Id);
            }
            
            if(Operation=='Update' || Operation=='Insert'){
                for(Serial__share oshare : [Select Id from Serial__share where RowCause =: Schema.Serial__share.RowCause.Community_Share__c
                                            and ParentId IN: SerialIds and UserOrGroupId IN :setuserIds]){
                                                delshareslist.add(oshare);
                                            }
                
                
            }
            
            
             System.debug('***'+mapAccUserIds);
       
            for(Id serialId : mapSerialaccounts.keyset()){
                for(Id accid : mapSerialaccounts.get(serialId)){
                    if(mapAccUserIds.containskey(accid)){
                        for(Id userId : mapAccUserIds.get(accid)){
                            if(userId!=null)
                            listshareupds.add(new Serial__share(ParentId=serialId, UserOrGroupId = userId, RowCause=Schema.Serial__share.RowCause.Community_Share__c, AccessLevel='Edit'));
                        }
                    }
                }
                
            }
            
            if(delshareslist!=null && !delshareslist.Isempty()){
                Database.delete(delshareslist);
            }
            
            if(listshareupds!=null && !listshareupds.Isempty()){
                Database.insert(listshareupds);
            }
        }catch(Exception ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'SerialSharinghelper',endTime__c = System.now());
           
            Insert log;
        } 
    }
}