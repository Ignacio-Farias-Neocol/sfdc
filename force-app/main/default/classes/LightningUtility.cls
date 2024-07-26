public class LightningUtility {
    public static Map<String, Schema.SObjectType> mSchema;
    static {
        mSchema = Schema.getGlobalDescribe();
    }
    
    public class SaveResult {
    	@AuraEnabled
        public SObject result {get; set;}
        @AuraEnabled
        public String errorMsg {get; set;}
    }
	
    /*----------------------------------------------------------------------*/
    /* Common Inquery                                                       */
    /*----------------------------------------------------------------------*/
    public class KeyValueResults {
        @AuraEnabled
        public List<KeyValue> results {get; set;}
        @AuraEnabled
        public String errorMsg {get; set;}
        
        public KeyValueResults() {
        	this.results = new List<KeyValue>();
        }
    }

    public class KeyValue implements Comparable {
        @AuraEnabled
        public String key {get; set;}
        @AuraEnabled
        public String value {get; set;}
        
        public KeyValue(String key, String value) {
            this.key = key;
            this.value = value;
        }
        
        public Integer compareTo(Object compareTo) {
    		KeyValue compareToKV = (KeyValue)compareTo;
    		try {
	        	if (key == compareToKV.key) return 0;
	        	if (key > compareToKV.key) return 1;
	        	return -1;
	        } catch (Exception e) {
	        	return 0;
	        }
		}
    }
	
	/*
	LightningUtility.KeyValueResults r = LightningUtility.retrievePicklistValues('Account', 'Type'); 
	System.Debug('*** r ' + r);
	*/
    @RemoteAction
    @AuraEnabled
    public static KeyValueResults retrievePicklistValues(String sObjectName, String fieldName) {
        KeyValueResults r = new KeyValueResults();

        try {
            DescribeSObjectResult dor = mSchema.get(sObjectName).getDescribe();
            DescribeFieldResult def = dor.fields.getMap().get(fieldName).getDescribe();

            r.results = new List<KeyValue>();
            for (Schema.PicklistEntry p : def.getPicklistValues()) {
                if (p.isActive() == true)
                    r.results.add(new KeyValue(p.getValue(), p.getLabel()));
            }
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        } 

        return r;
    }
    
	/*
	LightningUtility.KeyValueResults r = LightningUtility.retrieveRecordTypes('Account'); 
	System.Debug('*** r ' + r);
	*/
    @RemoteAction
    @AuraEnabled
    public static KeyValueResults retrieveRecordTypes(String sObjectName) {
        KeyValueResults r = new KeyValueResults();

        try {
            DescribeSObjectResult dor = mSchema.get(sObjectName).getDescribe();

            r.results = new List<KeyValue>();
            for (Schema.RecordTypeInfo p : dor.getRecordTypeInfos()) {
                //if (p.isActive() == true)
                r.results.add(new KeyValue(p.getRecordTypeId(), p.getName()));
            }
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        }

        return r;
    }

    /*----------------------------------------------------------------------*/
    /* Describe                                                             */
    /*----------------------------------------------------------------------*/
    public virtual class ColumnDefinition {
        ColumnDefinition(Schema.DescribeFieldResult dfr) {
            this.field = dfr.getName();
            this.displayName = dfr.getLabel();
            this.sortable = dfr.isSortable();
            this.filterable = dfr.isFilterable();
            this.locale = UserInfo.getLocale().replace('_','-');
            this.isAutoNumber = dfr.isAutoNumber();
            this.scale = dfr.getScale();

            Schema.DisplayType dtype = dfr.getType();
            this.displayType = 'Text';
            if (dtype == Schema.DisplayType.Email)
                this.displayType = 'Email';
            else if (dtype == Schema.DisplayType.Phone)
                this.displayType = 'Phone';
            else if (dtype == Schema.DisplayType.Boolean)
                this.displayType = 'Boolean';
            else if (dtype == Schema.DisplayType.Currency)
                this.displayType = 'Currency';
            else if (dtype == Schema.DisplayType.Date)
                this.displayType = 'Date';
            else if (dtype == Schema.DisplayType.Time || dtype == Schema.DisplayType.DateTime)
                this.displayType = 'DateTime';
            else if (dtype == Schema.DisplayType.Double || dtype == Schema.DisplayType.Integer)
                this.displayType = 'Number';
            else if (dtype == Schema.DisplayType.Percent)
                this.displayType = 'Percent';
            else if (dtype == Schema.DisplayType.URL)
                this.displayType = 'URL';
            else if (dtype == Schema.DisplayType.Reference)
                this.displayType = 'Reference';

            Schema.SOAPType t = dfr.getSOAPType();
            if (t == Schema.SOAPType.Date || t == Schema.SOAPType.DateTime || t == Schema.SOAPType.Time)
                this.sortingType = 'date';
            else if (t == Schema.SOAPType.Boolean || t == Schema.SOAPType.Double || t == Schema.SOAPType.Integer)
                this.sortingType = 'number';

            if (this.field == 'CreatedById')
                this.displayType = 'CreatedBy';
            else if (this.field == 'LastModifiedById')
                this.displayType = 'LastModifiedBy';
            //Added as a part of SFDC-16036: START
            if(this.field == 'C360_Account_Summary_Link__c'){
                this.displayType = 'URL';
            }
            //Added as a part of SFDC-16036: END
        }

        public void buildAuraGridColumn(Boolean isExpandingProperty) {
            this.auraGridColumn = new AuraGridColumn();
    
            this.auraGridColumn.fieldName = field;
            this.auraGridColumn.label = displayName;

            this.auraGridColumn.type = this.displayType.toLowerCase();
            if (this.displayType == 'DateTime' || this.displayType == 'Date' || Test.isRunningTest()) {
                this.auraGridColumn.type = 'date-local';
            } 
            
            if (this.displayType == 'Reference' || isExpandingProperty == true || this.displayType == 'CreatedBy' || this.displayType == 'LastModifiedBy') {
                this.auraGridColumn.type = 'url';
            }
            
            if (this.displayType == 'Currency') {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                this.auraGridColumn.typeAttributes.currencyCode = new attributeField();
                this.auraGridColumn.typeAttributes.currencyCode.fieldName = 'CurrencyIsoCode';
                this.auraGridColumn.typeAttributes.currencyDisplayAs = 'code';
                this.auraGridColumn.typeAttributes.minimumFractionDigits = this.scale;
                this.auraGridColumn.cellAttributes = new auraGridAttributes();
                this.auraGridColumn.cellAttributes.alignment = 'left';
            } 
            
            if (this.displayType == 'Number') {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                this.auraGridColumn.typeAttributes.minimumFractionDigits = this.scale;
                this.auraGridColumn.cellAttributes = new auraGridAttributes();
                this.auraGridColumn.cellAttributes.alignment = 'left';
            }

            if (this.displayType == 'Date' || Test.isRunningTest()) {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                this.auraGridColumn.typeAttributes.day = 'numeric';
                this.auraGridColumn.typeAttributes.month = 'numeric';
                this.auraGridColumn.typeAttributes.year = 'numeric';
            } 

            if (this.displayType == 'DateTime' || Test.isRunningTest()) {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                this.auraGridColumn.typeAttributes.day = 'numeric';
                this.auraGridColumn.typeAttributes.month = 'numeric';
                this.auraGridColumn.typeAttributes.year = 'numeric';
                this.auraGridColumn.typeAttributes.hour = 'numeric';
                this.auraGridColumn.typeAttributes.minute = '2-digit';
                this.auraGridColumn.typeAttributes.second = '2-digit';
                this.auraGridColumn.typeAttributes.hour12 = true;
            } 
            
            if (isExpandingProperty == true) {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                
                this.auraGridColumn.fieldName = field + '.link';
                this.auraGridColumn.typeAttributes.label = new attributeField();
                this.auraGridColumn.typeAttributes.label.fieldName = field;
                this.auraGridColumn.wrapText = true;

                this.auraGridColumn.cellAttributes = new auraGridAttributes();
                this.auraGridColumn.cellAttributes.iconName = new attributeField();
                this.auraGridColumn.cellAttributes.iconName.fieldName = 'leadIcon';
                this.auraGridColumn.cellAttributes.iconPosition = 'left';
            } 
            
            if (this.displayType == 'Reference' || this.displayType == 'CreatedBy' || this.displayType == 'LastModifiedBy') {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                
                this.auraGridColumn.fieldName = referencedObject + '.' + referencedField + '.link';
                this.auraGridColumn.typeAttributes.label = new attributeField();
                this.auraGridColumn.typeAttributes.label.fieldName = referencedObject + '.' + referencedField;
            }
            //Added as a part of SFDC-16036: START
            if (this.field == 'C360_Account_Summary_Link__c') {
                this.auraGridColumn.typeAttributes = new auraGridAttributes();
                this.auraGridColumn.typeAttributes.label = new attributeField();
                this.auraGridColumn.fieldName = this.field+ '.link';
                this.auraGridColumn.typeAttributes.label = new attributeField();
                this.auraGridColumn.typeAttributes.label.fieldName = this.field +'.linkLabel';
            }//Added as a part of SFDC-16036: end
        }

        @AuraEnabled
        public String field {get; set;}
        @AuraEnabled
        public String displayName {get; set;}
        @AuraEnabled
        public String referencedObject {get; set;}
        @AuraEnabled
        public String referencedField {get; set;}
        @AuraEnabled
        public Boolean referencedFieldIsAutoNumber {get; set;}
        @AuraEnabled
        public Boolean sortable {get; set;}
        @AuraEnabled
        public String sortingType {get; set;}
        @AuraEnabled
        public String displayType {get; set;}
        @AuraEnabled
        public String locale {get; set;}
        @AuraEnabled
        public Boolean filterable {get; set;}
        @AuraEnabled
        public Boolean displayed {get; set;}
        @AuraEnabled
        public AuraGridColumn auraGridColumn {get; set;}
        @AuraEnabled
        public Boolean isAutoNumber {get; set;}
        @AuraEnabled
        public Integer scale {get; set;}
        @AuraEnabled
        public Integer maxValueLength {get; set;}
        @AuraEnabled
        public Integer initialWidth {get; set;}

        public ColumnDefinition() {}
    }

    public class AuraGridColumn {
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public String fieldName {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public Integer initialWidth {get; set;}
        @AuraEnabled
        public Boolean wrapText {get; set;}
        @AuraEnabled
        public auraGridAttributes typeAttributes {get; set;}
        @AuraEnabled
        public auraGridAttributes cellAttributes {get; set;}
    }
    
    public class auraGridAttributes {
        @AuraEnabled
        public String day {get; set;}
        @AuraEnabled
        public String month {get; set;}
        @AuraEnabled
        public String year {get; set;}
        @AuraEnabled
        public String hour {get; set;}
        @AuraEnabled
        public String minute {get; set;}
        @AuraEnabled
        public String second {get; set;}
        @AuraEnabled
        public Boolean hour12 {get; set;}
        @AuraEnabled
        public Integer maximumFractionDigits {get; set;}
        @AuraEnabled
        public Integer maximumSignificantDigits {get; set;}
        @AuraEnabled
        public Integer minimumFractionDigits {get; set;}
        @AuraEnabled
        public Integer minimumSignificantDigits {get; set;}
        @AuraEnabled
        public attributeField currencyCode {get; set;}
        @AuraEnabled
        public String currencyDisplayAs {get; set;}
        @AuraEnabled
        public String alignment {get; set;}
        @AuraEnabled
        public attributeField label {get; set;}
        @AuraEnabled
        public attributeField iconName {get; set;}
        @AuraEnabled
        public String iconPosition {get; set;}
        @AuraEnabled
        public List<AuraGridAction> rowActions {get; set;}
    }

    public class attributeField {
        @AuraEnabled
        public String fieldName {get; set;}
    }

    public class AuraGridAction {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String name {get; set;}
    }

    public class ActionDefinition {
        public ActionDefinition(String method, String buttonFace, String delimiter) {
            this.method = method;
            this.buttonFace = buttonFace;
            this.delimiter = delimiter;
        }
        @AuraEnabled
        public String method {get; set;}
        @AuraEnabled
        public String buttonFace {get; set;}
        @AuraEnabled
        public String delimiter {get; set;}
        @AuraEnabled
        public AuraGridAction auraGridAction {get; set;}

        public void buildAuraGridAction() {
            this.auraGridAction = new AuraGridAction();
            auraGridAction.label = this.buttonFace;
            auraGridAction.name = this.method;
        }
    }

	public virtual class DisplayDescribe {
        @AuraEnabled
        public ColumnDefinition expandingProperty {get; set;}
        @AuraEnabled
        public List<ColumnDefinition> colDefs {get; set;}
        @AuraEnabled
        public List<ActionDefinition> actionDefs {get; set;}

        public DisplayDescribe() {
            colDefs = new List<ColumnDefinition>();
            actionDefs = new List<ActionDefinition>();
        }
	}
	
    public class SObjectDisplayDescribe extends DisplayDescribe {
    	public Set<String> returningFields {get; private set;}
    	
    	@AuraEnabled
        public String nameField{
        	get {
        		return expandingProperty.field.toLowerCase();
        	}
        	private set;
        }
        
        SObjectDisplayDescribe(String sObjectName) {
            getFieldEssentials(sObjectName, new Set<String>());
        }

    	SObjectDisplayDescribe(String sObjectName, String FieldSetAPIName) {
    		Set<String> fieldSetFieldSet = new Set<String>();
	        for (Schema.FieldSetMember f : mSchema.get(sObjectName).getDescribe().fieldSets.getMap().get(FieldSetAPIName.toLowerCase()).getFields()) {
	            fieldSetFieldSet.add(f.getFieldPath().toLowerCase());
	        }
	        
	        getFieldEssentials(sObjectName, fieldSetFieldSet);
    	}
    	
	    SObjectDisplayDescribe(String sObjectName, String[] filedsToDisplay) {
	        Set<String> fieldToDisplayLowerCaseSet = new Set<String>();
	        for (String f : filedsToDisplay) {
	            fieldToDisplayLowerCaseSet.add(f.toLowerCase());
	        }
	        
	        getFieldEssentials(sObjectName, fieldToDisplayLowerCaseSet);
	    }
	    
	    void getFieldEssentials(String sObjectName, Set<String> fieldToDisplayLowerCaseSet) {
	        DescribeSObjectResult dor = mSchema.get(sObjectName).getDescribe();
	        
	        Map<String, Schema.SObjectField> allFields = dor.fields.getMap();
	
	        Set<String> allfieldSet = new Set<String>();
	
	        for (String k : allFields.keySet()) {
	            Schema.DescribeFieldResult dfr = allFields.get(k).getDescribe();
	            if (dfr.isNameField()) {
	                allfieldSet.add(k);
	            } else if (k == 'CurrencyIsoCode') {
	                allfieldSet.add(k);
	            }
	        }
	        for (String k : fieldToDisplayLowerCaseSet) {
	            if (!allfieldSet.contains(k))
	                allfieldSet.add(k);

                if (k == 'CreatedById') {
                    allfieldSet.add('createddate');
                } else if (k == 'LastModifiedById') {
                    allfieldSet.add('lastmodifieddate');
                }
	        }
	
	        this.returningFields = new Set<String>();
			
	        for (String k : allfieldSet) {
	            Schema.DescribeFieldResult dfr = allFields.get(k).getDescribe();
	            if (dfr == null)
	            	continue;
	            //if (!dfr.isAccessible())
	            //    continue;
	            
	            if (dfr.isNameField()) {
	                this.returningFields.add(k);
	                this.expandingProperty = new ColumnDefinition(dfr);
	            }
	            
	            ColumnDefinition col = new ColumnDefinition(dfr);
                col.displayed = fieldToDisplayLowerCaseSet.contains(k);
	            if (!this.returningFields.contains(k)) {
	                this.returningFields.add(k);
	                this.colDefs.add(col);
	            }
                
	            String relationshipName = dfr.getRelationshipName();
	            List<Schema.sObjectType> ref_Tos = dfr.getReferenceTo();
	            if  (ref_Tos == null || ref_Tos.size() == 0)
	                continue;
	            
	            for (Schema.sObjectType ref_To : ref_Tos) {
	                Schema.DescribeSobjectResult ref_dor = ref_To.getDescribe();
	                
	                Map<String, Schema.SObjectField> ref_fieldMap = ref_dor.fields.getMap();
	                for (Schema.SObjectField ref_f : ref_fieldMap.values()) {
	                    Schema.DescribeFieldResult ref_dfr = ref_f.getDescribe();
	                    if (ref_dfr.isNameField()) {
	                        String key = relationshipName + '.' + ref_dfr.getName();
	                        if (!this.returningFields.contains(key)) {
	                            this.returningFields.add(key);
	                            col.referencedObject = relationshipName;
                                col.referencedField = ref_dfr.getName();
                                col.referencedFieldIsAutoNumber = ref_dfr.isAutoNumber();
	                        }
	                    }
	                }
	            }
	        }
	    }
    }
	
    public class SearchEntityInfo {
        @AuraEnabled
        public String sObjectName {get; set;}
        @AuraEnabled
        public String FieldSetAPIName {get; set;}
        @AuraEnabled
        public List<String> displayFields {get; set;}
        @AuraEnabled
        public String sObjectIcon {get; set;}
        @AuraEnabled
        public String lookupFilter {get; set;}
        @AuraEnabled
        public String queryLimit {get; set;}
        @AuraEnabled
        public List<ActionDefinition> displayActions {get; set;}
    }

    public class SearchResults {
        @AuraEnabled
        public String errorMsg {get; set;}
        @AuraEnabled
        public List<SObjectHierarchyResults> results {get; set;}
        
        SearchResults() {
            results = new List<SObjectHierarchyResults>();
        }
    }

    //Result set contains multiple fields. Lookup, Search results
    public class SObjectHierarchyResults {
        @AuraEnabled
        public String errorMsg {get; set;}
        @AuraEnabled
        public String locale {get; set;}
        @AuraEnabled
        public SObjectDisplayDescribe describe {get; set;}
        @AuraEnabled
        public List<SObjectInfo> results {get; set;}
		@AuraEnabled
        public SearchEntityInfo searchEntity {get; set;}

        public SObjectHierarchyResults() {
            this.results = new List<SObjectInfo>();
            this.locale = UserInfo.getLocale().replace('_','-');
        }

        public SObjectHierarchyResults(SearchEntityInfo searchEntity) {
            this.results = new List<SObjectInfo>();
            this.searchEntity = searchEntity;
            this.locale = UserInfo.getLocale().replace('_','-');

            if ((searchEntity.displayFields == null || searchEntity.displayFields.size() == 0) && !String.isEmpty(searchEntity.FieldSetAPIName)) {
                searchEntity.displayFields = new List<String>();

                Map<String, Schema.FieldSet> fsMap = mSchema.get(searchEntity.sObjectName).getDescribe().fieldSets.getMap();
                if (fsMap.containskey(searchEntity.FieldSetAPIName.toLowerCase())) {
                    for (Schema.FieldSetMember f : fsMap.get(searchEntity.FieldSetAPIName.toLowerCase()).getFields()) {
                        searchEntity.displayFields.add(f.getFieldPath());
                    }
                }
            }
            this.describe = new SObjectDisplayDescribe(searchEntity.sObjectName, searchEntity.displayFields != null ? searchEntity.displayFields : new List<String>());
            if (searchEntity.displayActions != null)
                this.describe.actionDefs = searchEntity.displayActions;
        }

        public void setRecords(List<SObject> records) {
            for (SObject a : records) {
                results.add(new SObjectInfo(a));
            }
        }
        
        public void setRecords(List<SObjectInfo> recordInfos) {
            results = recordInfos;
        }

        public List<AuraGridColumn> getAuraGridColumnDefinition() {
            List<AuraGridColumn> acols = new List<AuraGridColumn>();

            this.describe.expandingProperty.buildAuraGridColumn(true);
            acols.add(describe.expandingProperty.auraGridColumn);

            for (ColumnDefinition col : this.describe.colDefs) {
                if (col.displayed == true) {
                    col.buildAuraGridColumn(false);
                    acols.add(col.auraGridColumn);
                }
            }
            
            if (this.describe.actionDefs.size() > 0) {
                AuraGridColumn auraGridColumn = new AuraGridColumn();
                auraGridColumn.type = 'action';
                auraGridColumn.typeAttributes = new auraGridAttributes();
                auraGridColumn.typeAttributes.rowActions = new List<AuraGridAction>();

                for (ActionDefinition action : this.describe.actionDefs) {
                    action.buildAuraGridAction();
                    auraGridColumn.typeAttributes.rowActions.add(action.auraGridAction);
                }
                acols.add(auraGridColumn);
            }

            return acols;
        }

        public List<Map<String, Object>> getAuraGridData() {
            List<Map<String, Object>> arecords = new List<Map<String, Object>>();
            getAuraGridData(arecords, results);
            return arecords;
        }

        private void getAuraGridData(List<Map<String, Object>> arecords, List<SObjectInfo> infos) {
            for (SObjectInfo so : infos) {
                Map<String, Object> keyValues = so.buildAuraGridData(describe);
                arecords.add(keyValues);
                
                if (so.children != null && so.children.size() > 0) {
                    List<Map<String, Object>> arecordschildren = new List<Map<String, Object>>();
                    keyValues.put('_children', arecordschildren);

                    getAuraGridData(arecordschildren, so.children);
                }
            }
        }
        /*
        public List<Map<String, Object>> getAuraGridData() {
            List<Map<String, Object>> arecords = new List<Map<String, Object>>();
            for (SObjectInfo so : results) {
                Map<String, Object> keyValues = so.buildAuraGridData(describe);
                arecords.add(keyValues);
            }

            return arecords;
        }
        */
        public void adjustAuraGridColumnWidth() {
            List<ColumnDefinition> initialWidthColumns = new List<ColumnDefinition>();
            //maybecolumns' initialWidth = null, are flexible. 
            //If no maybecolumns, all columns have equal width
            List<ColumnDefinition> maybeColumns = new List<ColumnDefinition>();
            
            if (this.describe.expandingProperty.initialWidth != null || this.describe.expandingProperty.isAutoNumber == true) {
                initialWidthColumns.add(this.describe.expandingProperty);
            } else {
                maybeColumns.add(this.describe.expandingProperty);
            }

            for (ColumnDefinition col : this.describe.colDefs) {
                if (col.displayed == true) {
                    if (col.auraGridColumn != null &&
                            (col.displayType == 'Boolean' || 
                            col.displayType == 'Currency' || 
                            col.displayType == 'Date' || 
                            col.displayType == 'DateTime' || 
                            col.displayType == 'Number' || 
                            col.displayType == 'Percent' || 
                            col.displayType == 'Phone' || 
                            col.isAutoNumber == true ||
                            col.initialWidth != null ||
                            (col.displayType == 'Reference' && col.referencedFieldIsAutoNumber == TRUE) ||
                            col.maxValueLength == null || 
                            col.maxValueLength < 10)) {
                        initialWidthColumns.add(col);
                    } else {
                        maybeColumns.add(col);
                    }
                }
            }
            
            Boolean fixedColumns = (maybeColumns.size() == 0);
            for (ColumnDefinition col : initialWidthColumns) {
                if (col.initialWidth != null) {
                    col.auraGridColumn.initialWidth = col.initialWidth;
                } else {
                    if (fixedColumns == false) {
                        col.auraGridColumn.initialWidth = 120;
                    }
                }
            }
        }
    }

    public class SObjectInfo {
        public SObjectInfo(SObject record) {
            this.record = record;
            this.children = new List<SObjectInfo>();
        }

        @AuraEnabled
        public SObject record {get; set;}
        @AuraEnabled
        public List<SObjectInfo> children {get; set;}
        @AuraEnabled
        public Boolean checked {get; set;}
        @AuraEnabled
        public Boolean checkable {get; set;}
        @AuraEnabled
        public String icon {get; set;}

        @AuraEnabled
        public Boolean focused {get; set;}
        @AuraEnabled
		public Boolean focusedBranch {get; set;}
        
		public Map<String, Object> buildAuraGridData(SObjectDisplayDescribe describe) {
            Map<String, Object> keyValues = new Map<String, Object>();
            keyValues.put('Id', record.Id);

            String key = describe.expandingProperty.field;
            Object value = record.get(describe.expandingProperty.field);
            keyValues.put(key, value);

            if (value != null) {
                String valStr = String.valueOf(value);
                Integer length = valStr.length();
                if (describe.expandingProperty.maxValueLength == null || describe.expandingProperty.maxValueLength < length)
                    describe.expandingProperty.maxValueLength = length;
            }

            key = describe.expandingProperty.field + '.link';
            value = '/' + record.Id;
            keyValues.put(key, value);

            if (!String.isEmpty(icon)) {
                keyValues.put('leadIcon', icon);
            }

            for (ColumnDefinition col : describe.colDefs) {
                key = col.field;
                value = record.get(col.field);
                keyValues.put(key, value);
                
                if (col.displayType == 'Reference' || col.displayType == 'CreatedBy' || col.displayType == 'LastModifiedBy') {
                    key = col.referencedObject  + '.' + col.referencedField;
                    value = transverse (record, key);
                    keyValues.put(key, value);

                    if (value != null) {
                        String valStr = String.valueOf(value);
                        Integer length = valStr.length();
                        if (col.maxValueLength == null || col.maxValueLength < length)
                            col.maxValueLength = length;
                    }
                    
                    if (value != null) {
                        system.debug('key=='+key);
                        key = col.referencedObject + '.' + col.referencedField + '.link';
                        value = '/' + String.valueOf(record.get(col.field));
                        keyValues.put(key, value);
                    }
                    
                }
                //Added as a part of SFDC-16036: START
                else if(key == 'C360_Account_Summary_Link__c'){
                    key = col.field + '.link';
                    value = String.valueOf(record.get(col.field));
                    keyValues.put(key, value);
                    key = col.field + '.linkLabel';
                    value = 'Link';
                    keyValues.put(key, value);
                }//Added as a part of SFDC-16036: END
                else {
                    if (value != null) {
                        String valStr = String.valueOf(value);
                        Integer length = valStr.length();
                        if (col.maxValueLength == null || col.maxValueLength < length)
                            col.maxValueLength = length;
                    }
                }
            }
			system.debug('keyValues--'+keyValues);
			return keyValues;
        }
    }

    /*----------------------------------------------------------------------*/
    /* SOQL, SOSL inquery                                                   */
    /*----------------------------------------------------------------------*/
	@RemoteAction
    @AuraEnabled
    public static SObjectHierarchyResults retrieveRecordByID(String recordID, List<SearchEntityInfo> searchEntities) {
        try {
            String idkeyPrefix = recordID.subString(0, 3);
            SearchEntityInfo searchEntity;
            for (SearchEntityInfo entity : searchEntities) {
                String keyPrefix = mSchema.get(entity.sObjectName).getDescribe().getKeyPrefix();
                if (keyPrefix.equals(idkeyPrefix))
                    searchEntity = entity;
            }
	        SObjectHierarchyResults r = new SObjectHierarchyResults(searchEntity);
            
            String soqlFields = String.join(new List<String>(r.describe.returningFields), ',');
            SObjectDisplayDescribe describe = new SObjectDisplayDescribe(searchEntity.sObjectName);
	        String query = 'Select ID, ' + soqlFields + ' From ' + searchEntity.sObjectName  + ' Where ID = \'' + recordID + '\'';
            r.setRecords(database.query(query));
            
	        return r;
        } catch (Exception e) {
        	SObjectHierarchyResults r = new SObjectHierarchyResults();
            r.errorMsg = e.getMessage();
            return r;
        }
    }
	
    /*
    String strEntities= '[{' +
                    '   "sObjectName" : "Contact",' +
                    '   "sObjectIcon" : "standard:contact",' +
                    '   "queryLimit" : "10",' +
                    '   "FieldSetAPIName" : "Test"' +
                    '}]';
    List<LightningUtility.SearchEntityInfo> searchEntities = (List<LightningUtility.SearchEntityInfo>)JSON.deserialize(strEntities, List<LightningUtility.SearchEntityInfo>.class);
    LightningUtility.SearchResults r = LightningUtility.searchRecords('Chris', searchEntities);
    for (LightningUtility.SObjectHierarchyResults hr : r.results) {
        System.Debug('*** ' + hr.getAuraGridColumnDefinition());
        System.Debug('*** ' + hr.getAuraGridData());
    }
    
    String strEntities= '[{' +
                    '   "sObjectName" : "Contact",' +
                    '   "sObjectIcon" : "standard:contact",' +
                    '   "queryLimit" : "10",' +
                    '   "displayFields" : ["Email", "Title", "Phone"]' +
                    '   },' +
                    '   {' +
                    '   "sObjectName" : "User",' +
                    '   "sObjectIcon" : "standard:user",' +
                    '   "queryLimit" : "10",' +
                    '   "displayFields" : ["Email", "Title"]' +
                    '}]';
    List<LightningUtility.SearchEntityInfo> searchEntities = (List<LightningUtility.SearchEntityInfo>)JSON.deserialize(strEntities, List<LightningUtility.SearchEntityInfo>.class);
    LightningUtility.SearchResults r = LightningUtility.searchRecords(searchEntities, 'Won'); 
    System.Debug('*** r.results ' + r.results);
    */
    @RemoteAction
    @AuraEnabled
    public static SearchResults searchRecords(String searchword, List<SearchEntityInfo> searchEntities) {
        SearchResults r = new SearchResults();
        
        try {
            String searchString = searchword == null ? '' : searchword.Trim();
            
            if (searchEntities.size() == 1 && (String.isEmpty(searchString) || searchString.length() <= 2)) {
                
                SearchEntityInfo entity = searchEntities[0];
                SObjectHierarchyResults hr = new SObjectHierarchyResults(entity);
                r.results.add(hr);
                
                Integer soqlLimit = 200;
                try {
                    Integer lmt = Integer.valueOf(entity.queryLimit); 
                    if (lmt > 0)
                        soqlLimit = lmt;
                } catch (Exception e) {}
                
                String soqlFields = String.join(new List<String>(hr.describe.returningFields), ',');
                String searchQuery;
                String lookupFilter = String.isEmpty(entity.lookupFilter) ? '' : ' AND ' + entity.lookupFilter.ReplaceAll('&apos;', '\'');
                
                if (String.isEmpty(searchString)) {
                    searchQuery = 'Select ID, ' + soqlFields +
                                         ' From ' + entity.sObjectName + 
                                        (' Where LastViewedDate <> NULL ' + lookupFilter) +
                                         ' Order by LastViewedDate desc ' + 
                                         ' LIMIT ' + String.valueOf(soqlLimit);
                } else {
                    searchQuery = 'Select ID, ' + soqlFields + 
                                        ' From ' + entity.sObjectName + 
                                        ' Where ' + hr.describe.nameField + ' LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'' + 
                                            lookupFilter + 
                                        ' Order by ' + hr.describe.nameField + 
                                        ' LIMIT ' + String.valueOf(soqlLimit);
                }
                hr.setRecords(database.query(searchQuery));
            } else if (!String.isEmpty(searchString) && searchString.length() > 2) {
                
                String[] strReturnings = new String[]{};
                Map<String, SObjectHierarchyResults> entityResults = new Map<String, SObjectHierarchyResults>();
                
                for (SearchEntityInfo entity : searchEntities) {
                    SObjectHierarchyResults hr = new SObjectHierarchyResults(entity);
                    r.results.add(hr);
                    
                    String keyPrefix = mSchema.get(entity.sObjectName).getDescribe().getKeyPrefix();
                    entityResults.put(keyPrefix, hr);
                    
                    Integer soqlLimit = 200;
                    try {
                        Integer lmt = Integer.valueOf(entity.queryLimit); 
                        if (lmt > 0)
                            soqlLimit = lmt;
                    } catch (Exception e) {}
                    
                    String soqlFields = String.join(new List<String>(hr.describe.returningFields), ',');
                    String lookupFilter = String.isEmpty(entity.lookupFilter) ? '' : ' WHERE ' + entity.lookupFilter.ReplaceAll('&apos;', '\'');
                    
                    String strReturning = entity.sObjectName + 
                                        '(' + soqlFields + 
                                            lookupFilter + 
                                            ' LIMIT ' + String.valueOf(soqlLimit) + ')';
                    strReturnings.add(strReturning);
                }
                
                if (strReturnings.size() > 0) {
                    String searchQuery = 'FIND \'' + searchString + '\' IN NAME FIELDS RETURNING ' + String.join(strReturnings, ',');
                    
                    List<List<SObject>> searchResultsResults = search.query(searchQuery);
                    if (Test.isRunningTest()) {
                        searchResultsResults = new List<List<SObject>>();
                        List<Account> accounts = [Select ID, Name, Website, AnnualRevenue, NumberOfEmployees, BillingState, BillingPostalCode, BillingCountry, CreatedDate, CreatedByID, CreatedBy.Name, LastModifiedDate, LastModifiedByID, LastModifiedBy.Name, CurrencyIsoCode From Account LIMIT 2];
                        searchResultsResults.add(accounts);
                    }
                    for (List<SObject> searchResults : searchResultsResults) {
                        if (searchResults.size() > 0) {
                            SObject firstRecord = searchResults[0];
                            String keyPrefix = String.valueOf(firstRecord.Id).subString(0, 3);
                            SObjectHierarchyResults hr = entityResults.get(keyPrefix);
                            
                            if (hr != null)
                                hr.setRecords(searchResults);
                        }
                    }
                }
            }
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        }
        
        return r;
    }
    
    /**************************************************************************
    * Builds query string
    ***************************************************************************/
    public static Set<String> getCustomFieldNames(Schema.SObjectType token, Boolean modifiableOnly) {
        Set<String> fieldNames = new Set<String>();
        
        Map<String, Schema.SObjectField> M = token.getDescribe().fields.getMap();
        for (String s : M.keySet()) {
            Schema.DescribeFieldResult r = M.get(s).getDescribe();
            if (r.isCustom() && (!modifiableOnly || (modifiableOnly && !r.isAutoNumber() && !r.isCalculated()))) {
                fieldNames.add(r.getName());
            }
        }
        
        return fieldNames;
    }
    
    public static String buildObjectQuery(Set<String> fieldNames, String specialFields, String whereClause, String sObjectName) {
        String queryStr = 'SELECT ';
        
        // standard fields
        queryStr += 'Id';
        queryStr += ', Name';
        
        if(specialFields != null) {
            queryStr += ',' + specialFields;
        }
        
        // custom fields
        if (fieldNames != null) {
            for (String fieldName : fieldNames) {
                if (fieldName == 'Id' || fieldName == 'Name') {
                    continue;
                }
                
                queryStr += ',' + fieldName;
            }
        }
        
        queryStr += ' FROM ' + sObjectName;
        
        if(whereClause != null) {
            queryStr += ' WHERE ';
            queryStr += whereClause;
        }
        
        return queryStr;
    }

    /**
    * Dynamically transverse dynamically SOQL'd SObject fields
    */
    public static Object transverse (SObject record, String inputFieldPath) {
        if (record == null)
            return null; 
        
        SObject currentSObject = record;
        String fieldPath = inputFieldPath;

        while (fieldPath.contains('.')) {
            List<String> pathPartList = fieldPath.split ('[.]', 2);
            currentSObject = (SObject) currentSObject.getSobject(pathPartList[0]);
            
            if (currentSObject == null) { 
            	System.Debug(Logginglevel.INFO, '*** (transverse) no more value');
                return null; 
            }
            fieldPath = pathPartList[1];
        }
        
        return currentSObject.get(fieldPath);
    }
}