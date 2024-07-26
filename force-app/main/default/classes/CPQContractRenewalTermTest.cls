/**
* @author        Sonal Agrawal(Bluvium)
* @date          15th December 2023
* @description   Cover CPQContractRenewalTermBatch and CPQContractRenewalTermBatchSched class which scheduled at 2:30 am daily
*
*/
@isTest
public class CPQContractRenewalTermTest {
  @testSetup static void testSetup(){
      Account acc = new Account();
        acc.Name = 'TESH ACaFDC';
        acc.Type ='Customer';
        insert acc;
       List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = acc.Id, StartDate = System.Today(), ContractTerm = 12,SBQQ__RenewalTerm__c=5,EndDate=Date.today().addDays(366), status ='Draft',Business_Group__c='MSP')
            };
            insert testContracts;
      ContractHistory c = new ContractHistory();
      c.Field = 'SBQQ__RenewalTerm__c';
      c.ContractId = testContracts[0].Id;
      Insert c;
        TriggerHandler.clearAllBypasses();
  }
    @isTest static void CPQContractRenewalTermBatchTest(){
        List<ContractHistory> ConthistoryList = [Select id,Field,OldValue, NewValue,ContractId, CreatedDate,Contract.CreatedDate,Contract.SBQQ__RenewalTerm__c, contract.ContractTerm  from ContractHistory where Field ='SBQQ__RenewalTerm__c' and contract.ContractTerm!=null and CreatedDate =LAST_N_DAYS:90 order by CreatedDate desc];
        system.assertequals(1,ConthistoryList.size());
        Test.startTest();
            CPQContractRenewalTermBatchSched  s = new CPQContractRenewalTermBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQContractRenewalTermBatchSched', sch, s);

            CPQContractRenewalTermBatch b1 = new CPQContractRenewalTermBatch();
            Database.executeBatch(b1);
        Test.stopTest();
    }
}