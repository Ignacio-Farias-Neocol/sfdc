/**
* @author Salesforce Services
* @date 11/04/2020
*
* @group Rule Engine
*
* @description: test class for BooleanExpressionEvaluator   
*/

@isTest
public class BooleanExpressionEvaluatorTest {

    @isTest
    private static void testExpressionEvaluation(){

			BooleanExpressionEvaluator bee = new BooleanExpressionEvaluator();

			Test.startTest();
				List<String> expressionList = new List<String>{'TRUE AND FALSE', 'TRUE OR FALSE', '((TRUE AND TRUE) OR (FALSE AND FALSE))', 'true AND true', 'false AND false', ''};

				//Asserts
				System.assert(!bee.eval(expressionList[0]));
				System.assert(bee.eval(expressionList[1]));
				System.assert(bee.eval(expressionList[2]));
				System.assert(bee.eval(expressionList[3]));
				System.assert(!bee.eval(expressionList[4]));
				System.assert(!bee.eval(expressionList[5]));

				System.assert(bee.eval(bee.convertToBoolean('((1 AND 2) AND (3 OR 4))', new Map<Integer, Boolean>{1=>TRUE, 2=>TRUE, 3=>TRUE,4=>FALSE})));
				
			Test.stopTest();
    }

}