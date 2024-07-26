import { LightningElement, api, track } from 'lwc';
import statusHeader from '@salesforce/label/c.g_Status_Filter_Header';

export default class StatusSearchFilter extends LightningElement {

    @api statuses;

    //tempStatus = [];
    statusFilter = [];
    isStatusFilterSet = false;
    
    filters = {};

    labels = {
        statusHeader
      }
    // logic to maintain the statusFilter value
    renderedCallback(){
        if(!this.isStatusFilterSet){
            console.log('inside if render...');
            //this.tempStatus = this.statuses;
            this.statusFilter = this.statuses;
            this.isStatusFilterSet = true;
        }
    }

    @api reset(){
        this.template.querySelectorAll(".statusCB").forEach((cb) => {
            cb.checked = true;
          });
          
          this.statusFilter = this.statuses;
          this.filters = {
            statusFilter:this.statusFilter
        };
        console.log('in api reset this.filters...'+JSON.stringify(this.filters));
          this.publishEvent();
    }

    handleStatusFilterChange(event){
        if(event.target.checked){
            if(!this.statusFilter.includes(event.target.label)){
                this.statusFilter.push(event.target.label);
            }
        }else{
            const filterArray = this.statusFilter;
            this.statusFilter = filterArray.filter((item) => item !== event.target.label);
        }
        this.filters = {
            statusFilter:this.statusFilter
        };
        this.publishEvent();
    }

    publishEvent(){
        const selectedEvent = new CustomEvent('statusfilterchange', {
            detail:this.filters
           });
        this.dispatchEvent(selectedEvent);
    }
}