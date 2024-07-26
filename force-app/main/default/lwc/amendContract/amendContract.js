import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord ,getFieldValue ,getRecordNotifyChange} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import checkAmendEligible from '@salesforce/apex/CPQAmendController.checkAmendEligible';

import cpqAmendButtonURL from '@salesforce/label/c.cpqAmendButtonURL';


export default class AmendContract extends NavigationMixin(LightningElement) {


// variable to store Record Id supplied by the flexipage
@api recordId;

//Variable for Spinner
@track isLoading = false;

 //Variable for Icon
 @track iconVar;

 valResult;
 message;
 

  // Load icon on component load
  async connectedCallback(){
    this.iconVar='custom:custom64';
    this.inprogress = true;
    console.log('LWC Component Loaded Successfully with Record ID::' + this.recordId);
    console.log('Log:: /apex/SBQQ__AmendContract?scontrolCaching=1&'+this.recordId);
    this.valResult=true;
    await checkAmendEligible({ recordId: this.recordId })
    .then(results => {

    
      console.log('This is Result:::'+ results.result);

      if(results.result==false)
      {
        this.valResult=false;
        this.message=results.message;
        console.log('This is Message:::'+ results.message);
      }
      else {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: cpqAmendButtonURL+this.recordId
            }
        })
      }

   
})
.catch(error => {

  this.isLoading = false;

  let message = 'Unknown error';
  if (Array.isArray(error.body)) {
      message = error.body.map(e => e.message).join(', ');
  } else if (typeof error.body.message === 'string') {
      message = error.body.message;
  }
  this.dispatchEvent(
      new ShowToastEvent({
          title: 'Error while Amending Contract',
          message: message,
          variant: 'error',
          mode: 'sticky'
      }),
  );

});

}
}