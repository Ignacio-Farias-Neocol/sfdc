@RestResource(UrlMapping='/ExportQueryBuilder/*')
global with sharing class ExportQueryBuilder {
    private static set<string> removeFields = new set<string>{'id', 'ownerid', 'isdeleted', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp','lastvieweddate', 'lastreferenceddate', 'isarchived'};
    @HttpGet
    global static string returnExportQuery(){
        RestRequest req = RestContext.request;
        String sObjectName = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        //Schema.DescribeSObjectResult sObjDescribe = sObjectType.getDescribe();
        Schema.DescribeSObjectResult sObjDescribe = Schema.getGlobalDescribe().get(sObjectName.toLowerCase()).getDescribe();
        set<string> fs = new set<string>();
        fs.addAll(sObjDescribe.fields.getMap().keySet());
        fs.removeall(removeFields);
        list<string> queryFields = new list<string>();
        for(string f : fs){
            Schema.DescribeFieldResult dfr = sObjDescribe.fields.getMap().get(f).getDescribe();
            if(dfr.isCalculated() || !dfr.isUpdateable()){
                continue;
            }

            if(dfr.getReferenceTo().size() == 1){
                Schema.DescribeSObjectResult lookupDescribe = Schema.getGlobalDescribe().get(dfr.getReferenceTo()[0].getDescribe().getName()).getDescribe();
                //system.debug(JSON.serialize(lookupDescribe.fields.getMap().keySet()));
                if(lookupDescribe.fields.getMap().containsKey('extid__c')){
                    if(f.right(3) == '__c'){
                        queryFields.add(f.left(f.length()-3) + '__r.extid__c');
                    }else{
                        queryFields.add(f.left(f.length()-2) + '.extid__c');
                    }
                }
            }else{
                queryFields.add(f);
            }

        }
        string q = 'SELECT ';
        q+= string.join(queryFields, ',');
        q+= ' FROM ' + sObjDescribe.getName();
        system.debug(q);
        return q;
    }
}