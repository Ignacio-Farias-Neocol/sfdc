public with sharing class FindOppDuplicatesExtension 
{
    public Boolean HasMergeAllOppPermission { get; set; }
    public Boolean HasMergeOwnOppPermission { get; set; }
    public String Keyword { get; set; }

    public List<OpportunityWrapper> OpportunityList { get; set; }
    private Id masterOppId;

    private static final String MERGE_ALL_OPEN_OPPORTUNITY = 'De_duplicate_All_Open_Opportunity_Permission';
    private static final String MERGE_OPEN_OPPORTUNITY = 'De_duplicate_Open_Opportunity_Permission';
    private static final Integer MAX_ROWS = 500;
    
    public FindOppDuplicatesExtension(ApexPages.StandardController stdController) 
    {
        Integer mergeAll = [select count() from PermissionSetAssignment where AssigneeId = :UserInfo.getUserId() and PermissionSet.Name = :MERGE_ALL_OPEN_OPPORTUNITY];
        Integer mergeOwn = [select count() from PermissionSetAssignment where AssigneeId = :UserInfo.getUserId() and PermissionSet.Name = :MERGE_OPEN_OPPORTUNITY];
        HasMergeAllOppPermission = mergeAll > 0;
        HasMergeOwnOppPermission = mergeAll > 0 || mergeOwn > 0;

        masterOppId = stdController.getId();
        system.debug('stdController.getId();  = '  + stdController.getId());
        retrieveOpportunity();
    }
    
    public PageReference next()
    {
        PageReference pageRef = new PageReference('/apex/MergeOpportunity');
        List<String> selectedOppIds = new List<String>();  
        for(OpportunityWrapper wrapper : OpportunityList)
        {
            if(wrapper.IsSelected)
            {
                if(wrapper.Opp.Id == masterOppId)
                {
                    pageRef.getParameters().put('master', masterOppId);
                }
                else
                {
                    selectedOppIds.add(wrapper.Opp.Id);
                }
            }
        }
        
        pageRef.getParameters().put('duplicates', String.join(selectedOppIds, ';'));
        return pageRef;
    }
    public class OpportunityWrapper
    {
        public Boolean IsSelected { get; set; }
        public Opportunity Opp { get; set; }

        public OpportunityWrapper(Boolean isSelected, Opportunity opp)
        {
            this.IsSelected = isSelected;
            this.Opp = opp;
        }
    }  

    public void retrieveOpportunity()
    {
        Integer limits = MAX_ROWS;
        OpportunityList = new List<OpportunityWrapper>();
        // Select the opportunity that starts the process
        Opportunity currentOpp = [select Id, Name, OwnerId, Owner.Name, AccountId, Account.Name, 
                                         Amount, StageName, IsClosed, CloseDate, 
                                         CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate
                                  from Opportunity where Id = :masterOppId];
        // Add the opportunity to the list if it's not closed yet
        /*
        if(!currentOpp.IsClosed)
        {
            if(currentOpp.OwnerId == UserInfo.getUserId() || HasMergeAllOppPermission)
            {
                OpportunityList.add(new OpportunityWrapper(true, currentOpp));
                limits--;
            }
        } 
        */
        if(currentOpp.OwnerId == UserInfo.getUserId() || HasMergeAllOppPermission)
        {
            OpportunityList.add(new OpportunityWrapper(true, currentOpp));
            limits--;
        }   

        List<Opportunity> opps = new List<Opportunity>();  
        // Add open opportunities that are associated with the same account as the current opportunity.
        String selectFields = 'select Id,Name,OwnerId,Owner.Name,AccountId,Account.Name,Amount,StageName,';
        selectFields += 'IsClosed,CloseDate,CreatedBy.Name,CreatedDate,LastModifiedBy.Name,LastModifiedDate';
        String queryString = selectFields + ' from Opportunity';
        queryString += ' where AccountId = \'' + String.escapeSingleQuotes(currentOpp.AccountId) + '\'';
        queryString += ' and Id != \'' + String.escapeSingleQuotes(currentOpp.Id) + '\'';
        //queryString += ' and IsClosed = false';        
        if(!HasMergeAllOppPermission)
        {
            queryString += ' and OwnerId = \'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\'';
        }
        if(String.isNotBlank(Keyword))
        {
            String keywordPattern = '%' + Keyword + '%';
            queryString += ' and Name LIKE :keywordPattern';
        }
        queryString += ' order by LastModifiedDate desc limit :limits';
       
        opps.addAll((List<Opportunity>)Database.query((queryString)));
        limits = limits - opps.size();

        if(limits > 0)
        {
            // Add the rest of open opportunities.
            queryString = selectFields + ' from Opportunity';
            queryString += ' where AccountId != \'' + String.escapeSingleQuotes(currentOpp.AccountId) + '\'';
            //queryString += ' and IsClosed = false';     
            if(!HasMergeAllOppPermission)
            {
                queryString += ' and OwnerId = \'' + String.escapeSingleQuotes(UserInfo.getUserId()) + '\'';
            }
            if(String.isNotBlank(Keyword))
            {
                String keywordPattern = '%' + Keyword + '%';
                queryString += ' and Name LIKE :keywordPattern';
            }
            queryString += ' order by LastModifiedDate desc limit :limits';   
            opps.addAll((List<Opportunity>)Database.query(queryString)); 
        }

        for(Opportunity opp : opps)
        {
            OpportunityList.add(new OpportunityWrapper(false, opp));
        }
    }
}