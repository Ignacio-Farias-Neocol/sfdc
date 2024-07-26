/**
 * Created by rsieve on 5/16/18.
 */

global with sharing class FieldsetRelatedListCon {

    @AuraEnabled
    global static Object fetchGridColumns(string fieldFullName, string fieldSetName){
        system.debug('~~~~~FieldsetRelatedListCon.fetchGridColumns ');
        system.debug(fieldFullName);
        system.debug(fieldSetName);
        list<string> splitPath = fieldFullName.split('\\.');

        string sObjectName = splitPath[0].toLowerCase();
        system.debug('~~~~~ sObjectName --' + sObjectName + '--');
        Schema.DescribeSObjectResult sObjDescribe = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        Schema.FieldSet fieldSet = sObjDescribe.fieldSets.getMap().get(fieldSetName.toLowerCase());
        map<string, Schema.SObjectField> mFields = sObjDescribe.fields.getMap();

        system.debug(fieldset);

        List<map<string, Object>> colConfig = new List<map<string, Object>>();
        for(Schema.FieldSetMember fsm : fieldSet.fields){

            if(mFields.containsKey(fsm.getFieldPath().toLowerCase())){
                Schema.DescribeFieldResult fieldDescribe = mFields.get(fsm.getFieldPath()).getDescribe();
                if(fieldDescribe.isNameField()){
                    map<string, Object> mCol = new map<string, Object>();
                    mCol.put('label', fsm.getLabel());
                    mCol.put('fieldName', 'Id');
                    system.debug(fsm.type.name());
                    mCol.put('type', 'url');
                    map<string, Object> iAttr = new map<string, Object>();
                    iAttr.put('label', new map<string, string>{'fieldName' => fsm.getFieldPath()});
                    iAttr.put('target', '_blank');
                    mCol.put('typeAttributes', iAttr);
                    mCol.put('wrapText', true);
                    colConfig.add(mCol);
                }else{
                    map<string, Object> mCol = new map<string, Object>();
                    mCol.put('label', fsm.getLabel());
                    mCol.put('fieldName', fsm.getFieldPath());
                    system.debug(fsm.type.name());
                    mCol.put('type', GridUtils.gridTypes.get(fsm.type.name()));
                    if(mCol.get('type') == 'url'){
                        map<string, Object> iAttr = new map<string, Object>();
                        iAttr.put('label', new map<string, string>{'fieldName' => fsm.getFieldPath().replace('__c','__r.Name')});
                        iAttr.put('target', '_blank');
                        mCol.put('typeAttributes', iAttr);
                    }
                    mCol.put('wrapText', true);
                    colConfig.add(mCol);
                }
            }
            else{
                map<string, Object> mCol = new map<string, Object>();
                mCol.put('label', fsm.getLabel());
                mCol.put('fieldName', fsm.getFieldPath());
                system.debug(fsm.type.name());
                mCol.put('type', GridUtils.gridTypes.get(fsm.type.name()));
                if(mCol.get('type') == 'url'){
                    map<string, Object> iAttr = new map<string, Object>();
                    iAttr.put('label', new map<string, string>{'fieldName' => fsm.getFieldPath().replace('__c','__r.Name')});
                    iAttr.put('target', '_blank');
                    mCol.put('typeAttributes', iAttr);
                }
                mCol.put('wrapText', true);
                colConfig.add(mCol);
            }


        }

        system.debug('~~~~~ CONFIG: ' +JSON.serialize(colConfig));
        return colConfig;
    }

    /*
    @AuraEnabled
    global static Object fetchGridColumns(string sObjectName, string fieldSetName){
        system.debug(sObjectName);
        system.debug(fieldSetName);
        Schema.FieldSet fieldSet = Schema.getGlobalDescribe().get(sObjectName.toLowerCase()).getDescribe().fieldSets.getMap().get(fieldSetName);
        system.debug(fieldset);
        List<map<string, Object>> colConfig = new List<map<string, Object>>();
        for(Schema.FieldSetMember fsm : fieldSet.fields){
            map<string, Object> mCol = new map<string, Object>();
            mCol.put('label', fsm.getLabel());
            mCol.put('fieldName', fsm.getFieldPath());
            mCol.put('type', GridUtils.gridTypes.get(fsm.type.name()));
            colConfig.add(mCol);
        }

        return colConfig;
    }
    */

    /**
     *
     *
     * @param recordId - record id from the lighting component  e.g. id of account
     * @param fieldFullName - full name of the related object joined to record id. e.g. Contact.accountId
     * @param fieldSetName - field set to be displayed
     * @param addlFields - additonal fields to be added
     *
     * @return
     */
    @AuraEnabled
    global static List<sObject> fetchData(Id recordId, string fieldFullName, string fieldSetName, list<string> addlFields){

        system.debug('~~~~~FieldsetRelatedListCon.fetchData ');
        system.debug('~~~~~' + fieldFullName + '~~~~~');
        system.debug('~~~~~' + fieldSetName + '~~~~~');
        list<string> splitPath = fieldFullName.split('\\.');

        string sObjectName = splitPath[0].toLowerCase();
        Schema.DescribeSObjectResult sObjDescribe = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        Schema.FieldSet fieldSet = sObjDescribe.fieldSets.getMap().get(fieldSetName.toLowerCase());

        set<string> fields = new set<string>{'id'};
        for(string f : addlFields){
            if(String.isNotBlank(f)){
                fields.add(f.toLowerCase());
            }
        }
        for(Schema.FieldSetMember fsm : fieldSet.fields){
            if(!fsm.getFieldPath().contains('.')){
                Schema.DescribeFieldResult fieldDescribe = sObjDescribe.fields.getMap().get(fsm.getFieldPath()).getDescribe();
                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){
                    Schema.SObjectType sObjType = fieldDescribe.getReferenceTo()[0];
                    Schema.DescribeSObjectResult relatedSobjDescribe = sObjType.getDescribe();
                    for(Schema.SObjectField f : relatedSobjDescribe.fields.getMap().values()){
                        Schema.DescribeFieldResult relatedDescribeFieldResult = f.getDescribe();
                        if(relatedDescribeFieldResult.isNameField()){
                            if(relatedDescribeFieldResult.isCustom() || fsm.getFieldPath().right(3) == '__c'){
                                fields.add(fsm.getFieldPath().replace('__c', '__r') + '.' + relatedDescribeFieldResult.getName());
                            }else{
                                fields.add(fsm.getFieldPath().left(fsm.getFieldPath().length() - 2) + '.' + relatedDescribeFieldResult.getName());
                            }
                            break;
                        }
                    }
                }
            }
            fields.add(fsm.getFieldPath().toLowerCase());
        }
        System.debug('**Feilds: ' + fields);
        string query = 'SELECT ';
        query += string.join(new list<string>(fields), ',');
        query += ' FROM ';
        query += splitPath[0];
        query += ' WHERE ' + splitPath[1] + ' = \'' + recordId + '\'';

        system.debug('***fieldsetquery ' + query);
        List<sObject> recs = Database.query(query);
        system.debug('DATA ~~~~~' + JSON.serialize(recs) + '~~~~~');

        return recs;

    }
}