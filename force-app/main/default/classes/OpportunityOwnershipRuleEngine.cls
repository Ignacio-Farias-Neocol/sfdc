/**
* @author Salesforce Services
* @date 10/29/2020
*
* @group Rule Engine
*
* @description: Rule engine used to determine the Opportunity ownership based on Territory
*/
public with sharing class OpportunityOwnershipRuleEngine extends RuleEngine {

    //Assigns owner to Opportunity based on defined rules
    public List<Opportunity> assignOwners(List<Opportunity> opportunityRecords, List<Opportunity_Ownership_Rule__c> rules){
        //Map containing the territory ID and related Opportunities
        Map<Id, List<Opportunity>> territoryIdOppMap = new Map<Id, List<Opportunity>>();
        
        //Map built to return the list of opportunities
        Map<Id,Opportunity> returnOpptyMap = new Map<Id,Opportunity>();

        System.debug('***OPPTY TO BE UPDATED:' + opportunityRecords);
        //Loop through Opportunities to identify territories
        for(Opportunity currentOpp: opportunityRecords){
            if(currentOpp.Territory2Id!=null){
                if(territoryIdOppMap.containsKey(currentOpp.Territory2Id)){
                    territoryIdOppMap.get(currentOpp.Territory2Id).add(currentOpp);
                }
                else{
                    territoryIdOppMap.put(currentOpp.Territory2Id, new List<Opportunity>{currentOpp});
                }
            }
            
        } //END FOR

        //Determine the ownership rules to be executed
        List<Opportunity_Ownership_Rule__c> rulesTobeEvaluated;
        if(rules!=null && !rules.isEmpty()){
            rulesTobeEvaluated = rules;
        }
        else{
            rulesTobeEvaluated = [SELECT Advanced_Condition__c,
                                         Conditions_Met__c,
                                         Opportunity_Owner__c,
                                         TerritoryID__c,
                                         (SELECT Field_API_Name__c, 
                                                 Index__c,
                                                 Operator__c,
                                                 Value__c 
                                          FROM Opportunity_Ownership_Condition__r) 
                                  FROM Opportunity_Ownership_Rule__c 
                                  WHERE Active__c = true 
                                  AND TerritoryID__c in :territoryIdOppMap.keyset()];
        }

        //Loop through all active rules and determine the opportunity owner 
        for(Opportunity_Ownership_Rule__c rule: rulesTobeEvaluated){
            //For the territory defined in the rule get all oppties
            if(territoryIdOppMap.containsKey(rule.TerritoryID__c)){
                for(Opportunity currentOpp: territoryIdOppMap.get(rule.TerritoryID__c)){
                    if(!returnOpptyMap.containsKey(currentOpp.Id)){
                        if(evaluateRule(rule, currentOpp)){
                            if(currentOpp.OwnerId != rule.Opportunity_Owner__c){
                                returnOpptyMap.put(currentOpp.Id, new Opportunity(Id = currentOpp.Id, OwnerId = rule.Opportunity_Owner__c));
                            }
                        }
                    }
                } //END FOR
            }
        }

        if(returnOpptyMap!=null && !returnOpptyMap.isEmpty()){
            return returnOpptyMap.values();
        }
        else{
            return null;
        }
    }

    //Evaluates a rule against an Opportunity
    public Boolean evaluateRule(Opportunity_Ownership_Rule__c rule, Opportunity opp){
        //Map of Index number and condition evaluation result
        Map<Integer, Boolean> indexValuesMap = new Map<Integer, Boolean>();

        //Logic string
        String expression = '';

        //Create an instance of boolean expression evaluator
        BooleanExpressionEvaluator bee = new BooleanExpressionEvaluator();

        //Evaluate the following only if there are conditions. 
        //Else the rule is marked as true because we assume that the owner should be assigned based on the territory only. 
        if(rule.Opportunity_Ownership_Condition__r!=null && !rule.Opportunity_Ownership_Condition__r.isEmpty()){
            //Get Conditions for given rule
            for(Opportunity_Ownership_Condition__c condition: rule.Opportunity_Ownership_Condition__r){
                Boolean conditionResult = evaluateCondition(condition, opp);
                if(rule.Conditions_Met__c == 'All'){
                    expression += String.isBlank(expression)? String.valueOf(conditionResult) : (' AND ' + String.valueOf(conditionResult));
                }
                else if(rule.Conditions_Met__c == 'Any'){
                    expression += String.isBlank(expression)? String.valueOf(conditionResult) : (' OR ' + String.valueOf(conditionResult));
                }
                if(!indexValuesMap.containsKey(Integer.valueOf(condition.Index__c))){
                    indexValuesMap.put(Integer.valueOf(condition.Index__c), conditionResult);
                }
            }

            //Convert the advanced condition string to boolean expression
            if(rule.Conditions_Met__c == 'Custom'){
                expression = bee.convertToBoolean(rule.Advanced_Condition__c, indexValuesMap);
            }
        }
        else{
            expression = 'TRUE';
        }

        //Evaluate the expression string
        return bee.eval(expression);
    }

    //Evaluates a condition against an opportunity
    public Boolean evaluateCondition(Opportunity_Ownership_Condition__c condition, Opportunity opp){
        //Get actual value
        Object actualValue = getValueAsObject(opp, condition.Field_API_Name__c);
        if(actualValue instanceof Decimal){
            return compare(actualValue, Decimal.valueOf(condition.Value__c), condition.Operator__c);
        }
        else{
            return compare(actualValue, condition.Value__c, condition.Operator__c);
        }
    }

    //Used to build a query with all fields of an object
    public static String dynamicQueryBuilder(String sobjType,String additionalFieldsCommaSeparated,String whereClause){
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobjType);
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        Set<String> allField = new Set<String>();
        for (Schema.SObjectField field : fieldMap.values()) {
            allField.add(field.getDescribe().getName());
        }
        String queryString = '';
        if(!allField.isEmpty()){
            queryString += 'SELECT ' + String.join(new List<String>(allField),',');

            //Are there additional fields?
            if(String.isNotBlank(additionalFieldsCommaSeparated)){
                queryString += ',' + additionalFieldsCommaSeparated;
            }

            //Add the object name
            queryString += ' FROM ' + sobjType;

            //Is there a where clause?
            if(String.isNotBlank(whereClause)){
                queryString += ' WHERE ' + whereClause;
            }
        }
        return String.isNotBlank(queryString) ? queryString : null;
    }    
}