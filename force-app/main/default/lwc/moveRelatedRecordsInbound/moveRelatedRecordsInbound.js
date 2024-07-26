import { LightningElement, api,track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { CloseActionScreenEvent } from 'lightning/actions';

import initiateMoveProcess from '@salesforce/apex/MoveContractRelatedRecords.initiateMoveProcess';
import checkJobStatus from '@salesforce/apex/MoveContractRelatedRecords.checkJobStatus';


export default class moveRelatedRecordsInbound extends LightningElement {

   @api recordId;

   @api objectApiName;

   message;
   jobmessage;
   queryTerm;
   loaded=true;

//    async connectedCallback(){
//     this.iconVar='custom:custom64';
//     this.inprogress = true;
//     console.log('LWC Component Loaded Successfully with Record ID::' + this.recordId);

//    }



    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.loaded = false;
            initiateMoveProcess({ sourceContractNumber: evt.target.value ,currentContractId:this.recordId})
            //this.queryTerm = evt.target.value + '::' + this.recordId;
            .then(results=>{
                this.loaded = true;
                console.log('This is Result:::'+ results.result);

                if(results.result==false){
                    this.message=results.message;
                    console.log('This is Message:::'+ results.message);
                }
                else {
                    this.loaded = false;

                    this.message=results.message;                   

                    var interval = setInterval(function () {

                        checkJobStatus({jobID : results.message})
                        .then(response=>{
                            if(response=='Completed') {
                                alert(response);
                                this.message='Records moved Sucessfully.'+ ' \r\n'+
                                'Total Subs Moved :'+results.succesSubCount +'::'+
                                'Total Assets Moved :'+results.succesAsstCount +'::'+
                                'Total Assigned Serial Moved :'+results.succesAsCount ;
                              this.loaded=true;
                               
                                clearInterval(interval);    
                            }
                            else if(response=='Failed'){

                                this.message='The Job Failed . Please check Logs'; 
                               
                                clearInterval(interval);
                            }

                         
                        })

                    }.bind(this),2000);

                 
                }

               
            })
        }
    }

    
    
    

}