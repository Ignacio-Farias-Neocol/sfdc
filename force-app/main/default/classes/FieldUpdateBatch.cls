/**
* @author Brian Chong (Slalom)
* @date 2023-11-17
*
* @group 
* @group-content
*
* @description Virtual class for simple SObject Field updates
*/
public virtual class FieldUpdateBatch implements Database.Batchable<sObject> {

    public Integer limitInt;
    public Map<SObjectField, Object> fieldValueMap;
    public List<String> conditionsList;

    public String query {
        get {
            if(this.query == NULL) {
                this.query = buildQuery();
            }

            return this.query;
        }
        set;
    }

    public FieldUpdateBatch() {}

    public FieldUpdateBatch(Map<SObjectField, Object> fieldValueMap, List<String> conditionsList) {
        this.fieldValueMap = fieldValueMap;
        this.conditionsList = conditionsList;
    }

    protected virtual String buildQuery() {
        Set<SObjectField> fieldsSet = this.fieldValueMap.keySet();
        SObjectType sobj = fieldsSet?.iterator().next().getDescribe().getSObjectType();
        QueryBuilder builder = new QueryBuilder(sobj, fieldsSet, this.conditionsList, this.limitInt);
        return builder.getQuery();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for(SObject record : scope) {
            for(SObjectField fld : this.fieldValueMap.keySet()){
                record.put(fld, this.fieldValueMap.get(fld));
            }
        }

        update scope;
    }

    public void finish(Database.BatchableContext bc) {}

    public class QueryBuilder {
        public SObjectType sobj;
        Set<SObjectField> selectFieldsSet;
        List<String> conditionsList;
        Integer limitInt;

        final String BASE_QUERY = 'SELECT {0} FROM {1}';

        public QueryBuilder(SObjectType sobj, Set<SObjectField> selectFieldsSet, List<String> conditionsList, Integer limitInt) {
            this.sobj = sobj;
            this.selectFieldsSet = selectFieldsSet;
            this.conditionsList = conditionsList;
            this.limitInt = limitInt;
        }

        private String getFieldString() {
            List<String> fieldsStringList = new List<String>();

            for(SObjectField fld : selectFieldsSet) {
                fieldsStringList.add(fld.getDescribe().getName());
            }

            return String.join(fieldsStringList, ', ');
        }

        private String getSObjectString() {
            return this.sobj.getDescribe().getName();
        }

        public String getQuery() {
            String selectFieldsString = getFieldString();
            String query = String.format(BASE_QUERY, new List<String>{ selectfieldsString, getSObjectString() });
            
            if(!conditionsList?.isEmpty()) {
                query += ' WHERE ';
                query += String.join(conditionsList, ' AND ');
            }

            if(limitInt != NULL) {
                query += ' LIMIT ' + limitInt;
            }

            return query;
        }
    }
}