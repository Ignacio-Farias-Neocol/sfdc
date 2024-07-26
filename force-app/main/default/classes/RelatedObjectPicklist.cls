/**
 * Created by rsieve on 5/17/18.
 */

global with sharing class RelatedObjectPicklist extends VisualEditor.DynamicPickList{

    VisualEditor.DesignTimePageContext context;
    Schema.SObjectType sObjType;

    global RelatedObjectPicklist(VisualEditor.DesignTimePageContext context){
        this.context = context;
        system.debug('entityName: ' + this.context.entityName);
        this.sObjType = Schema.getGlobalDescribe().get(this.context.entityName).getDescribe().getSObjectType();
    }

    global override VisualEditor.DataRow getDefaultValue(){

        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('red', 'RED');
        //return defaultValue;
        return null;
    }
    global override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();

        for(Schema.ChildRelationship childRelationship : sObjType.getDescribe().getChildRelationships()){
            Schema.SObjectType childSObjType = childRelationship.getChildSObject();
            system.debug(childRelationship.getRelationshipName());
            if(childRelationship.getRelationshipName() == null) continue;
            VisualEditor.DataRow iRow = new VisualEditor.DataRow(childRelationship.getRelationshipName(), childSObjType.getDescribe().getName() + '.' + childRelationship.getField().getDescribe().getName());
            myValues.addRow(iRow);
        }

        return myValues;
    }

    global override string getLabel(Object attributeValue){


        for(Schema.ChildRelationship childRelationship : sObjType.getDescribe().getChildRelationships()){
            Schema.SObjectType childSObjType = childRelationship.getChildSObject();
            system.debug(childRelationship.getRelationshipName());
            if(childRelationship.getRelationshipName() == null) continue;
            string fullName = childSObjType.getDescribe().getName() + '.' + childRelationship.getField().getDescribe().getName();
            if(fullName == string.valueOf(attributeValue)){
                return childRelationship.getRelationshipName();
            }
        }
        system.debug(attributeValue);
        return string.valueOf(attributeValue);
    }

    global override boolean isValid(Object attributeValue){
        system.debug(attributeValue);
        return true;
    }
}