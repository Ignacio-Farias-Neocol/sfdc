/**
* @author HZ
* @date 2020
*
* @description helper class for returning random number in flows
*   2020-05-21 : Initial creation
*/

global with sharing class FlowRandomNumberHelper {

    global class GetParams {
        
        @InvocableVariable (required=true)
        global Integer maxRange;
    }
    
    @InvocableMethod(label = 'Get Random Number')
    public static List<Integer> getRandomNumber(List<GetParams> params){
        
        //return list of integers for flow
        List<Integer> wrapper = new List<Integer>();
        Integer randomNum = Math.round( Math.random() * params[0].maxRange );        

        wrapper.add(randomNum);
        return wrapper;
    }
}