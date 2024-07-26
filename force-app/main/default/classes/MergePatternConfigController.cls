public with sharing class MergePatternConfigController 
{
    public List<MergePattern__c> Patterns { get; set; }    

    /*public MergePatternConfigController() 
    {        
        Patterns = MergePatternFactory.getMergePatterns();
    }
    */
    
    public void initMergePatterns()
    {
        Patterns = MergePatternFactory.getMergePatterns();
    }

    public void saveMergePatterns()
    {
        MergePatternFactory.upsertMergePatterns(Patterns);
    }
}