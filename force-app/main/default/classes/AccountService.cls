public with sharing class AccountService {

    public static Map<String, Id> mapRecordTypeByName {
        get {
            if(mapRecordTypeByName == NULL) {
                mapRecordTypeByName = new Map<String, Id>();

                for(Schema.RecordTypeInfo recType : Account.sObjectType.getDescribe().getRecordTypeInfos()) {
                    if(recType.isActive()) {
                        mapRecordTypeByName.put(recType.getDeveloperName(), recType.getRecordTypeId());
                    }
                }
            }

            return mapRecordTypeByName;
        }
        set;
    }

    public static Account buildNotTransactionalAccount() {
        Account parentAccount = new Account();
        parentAccount.RecordTypeId = mapRecordTypeByName.get('Not_Transactional');
        parentAccount.Type = 'Aggregate';
        return parentAccount;
    }

    public static List<Account> findAccountByName(Account accRecord){

        return new AccountSelector.AccountSelectorWithoutSharing().findByAccountName(accRecord)[0];
    }

    public static List<DnbResult> getMatchResults(Map<String, Object> accRecord){

        List<DnbResult> matches;
        matches=  DnbEnrichmentService.getMatchResults(accRecord);

        return matches;

    }

    public static DnbResult  getDnBDataBlocksInfo(String duns){

        DnbResult blocks;
        blocks=  DnbEnrichmentService.getDnBDataBlocksInfo(duns);

        return blocks;

    }

    public static Account reparentAccounts(Account clonedAccount, Account originalAccount){
            if(clonedAccount == NULL) {
                throw new AccountServiceException('Cloned Account cannot be null');
            } else if(originalAccount == NULL) {
                throw new AccountServiceException('Original Account cannot be null');
            }

            System.debug('AccountService.reparentAccounts() clonedAccount = ' + clonedAccount);
            System.debug('AccountService.reparentAccounts() originalAccount = ' + originalAccount);
            List<Account> accountsToUpsert = new List<Account>();

            if(originalAccount?.ParentId != null){
                clonedAccount.ParentId=originalAccount.ParentId;
                accountsToUpsert.add(clonedAccount);
            } else if (originalAccount?.ParentId == null){
                Account parentAcc = buildNotTransactionalAccount();
                parentAcc.Name = originalAccount.Name;
                System.debug('buildNotTransactionalAccount() parentAcc = ' + parentAcc);
                insert parentAcc;

                originalAccount = new Account(Id = originalAccount.Id, ParentId = parentAcc.Id, Name = originalAccount.Name); // Only changes to ParentId should occur

                clonedAccount.ParentId=parentAcc.Id;

                accountsToUpsert.addAll(new List<Account>{ clonedAccount, originalAccount });
            }

        if(!accountsToUpsert.isEmpty()) {
            System.debug('accountsToUpsert = ' + accountsToUpsert);
            upsert accountsToUpsert;
        }

        return clonedAccount;
    }

    public static Account cloneAccount (Account orignalAccount, Account newAccount){
        Account accClone;

        if(orignalAccount!=null){
            orignalAccount.Type = newAccount?.Type;
            orignalAccount.Status__c = newAccount?.Status__c;
            orignalAccount.CurrencyIsoCode = newAccount?.CurrencyIsoCode;
            orignalAccount.Exclude_from_Duplicate_Rules__c=true;
            orignalAccount.Creation_Source_Audit__c = 'Clone';
			System.debug('orignalAccount::'+ orignalAccount);
            try{

              accClone= orignalAccount.clone(false,false,false,false);
              insert accClone;

              SessionPermSetActionHelper.newInstance('Access_to_Account_Exclude_from_Duplicate_Rules').deactivate();

            }

            catch(Exception ex){

                System.debug('Failed :: ' + ex.getMessage());
            }
        }

        return accClone;
    }

    /*public static SearchBeforeCreateWebService.Response findMatch(SearchBeforeCreateWebService.Request req) {
        try {
            List<Account> matchingAccounts = AccountSelector.findMatch(req.account);

            if(matchingAccounts.size() == 1) {
                return new SearchBeforeCreateWebService.Response(matchingAccounts[0].Id);
            } else if(matchingAccounts.isEmpty() && !req.dryrun) {
                Database.SaveResult result = Database.insert(req.account, true);
                if(result.isSuccess()) {
                    return new SearchBeforeCreateWebService.Response(req.account.Id);
                } else {
                    List<String> errors = new List<String>();
                    for(Database.Error err : result.getErrors()) {
                        errors.add(err.getMessage());
                    }
                    return new SearchBeforeCreateWebService.Response(false, null, errors);
                }
            } else if(matchingAccounts.size() > 1) {
                return new SearchBeforeCreateWebService.Response(false, null, new List<String>{'Multiple potential matches found.'});
            } else {
                return new SearchBeforeCreateWebService.Response(false, null, new List<String>{'Unknown error occurred.'});
            }
        } catch(Exception e) {
            return new SearchBeforeCreateWebService.Response(e);
        }
    }

    public static void createNotTransactionalParent(Account targetAccount) {
        // Logic to create Not Transactional Parent relationship
    }*/

    public class CloneQueable implements Queueable {
        public Account acc ;
        public CloneQueable(Account acc){
            this.acc = acc ;
        }
        public void execute(QueueableContext context) {
            // Ensure the account does not have an Id before insertion.
            if (this.acc.Id != null) {
                // Handle error or clear the Id.
                this.acc.Id = null;
            }            // Then insert the account.
            insert acc;
        }
    }

    public class AccountServiceException extends System.Exception {}
}