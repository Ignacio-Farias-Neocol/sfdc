import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord ,getFieldValue ,getRecordNotifyChange} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import sendSubCerts from '@salesforce/apex/DynamicBusinessRuleOrderItemAfter.sendSubCerts';
//import sendSubCerts from '@salesforce/apex/DynamicBusinessRuleSerialAfter.sendSubCerts';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class sendSubCertsComp extends LightningElement {

// variable to store Record Id supplied by the flexipage
@api recordId;

//Variable for Spinner
@track isLoading = true;

 //Variable for Icon
 @track iconVar;

 valResult;
 message; 

  // Load icon on component load
    async connectedCallback(){
    this.iconVar='custom:custom64';
    this.inprogress = true;
    console.log('LWC Component Loaded Successfully with Record ID::' + this.recordId);
 
    this.valResult=true;
    await sendSubCerts({ orderIdList: this.recordId , isFromTrigger:false})
    .then(results => {
      
      this.isLoading = false;
      console.log('This is Result:::'+ results.result);

      if(results.result==false)
      {
        this.valResult=false;
        this.message=results.message;
        console.log('This is Message:::'+ results.message);
      }
      else {

        this.valResult=true;
        this.message='Sub Cert Sent Succesfully !';
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
          title: 'Error while Send Sub Certificate',
          message: message,
          variant: 'error',
          mode: 'sticky'
      }),
  );

});

}
}