trigger ProfessionalServiceCaseCreationTrigger on Professional_Service_Case_Creation__e (after insert) {
    System.debug('##TriggerExecution');
	new ProfessionalServiceCaseCreationHandler().run();
}