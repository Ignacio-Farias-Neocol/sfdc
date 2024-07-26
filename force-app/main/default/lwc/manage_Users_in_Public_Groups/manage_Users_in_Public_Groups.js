import { LightningElement, track, api } from 'lwc';
import getGroupMembers from '@salesforce/apex/GroupMembersController.getGroupMembers';
import getUsersNotInGroups from '@salesforce/apex/GroupMembersController.getUsersNotInGroups';
import removeGroupMembers from '@salesforce/apex/GroupMembersController.removeGroupMembers';
import addGroupMembers from '@salesforce/apex/GroupMembersController.addGroupMembers';

export default class GroupMembers extends LightningElement {
  @track searchTerm = '';
  @track selectedGroup = '';
  isDisabled=true;
  @track groupOptions = [
    { label: 'TAC_Global_Premium_SME', value: 'TAC_Global_Premium_SME' },
    { label: 'WW_Premium_Manager_Group', value: 'WW_Premium_Manager_Group' },
  ];
  @track data = [];
  @track isRemoveAction = false;
  @track isAddAction = false;
  @track showDataTable = false;

  handleSearchTermChange(event) {
    this.searchTerm = event.target.value;
  }

  handleGroupChange(event) {
    this.selectedGroup = event.target.value;
    this.isDisabled=false;
  }

  handleSearch() {
   this.loadData();
  }

  loadData(){
  if (this.selectedGroup) {
      getGroupMembers({
        
        groupDeveloperName: this.selectedGroup,
        searchTerm: this.searchTerm
      })
        .then((result) => {
          
          let grpuserdata=[];
           grpuserdata=result.map((rec,index)=>{return {...rec,'add':false}});
          this.data =grpuserdata;
          
        getUsersNotInGroups({ 
          
          groupDeveloperName: this.selectedGroup,
          searchTerm: this.searchTerm
          })
        .then((result) => {
          if(result){
          let userdata=[];
         
          userdata=result.map((rec,index)=>{return {...rec,'add':true}});
          console.log('data:11:::::', userdata);
          this.data.push(...userdata);
          this.data = this.data.sort((a, b) => {
          if (a.Name < b.Name) {
          return -1;
          }
        });
          console.log('data::::::', JSON.stringify(this.data));
           this.showDataTable = true;
           }else{
            this.showDataTable = true;
           }
        })
        .catch((error) => {
          console.log(error);
        });


        })
      }
  }
  
  handleRemove(event){
    this.showDataTable = false;
    this.data=[];
    const userId = event.target.dataset.id;
    if (this.selectedGroup ) {
    removeGroupMembers({ groupDeveloperName: this.selectedGroup, userIds: userId })
      .then(() => {
        console.log('User Removed Successfully');
        this.loadData();
      })
      .catch((error) => {
        console.log(error);
      });
    }
  }

  handleAdd(event){
    const userId = event.target.dataset.id;
    this.showDataTable = false;
            this.data=[];
    if (this.selectedGroup) {
    addGroupMembers({ groupDeveloperName: this.selectedGroup, userIds: userId })
      .then(() => {
        console.log('User Removed Successfully');
        this.loadData();
      })
      .catch((error) => {
        console.error(error);
      });
    }
  }

  userDetailUrl(userId) {
    return `/lightning/r/User/${userId}/view`;
  }
}