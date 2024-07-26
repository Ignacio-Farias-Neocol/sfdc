/**
 * Class Name: CPQRnwBtDelayExecutionController
 * 
 * Description: Controller class for the VF page. This is added in order to add 
 *              some delay into the execution process of each contract via CPQRenewOpportunityBatch.
 * 
 * @author: Dilowar Hussain
 * CreatedDate: 01-09-2023
 * */
public class CPQRnwBtDelayExecutionController {
    /**
     * Constructor 
	**/
    public CPQRnwBtDelayExecutionController(){
        Integer delay = 0;
        if(ApexPages.currentPage().getParameters().get('CPQRnwBtDelayExecution') != null){
			delay = Integer.valueOf((ApexPages.currentPage().getParameters().get('CPQRnwBtDelayExecution')));
		}
        Long start = DateTime.now().getTime();
        while(DateTime.now().getTime()-start<delay);
    }
}