/**
* @author Salesforce Services
* @date 10/29/2020
*
* @group Rule Engine
*
* @description: Class used to evaluate boolean expressions
*/
public with sharing class BooleanExpressionEvaluator {
    private Map<String, String> logicTypes = new Map<String, String>{'AND' => 'AND', 'OR' => 'OR', '(' => 'PARENTHESIS'};
    private static Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>();
   
    public BooleanExpressionEvaluator(){
        populateEvaluationLogic();
    }
    /**
    * Evaluate the boolean expreassion 
    * 
    */
    public Boolean eval(String expression) {
        
        if(String.isNotBlank(expression)){
            // If expression contains all TRUE or FALSE
            if(expression.toUpperCase().containsNone('FALSE')) { return TRUE; }        
            if(expression.toUpperCase().containsNone('TRUE')) { return FALSE; }

            return Boolean.valueOf(evaluateExpression(expression.toUpperCase()));
        }
        else{
            return false;
        }

    }
    
    /**
    * Evaluate the complex boolean expression
    * 
    */
    private String evaluateExpression(String expression) {        
        for(String logicType : logicTypes.keySet()) {
            if(expression.contains(logicType)) {
                expression = simplifyExpression(expression, logicTypes.get(logicType));
            }
        }
        
        if(expression.contains('AND') || expression.contains('OR') || expression.contains('(')) {
            expression = evaluateExpression(expression);
        }
        
        return expression;
    }
    
    /**
     * Simplify the expression
     * 
     */
    private String simplifyExpression(String expression, String LogicType){
        Map<String, String> Logic = new Map<String, String>(expressionLogic.get(LogicType));
        
        for(String key : Logic.keySet()) {
            expression = expression.replace(key, Logic.get(key));
        }
        
        return expression;
    } 
    /**
     * Convert advanced condition string with indexes to boolean expression sting
     * 
     */
    public String convertToBoolean(String expression, Map<Integer,Boolean> valueMap) {
        String[] tokens = expression.split(' ');
        for(String token : tokens) {
            try {
                Integer index = Integer.valueOf(token.replaceAll('[^0-9]', ''));
                expression = expression.replaceAll(String.valueOf(index), String.valueOf(valueMap.get(index)));    
            } catch(Exception e) {
                system.debug('ERROR: ' + e.getMessage());
            }
        }
        return expression;
    }

    /**
    * Identify results for basic AND/OR Logic and evaluation or parenthesis
    * 
    */
    private void populateEvaluationLogic() {
        Map<String, String> ANDLogic = new Map<String, String>();
        Map<String, String> ORLogic = new Map<String, String>();
        Map<String, String> parenthesisLogic = new Map<String, String>();
        
        // AND Logic
        ANDLogic.put('TRUE AND TRUE', 'TRUE');
        ANDLogic.put('TRUE AND FALSE', 'FALSE');
        ANDLogic.put('FALSE AND TRUE', 'FALSE');
        ANDLogic.put('FALSE AND FALSE', 'FALSE');
        expressionLogic.put('AND', ANDLogic);
        
        // OR Logic
        ORLogic.put('TRUE OR TRUE', 'TRUE');
        ORLogic.put('TRUE OR FALSE', 'TRUE');
        ORLogic.put('FALSE OR TRUE', 'TRUE');
        ORLogic.put('FALSE OR FALSE', 'FALSE');
        expressionLogic.put('OR', ORLogic);
        
        // Braces Logic
        parenthesisLogic.put('(TRUE)', 'TRUE');
        parenthesisLogic.put('(FALSE)', 'FALSE');
        expressionLogic.put('PARENTHESIS', parenthesisLogic);
    }
}