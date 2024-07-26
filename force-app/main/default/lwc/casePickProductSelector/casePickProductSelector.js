import { LightningElement, api, track } from 'lwc';
import initData from "@salesforce/apex/CaseDependentPicklistController.initData";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { updateRecord } from 'lightning/uiRecordApi';

import ID_CASE_FIELD from '@salesforce/schema/Case.Id';
import PRODUCT_FAMILY_CASE_FIELD from '@salesforce/schema/Case.Product_Family_List__c';
import PICK_PRODUCT_CASE_FIELD from '@salesforce/schema/Case.Pick_Product_only_if_Essentials__c';
import CASE_REASON_CASE_FIELD from '@salesforce/schema/Case.Case_Reason__c';
import SUB_REASON_CASE_FIELD from '@salesforce/schema/Case.Sub_Reason__c';
import CLOSED_REASON_CASE_FIELD from '@salesforce/schema/Case.Closed_Case_Reason__c';

import {
    subscribe,
    unsubscribe,
    onError,
    setDebugFlag,
    isEmpEnabled,
} from 'lightning/empApi';


export default class CasePickProductSelector extends LightningElement {

    productFamilyPickListOption;
    pickProductPicklistOption;
    caseReasonPicklistOption;
    casesubReasonPiklistOption;
    caseClosedSubReasonPicklistOption;

    productFamilySelected;
    pickProductSelected;
    caseReasonSelected;
    caseSubReasonSelected;
    caseClosedReasonSelected;

    fullResponse;
    casePickProducts;

    caseRecord;


    channelName = '/topic/updatecasePickProdTopic';
    isSubscribeDisabled = false;
    isUnsubscribeDisabled = !this.isSubscribeDisabled;
    subscription = {};

    isUpdateFlow = false;
    fields = [PICK_PRODUCT_CASE_FIELD,CASE_REASON_CASE_FIELD,CLOSED_REASON_CASE_FIELD];

    @api showSpinner = false;


    @api recordId;
    isInit = false;
    connectedCallback(){

        console.time("connectedCallback");

        if(this.isInit){
            return;
        }
        this.isInit = true;
       // this.initDataJS();
        // Register error listener
        this.registerErrorListener();
        this.handleSubscribe();
        this.isUpdateFlow = false;
    }

    initDataJS(){
        debugger;
        initData({  reqStr : JSON.stringify( { recordId: this.recordId})})
        .then(result =>{
            let jsonRes = JSON.parse(result);
            let pickProducts = jsonRes.pickProducts;
            pickProducts.sort((a, b) => {
                let fa = a.label.toLowerCase(),
                fb = b.label.toLowerCase();
                if (fa < fb) {
                    return -1;
                }
                if (fa > fb) {
                    return 1;
                }
                return 0;
            });
            jsonRes.pickProducts = pickProducts;

            let caseReasons = jsonRes.caseReasons;
            caseReasons.sort((a, b) => {
                let fa = a.label.toLowerCase(),
                fb = b.label.toLowerCase();
                if (fa < fb) {
                    return -1;
                }
                if (fa > fb) {
                    return 1;
                }
                return 0;
            });
            jsonRes.caseReasons = caseReasons;

            let caseClosedReasons = jsonRes.caseClosedReasons;
            caseClosedReasons.sort((a, b) => {
                let fa = a.label.toLowerCase(),
                fb = b.label.toLowerCase();
                if (fa < fb) {
                    return -1;
                }
                if (fa > fb) {
                    return 1;
                }
                return 0;
            });
            jsonRes.caseClosedReasons = caseClosedReasons;

            this.fullResponse = jsonRes;
            //if(jsonRes.status){
                //this.productFamilyPickListOption = jsonRes.productFamily;
                this.casePickProducts = jsonRes.casePickProduct;
                this.caseRecord = jsonRes.caseRecord[0];

                this.handleProudctFamilyChange();
                this.handlePickProductChange();
                this.handleCaseReasonChange();
                //this.handleSubCaseReasonChange();
                this.handleClosedCaseReasonChange();

                // stop the spinner
                this.showSpinner = false;

            //}
        })
        .catch(result => {
            console.log('##sample');
            console.log(result);
            this.showSpinner = false;
        });        
    }
    disconnectedCallback(){
        this.handleUnsubscribe();
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

     // Handles subscribe button click
     handleSubscribe() {
        let thisObj = this;
        // Callback invoked whenever a new event message is received
        const messageCallback = function (response) {
            debugger;
            
            console.log('New message received: ', JSON.stringify(response));
            if(response.data.sobject.Id == thisObj.recordId){
                thisObj.initDataJS();
            }
            
            // Response contains the payload of the new message received
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
            this.toggleSubscribeButton(true);
        });
    }

    // Handles unsubscribe button click
    handleUnsubscribe() {
        this.toggleSubscribeButton(false);

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    toggleSubscribeButton(enableSubscribe) {
        this.isSubscribeDisabled = enableSubscribe;
        this.isUnsubscribeDisabled = !enableSubscribe;
    }

    handleProudctFamilyChange(event){
        debugger;

        this.pickProductPicklistOption = undefined;
        this.caseReasonPicklistOption = undefined;
        this.casesubReasonPiklistOption = undefined;
        this.caseClosedSubReasonPicklistOption = undefined;
        this.pickProductSelected = undefined;
        this.caseReasonSelected = undefined;
        this.caseSubReasonSelected = undefined;
        this.caseClosedReasonSelected = undefined;

        this.productFamilySelected = event != undefined ? event.currentTarget.value : this.caseRecord.Product_Family_List__c;
        let pickProducts = this.fullResponse.pickProducts;
        if(pickProducts != undefined && pickProducts != null){
            let pickProductsOptions = [];

            for(let i=0;i<pickProducts.length;i++){
                let isValidPicklist = false;
                for(let j=0;j<this.casePickProducts.length;j++){
                    if(this.casePickProducts[j].Product_Family_List__c != undefined && this.productFamilySelected != undefined
                        && this.casePickProducts[j].Pick_Product_only_if_Essentials__c != undefined &&                        
                       // this.casePickProducts[j].Product_Family_List__c.toLowerCase() == this.productFamilySelected.toLowerCase() &&                        
                        this.casePickProducts[j].Pick_Product_only_if_Essentials__c.toLowerCase() == pickProducts[i].value.toLowerCase()
                        ){
                        isValidPicklist = true;
                        break;
                    }
                }
                if(isValidPicklist){
                    pickProductsOptions.push({
                        'label': pickProducts[i].value,
                        'value': pickProducts[i].value
                    });
                }
            }
            this.pickProductPicklistOption = pickProductsOptions;
        }
    }

    handlePickProductChange(event){
        debugger;

        this.caseReasonPicklistOption = undefined;
        this.casesubReasonPiklistOption = undefined;
        this.caseClosedSubReasonPicklistOption = undefined;
        this.caseReasonSelected = undefined;
        this.caseSubReasonSelected = undefined;
        this.caseClosedReasonSelected = undefined;


        this.pickProductSelected = event != undefined ? event.currentTarget.value : this.caseRecord.Pick_Product_only_if_Essentials__c;
        //this.pickProductSelected = event.currentTarget.value;

        let caseReasons = this.fullResponse.caseReasons;
        if(caseReasons != undefined && caseReasons != null){
            let caseReasonsOptions = [];

            for(let i=0;i<caseReasons.length;i++){
                let isValidPicklist = false;
                for(let j=0;j<this.casePickProducts.length;j++){
                    if(
                        //this.casePickProducts[j].Product_Family_List__c != undefined && this.productFamilySelected != undefined
                         this.casePickProducts[j].Pick_Product_only_if_Essentials__c != undefined && this.pickProductSelected != undefined &&                        
                        //this.casePickProducts[j].Product_Family_List__c.toLowerCase() == this.productFamilySelected.toLowerCase() &&
                        this.casePickProducts[j].Pick_Product_only_if_Essentials__c.toLowerCase() == this.pickProductSelected.toLowerCase() &&                        
                        this.casePickProducts[j].Case_Reason__c.toLowerCase() == caseReasons[i].value.toLowerCase()
                        ){
                        isValidPicklist = true;
                        break;
                    }
                }
                if(isValidPicklist){
                    caseReasonsOptions.push({
                        'label': caseReasons[i].value,
                        'value': caseReasons[i].value
                    });
                }
            }
            this.caseReasonPicklistOption = caseReasonsOptions;
        }
    }

    handleCaseReasonChange(event){
        debugger;

        this.casesubReasonPiklistOption = undefined;
        this.caseClosedSubReasonPicklistOption = undefined;
        this.caseSubReasonSelected = undefined;
        this.caseClosedReasonSelected = undefined;

        //this.caseReasonSelected = event.currentTarget.value;
        this.caseReasonSelected = event != undefined ? event.currentTarget.value : this.caseRecord.Case_Reason__c;

        /*
        let subReasones = this.fullResponse.subReasone[this.caseReasonSelected];
        console.log(subReasones);
        if(subReasones != undefined && subReasones != null){
            let subReasonesOptions = [];
            for(let i=0;i<subReasones.length;i++){
                let isValidPicklist = false;
                for(let j=0;j<this.casePickProducts.length;j++){
                    if(this.casePickProducts[j].Product_Family_List__c != undefined && this.productFamilySelected != undefined
                        && this.casePickProducts[j].Case_Reason__c != undefined && this.caseReasonSelected != undefined
                        && this.casePickProducts[j].Pick_Product_only_if_Essentials__c != undefined && this.pickProductSelected != undefined
                        && this.casePickProducts[j].Sub_Reason__c  != undefined &&  subReasones[i]  != undefined &&
                        this.casePickProducts[j].Product_Family_List__c.toLowerCase() == this.productFamilySelected.toLowerCase() &&
                        this.casePickProducts[j].Case_Reason__c.toLowerCase() == this.caseReasonSelected.toLowerCase() &&
                        this.casePickProducts[j].Pick_Product_only_if_Essentials__c.toLowerCase() == this.pickProductSelected.toLowerCase() &&                        
                        this.casePickProducts[j].Sub_Reason__c.toLowerCase() == subReasones[i].toLowerCase()
                        ){
                        isValidPicklist = true;
                        break;
                    }
                }
                if(isValidPicklist){
                    subReasonesOptions.push({
                        'label': subReasones[i],
                        'value': subReasones[i]
                    });
                }
            }
            this.casesubReasonPiklistOption = subReasonesOptions;
        }
        */


        let caseClosedReasones = this.fullResponse.caseClosedReasons;
        console.log(this.fullResponse);
        if(caseClosedReasones != undefined && caseClosedReasones != null){
            let caseClosedReasonesOptions = [];

            let casePickProductsMap = {};
            for(let j=0;j<this.casePickProducts.length;j++){
                casePickProductsMap[this.casePickProducts[j].Pick_Product_only_if_Essentials__c.toLowerCase() + ','+
                                      this.casePickProducts[j].Case_Reason__c.toLowerCase() + ','+
                                      this.casePickProducts[j].Case_Closed_Reason_WM__c.toLowerCase()] = true;
            }
            console.log(casePickProductsMap);

            /* Old code
            for(let i=0;i<caseClosedReasones.length;i++){
                let isValidPicklist = false;
                for(let j=0;j<this.casePickProducts.length;j++){
                    if(
                        //this.casePickProducts[j].Product_Family_List__c != undefined && this.productFamilySelected != undefined
                         this.casePickProducts[j].Case_Reason__c != undefined && this.caseReasonSelected != undefined
                        && this.casePickProducts[j].Pick_Product_only_if_Essentials__c != undefined && this.pickProductSelected != undefined
                        && this.casePickProducts[j].Case_Closed_Reason_WM__c != undefined &&  caseClosedReasones[i] != undefined &&
                       //this.casePickProducts[j].Product_Family_List__c.toLowerCase() == this.productFamilySelected.toLowerCase() &&
                        this.casePickProducts[j].Case_Reason__c.toLowerCase()== this.caseReasonSelected.toLowerCase() &&
                        this.casePickProducts[j].Pick_Product_only_if_Essentials__c.toLowerCase() == this.pickProductSelected.toLowerCase() &&                        
                        this.casePickProducts[j].Case_Closed_Reason_WM__c.toLowerCase() == caseClosedReasones[i].value.toLowerCase()
                        ){
                        isValidPicklist = true;
                        break;
                    }
                }
                if(isValidPicklist){
                    caseClosedReasonesOptions.push({
                        'label': caseClosedReasones[i].value,
                        'value': caseClosedReasones[i].value
                    });
                }
            }
            this.caseClosedSubReasonPicklistOption = caseClosedReasonesOptions;
            */

            for(let i=0;i<caseClosedReasones.length;i++){
                let isValidPicklist = false;
               // console.log(this.pickProductSelected.toLowerCase()+','+ this.caseReasonSelected.toLowerCase() + ','+
               // caseClosedReasones[i].value.toLowerCase());
                if(
                    //this.casePickProducts[j].Product_Family_List__c != undefined && this.productFamilySelected != undefined
                    this.caseReasonSelected != undefined &&
                    this.pickProductSelected != undefined &&
                    caseClosedReasones[i] != undefined &&
                    casePickProductsMap[this.pickProductSelected.toLowerCase()+','+ this.caseReasonSelected.toLowerCase() + ','+
                                        caseClosedReasones[i].value.toLowerCase()]
                    ){
                    isValidPicklist = true;
                    //break;
                }
            
                if(isValidPicklist){
                    caseClosedReasonesOptions.push({
                        'label': caseClosedReasones[i].value,
                        'value': caseClosedReasones[i].value
                    });
                }
            }
            console.log(caseClosedReasonesOptions);
            this.caseClosedSubReasonPicklistOption = caseClosedReasonesOptions;
        }
        
        /*
        let subReasonesOptions = [];
        for(let i=0;i<subReasones.length;i++){
            let isValidPicklist = false;
            for(let j=0;j<this.casePickProducts;j++){
                if(this.casePickProducts[j].Product_Family_List__c == this.productFamilySelected ||
                    this.casePickProducts[j].Case_Reason__c == this.caseReasonSelected ||
                    this.casePickProducts[j].Pick_Product_only_if_Essentials__c == this.pickProductSelected
                    ){
                    isValidPicklist = true;
                    break;
                }
            }
            if(isValidPicklist){
                subReasonesOptions.push({
                    'label': subReasones[i],
                    'value': subReasones[i]
                });
            }
        }
        this.casesubReasonPiklistOption = subReasonesOptions;
        */
       /*
       let caseClosedReasones = this.fullResponse.caseClosedReasons[this.caseReasonSelected];
       console.log(this.fullResponse);
       if(caseClosedReasones != undefined && caseClosedReasones != null){
           
            let caseClosedReasonesOptions = [];

            for(let i=0;i<caseClosedReasones.length;i++){
                caseClosedReasonesOptions.push({
                    'label': caseClosedReasones[i],
                    'value': caseClosedReasones[i]
                });
            }
            this.caseClosedSubReasonPicklistOption = caseClosedReasonesOptions;
       }
       */



       
       /*
        let caseClosedReasonesOptions = [];
        for(let i=0;i<caseClosedReasones.length;i++){
            caseClosedReasonesOptions.push({
                'label': caseClosedReasones[i],
                'value': caseClosedReasones[i]
            });
        }
        this.caseClosedSubReasonPicklistOption = caseClosedReasonesOptions;
        */
    }

    handleSubCaseReasonChange(event){
        debugger;
        
        this.caseSubReasonSelected = event != undefined ? event.currentTarget.value : this.caseRecord.Sub_Reason__c;
        
        /*
        this.caseClosedReasonSelected = undefined;


        let caseClosedReasones = this.fullResponse.caseClosedReasons[this.caseSubReasonSelected];
        console.log(this.fullResponse);
        if(caseClosedReasones != undefined && caseClosedReasones != null){
                let caseClosedReasonesOptions = [];

                for(let i=0;i<caseClosedReasones.length;i++){

                let isValidPicklist = false;
                for(let j=0;j<this.casePickProducts.length;j++){
                    if(this.casePickProducts[j].Product_Family_List__c == this.productFamilySelected &&
                        this.casePickProducts[j].Sub_Reason__c == this.caseSubReasonSelected &&
                        this.casePickProducts[j].Pick_Product_only_if_Essentials__c == this.pickProductSelected &&
                        this.casePickProducts[j].Case_Closed_Reason_WM__c == caseClosedReasones[i]
                        ){
                        isValidPicklist = true;
                        break;
                    }
                }
                if(isValidPicklist){
                        caseClosedReasonesOptions.push({
                            'label': caseClosedReasones[i],
                            'value': caseClosedReasones[i]
                        });
                }
            }
            this.caseClosedSubReasonPicklistOption = caseClosedReasonesOptions;
        }
        */


    }

    handleClosedCaseReasonChange(event){
        debugger;
        //this.caseClosedReasonSelected = event.currentTarget.value;
        this.caseClosedReasonSelected = event != undefined ? event.currentTarget.value : this.caseRecord.Closed_Case_Reason__c;
    }

    handleUpdatePickProduct(){
        let fields = {};
        fields[ID_CASE_FIELD.fieldApiName] = this.recordId;
        fields[PRODUCT_FAMILY_CASE_FIELD.fieldApiName] = this.productFamilySelected;
        fields[PICK_PRODUCT_CASE_FIELD.fieldApiName] = this.pickProductSelected;
        fields[CASE_REASON_CASE_FIELD.fieldApiName] = this.caseReasonSelected;
        fields[SUB_REASON_CASE_FIELD.fieldApiName] = this.caseSubReasonSelected;
        fields[CLOSED_REASON_CASE_FIELD.fieldApiName] = this.caseClosedReasonSelected == undefined ? null : this.caseClosedReasonSelected;
        
        const recordInput1 = { fields };
        updateRecord(recordInput1)
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case Updated Successfully.',
                    variant: 'success'
                })
            );
            this.isUpdateFlow = false;
        })
        .catch(error => {
            console.log(error);
        });        
    }

  /*  handleRefershUpdatePickProduct(){
        debugger;
        this.initDataJS();
    } */

    handleEditPickProduct(){
        this.showSpinner = true;
        this.initDataJS();
        this.isUpdateFlow = true;
    }
}