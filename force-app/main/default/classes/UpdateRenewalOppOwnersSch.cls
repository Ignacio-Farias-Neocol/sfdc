/***
 * Scheduler class for the batch UpdateRenewalOppOwners.
 * 
 *
 * @author Dilowar
 *  @date 2024
 * 
 */
public with sharing class UpdateRenewalOppOwnersSch implements Schedulable{
    /**
     * Execute method
     */
    public void execute(SchedulableContext sc) {
        UpdateRenewalOppOwners batchUR = new UpdateRenewalOppOwners();
        database.executebatch(batchUR, 200);
      }
}