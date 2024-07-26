public with sharing class MergeOpportunityController  
{
    // Duplicate records to be merged.
    public List<Opportunity> DuplicateOpps { get; set; }
    // All updateable fields
    public List<String> Fields { get; set; }
    public Map<String, FieldComparison> ComparisonMap { get; set; }

    public Integer SelectedMaster { get; set; }
    public String SelectedFieldsValue { get; set; }
    
    //public String ConfigStatus { get; private set; }
    public List<MergePattern__c> MergePatterns { get; set; }
    
    public Set<String> excludeobjects = new Set<String>();

    private String defaultMasterId;        

    public MergeOpportunityController() 
    {
        // Find all opportunity fields that are updateable.
        initUpdateableFields();
        retrieveRecords();
        

        

        for(String fieldName : Fields)
        {
            ComparisonMap.get(fieldName).IsIdentical = isIdentical(fieldName);
            ComparisonMap.get(fieldName).IsEmpty = isEmpty(fieldName);
        }
    }

    public void initChildObjectsMergePattern()
    {
        MergePatterns = MergePatternFactory.getMergePatterns();
    }

    public PageReference mergeDuplicates()
    {
        Savepoint sp = Database.setSavepoint();
        
        for(Opportunity_Merge_Setting__mdt excludeobj : [Select Object_API_Name__c from Opportunity_Merge_Setting__mdt]){
            excludeobjects.add(excludeobj.Object_API_Name__c);
        }
        
        Opportunity masterOpp = DuplicateOpps[SelectedMaster];
        System.debug('masterOpp: ' + masterOpp);
        try
        {
            
            mergeFieldsValue(masterOpp);
            mergeRelatedLists(masterOpp.Id);
            deleteDuplicates();
           
            return new PageReference('/' + masterOpp.Id);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }
    }
    public PageReference previous()
    {
        return new PageReference('/apex/FindOppDuplicates?id=' + defaultMasterId);
    }
    public PageReference cancel()
    {
        return new PageReference('/' + defaultMasterId);
    }

    private void mergeFieldsValue(Opportunity masterOpp)
    {
        List<String> fieldDetail;
        String fieldName;
        Integer fieldIndex;
        if(String.isNotBlank(SelectedFieldsValue))
        {
            for(String selectedField : SelectedFieldsValue.split('&'))
            {
                fieldDetail = selectedField.split(',');
                fieldName = fieldDetail[0];
                System.debug('***Field Name: ' + fieldName);
                fieldIndex = Integer.valueOf(fieldDetail[1]);
                // if the field selected is not on the master record.
                System.debug('*** fieldIndex: ' + fieldIndex + ' ***SelectedMaster: ' + SelectedMaster );
                if(fieldIndex != SelectedMaster)
                {
                    /** SFDC-9041
                    * Check if the Original Opportunity Field is being updated. 
                    * If this field value is same as the Master Opp ID, then merge errors out.
                    * Hence do not copy this field if it is same as Master Opp Id 
                    */
                    if(fieldName.equalsIgnoreCase('Original_Opportunity__c')){
                        System.debug('*** masterOpp: ' + masterOpp.Id + ' ***DuplicateOpps[fieldIndex].get(fieldName): ' + DuplicateOpps[fieldIndex].get(fieldName) );
                    }
                    
                    if(fieldName.equalsIgnoreCase('Original_Opportunity__c') && 
                       masterOpp.Id == DuplicateOpps[fieldIndex].get(fieldName)){
                        continue;
                    }
                    masterOpp.put(fieldName, DuplicateOpps[fieldIndex].get(fieldName));
                }
            }
            update masterOpp;
        }
    }

    private void mergeRelatedLists(String masterOppId)
    {
        System.debug('masterOppId: ' + masterOppId);
        List<String> losingOppIds = new List<String>();
        for(Opportunity opp : DuplicateOpps)
        {
            if(opp.Id != masterOppId)
            {
                losingOppIds.add(opp.Id);
            }
        }
        System.debug('losingOppIds: ' + losingOppIds);

        Schema.DescribeSObjectResult sObjectDescribe = Opportunity.sobjectType.getDescribe();        
        for(Schema.ChildRelationship cr : sObjectDescribe.getChildRelationships())
        {
            mergeChildRecords(masterOppId, losingOppIds, cr);
        }
    }
    private void initUpdateableFields()
    {
        Fields = new List<String>();
        ComparisonMap = new Map<String, FieldComparison>();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for(String fieldName : fieldMap.keySet())
        {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if(fieldDescribe.isUpdateable() && !fieldDescribe.isDeprecatedAndHidden())
            {
                Fields.add(fieldName);
                ComparisonMap.put(fieldName, new FieldComparison(fieldDescribe.getLabel(), fieldName));
            }
        }
    }

    private void retrieveRecords()
    {
        DuplicateOpps = new List<Opportunity>();

        // retrieve master record
        defaultMasterId = ApexPages.currentPage().getParameters().get('master');
        String queryString = 'select Id,' + String.join(Fields, ',') + ' from Opportunity';
        if(String.isNotBlank(defaultMasterId))
        {
            DuplicateOpps.add(Database.query(String.escapeSingleQuotes(queryString) + ' where Id = :defaultMasterId'));
        }

        // retrieve duplicate records.
        List<String> oppIds = new List<String>();
        String duplicateOppIds = ApexPages.currentPage().getParameters().get('duplicates');
        if(String.isNotBlank(duplicateOppIds))
        {
            oppIds = duplicateOppIds.split(';');
        }        
        DuplicateOpps.addAll((List<Opportunity>)Database.query(String.escapeSingleQuotes(queryString) + ' where Id in :oppIds'));

        if(String.isBlank(defaultMasterId))
        {
            defaultMasterId = DuplicateOpps[0].Id;
        }
    }

    private void mergeChildRecords(String masterOppId, List<String> losingOppIds, Schema.ChildRelationship cr)
    {
        Schema.DescribeSObjectResult sObjectDescribe = cr.getChildSObject().getDescribe();
        String childObjectName = sObjectDescribe.getName();
        SYstem.debug('childObjectName: ' + childObjectName);
        SYstem.debug('excludeobjects: ' + excludeobjects);
        
        //List<Opportunity_Merge_Settings__mdt> listexcludeobject = [Select Object_API_Name__c from Opportunity_Merge_Settings__mdt];
       
        //excludeobjects.add('OpportunityShare');
        
        // Exclude child objects that don't need to be merged.
        /* if(!childObjectName.equalsIgnoreCase('OpportunityShare') 
        && !childObjectName.equalsIgnoreCase('FeedItem')
        && !childObjectName.equalsIgnoreCase('OpportunityOverride')
        && !childObjectName.equalsIgnoreCase('TaskRelation')
        && !childObjectName.equalsIgnoreCase('OutgoingEmail')
        && !childObjectName.equalsIgnoreCase('OpportunitySplit')          
        && !childObjectName.equalsIgnoreCase('OpportunityTeamMember')
        && !childObjectName.equalsIgnoreCase('AccountPartner')
        && !childObjectName.equalsIgnoreCase('OpportunityPartner'))  
       */ 
        
       if(!excludeobjects.contains(childObjectName))                  
        {
            // If the child object is createable or updateable
            if(sObjectDescribe.isCreateable() || sObjectDescribe.isUpdateable())
            {
                Schema.DescribeFieldResult fieldDescribe = cr.getField().getDescribe();

                // If the lookup field is updateable
                if(fieldDescribe.isUpdateable())
                {
                    transferToMaster(masterOppId, losingOppIds, sObjectDescribe.getName(), fieldDescribe.getName());
                }
                else if(fieldDescribe.isCreateable())
                {
                    copyChildRecords(masterOppId, losingOppIds, sObjectDescribe, fieldDescribe.getName());
                }
            }
        }
    }

    private void transferToMaster(String masterOppId, List<String> losingOppIds, String childObject, String relationshipField)
    {
        String queryString = 'select Id,' + relationshipField + ' from ' + childObject;
        queryString += ' where ' + relationshipField + ' in :losingOppIds';

        System.debug('childObject: ' + childObject);
        System.debug('relationshipField: ' + relationshipField);

        List<sObject> childRecords = Database.query(String.escapeSingleQuotes(queryString));        
        for(sObject childRecord : childRecords)
        {
            childRecord.put(relationshipField, masterOppId);
        }
        System.debug('childRecords: ' + childRecords);
        update childRecords;
    }

    private void copyChildRecords(String masterOppId, List<String> losingOppIds, Schema.DescribeSObjectResult sObjectDescribe, String relationshipField)
    {
        String objectName = sObjectDescribe.getName();        
        List<String> createableFields = new List<String>();
        System.debug('objectName: ' + objectName);
        Map<String, Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap();
        for(String fieldName : fieldMap.keySet())
        {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if(fieldDescribe.isCreateable())
            {                
                // Cannot specify both UnitPrice and TotalPrice
                if(objectName.equalsIgnoreCase('OpportunityLineItem') && fieldName.equalsIgnoreCase('TotalPrice'))
                {
                    continue;
                }
                // Cannot specify both Opportunity and AccountFrom
                if(objectName.equalsIgnoreCase('Partner') && fieldName.equalsIgnoreCase('AccountFromId'))
                {
                    continue;
                }
                // ActivityId can only be specified for emails on cases. It’s auto-created for other entities, like Opportunity.
                if(objectName.equalsIgnoreCase('EmailMessage') && (fieldName.equalsIgnoreCase('ActivityId') || fieldName.equalsIgnoreCase('FromAddress')) )
                {
                    continue;
                }                
                createableFields.add(fieldDescribe.getName());
            }
        }

        String queryString = 'select Id,' + String.join(createableFields, ',') + ' from ' + objectName;
        queryString += ' where ' + relationshipField + ' in :losingOppIds';

        queryString=String.escapeSingleQuotes(queryString);
        
        // Ignore Account-Account Partner.
        if(objectName.equalsIgnoreCase('Partner'))
        {
            queryString += ' and Role != \'Client\'';
        }
        if(objectName.equalsIgnoreCase('EntitySubscription'))
        { 
            queryString += ' limit 1000'; 
        }
        System.debug('queryString: ' + queryString);
        List<sObject> childRecords = Database.query((queryString));
        if(childRecords.size() > 0)
        {
            List<sObject> newRecords = new List<sObject>();
            for(sObject childRecord : childRecords)
            {
                sObject cloned = childRecord.clone(false, false, false, false);
                //SFDC-14631 - Need to bring the email messages from losing opty to winnning opty. Due to restricted picklist 
                //for From field on EmailMessage object, ValidatedFromAddress should be set to null.
                if(childRecord.getSObjectType() == Schema.getGlobalDescribe().get('EmailMessage')){

                    ((EmailMessage)cloned).ValidatedFromAddress = null;
                }
                newRecords.add(cloned);
            }
            for(sObject newRecord : newRecords)
            {
                newRecord.put(relationshipField, masterOppId);
            }
            System.debug('$$' + newRecords);
            insert newRecords;
            delete childRecords;
        }
    }

    // Check if the field value on all records are identical.
    private Boolean isIdentical(String fieldName)
    {
        Integer size = DuplicateOpps.size();
        for(Integer i = 0; i < size-1; i++)
        {
            if(DuplicateOpps[i].get(fieldName) != DuplicateOpps[i+1].get(fieldName))
            {
                return false;
            }
        }
        return true;
    }

    // Check if the field value on all records are empty.
    private Boolean isEmpty(String fieldName)
    {
        for(Opportunity opp : DuplicateOpps)
        {
            if(opp.get(fieldName) != null)
            {
                return false;
            }
        }
        return true;
    }

    private void deleteDuplicates()
    {
        List<Opportunity> oppsToDelete = new List<Opportunity>();
        Integer size = DuplicateOpps.size();
        for(Integer i = 0; i < size; i++)
        {
            if(i != SelectedMaster)
            {
                oppsToDelete.add(DuplicateOpps[i]);
            }
        }
        delete oppsToDelete;
    }

    public class FieldComparison
    {
        public String FieldLabel { get; set; }
        public String FieldName { get; set; }
        public Boolean IsIdentical { get; set; }
        public Boolean IsEmpty { get; set; }
        public String ClassName
        {
            get
            {
                if(IsEmpty)
                {
                    return 'empty';
                }
                if(IsIdentical)
                {
                    return 'identical';
                }
                return 'required-input';
            }
        }

        public FieldComparison(String fieldLabel, String fieldName)
        {
            this.FieldLabel = fieldLabel;
            this.FieldName = fieldName;
        }        
    }
}