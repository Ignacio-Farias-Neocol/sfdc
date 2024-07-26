import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {NavigationMixin} from 'lightning/navigation';
import getCustomerComments from '@salesforce/apex/PortalCommunicationController.getCustomerComments';
import insertFeedComment from '@salesforce/apex/PortalCommunicationController.insertFeedComment';
import fileFormatAccept from '@salesforce/label/c.CommunicationPortal_File_allowed';

export default class PortalCommunication extends NavigationMixin(LightningElement) {

    @api recordId;
    file={name:''};
    hasFile=false;
    feedItemList;
    currentUser;
    feedItemId;
    isActiveComment = false;
    previousfeedItemfocusId='';
    isLoading=false;
    hasAttachment=false;
    businessImpact;
    prefredContactMethod;
    isCustomerCaseClouser = false;
    communityRequestCloseReason;
    closeReasonComments;
     allowedFormats = [
        'attachment'
    ];
    fileFormatLabel=fileFormatAccept;

    chatComment = {};
    isInit = false;
    connectedCallback(){
        if(this.isInit){
            return;
        }
        this.isInit = true;
        this.getCustomerCommentsJS();
    }

    getCustomerCommentsJS(){
        
        getCustomerComments(
            {  req : 
                JSON.stringify( { recordId: this.recordId, })
            })
        .then(result =>{
            let jsonRes = JSON.parse(result);
            if(jsonRes.status){
                if(jsonRes.caseObj[0].Origin == 'Portal' && !jsonRes.isMSPCase){
                    this.feedItemList = [];
                }
                if(jsonRes.feedCommentWrpList.length){
                    this.feedItemList = jsonRes.feedCommentWrpList;
                    
                }
                let caseObj = jsonRes.caseObj[0];
                this.businessImpact = caseObj.Customers_Provided_Business_Impact__c;
                this.prefredContactMethod = caseObj.preferred_Contact_Method__c;
                this.communityRequestCloseReason = caseObj.Community_Request_Close_Reason__c;
                this.closeReasonComments = caseObj.Close_Reason_Comments__c;
                if(this.communityRequestCloseReason != undefined && this.communityRequestCloseReason != ''){
                    this.isCustomerCaseClouser  = true;
                    if(this.feedItemList==undefined){
                        this.feedItemList=[];
                    }
                }                                   
                /*
                if(this.feedItemList.length){
                    this.feedItemId = this.feedItemList[0].feedItemId;
                }
                */
                this.currentUser = jsonRes.currentUser; 
                // Start SFDC- 18849 
                for(let key in this.feedItemList){
                    if(this.feedItemList[key].commentBody)
                    this.feedItemList[key].commentBody=this.feedItemList[key].commentBody.replace(/<img[^>]*>/g,"");
                    
                    if(this.feedItemList[key].relatedRecordId.length>0){
                         
                         this.hasAttachment=true;
                    }

                    for(let fc in this.feedItemList[key].feedCommentWrpList){
                        if(this.feedItemList[key].feedCommentWrpList[fc].commentBody)
                            this.feedItemList[key].feedCommentWrpList[fc].commentBody =this.feedItemList[key].feedCommentWrpList[fc].commentBody.replace(/<img[^>]*>/g,"");    
                    if(this.feedItemList[key].feedCommentWrpList[fc].relatedRecordId.length>0 || this.feedItemList[key].relatedRecordId.length>0){
                            
                            this.hasAttachment=true;
                            
                        }
                    }
                }
                // Start SFDC- 18849           
            }
        })
        .catch(result => {
            console.log(result);
        });
    }

    handleCreateComment(event){
        let feedItemId = event.currentTarget.dataset.feeditemid;
        this.isLoading=true;

        insertFeedComment(
                {  req : 
                    JSON.stringify( { recordId: this.recordId, feedItemId : event.currentTarget.dataset.feeditemid, commentText: this.chatComment[event.currentTarget.dataset.feeditemid],file:this.hasFile==true?this.file:''})
                })
            .then(result =>{
               
                let jsonRes = JSON.parse(result);
                if(jsonRes.status){
                    const evt = new ShowToastEvent({
                        title: 'Comment posted successfully.',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                    this.hasFile=false;   
                    this.file={name:''};
                    this.isLoading=false;

                    //this.getCustomerCommentsJS();  
                   // this.template.querySelector('textarea').value = '';
                    let elements = this.template.querySelectorAll('textarea');
                    for(let i=0;i<elements.length;i++){
                        elements[i].value = '';
                    }
                    
                    this.template.querySelector('[data-commentcollapse="'+ feedItemId + "").classList.add('slds-hide');
                    this.template.querySelector('[data-commentexpend="'+ feedItemId + "").classList.remove('slds-hide');
                    this.getCustomerCommentsJS();
                }
            })
            .catch(result => {
                console.log(result);
            });
    }

    handleChatComment(event){
        this.chatComment[event.currentTarget.dataset.feeditemid] =  this.stripTags(event.currentTarget.value);
    }
    
    handlefocusComment(event){
        let feedItemId = event.currentTarget.dataset.feeditemid;
        this.template.querySelector('[data-commentcollapse="'+ feedItemId + "").classList.remove('slds-hide');
        this.template.querySelector('[data-commentexpend="'+ feedItemId + "").classList.add('slds-hide');
        console.log('feedItemId',feedItemId);
        // Start SFDC- 18849 
        if(this.previousfeedItemfocusId==feedItemId){

        }else{
            this.hasFile=false;   
            this.file={name:''};
            this.isActiveComment = true;
        }
        this.previousfeedItemfocusId=feedItemId;
        // End SFDC- 18849 
    }

    onloadCaseHandler(event){
        
        var record = event.detail.records;
        var fields = record[this.recordId].fields; 
        //this.businessImpact = fields.Customers_Provided_Business_Impact__c.value;
        //this.prefredContactMethod = fields.preferred_Contact_Method__c.value;
    }
    // Start SFDC- 18849 
     previewHandler(event){
        console.log(event.target.dataset.id)
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }
      
   
 hanldlefileUpload() {
  let input = document.createElement('input');
  input.type = 'file';
  input.accept=this.fileFormatLabel;
  input.onchange = _ => {
    // you can use this method to get file and perform respective operations
            let files =   Array.from(input.files);
            let getfile=files[0];
            this.hasFile=true;

        var reader = new FileReader()
         reader.onload = () => {
            var base64 = reader.result.split(',')[1];
             
    // The size of the file.
        this.file = {
                'name': getfile.name,
                'base64': base64,
                'type':getfile.type
            }
            
        }
        reader.readAsDataURL(getfile);
            
        };
  input.click();
  
}
stripTags(html){
  const parseHTML= new DOMParser().parseFromString(html, 'text/html');
  return parseHTML.body.textContent || '';
}
// End SFDC- 18849 
}