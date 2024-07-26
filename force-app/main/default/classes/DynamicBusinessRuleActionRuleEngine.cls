/**
* @author <the author of the class>
* @date 2018
*
* @group a group to display this class under, in the menu hierarchy
* @group-content a relative path to a static html file that provides content about the group
*
* @description one or more lines that provide an overview of the class
*/
public with sharing class DynamicBusinessRuleActionRuleEngine extends RuleEngine {

	// IY: seems to not used...
	/*
	private enum ActionType {
		FIELD_UPDATE,
		APEX_ACTION
	}

	private static final Map<ActionType, String> contextMap = new Map<ActionType,String> {
		ActionType.FIELD_UPDATE => 'FieldUpdate',
		ActionType.APEX_ACTION => 'ApexAction'
	};
	*/
	public static final String CONTEXT_TYPE_BULK_INSERT = 'Bulk Insert';
	public static final String CONTEXT_TYPE_BULK_UPDATE = 'Bulk Update';
	public static final String CONTEXT_TYPE_BULK_DELETE = 'Bulk Delete';
	public static final String CONTEXT_TYPE_BULK_SAVE = 'Bulk Save';  // i.e. either insert or update


	public static final String TRIGGER_ORDER_PRE = 'PRE';
	public static final String TRIGGER_ORDER_POST = 'POST';

	public static List < Business_Rule_Action__mdt> ALL_ACTIVE_RULES;
	static {
		ALL_ACTIVE_RULES =  [select Action_Order__c, Action_Type__c, Apex_Class_Name__c, Apex_JSON_Parameter__c, Comparator__c,
				Context__c, Description__c, DeveloperName, Expected__c, Field_API_Name__c, Id, Is_Active__c, Label, Language, MasterLabel,
				NamespacePrefix, QualifiedApiName, SObject_Name__c, Target_Field_API_Name__c, Target_Value__c, Trigger_Order__c
		from Business_Rule_Action__mdt where is_Active__c = true order by SObject_Name__c, Action_Order__c, Trigger_Order__c];
	}

	private static Map<String, RuleMeta> allActiveRulesMap;

	/*******************************************************************************************************
	*  @description Type of Object
	*/
	private SObjectType rootType;
    private String objectName;

	/*******************************************************************************************************
	*  @description Records validated
	*/
	private Map<Id,SObject> newRecordMap;  // derived from trigger.newMap ; Note this map only is available for update , not for insert
	private Map<Id,SObject> oldRecordMap;  // derived from trigger.newMap ; Note this map only is available for update , not for insert
	private List<SObject> records ; // derived from trigger.new

	/*******************************************************************************************************
	*  @description custom apex action . that function like a pre trigger
	*/
	private Map<String,DynamicBusinessRuleAction> apexActions;


	/*******************************************************************************************************
	*  @description context type
	*/
	private List<String> context;
	private String contextType;
	private String triggerOrder;

	public static void testMethodOne() {
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
		DisplayType targetFieldType = objectFields.get('Is_Enterprise_Account__c').getDescribe().getType();

		System.debug('~~Hello~~');

		System.debug(targetFieldType == Schema.DisplayType.Boolean);
	}

	/*******************************************************************************************************
    * @description Returns field describe data
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return the describe field result for the given field
    * @example
    */
	private DynamicBusinessRuleActionRuleEngine(Map<Id,SObject> newRecordMap,  Map<Id,SObject> oldRecordMap, List<SObject> records,  String contextType, String triggerOrder) {
		System.debug('~~ DynamicBusinessRuleActionRuleEngine ~~ contextType: '  + contextType + ' triggerOrder: ' + triggerOrder);
		// System.debug('~~ DynamicBusinessRuleActionRuleEngine ~~ newRecordMap: ' + newRecordMap );
		// System.debug('~~ DynamicBusinessRuleActionRuleEngine ~~ oldRecordMap: ' + oldRecordMap );
		// System.debug('~~ DynamicBusinessRuleActionRuleEngine ~~ records: ' + records );

		SObjectType recordType;
		if (records != null){
			recordType = records[0].getSObjectType();
		}
		System.debug('~~ RecordType ~~' + recordType);
		this.rootType = recordType;
        this.objectName = getObjectNameByObjectType(this.rootType);
		System.debug('~~ Object Name ~~' + this.objectName);
		this.newRecordMap = newRecordMap;
		this.oldRecordMap = oldRecordMap;
		this.records = records;
		this.apexActions = new Map<String,DynamicBusinessRuleAction>();
		this.context = new List <String>{CONTEXT_TYPE_BULK_SAVE}; // always include rule for both bulk insert or update
		this.context.add(contextType);
		this.contextType = contextType;
		this.triggerOrder = triggerOrder;
	}


	/*******************************************************************************************************
    * @description retrieve the apex instance with the interface of DynamicBusinessRuleAction
    * @param classname that implement DynamicBusinessRuleAction interface
    * @return the instance
    * @example
    */
	private DynamicBusinessRuleAction getDynamicBusinessRuleActionInstance(String className) {

		DynamicBusinessRuleAction dvr = this.apexActions.get(className);
		if (dvr == null) {
			Type t = Type.forName(className);
			if (t != null) {
				Object obj = t.newInstance();
				if (obj instanceof DynamicBusinessRuleAction) {
					this.apexActions.put(className, dvr = (DynamicBusinessRuleAction)obj);
				}
			}
		}

		return dvr;

	}

	/*
	public static void test() {
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();
		DisplayType targetFieldType = objectFields.get('Is_Enterprise_Account__c').getDescribe().getType();
		System.debug(targetFieldType);
	}
	*/

	/*******************************************************************************************************
    * @description Returns field describe data
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return the describe field result for the given field
    * @example
    */
	public static void validateAndExecuteRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List<SObject> records,  String contextType, String triggerOrder) {

		DynamicBusinessRuleActionRuleEngine engine = new DynamicBusinessRuleActionRuleEngine(newRecordMap,  oldRecordMap, records, contextType, triggerOrder);

		// System.debug('~~validateAndExecuteRecords~~' + records + ' contextType: ' + contextType + ' triggerOrder: ' + triggerOrder);

		List<RuleMeta> rules = engine.getBusinessRuleAction();

		System.debug('~~ rules ('+ rules.size() + ') ~~' + rules);

        if (rules.size() > 0) {
            engine.validateAndExecuteRelatedRecords(rules);
        }
	}


	/*******************************************************************************************************
    * @description Returns field describe data
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return the describe field result for the given field
    * @example
    * Account a = new Account();
    */
	 /* public List<RuleMeta> getBusinessRuleAction() {
		Map<String, RuleMeta> ruleActions = new Map<String, RuleMeta>();

		if (this.rootType != null) {
			String objectName = getObjectNameByObjectType(this.rootType);

			//
			String businessRuleActionSoql = buildSoql(objectName, this.context, this.triggerOrder);
			System.debug('~~ businessRuleActionSoql' + businessRuleActionSoql);

			List<Business_Rule_Action__mdt> businessRuleActions = Database.query(businessRuleActionSoql);
			System.debug('~~ businessRuleActions' +  JSON.serializePretty(businessRuleActions));
			//

			for (Business_Rule_Action__mdt businessRuleAction : ALL_ACTIVE_RULES) {

				if (objectName == businessRuleAction.SObject_Name__c &&
						this.context.contains(businessRuleAction.Context__c) &&
						this.triggerOrder == businessRuleAction.Trigger_Order__c){  // skip those that does not match current sobject

					RuleMeta meta = ruleActions.get(businessRuleAction.SObject_Name__c);

					if (meta == null) {
						meta = new RuleMeta(businessRuleAction.SObject_Name__c);
						ruleActions.put(businessRuleAction.SObject_Name__c, meta);
					}
					meta.rules.add(businessRuleAction);

				}
			}

		}

		return ruleActions.values();
	} */

	/*******************************************************************************************************
    * @description Get business rule action data for the current object
    * @param
    * @return List<RuleMeta> rules
    * @example
    */
    private List<RuleMeta> getBusinessRuleAction() {
		List<RuleMeta> ruleMetaList = new List<RuleMeta>();

		// Build map if not built already
		if (allActiveRulesMap == null) {
            System.debug('Building allActiveRulesMap');
			allActiveRulesMap = new Map<String, RuleMeta>();

			for (Business_Rule_Action__mdt businessRuleAction : ALL_ACTIVE_RULES) {
				if (businessRuleAction.Context__c == CONTEXT_TYPE_BULK_SAVE) {
					addRuleToAllActiveRulesMap(businessRuleAction.SObject_Name__c,
											   CONTEXT_TYPE_BULK_INSERT,
											   businessRuleAction.Trigger_Order__c,
											   businessRuleAction);
					addRuleToAllActiveRulesMap(businessRuleAction.SObject_Name__c,
											   CONTEXT_TYPE_BULK_UPDATE,
											   businessRuleAction.Trigger_Order__c,
											   businessRuleAction);
				} else {
					addRuleToAllActiveRulesMap(businessRuleAction.SObject_Name__c,
											   businessRuleAction.Context__c,
											   businessRuleAction.Trigger_Order__c,
											   businessRuleAction);
				}
			}
		}

		// Find RuleMeta from allActiveRulesMap using key
		String key = generateKey(this.objectName, this.contextType, this.triggerOrder);

		if (allActiveRulesMap.containsKey(key)) {
			ruleMetaList.add(allActiveRulesMap.get(key));
		}

		return ruleMetaList;
	}

	/*******************************************************************************************************
    * @description Add rule to the All Active Rules map
    * @param String object name
	* @param String context
	* @param String trigger order
	* @param Business_Rule_Action__mdt rule action to save in the map
    * @return void
    * @example
    */
    private static void addRuleToAllActiveRulesMap(String objectName, String context, String triggerOrder, Business_Rule_Action__mdt ruleAction) {

		// Build search key
		String key = generateKey(objectName, context, triggerOrder);

		// Check if key exists in the map,
		// if not, create new RuleMeta record and add to the map
		RuleMeta meta = allActiveRulesMap.get(key);
		if (meta == null) {
			meta = new RuleMeta(objectName);
			allActiveRulesMap.put(key, meta);
		}
		meta.rules.add(ruleAction);
	}

	/*******************************************************************************************************
    * @description Generate key for the All Active Rules map, make key upper case to prevent user errors
    * @param String object name
	* @param String context
	* @param String trigger order
    * @return String key
    * @example
    */
	private static String generateKey(String objectName, String context, String triggerOrder) {

		String key = objectName + '-' + context + '-' + triggerOrder;

		return key.toUppercase();
	}

	/*******************************************************************************************************
    * @description run one rule
    * @param String api name of the rule
    * @return void
    * @example
    *
    *  DynamicBusinessRuleActionRuleEngine.runOneRule('Case_Premium_Support_Entitlement_Asset', records):
    */
	public static void runOneRule (String ruleName, List <SObject> records ){

		List <Business_Rule_Action__mdt> bRules = [select Action_Order__c, Action_Type__c, Apex_Class_Name__c, Apex_JSON_Parameter__c, Comparator__c, Context__c, Description__c, DeveloperName, Expected__c, Field_API_Name__c, Id, Is_Active__c, Label, Language, MasterLabel, NamespacePrefix, QualifiedApiName, SObject_Name__c, Target_Field_API_Name__c, Target_Value__c, Trigger_Order__c from Business_Rule_Action__mdt where developerName = :ruleName]; //  'Case_Premium_Support_Entitlement_Asset'
		if (bRules.size() == 1){

			DynamicBusinessRuleAction dvr;
			Type t = Type.forName(bRules[0].Apex_Class_Name__c);
			if (t != null) {
				Object obj = t.newInstance();
				if (obj instanceof DynamicBusinessRuleAction) {
					 dvr = (DynamicBusinessRuleAction)obj;
				}
			}
			if (dvr != null) {
				dvr.processRecords(null, null, records, bRules[0].Apex_JSON_Parameter__c, bRules[0].Trigger_Order__c, bRules[0].Context__c);
			}
		}
	}

	/*******************************************************************************************************
    * @description Main method to evalute rule against current context
    * @param List<RuleMeta> rules
    * @return void
    * @example
    */
	private void validateAndExecuteRelatedRecords(List<RuleMeta> rules) {



		for (RuleMeta meta : rules) {
			// System.debug('~~ rule meta ~~' + meta);
            System.debug('~~ rules meta ('+ meta.rules.size() + ') ~~' + meta);

			for (Business_Rule_Action__mdt rule : meta.rules) {
				System.debug('~~ each rule ~~' + rule);

				if (String.isNotBlank(rule.Field_API_Name__c)) {

					Map<Id,SObject> newRecordMapByApex = new Map<Id,SObject>();
					Map<Id,SObject> oldRecordMapByApex = new Map<Id,SObject>();
					List<SObject> recordByApex = new List<SObject>();

					 for (SObject record : records) {
						 /*
					 	System.debug('~~ Expected__c: ~~ ' + rule.Expected__c);
					 	System.debug('~~ Field_API_Name__c: ~~' + rule.Field_API_Name__c);
					 	System.debug('~~ rule.Field_API_Name__c ~~' + getValueAsObject(record, rule.Field_API_Name__c));
					 	*/

					 	Object actualValue = getValueAsObject(record, rule.Field_API_Name__c);
					 	// Object expectedValue = getValueAsObject(record, rule.Expected__c);
						Object actualOldValue;
						if (oldRecordMap != null ) {
							actualOldValue = getValueAsObject(oldRecordMap.get(record.Id), rule.Field_API_Name__c );
						}

					 	System.debug('~~ actual: ' + actualValue +  ' - old actual: ' + actualOldValue + ' - Expected:' + rule.Expected__c);

						Boolean isMatched = compare(actualValue, actualOldValue,  rule.Expected__c, rule.Comparator__c);
						System.debug('~~ isMatched ~~' + isMatched);

						 if (isMatched) {
					 		if (rule.Action_Type__c.equals('FieldUpdate')) {
								/*
					 			Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(rule.SObject_Name__c).getDescribe().fields.getMap();
								DisplayType targetFieldType = objectFields.get(rule.Target_Field_API_Name__c).getDescribe().getType();
								System.debug('~~ Target Field: ' + rule.Target_Field_API_Name__c + ' ~~ Value: ' + rule.Target_Value__c);

								if (targetFieldType == Schema.DisplayType.Boolean) {
									Boolean actualTargetValue = Boolean.valueOf(rule.Target_Value__c);
									record.put(rule.Target_Field_API_Name__c, actualTargetValue);
								} else {
									record.put(rule.Target_Field_API_Name__c, rule.Target_Value__c);
								}
								*/
								setTargetValue(record, rule.Target_Field_API_Name__c, rule.Target_Value__c);
					 		} else if (rule.Action_Type__c.equals('ApexAction')  && String.isNotBlank(rule.Apex_Class_Name__c) ) {

								// build the record set to be invoked by apex
								if (record.Id != null &&  newRecordMap != null  ){
									newRecordMapByApex.put(record.Id, newRecordMap.get(record.Id));
								}
								if (record.Id != null &&  oldRecordMap != null  ){
									oldRecordMapByApex.put(record.Id, oldRecordMap.get(record.Id));
								}
								recordByApex.add(record);
							}
					 	}

					 }

					// execute apex action

					if (recordByApex.size() > 0 && rule.Action_Type__c.equals('ApexAction')  ) {
						System.debug('~~ running apex Action: ' + rule.DeveloperName + ' - ' +  rule.Apex_Class_Name__c );

						DynamicBusinessRuleAction dvr = getDynamicBusinessRuleActionInstance(rule.Apex_Class_Name__c);
						if (dvr != null) {
							dvr.processRecords(newRecordMapByApex, oldRecordMapByApex, recordByApex, rule.Apex_JSON_Parameter__c, this.triggerOrder, this.contextType);
						}
					}


				}
			}

		}  // all rules



	}


	/*
	private String buildSoql(String objectName, List <String> context, String triggerOrder) {
		String[] soqlFields = new String[]{'DeveloperName', 'Label', 'Is_Active__c', 'Action_Type__c', 'Comparator__c', 'Context__c', 'Expected__c', 'Field_API_Name__c',
			'SObject_Name__c', 'Target_Field_API_Name__c', 'Target_Value__c', 'Apex_Class_Name__c', 'Apex_JSON_Parameter__c', 'Action_Order__c'};


		String retrieveBusinessRuleActionSoql = 'SELECT ' + String.join(soqlFields, ',') + ' FROM Business_Rule_Action__mdt WHERE Is_Active__c = true and Trigger_Order__c = :triggerOrder and Context__c in :context and SObject_Name__c = :objectName order by Action_Order__c';

		return retrieveBusinessRuleActionSoql;
	}

	 */

	private String getObjectNameByObjectType(SObjectType objectType) {
		return objectType.getDescribe().getName();
	}


	/*
		RULE META CLASS
	*/
	 // rules grouped by their object type, along with that object's referenced fields
    private class RuleMeta {

        public List<Business_Rule_Action__mdt> rules {get;private set;}
        public Set<String> objFields {get;private set;}
        public Set<String> parentFieldNames {get;private set;}
        public String objName {get;private set;}

        public RuleMeta(String objName) {
            this.objFields = new Set<String> { 'Name' };
            this.objName = objName;
            this.parentFieldNames = new Set<String>();
            this.rules = new List<Business_Rule_Action__mdt>();
        }

        public String toSoql() {

            List<String> criterias = new List<String>();
            for (String parentFieldName : this.parentFieldNames) {
                criterias.add(String.format('{0} = :parentId', new List<String> { parentFieldName }));
            }

            return String.format('select {0} from {1} where ({2})', new List<String> {
                (String.join(new List<String>(this.objFields), ',')),
                (this.objName),
                (String.join(criterias, ' or '))
            });

        }

    }



}