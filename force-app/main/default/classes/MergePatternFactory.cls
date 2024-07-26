public with sharing class MergePatternFactory 
{
    //public static String configStatus;
    //public static List<String> patternNames;

    public static List<MergePattern__c> getMergePatterns()
    {
        // Init the default merge patterns for all opportunity child objects via describe.
        List<MergePattern__c> defaultMergePatterns = getDefaultMergePatterns();
        // Load the existing merge patterns from custom settings.
        Map<String, MergePattern__c> currentMergePatternMap = loadCurrentMergePatterns();

        return generateNewMergePatterns(defaultMergePatterns, currentMergePatternMap);
    }

    // Use describe to find out all opportunity child objects that are either createable or updateable.
    private static List<MergePattern__c> getDefaultMergePatterns()
    {
        List<MergePattern__c> defaultPatterns = new List<MergePattern__c>();
        // Get Opportunity Describe Result
        Schema.DescribeSObjectResult oppDescribeResult = Opportunity.sobjectType.getDescribe();        
        Schema.DescribeSObjectResult childObjectDescribe;
        Schema.DescribeFieldResult fieldDescribe;    
        Integer index = 10;    
        // Loop the opportunity child objects
        for(Schema.ChildRelationship cr : oppDescribeResult.getChildRelationships())
        {
            childObjectDescribe = cr.getChildSObject().getDescribe();
            if(childObjectDescribe.isCreateable() || childObjectDescribe.isUpdateable())
            {
                fieldDescribe = cr.getField().getDescribe();
                defaultPatterns.add(new MergePattern__c(ObjectName__c = childObjectDescribe.getName(),
                                                        FieldName__c = fieldDescribe.getName(),
                                                        MergePattern__c = 'Merge',
                                                        Name = 'OpportunityChild' + index,
                                                        IsVisible__c = false));
                index++;
            }
        }
        return defaultPatterns;
    }

    private static Map<String, MergePattern__c> loadCurrentMergePatterns()
    {
        Map<String, MergePattern__c> currentMergePatternMap = new Map<String, MergePattern__c>();
        for(MergePattern__c pattern : [select Id, Name, ObjectName__c, FieldName__c, MergePattern__c, IsVisible__c
                                       from MergePattern__c order by Name])
        {
            currentMergePatternMap.put(pattern.ObjectName__c + pattern.FieldName__c, pattern);
        }
        return currentMergePatternMap;
    }

    private static List<MergePattern__c> generateNewMergePatterns(List<MergePattern__c> defaultPatterns, Map<String, MergePattern__c> currentPatternMap)
    {
        if(currentPatternMap.isEmpty())
        {
            return defaultPatterns;
        }

        List<MergePattern__c> newPatterns = new List<MergePattern__c>();
        MergePattern__c newPattern;
        String key;
        // If there is any new child object that hasn't been defined in the merge pattern,
        // then we will need to add them to the merge patterns and adjust the pattern name for each line.
        Boolean isUpsertRequired = false;
        for(MergePattern__c defaultPattern : defaultPatterns)
        {
            key = defaultPattern.ObjectName__c + defaultPattern.FieldName__c;
            if(currentPatternMap.containsKey(key))
            {
                newPattern = currentPatternMap.get(key);
                // Reset the pattern name 
                newPattern.Name = defaultPattern.Name;
                currentPatternMap.remove(key);
            }
            else
            {
                newPattern = defaultPattern;
                isUpsertRequired = true;
            }
            newPatterns.add(newPattern);
        }

        if(!currentPatternMap.isEmpty())
        {
            delete currentPatternMap.values();
        }

        if(isUpsertRequired)
        {
            upsert newPatterns;
        }
        return newPatterns;
    }

    public static void upsertMergePatterns(List<MergePattern__c> patterns)
    {
        if(patterns != null && !patterns.isEmpty())                
        {
            upsert patterns;  
        }        
    }
}