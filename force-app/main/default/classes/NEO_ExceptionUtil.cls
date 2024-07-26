/**
 * @description       : 
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-11-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_ExceptionUtil {

    public class FlowException extends Exception {}

    @InvocableMethod(label='Invoke NEO_ExceptionUtil')
    public static void throwNewCustomException(String exMessage) {
        throw new FlowException(exMessage);
    }
}