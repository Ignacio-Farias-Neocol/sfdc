/**
* @author SFDC
* @date 2017
*
* @group Dynamic Validation
* @group-content a relative path to a static html file that provides content about the group
*
* @description a vaildation engine to support 1. standalone validation with result written to log 2. apex trigger validation
*/
public with sharing class DynamicValidationRuleEngine extends RuleEngine {

    private enum ValidationType { 
        SINGLE,
        BULK_SAVE,
        BULK_DELETE,
        BULK_EITHER
    }

    private static final Map<ValidationType,String> contextMap = new Map<ValidationType,String> {
        ValidationType.SINGLE => 'Single',
        ValidationType.BULK_SAVE => 'Bulk Save',
        ValidationType.BULK_DELETE => 'Bulk Delete',
        ValidationType.BULK_EITHER => 'Bulk Either'
    };


    private SObject parent;
    private SObjectType rootType;
    private Map<String,DynamicValidationRule> apexRules;
    private ValidationType runType;
    private Map<Id,SObject> recordMap;
    private Map<Id,SObject> previousRecordMap;
    private List <SObject> records;


    private static List < Dynamic_Validation_Rule__mdt> ALL_ACTIVE_RULES;
    static {
        ALL_ACTIVE_RULES =  [select Apex_Class_Name__c, Comparator__c, Context__c, DeveloperName, Error_Message__c, Expected__c, Field_API_Name__c, Id, Is_Active__c, Label,
                Only_If_Changed_On__c, Parent_Relationship_Field__c, Parent_SObject_Name__c, QualifiedApiName,
                RuleSet__c, Severity__c, SObject_Name__c from Dynamic_Validation_Rule__mdt where Is_Active__c = true];
    }




    // static entry point
    public static ValidationResults validateRecords(Id recordId) {
        return validateRecords(recordId, null);
    }

    public static ValidationResults validateRecords(Id recordId, String ruleSet) {

        DynamicValidationRuleEngine engine = new DynamicValidationRuleEngine(recordId);

        // get relevant validation rules, mapped by their object name
        List<RuleMeta> rules = engine.fetchRules(ruleSet);

        // evaluate related recordMap
        Map<SObject,ValidationResult> results = engine.validateRelatedRecords(rules);

        // save results
        LogHeader logHeader = engine.logResults(results);

        return new ValidationResults(logHeader, recordId, results);

    }

    public static void validateRecords(Map<Id,SObject> previousRecordMap, Map<Id,SObject> recordMap, List <SObject> records, Boolean isDelete) {

        System.debug('~~~~ recordMap being validate: ' +recordMap + 'previous recordMap: ' + previousRecordMap );

        DynamicValidationRuleEngine engine = new DynamicValidationRuleEngine(previousRecordMap, recordMap, records, isDelete);

        // get relevant validation rules, mapped by their object name
        List<RuleMeta> rules = engine.fetchRules(null);
        System.debug('~~~~ recordMap being validate rules: ' + rules );

        if (rules.isEmpty()) {
            return;
        }

        // evaluate related recordMap
        Map<SObject,ValidationResult> results = engine.validateRelatedRecords(rules);
        System.debug('~~~~ recordMap being validate results: ' + results );
        for (SObject record : results.keySet()) {

            ValidationResult result = results.get(record);
            if (result.hasError) {
                // add errors to record
                record.addError(String.join(result.reasons, ', '));
            }

        }
        
    }

    

    private DynamicValidationRuleEngine(Id parentId) {

        this.apexRules = new Map<String,DynamicValidationRule>();
        this.rootType = parentId.getSObjectType();
        this.runType = ValidationType.SINGLE;

        // confirm parent, also grab its name
        List<SObject> objs = Database.query(String.format('select Name from {0} where Id = :parentId', new List<String> {
            (this.rootType.getDescribe().getName())
        }));

        if (!objs.isEmpty()) {
            this.parent = objs[0];
        }

    }

    private DynamicValidationRuleEngine(Map<Id,SObject> previousRecordMap, Map<Id,SObject> recordMap, List <SObject> records,  Boolean isDelete) {

        this.apexRules = new Map<String,DynamicValidationRule>();
        this.rootType = records == null || records.isEmpty() ? null : records[0].getSObjectType(); // recordMap == null || recordMap.isEmpty() ? null : recordMap.values()[0].getSObjectType();
        this.runType = isDelete ? ValidationType.BULK_DELETE : ValidationType.BULK_SAVE;
        this.recordMap = recordMap;
        this.previousRecordMap = previousRecordMap;
        this.records = records; 

    }

    private List<RuleMeta> fetchRules(String ruleSet) {

        // objName => meta
        Map<String,RuleMeta> rules = new Map<String,RuleMeta>();

        if (this.rootType != null ) {  // IY, check if the root type exists.

            String rootObject = this.rootType.getDescribe().getName();
            List<String> context = new List<String>{
                    (contextMap.get(this.runType))
            };

            if (this.runType != ValidationType.SINGLE) {
                context.add(contextMap.get(ValidationType.BULK_EITHER));
            }

            if (String.isNotBlank(ruleSet)) {
                ruleSet = '%' + ruleSet + '%';
            }


            /*
            String soql =
                    'select ' +
                            'Apex_Class_Name__c, ' +
                            'Comparator__c, ' +
                            'Error_Message__c, ' +
                            'Expected__c, ' +
                            'Field_API_Name__c, ' +
                            'Parent_Relationship_Field__c, ' +
                            'Severity__c, ' +
                            'SObject_Name__c ,' +
                            'Only_If_Changed_On__c ' +
                            'from Dynamic_Validation_Rule__mdt ' +
                            'where Is_Active__c = true ' +
                            'and Context__c in :context ' +
                            (this.runType == ValidationType.SINGLE ? 'and Parent_SObject_Name__c = :rootObject ' : 'and SObject_Name__c = :rootObject ') +
                            (this.runType != ValidationType.SINGLE ? 'and Severity__c = \'ERROR\' ' : '') +
                            (String.isNotBlank(ruleSet) ? 'and RuleSet__c like :ruleSet ' : '');

            System.debug('~~~ ruleSet: ' + ruleSet + 'context: ' + context + 'root object: ' + rootObject +  ' soql: ' + soql );
             */

            // for (Dynamic_Validation_Rule__mdt rule : (List<Dynamic_Validation_Rule__mdt>) Database.query(soql)) {

            for (Dynamic_Validation_Rule__mdt rule : ALL_ACTIVE_RULES) {


                // 2019-10-16: filter rule
                if ( (rule.Context__c == null || context.contains(rule.Context__c))  // filter by context , if exists
                      && (                                                           // filter by root object
                        (this.runType == ValidationType.SINGLE && rule.Parent_SObject_Name__c == rootObject)
                        || (this.runType != ValidationType.SINGLE && rule.SObject_Name__c == rootObject)
                      )
                        && (                                                           // filter by severity
                        (this.runType != ValidationType.SINGLE && rule.Severity__c == 'ERROR')
                                || (this.runType == ValidationType.SINGLE )
                        )
                        && (                                                            // filter by rule set
                        (String.isBlank(ruleSet))
                        || (String.isNotBlank(ruleSet)  && String.isNotBlank(rule.RuleSet__c) &&  rule.RuleSet__c.indexOf(ruleSet) != -1)
                      )
                ) {


                    RuleMeta meta = rules.get(rule.SObject_Name__c);
                    if (meta == null) {
                        rules.put(rule.SObject_Name__c, meta = new RuleMeta(rule.SObject_Name__c));
                    }

                    meta.parentFieldNames.add(this.runType == ValidationType.SINGLE ? rule.Parent_Relationship_Field__c : 'Id');
                    meta.rules.add(rule);

                    if (String.isNotBlank(rule.Field_API_Name__c)) {
                        addFieldReference(meta.objFields, rule.Expected__c);
                        addFieldReference(meta.objFields, rule.Field_API_Name__c);
                    } else if (String.isNotBlank(rule.Apex_Class_Name__c)) {

                        DynamicValidationRule dvr = getDynamicValidationRuleInstance(rule.Apex_Class_Name__c);
                        if (dvr != null) {
                            meta.objFields.addAll(dvr.getExpectedFields());
                        }

                    }



                }



            }
        }

        return rules.values();

    }

    private Map<SObject,ValidationResult> validateRelatedRecords(List<RuleMeta> rules) {

        Map<SObject,ValidationResult> results = new Map<SObject,ValidationResult>();

        // need to fetch per object, then check each rule against each record
        for (RuleMeta meta : rules) {

            Map<Id,SObject> recordMap;
            if (this.runType == ValidationType.SINGLE) {
                Id parentId = this.parent.Id; // used by generated dynamic soql
                String soql = meta.toSoql();
                recordMap = new Map<Id,SObject>(Database.query(soql));
            }
            else {
                recordMap = this.recordMap;
            }

            for (Dynamic_Validation_Rule__mdt rule : meta.rules) {


                // apply is Changed filter
                Map<Id,SObject> filteredMap = new Map<Id,SObject>();
                List <SObject> filterRecords = new List<SObject>();
                
                if (String.isNotBlank(rule.Only_If_Changed_On__c)) {


                    if (recordMap == null || recordMap.size() == 0 || previousRecordMap == null || previousRecordMap.size() == 0  ){
                        // this is before insert trigger where map does not exist
                        filterRecords = this.records;
                    } else {
                        for (SObject record : records) {
                            Id recordId = (Id) record.get('Id');
                            if (
                                previousRecordMap != null &&    previousRecordMap.size() > 0 &&
                                recordMap != null && recordMap.size()  > 0 &&
                                IsChanged(record.get(rule.Only_If_Changed_On__c), previousRecordMap.get(recordId).get(rule.Only_If_Changed_On__c))) {
                                    filteredMap.put(record.Id, record);
                                    filterRecords.add(record);
                            }
                        }
                    }
                } else {
                    // keep
                    filteredMap = this.recordMap;
                    filterRecords = this.records;
                }



                if (String.isNotBlank(rule.Field_API_Name__c)) {

                    for (SObject record : filterRecords) {

                        Object expectedValue = getValueAsObject(record, rule.Expected__c);
                        Object actualValue = getValueAsObject(record, rule.Field_API_Name__c);
                        Boolean isValid = !compare(actualValue, expectedValue, rule.Comparator__c); // similar to salesforce validation rule. if matching is positive, it means that something wrong
                        // System.debug('~~~ expect ' + rule.Expected__c + '/' +  expectedValue + ' ' + rule.Comparator__c + ' ' + rule.Field_API_Name__c + '/' +  actualValue  + ' IsValid: ' + isValid );

                        addRecordResult(results, record, isValid, rule);

                    }

                }
                else if (String.isNotBlank(rule.Apex_Class_Name__c)) {

                    DynamicValidationRule dvr = getDynamicValidationRuleInstance(rule.Apex_Class_Name__c);
                    System.debug('~~~ validating: ' + rule.Apex_Class_Name__c + ' dvr : '  + dvr + ' for ' +  filterRecords );
                    if (dvr != null) {

                        Map<SObject,Boolean> dvrResults = dvr.evaluateRule(filterRecords);  // isValid = false, something is wrong
                        for (SObject o : dvrResults.keySet()) {

                            addRecordResult(results, o, dvrResults.get(o), rule);

                        }

                    }

                }

            }

        }

        System.debug('~~~~ rule results: ' + results);
        return results;

    }

    private LogHeader logResults(Map<SObject,ValidationResult> results) {

        // create parent header
        Dynamic_Validation_Header__c header = new Dynamic_Validation_Header__c(
            Parent_Name__c = String.valueOf(this.parent.get('Name')),
            Parent_Id__c = this.parent.Id
        );
        DML.save(header, this);

        // get auto numbered run id
        Integer runId = Integer.valueOf([select Run_Id__c from Dynamic_Validation_Header__c where Id = :header.Id].Run_Id__c);

        List<Dynamic_Validation_Log__c> logs = new List<Dynamic_Validation_Log__c>();

        for (ValidationResult result : results.values()) {

            String severity = 'SUCCESS';
            if (result.hasError) {
                severity = 'ERROR';
            }
            else if (result.hasWarning) {
                severity = 'WARNING';
            }

            logs.add(new Dynamic_Validation_Log__c(
                Child_Record_Id__c = result.record.Id,
                Child_Record_Name__c = String.valueOf(result.record.get('Name')),
                Dynamic_Validation_Header__c = header.Id,
                Failure_Messages__c = String.join(result.reasons, '\n'),
                Parent_Record_Id__c = this.parent.Id,
                Parent_Record_Name__c = String.valueOf(this.parent.get('Name')),
                Severity__c = severity
            ));
        }

        DML.save(logs, this);

        // attempt to update the parent record's Last_Dynamic_Validation_Run_Id__c
        try {
            SObject obj = this.rootType.newSObject(this.parent.Id);
            obj.put('Last_Dynamic_Validation__c', header.Id);
            withoutSharingDML.save(obj, this);  // SE is read only for many profile
        }
        catch (System.SObjectException e) {
            // go ahead and fail gracefully
        }

        return new LogHeader(header.Id, runId );

    }

    private DynamicValidationRule getDynamicValidationRuleInstance(String className) {

        DynamicValidationRule dvr = this.apexRules.get(className);
        if (dvr == null) {
            Type t = Type.forName(className);
            if (t != null) {
                Object obj = t.newInstance();
                if (obj instanceof DynamicValidationRule) {
                    this.apexRules.put(className, dvr = (DynamicValidationRule)obj);
                }
            }
        }

        return dvr;

    }

    private void addRecordResult(Map<SObject,ValidationResult> results, SObject record, Boolean validity, Dynamic_Validation_Rule__mdt rule) {

        ValidationResult result = results.get(record);
        if (result == null) {
            results.put(record, result = new ValidationResult(record));
        }

        if (!validity) {
            if (rule.Severity__c == 'ERROR') {
                result.hasError = true;
            }
            else if (rule.Severity__c == 'WARNING') {
                result.hasWarning = true;
            }
            result.reasons.add(String.format('{0}: {1}', new List<String> {
                    rule.Severity__c,
                    rule.Error_Message__c
            }));
        } else {
            // 2018-02-15 US2839; Message appears for all lines, not just failures
            result.reasons.add(String.format('{0}: {1}', new List<String>{
                    'Validated',
                    rule.Error_Message__c
            }));
        }

    }

    private void addFieldReference(Set<String> fields, String field) {
        if (!isDecimal(field) && !field.startsWith(STR) && !field.equalsIgnoreCase('null')) {
            fields.add(field);
        }
    }

    private Decimal safeDecimal(Decimal d) {
        return d == null ? 0 : d;
    }

    // rules grouped by their object type, along with that object's referenced fields
    private class RuleMeta {

        public List<Dynamic_Validation_Rule__mdt> rules {get;private set;}
        public Set<String> objFields {get;private set;}
        public Set<String> parentFieldNames {get;private set;}
        public String objName {get;private set;}

        public RuleMeta(String objName) {
            this.objFields = new Set<String> { 'Name' };
            this.objName = objName;
            this.parentFieldNames = new Set<String>();
            this.rules = new List<Dynamic_Validation_Rule__mdt>();
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

    public class LogHeader {
        public Integer runId {get;private set;}
        public String headerId {get ; private set; }
        public LogHeader (String headerId, Integer runId){
            this.runId = runId;
            this.headerId = headerId;
        }
    }

    public class ValidationResults {

        public Id recordId {get;private set;}
        public Boolean hasErrors {get;private set;}
        public Boolean hasWarnings {get;private set;}
        public Integer runId {get;private set;}
        public String headerId {get ; private set; }
        public Map<SObject,ValidationResult> results {get;private set;}

        public ValidationResults(LogHeader header,  Id recordId, Map<SObject,ValidationResult> results) {

            this.runId = header.runId;
            this.recordId = recordId;
            this.headerId = header.headerId;
            this.hasErrors = false;
            this.hasWarnings = false;
            this.results = results;

            // check validity
            for (ValidationResult result : results.values()) {
                this.hasErrors |= result.hasError;
                this.hasWarnings |= result.hasWarning;
            }

        }

    }

    public class ValidationResult {

        public Boolean hasError {get;set;}
        public Boolean hasWarning {get;set;}
        public SObject record {get;private set;}
        public List<String> reasons {get;private set;}

        public ValidationResult(SObject record) {
            this.hasError = false;
            this.hasWarning = false;
            this.reasons = new List<String>();
            this.record = record;
        }

    }

}