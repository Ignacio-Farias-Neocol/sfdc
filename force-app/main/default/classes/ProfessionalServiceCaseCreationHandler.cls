public with sharing class ProfessionalServiceCaseCreationHandler extends TriggerHandler {
    public override void afterInsert() {
        System.debug('##ProfessionalServiceCaseCreationHandler afterInsert');
		ProfessionalServiceCaseCreationHelper.getOrderIdsAndCreateCases(Trigger.new);
	}
}