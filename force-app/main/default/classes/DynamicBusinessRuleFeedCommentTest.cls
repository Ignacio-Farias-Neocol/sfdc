/**
*  @author Bhavesh Jha
*  @date 28/02/2020
*  @group Model
*  @description  test model class for Feed Comment trigger object after insert
*/

@IsTest
public class DynamicBusinessRuleFeedCommentTest {
    @future
    public static void insertUser(){
        TestDataFactory.createUser('System Administrator');
        contact conCase=[select id,accountId from contact where lastName='portalTestUserv1' limit 1];
       	contact contactRecord2=[select id,accountId from contact where lastName='portalTestUserv2' limit 1]; 
            
        Profile prfile = [select Id,name from Profile where UserType = 'PowerPartner' AND name='Partner Community User' limit 1];

        User newUser1 = new User(
        profileId = prfile.id,
        username = 'newUsertestt@yahoo.com' + System.currentTimeMillis(),
        email = 'pb@f.com',
        emailencodingkey = 'UTF-8',
        localesidkey = 'en_US',
        languagelocalekey = 'en_US',
        timezonesidkey = 'America/Los_Angeles',
        alias='nuser',
        lastname='lastname',
        contactId = conCase.id 
        );
        insert newUser1;
        
        // insert user with Apollo: Barracuda CCPlus Admin Login Profile
        Profile apolloProfile = [select Id,name from Profile where Name='Apollo: Barracuda CCPlus Admin Login Profile' limit 1];
        
        User newUser2 = new User(
            profileId = apolloProfile.id,
            username = 'newUsertestt@yaho.com' + System.currentTimeMillis(),
            email = 'pb@f.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuserabc',
            lastname='lasttest',
            contactId = contactRecord2.Id
            
        );
        insert newUser2;  
    }
 
    @testSetup static void setup() {

    TriggerContextVariables.RUN_CASE_TRIGGER = false;
      Test.startTest();
         
       Account acc1 = new Account (
        Name = 'newAcc1'
        );  
        insert acc1;
        
        // create Contact 1
        Contact conCase = new Contact (
            AccountId = acc1.id,
            LastName = 'portalTestUserv1',
            email = 'pb@f.com'
        );
        insert conCase;
        
        // create Contact 2
        Contact contactRecord2 = new Contact (
            AccountId = acc1.Id,
            LastName = 'portalTestUserv2',
            email = 'pbtwo@f.com'
        );
        insert contactRecord2;   
        
        // create Contact 2
        Contact contactRecord3 = new Contact (
            AccountId = acc1.Id,
            LastName = 'portalTestUserv3',
            email = 'pbtwo3@f.com'
        );
        insert contactRecord3;             
        
        //Create user
       insertUser(); 
        
        /*
	 //  User newUser2=[select id from user where username like 'newUsertestt@yaho.com%' limit 1];
      // User newUser1=[select id from user where username like 'newUsertestt@yahoo.com%' limit 1];
         
        	//Web Message Record Type ID
      Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
      //Tech Support Record Type Id
      Id techSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
      //Professional Services Record Type Id
      Id professionalServicesRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();        
        
                 
        
      
         //New Web Message Case
      Case newWebMessageCase = new case(RecordTypeId = webMessageRTId,
                                        Status =  'New',
                                        AccountId = acc[0].Id,
                                        ContactId = con[0].id, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = con[0].FirstName,
                                        Web_Last_Name__c = con[0].LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc'
                                        //Is_Test_Record__c = true,
                                        );
            
      //Waiting for Customer Response Web Message Case
      Case waitingWebMessageCase = new case(RecordTypeId = webMessageRTId,
                                            Status =  'Waiting for Customer Response',
                                            AccountId = acc[0].Id,
                                            ContactId = con[0].id, 
                                            Subject = 'Case Created for new Test Classesss',
                                            Origin = 'Email',
                                            Web_Region__c = 'Americas', 
                                            Product_Family_List__c = 'Backup Server/Service',
                                            Case_Reason__c= 'BCC', 
                                            Offline_Support_Type__c = 'Sales',
                                            Web_Serial__c = '76543',
                                            Description = 'Web Case ', 
                                            Web_First_Name__c = con[0].FirstName,
                                            Web_Last_Name__c = con[0].LastName,
                                            
                                            RMA_Submitted_By__c = newUser2.Id,
                                            Escalated_to_support_escalations_by__c = newUser2.Id,
                                            Closed_Case_Reason__c = 'Account Merge',
                                            Missing_Serial_Number__c = 'abc',
                                            //Is_Test_Record__c = true,
                                            WOC_Reason__c='Serial Verification');
        //In Progress Web Message Case
        Case inProgressWebMessageCase = new case(RecordTypeId = webMessageRTId,
                                                  Status =  'In Progress',
                                                  AccountId = acc[0].Id,
                                                  ContactId = contactRecord3.Id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                  RMA_Submitted_By__c = newUser2.Id,
                                                  Escalated_to_support_escalations_by__c = newUser2.Id,
                                                  Closed_Case_Reason__c = 'Account Merge',
                                                  Missing_Serial_Number__c = 'abc'
                                                 //Is_Test_Record__c = true,
                                                 );  
        
        //In Progress Web Message Case
        Case inProgressProfessionalServiceCase = new case(RecordTypeId = professionalServicesRTId,
                                                  Status =  'In Progress',
                                                  AccountId = acc1.Id,
                                                  ContactId = contactRecord3.Id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                          RMA_Submitted_By__c = newUser2.Id,
                                                          Escalated_to_support_escalations_by__c = newUser2.Id,
                                                          Closed_Case_Reason__c = 'Account Merge',
                                                          Missing_Serial_Number__c = 'abc'
                                                          //Is_Test_Record__c = true,
                                                  );  
        
        //In Progress Web Message Case
        Case newProfessionalServiceCase = new case(RecordTypeId = professionalServicesRTId,
                                                  Status =  'New',
                                                  AccountId = acc1.Id,
                                                  ContactId = contactRecord3.Id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                   RMA_Submitted_By__c = newUser2.Id,
                                                   Escalated_to_support_escalations_by__c = newUser2.Id,
                                                   Closed_Case_Reason__c = 'Account Merge',
                                                   Missing_Serial_Number__c = 'abc'
                                                   //Is_Test_Record__c = true,
                                                  ); 

        //In Progress Web Message Case
        Case wfcrProfessionalServiceCase = new case(RecordTypeId = professionalServicesRTId,
                                                  Status =  'Waiting for Customer Response',
                                                  AccountId = acc1.Id,
                                                  ContactId = contactRecord3.id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                    RMA_Submitted_By__c = newUser2.Id,
                                                    Escalated_to_support_escalations_by__c = newUser2.Id,
                                                    Closed_Case_Reason__c = 'Account Merge',
                                                    Missing_Serial_Number__c = 'abc'
                                                    //Is_Test_Record__c = true,
                                                  ); 

        //In Progress Web Message Case
        Case closedProfessionalServiceCase = new case(RecordTypeId = professionalServicesRTId,
                                                  Status =  'Closed',
                                                  AccountId = acc1.Id,
                                                  ContactId = contactRecord3.id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                      RMA_Submitted_By__c = newUser2.Id,
                                                      Escalated_to_support_escalations_by__c = newUser2.Id,
                                                      Closed_Case_Reason__c = 'Account Merge',
                                                      Missing_Serial_Number__c = 'abc'
                                                      //Is_Test_Record__c = true,
                                                  );         
        
        //closed Web Message Case
        Case closedWebMessageCase = new case(RecordTypeId = webMessageRTId,
                                                  Status =  'Closed',
                                                  AccountId = acc[0].Id,
                                                  ContactId = con[0].id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                             RMA_Submitted_By__c = newUser2.Id,
                                             Escalated_to_support_escalations_by__c = newUser2.Id,
                                             Closed_Case_Reason__c = 'Account Merge',
                                             Missing_Serial_Number__c = 'abc'
                                             //Is_Test_Record__c = true,
                                                  );          

      //Waiting for Customer Response Tech Support Case
      Case waitingTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                             Status =  'Waiting for Customer Response',
                                             AccountId = acc[0].Id,
                                             ContactId = con[0].id, 
                                             Subject = 'Case Created for new Test Classesss',
                                             Origin = 'Email',
                                             Web_Region__c = 'Americas', 
                                             Product_Family_List__c = 'Backup Server/Service',
                                             Case_Reason__c= 'BCC', 
                                             Offline_Support_Type__c = 'Sales',
                                             Web_Serial__c = '76543',
                                             Description = 'Web Case ', 
                                             Web_First_Name__c = con[0].FirstName,
                                             Web_Last_Name__c = con[0].LastName,
                                             
                                             RMA_Submitted_By__c = newUser2.Id,
                                             Escalated_to_support_escalations_by__c = newUser2.Id,
                                             Closed_Case_Reason__c = 'Account Merge',
                                             Missing_Serial_Number__c = 'abc',
                                             //Is_Test_Record__c = true,
                                             WOC_Reason__c='Call back'); 

      //Resolved Tech Support Case
      Case resolvedTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                              Status =  'Resolved',
                                              AccountId = acc[0].Id,
                                              ContactId = con[0].id, 
                                              Subject = 'Case Created for new Test Classesss',
                                              Origin = 'Email',
                                              Web_Region__c = 'Americas', 
                                              Product_Family_List__c = 'Backup Server/Service',
                                              Case_Reason__c= 'BCC', 
                                              Offline_Support_Type__c = 'Sales',
                                              Web_Serial__c = '76543',
                                              Description = 'Web Case ', 
                                              Web_First_Name__c = con[0].FirstName,
                                              Web_Last_Name__c = con[0].LastName,
                                              
                                              RMA_Submitted_By__c = newUser2.Id,
                                              Escalated_to_support_escalations_by__c = newUser2.Id,
                                              Missing_Serial_Number__c = 'abc',
                                              //Is_Test_Record__c = true,
                                              Closed_Case_Reason__c = 'Account Merge'); 
            
      //Vendor Hold Tech Support Case
      Case vendorHoldTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                                Status =  'Vendor Hold',
                                                AccountId = acc[0].Id,
                                                ContactId = con[0].id, 
                                                Subject = 'Case Created for new Test Classesss',
                                                Origin = 'Email',
                                                Web_Region__c = 'Americas', 
                                                Product_Family_List__c = 'Backup Server/Service',
                                                Case_Reason__c= 'BCC', 
                                                Offline_Support_Type__c = 'Sales',
                                                Web_Serial__c = '76543',
                                                Description = 'Web Case ', 
                                                Web_First_Name__c = con[0].FirstName,
                                                Web_Last_Name__c = con[0].LastName,
                                                RMA_Submitted_By__c = newUser2.Id,
                                                Escalated_to_support_escalations_by__c = newUser2.Id,
                                                Closed_Case_Reason__c = 'Account Merge',
                                                Missing_Serial_Number__c = 'abc'
                                                //Is_Test_Record__c = true,
                                                );            
        //In Progress Tech Support Case
        Case inProgressTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                                  Status =  'In Progress',
                                                  AccountId = acc[0].Id,
                                                  ContactId = con[0].id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                  RMA_Submitted_By__c = newUser2.Id,
                                                  Escalated_to_support_escalations_by__c = newUser2.Id,
                                                  Closed_Case_Reason__c = 'Account Merge',
                                                  Missing_Serial_Number__c = 'abc'
                                                 // Is_Test_Record__c = true,
                                                  );  
                                                  
        //Closed Tech Support Case
        Case closedTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                                  Status =  'Closed',
                                                  AccountId = acc[0].Id,
                                                  ContactId = con[0].id, 
                                                  Subject = 'Case Created for new Test Classesss',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                  CreatedById=newUser1.Id,
                                                  Closed_Case_Reason__c = 'Account Merge',
                                              RMA_Submitted_By__c = newUser2.Id,
                                              Escalated_to_support_escalations_by__c = newUser2.Id,
                                              Missing_Serial_Number__c = 'abc',
                                              //Is_Test_Record__c = true,
                                             	  ownerId=newUser1.id);      
        
        //Closed Tech Support Case
        Case closedTechSupportCaseWithParentId = new case(RecordTypeId = techSupportRTId,
                                                  Status =  'Closed',
                                                  AccountId = acc[0].Id,
                                                  ContactId = con[0].id,  
                                                  Subject = 'Case Created with ParentId',
                                                  Origin = 'Email',
                                                  Web_Region__c = 'Americas', 
                                                  Product_Family_List__c = 'Backup Server/Service',
                                                  Case_Reason__c= 'BCC', 
                                                  Offline_Support_Type__c = 'Sales',
                                                  Web_Serial__c = '76543',
                                                  Description = 'Web Case ', 
                                                  Web_First_Name__c = con[0].FirstName,
                                                  Web_Last_Name__c = con[0].LastName,
                                                  CreatedById=newUser1.Id,
                                                  Closed_Case_Reason__c = 'Account Merge',
                                                          RMA_Submitted_By__c = newUser2.Id,
                                                          Escalated_to_support_escalations_by__c = newUser2.Id,
                                                          Missing_Serial_Number__c = 'abc',
                                                          //Is_Test_Record__c = true,
                                                  ownerId=newUser1.id);
        
        //List of test cases
        List<Case> lstCases = new List<Case>{newWebMessageCase, 
            waitingWebMessageCase,
            inProgressTechSupportCase
           /* inProgressWebMessageCase,
            closedWebMessageCase,
            waitingTechSupportCase, 
            resolvedTechSupportCase,
            vendorHoldTechSupportCase,
            
            closedTechSupportCase,
            closedTechSupportCaseWithParentId,
            inProgressProfessionalServiceCase,
            newProfessionalServiceCase,
            wfcrProfessionalServiceCase,
            closedProfessionalServiceCase
            };                                            
        
       // insert lstCases;
 	system.debug('lstCases->' + lstCases);*/
        Test.stopTest();
        
          
    
  }
  
  /** Add Feed Comments to cases and it should update case status as per the business rule */
  static testmethod void shouldUpdateCaseStatus() {
    
        User newUser2=[SELECT id,contact.accountId,contact.firstName,contact.lastName,contactId 
                    FROM user 
                    WHERE userName Like 'newUsertestt@yaho.com%' LIMIT 1] ;
      
     List<case> csList=new List<Case>();
      
      
    Id newWebMessageCaseId;
    Id waitingWebMessageCaseId;
    Id waitingTechSupportCaseId;
    Id resolvedTechSupportCaseId;
    Id vendorHoldTechSupportCaseId;
    Id closedWebMessageCaseId;
     
     Id techSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();    
    Case vendorHoldTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                                Status =  'Vendor Hold',
                                                AccountId = newUser2.contact.AccountId,
                                                ContactId = newUser2.contactId, 
                                                Subject = 'Case Created for new Test Classesss',
                                                Origin = 'Email',
                                                Web_Region__c = 'Americas', 
                                                Product_Family_List__c = 'Backup Server/Service',
                                                Case_Reason__c= 'BCC', 
                                                Offline_Support_Type__c = 'Sales',
                                                Web_Serial__c = '76543',
                                                Description = 'Web Case ', 
                                                Web_First_Name__c = newUser2.contact.FirstName,
                                                Web_Last_Name__c = newUser2.contact.LastName,
                                                RMA_Submitted_By__c = newUser2.Id,
                                                Escalated_to_support_escalations_by__c = newUser2.Id,
                                                Closed_Case_Reason__c = 'Account Merge',
                                                Missing_Serial_Number__c = 'abc',
                                                ownerId=newUser2.Id
                                                ); 
      
      csList.add(vendorHoldTechSupportCase);

    //Web Message Record Type ID
    Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
    //Tech Support Record Type Id
    Case newWebMessageCase = new case(RecordTypeId = techSupportRTId,
                                        Status =  'In Progress',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        );
     csList.add(newWebMessageCase);
      
      System.runAs(newUser2){
          insert csList;
      }
      
    Test.startTest();
    List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
      
      //User portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];  
          //Prepare feedcomment
          for(Case currentCase: [SELECT Id, 
                                 RecordType.DeveloperName,
                                 Status 
                                 FROM Case where RecordTypeId =: techSupportRTId]){
                                     
                                     lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                                                  body     = 'test'));
                                     
                                     switch on currentCase.RecordType.DeveloperName{
                                         //Tech Support Cases
                                         when 'Technical_Support'{
                                             switch on currentCase.Status{
                                                 when 'Waiting for Customer Response'{
                                                     waitingTechSupportCaseId = currentCase.Id; 
                                                 }
                                                 when 'Vendor Hold'{
                                                     vendorHoldTechSupportCaseId = currentCase.id;
                                                 }
                                                 when 'Resolved'{
                                                     resolvedTechSupportCaseId = currentCase.id;
                                                 }
                                             }
                                         }
                                         //Web Message Cases
                                         when 'Web_Case'{
                                             switch on currentCase.Status{
                                                 when 'Waiting for Customer Response'{
                                                     waitingWebMessageCaseId = currentCase.id;
                                                 }
                                                 when 'New'{
                                                     newWebMessageCaseId = currentCase.Id;
                                                 }          
                                                 when 'Closed'{
                                                     closedWebMessageCaseId = currentCase.Id;
                                                 }
                                                 
                                             }
                                         }
                                     }  //END SWITCH                                                                    
                                 } //END FOR
          
          //Insert feed comments   
          insert lstFeedItem;  
          
          for(FeedItem currentFeedItem: lstFeedItem){
              feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                              FeedItemId  = currentFeedItem.Id,
                                              CreatedByID = UserInfo.getUserId()));
          }
          
          //Insert FeedComment
          insert feedcmntLst; 
          
          DynamicBusinessRuleFeedComment.removeChildFeedItem(JSON.serialize(csList));

    Test.stopTest();

    //Prepare the case map
    Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, 
                                                      Status, 
                                                      Last_Case_Note_Added__c 
                                               FROM Case 
                                               WHERE Id in (:newWebMessageCaseId, 
                                                            :waitingWebMessageCaseId,
                                                            :waitingTechSupportCaseId,
                                                            :resolvedTechSupportCaseId,
                                                            :vendorHoldTechSupportCaseId)]);

    //Assert
    System.debug('statusss:::::::  '+caseMap.get(vendorHoldTechSupportCaseId).Status);
    System.assert(caseMap!=null && !caseMap.isEmpty());
      
   	//System.assertEquals('Vendor Hold', caseMap.get(vendorHoldTechSupportCaseId).Status);
   // System.assertEquals('In Progress', caseMap.get(waitingTechSupportCaseId).Status);
    //System.assertEquals('In Progress', caseMap.get(resolvedTechSupportCaseId).Status);
    // System.assertEquals('New', caseMap.get(waitingWebMessageCaseId).Status);
  } 
    
  static testmethod void shouldUpdateCaseStatus2() {
              User newUser2=[SELECT id,contact.accountId,contact.firstName,contact.lastName,contactId 
                    FROM user 
                    WHERE userName Like 'newUsertestt@yaho.com%' LIMIT 1] ;
      
      List<case> csList=new List<case>();
      
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    Id newWebMessageCaseId;
    Id waitingWebMessageCaseId;
    Id waitingTechSupportCaseId;
    Id resolvedTechSupportCaseId;
    Id vendorHoldTechSupportCaseId;
    Id closedWebMessageCaseId;

    //Web Message Record Type ID
    Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
    //Tech Support Record Type Id
    Id techSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();    
      Case newWebMessageCase = new case(RecordTypeId = webMessageRTId,
                                        Status =  'Closed',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        //Is_Test_Record__c = true,
                                        );
    csList.add(newWebMessageCase);
       Case newTechSupportCase = new case(RecordTypeId = techSupportRTId,
                                        Status =  'Closed',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        //Is_Test_Record__c = true,
                                        );
    csList.add(newTechSupportCase);
    insert csList;
    Test.startTest();
    List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
      
      //User portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];  
    
          //Prepare feedcomment
          for(Case currentCase: [SELECT Id, 
                                 RecordType.DeveloperName,
                                 Status 
                                 FROM Case where RecordTypeId IN (:webMessageRTId,
                                                                   :techSupportRTId)]){
                                     lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                                                  body     = 'test'));
                                     
                                     switch on currentCase.RecordType.DeveloperName{
                                         //Tech Support Cases
                                         when 'Technical_Support'{
                                             switch on currentCase.Status{
                                                 when 'Waiting for Customer Response'{
                                                     waitingTechSupportCaseId = currentCase.Id; 
                                                 }
                                                 when 'Vendor Hold'{
                                                     vendorHoldTechSupportCaseId = currentCase.id;
                                                 }
                                                 when 'Closed'{
                                                     resolvedTechSupportCaseId = currentCase.id;
                                                 }
                                             }
                                         }
                                         //Web Message Cases
                                         when 'Web_Case'{
                                             switch on currentCase.Status{
                                                 when 'Waiting for Customer Response'{
                                                     waitingWebMessageCaseId = currentCase.id;
                                                 }
                                                 when 'New'{
                                                     newWebMessageCaseId = currentCase.Id;
                                                 }          
                                                 when 'Closed'{
                                                     closedWebMessageCaseId = currentCase.Id;
                                                 }
                                                 
                                             }
                                         }
                                     }  //END SWITCH                                                                    
                                 } //END FOR
          
          //Insert feed comments
          insert lstFeedItem;
          
          for(FeedItem currentFeedItem: lstFeedItem){
              feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                              FeedItemId  = currentFeedItem.Id,
                                              CreatedByID = UserInfo.getUserId()));
          }
          
          //Insert FeedComment
          insert feedcmntLst; 
          
      

    Test.stopTest();

    //Prepare the case map
    Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, 
                                                      Status, 
                                                      Last_Case_Note_Added__c 
                                               FROM Case 
                                               WHERE Id in (:closedWebMessageCaseId, 
                                                            :waitingWebMessageCaseId,
                                                            :waitingTechSupportCaseId,
                                                            :resolvedTechSupportCaseId,
                                                            :vendorHoldTechSupportCaseId)]);

    //Assert
    System.assert(caseMap!=null && !caseMap.isEmpty());
    //System.assertEquals('In Progress', caseMap.get(vendorHoldTechSupportCaseId).Status);
    //System.assertEquals('In Progress', caseMap.get(waitingTechSupportCaseId).Status);
    System.assertEquals('Closed', caseMap.get(resolvedTechSupportCaseId).Status);
    System.assertEquals('Closed', caseMap.get(closedWebMessageCaseId).Status);
  } 
        
    
  static testmethod void shouldUpdateCaseStatus3() {
     
       User newUser2=[SELECT id,contact.accountId,contact.firstName,contact.lastName,contactId 
                    FROM user 
                    WHERE userName Like 'newUsertestt@yaho.com%' LIMIT 1] ;
      
      
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    Id newProfessionalCaseId;
    
    Id professionalservieRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();    
      
   Case professionalService = new case(RecordTypeId = professionalservieRTId,
                                        Status =  'Closed',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        //Is_Test_Record__c = true,
                                        );
      
      
       
      
      insert professionalService;
      
      
    Test.startTest();
    List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
      
      //User portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];  
    
          //Prepare feedcomment
          for(Case currentCase: [SELECT Id, 
                                 RecordType.DeveloperName,
                                 Status 
                                 FROM Case where RecordTypeId =: professionalservieRTId]){
                                     lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                                                  body     = 'test'));
                                     
                                   newProfessionalCaseId=currentCase.Id;
                                 } //END FOR
          
          //Insert feed comments
          insert lstFeedItem;
          
          for(FeedItem currentFeedItem: lstFeedItem){
              feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                              FeedItemId  = currentFeedItem.Id,
                                              CreatedByID = UserInfo.getUserId()));
          }
          
          //Insert FeedComment
          insert feedcmntLst; 
          
      

    Test.stopTest();

    //Prepare the case map
    Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, 
                                                      Status, 
                                                      Last_Case_Note_Added__c 
                                               FROM Case 
                                               WHERE Id =:newProfessionalCaseId]);

    //Assert
    System.assert(caseMap!=null && !caseMap.isEmpty());
    //System.assertEquals('In Progress', caseMap.get(vendorHoldTechSupportCaseId).Status);
    System.assertEquals('Closed', caseMap.get(newProfessionalCaseId).Status);
    //System.assertEquals('In Progress', caseMap.get(resolvedTechSupportCaseId).Status);
    //System.assertEquals('New', caseMap.get(waitingWebMessageCaseId).Status);
  } 
    
    

  /** Add Feed Comments to a closed case and it should create a new case */
  static testmethod void shouldCreateNewCase() {
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    Test.startTest();
    List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
    
    //Prepare feedcomment
    for(Case currentCase: [SELECT Id, 
                                  RecordType.DeveloperName,
                                  Status 
                          FROM Case 
                          WHERE Status = 'Closed' 
                          AND RecordType.DeveloperName = 'Technical_Support']){
      lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                   body     = 'test'));
    } //END FOR

    //Insert feed comments
    insert lstFeedItem;

    //Feed comment body
    String commentBody = 'Case Status Will Change to In Progress. Testing the number of characters that can be accommodated in the subject of the new case' + 
    'Case Status Will Change to In Progress. Testing the number of characters that can be accommodated in the subject of the new case.';
    
    //Add feed comments
    for(FeedItem currentFeedItem: lstFeedItem){

      //Add 2 comments to test the bulkification of the method
      feedcmntLst.add(new FeedComment(CommentBody = commentBody,
                                      FeedItemId  = currentFeedItem.Id,
                                      CreatedByID = UserInfo.getUserId()));                                    
    }

    //Insert FeedComment
  //  insert feedcmntLst[0]; 

    Test.stopTest();
	//case ToBeUpdateCase = new case(id=[SELECT id from case where subject = 'Case Created with ParentId' LIMIT 1][0].id);
    //  ToBeUpdateCase.ParentId = [SELECT id from case where subject='Case Created for new Test Classesss'][0].Id;
      //update ToBeUpdateCase;
     /* user portalUser = null;
      try{
      	portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];     
      }
      catch(Exception e){
          
      }
      if(portalUser == null || portalUser.IsActive == false){
          Profile p;
          if(portalUser == null){
              p = [Select Id From Profile Where Name='Partner Community User' LIMIT 1];
          }    
          Blob b = Crypto.GenerateAESKey(128);
          String h = EncodingUtil.ConvertTohex(b);
          String uid = h.SubString(0,8);
          portalUser = new User(Alias = uid, Email= uid + '@mydomain.com', 
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
          LocaleSidKey='en_US', ProfileId = (portalUser == null ? p.Id : portalUser.ProfileId), 
          TimeZoneSidKey='America/New_York', UserName= uid + '@mydomain.com');
          //insert portalUser;
      }
      if(portalUser != null && portalUser.IsActive == true){
          system.runAs(portalUser){
              
             // update ToBeUpdateCase;
             
              // web case close
              try{
                  // web case close
                  case cas4 = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Web_Case' LIMIT 1].Id);
                  cas4.AccountId = portalUser.AccountId;
                  update cas4;              
                  FeedItem feedItm4 = new FeedItem(ParentId = cas4.id,body= 'test');
                  insert feedItm4;
                  FeedComment feedComent4 =  new FeedComment(CommentBody = 'commentBody',
                                                             FeedItemId  = feedItm4.Id,
                                                             CreatedByID = portalUser.id);  //UserInfo.getUserId());
                  insert feedComent4;                    
              } catch(exception e){
                  
              }    
              
              Account acc = [Select Id from Account where Name = 'newAcc1' limit 1];
              case cas3 = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
              cas3.AccountId = portalUser.AccountId;
              update cas3;
              FeedItem feedItm3 = new FeedItem(ParentId = cas3.id,body= 'test');
              insert feedItm3;
              FeedComment feedComent3 =  new FeedComment(CommentBody = 'commentBody',
                                                        FeedItemId  = feedItm3.Id,
                                                        CreatedByID = portalUser.id);  //UserInfo.getUserId());
              insert feedComent3;                                 
             
         
          }
      }
      else{
          case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
             FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
              insert feedItm;
           FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                          FeedItemId  = feedItm.Id,
                                          CreatedByID = portalUser.id);  //UserInfo.getUserId());
              insert feedComent;
      }
      
    //Assertions
    Map<Id,Case> assertionCaseMap = new Map<Id, Case>([SELECT Id,
                                                              AccountId,
                                                              ContactId,
                                                              Description,
                                                              Origin,
                                                              ParentId,
                                                              Product_Family_List__c,
                                                              Status,
                                                              Subject,
                                                              Web_Region__c,
                                                              Web_Serial__c,
                                                              Web_First_Name__c,
                                                              Web_Last_Name__c,
                                                              RecordType.DeveloperName          
                                                       FROM Case 
                                                       WHERE Status in ('New', 'Closed') 
                                                       AND RecordType.DeveloperName = 'Technical_Support' AND ParentId != null]);

    System.assert(assertionCaseMap!=null && !assertionCaseMap.isEmpty());

    //Boolean to check of new case exists
    Boolean newCaseCreated = false;
    for(Case currentCase: assertionCaseMap.values()){
      if(currentCase.RecordType.DeveloperName == 'Technical_Support' &&(currentCase.Status == 'New' || currentCase.Status == 'Closed') ){
        //Get the parent case
        System.assert(String.isNotBlank(String.valueOf(currentCase.ParentId)));
        if(assertionCaseMap.containsKey(currentCase.ParentId)){
          Case parentCase = assertionCaseMap.get(currentCase.ParentId);
          System.assertEquals(parentCase.AccountId,currentCase.AccountId);
          System.assertEquals(parentCase.ContactId,currentCase.ContactId);
          System.assertEquals(commentBody.stripHtmlTags(),currentCase.Description);
          System.assertEquals(parentCase.Origin,currentCase.Origin);
          System.assertEquals(parentCase.Product_Family_List__c,currentCase.Product_Family_List__c);
          System.assertEquals(commentBody.stripHtmlTags().left(255),currentCase.Subject);
          System.assertEquals(parentCase.Web_Region__c,currentCase.Web_Region__c);
          System.assertEquals(parentCase.Web_Serial__c,currentCase.Web_Serial__c);
          System.assertEquals(parentCase.Web_First_Name__c,currentCase.Web_First_Name__c);
          System.assertEquals(parentCase.Web_Last_Name__c,currentCase.Web_Last_Name__c);
        }
        newCaseCreated = true;
      }
    }
    //Fail assertion if the new case was not created
    System.assert(newCaseCreated);*/
  }
    
    
    @isTest
    public static void communityCase(){
        Test.startTest();
         User newUser2=[SELECT id,contact.accountId,contact.firstName,contact.lastName,contactId 
                    FROM user 
                    WHERE userName Like 'newUsertestt@yaho.com%' LIMIT 1] ;
      
      
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
        
    Id Community_HelpRTId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();    
    Id Community_HelprecordId;
        Case communityCs = new case(RecordTypeId = Community_HelpRTId,
                                        Status =  'Waiting for Requester Response',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        //Is_Test_Record__c = true,
                                        );
        insert communityCs;
         List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
      
      //User portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];  
    
          //Prepare feedcomment
          for(Case currentCase: [SELECT Id, 
                                 RecordType.DeveloperName,
                                 Status 
                                 FROM Case where RecordTypeId =: Community_HelpRTId]){
                                     lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                                                  body     = 'test'));
                                     
                                   Community_HelprecordId=currentCase.Id;
                                 } //END FOR
          
          //Insert feed comments
          insert lstFeedItem;
          
          for(FeedItem currentFeedItem: lstFeedItem){
              feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                              FeedItemId  = currentFeedItem.Id,
                                              CreatedByID = UserInfo.getUserId()));
          }
          
          //Insert FeedComment
          insert feedcmntLst; 
          
      

    Test.stopTest();

    //Prepare the case map
    Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, 
                                                      Status, 
                                                      Last_Case_Note_Added__c 
                                               FROM Case 
                                               WHERE Id =:Community_HelprecordId]);

    //Assert
    System.assert(caseMap!=null && !caseMap.isEmpty());
    //System.assertEquals('In Progress', caseMap.get(vendorHoldTechSupportCaseId).Status);
    System.assertEquals('Response Received', caseMap.get(Community_HelprecordId).Status);
    }

    @isTest
    public static void Case_Internal_Ticket_Record_Type(){
        Test.startTest();
         User newUser2=[SELECT id,contact.accountId,contact.firstName,contact.lastName,contactId 
                    FROM user 
                    WHERE userName Like 'newUsertestt@yaho.com%' LIMIT 1] ;
      
      
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
        
    Id Internal_RTId=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Internal_Ticket_Record_Type').getRecordTypeId();    
    Id InternalrecordId;
        Case InternalCs = new case(RecordTypeId = Internal_RTId,
                                        Status =  'Waiting for Requester Response',
                                        AccountId = newUser2.contact.AccountId,
                                        ContactId = newUser2.contactId, 
                                        Subject = 'Case Created for new Test Class',
                                        Origin = 'Email',
                                        Web_Region__c = 'Americas', 
                                        Product_Family_List__c = 'Backup Server/Service',
                                        Case_Reason__c= 'BCC', 
                                        Offline_Support_Type__c = 'Sales',
                                        Web_Serial__c = '76543',
                                        Description = 'Web Case ', 
                                        Web_First_Name__c = newUser2.contact.FirstName,
                                        Web_Last_Name__c = newUser2.contact.LastName,
                                        RMA_Submitted_By__c = newUser2.Id,
                                        Escalated_to_support_escalations_by__c = newUser2.Id,
                                        Closed_Case_Reason__c = 'Account Merge',
                                        Missing_Serial_Number__c = 'abc',
                                        ownerId=newUser2.Id
                                        //Is_Test_Record__c = true,
                                        );
        insert InternalCs;
         List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
      
      //User portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];  
    
          //Prepare feedcomment
          for(Case currentCase: [SELECT Id, 
                                 RecordType.DeveloperName,
                                 Status 
                                 FROM Case where RecordTypeId =: Internal_RTId]){
                                     lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                                                  body     = 'test'));
                                     
                                   InternalrecordId=currentCase.Id;
                                 } //END FOR
          
          //Insert feed comments
          insert lstFeedItem;
          
          for(FeedItem currentFeedItem: lstFeedItem){
              feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                              FeedItemId  = currentFeedItem.Id,
                                              CreatedByID = UserInfo.getUserId()));
          }
          
          //Insert FeedComment
          insert feedcmntLst; 
          
      
          DynamicBusinessRuleFeedComment fc=new DynamicBusinessRuleFeedComment();
          fc.sendEmailAndBellNotification(feedcmntLst[0], InternalCs, 'RMA_Case_Comment_Email_Template2', 'Engineering_Escalated_By__c');

          fc.sendEmailAndBellNotification(feedcmntLst[0], InternalCs, 'Escalated_Case_Comment_Email_Template', 'Engineering_Escalated_By__c');

          fc.sendEmailAndBellNotification(feedcmntLst[0], InternalCs, 'Escalated_Case_Comment_Email_Template', 'RMA_Submitted_By__c');

          fc.sendEmailAndBellNotification(feedcmntLst[0], InternalCs, 'Escalated_Case_Comment_Email_Template', 'Escalated_to_support_escalations_by__c');
    Test.stopTest();

    //Prepare the case map
    // Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, 
    //                                                   Status, 
    //                                                   Last_Case_Note_Added__c 
    //                                            FROM Case 
    //                                            WHERE Id =:Community_HelprecordId]);

    // //Assert
    // System.assert(caseMap!=null && !caseMap.isEmpty());
   
    // System.assertEquals('Response Received', caseMap.get(Community_HelprecordId).Status);
    }

    // @isTest
    // public static void sendEmailAndBellNotificationTest(){
    //     Test.startTest();

    //     DynamicBusinessRuleFeedComment fc=new DynamicBusinessRuleFeedComment();
    //     fc.sendEmailAndBellNotification(null, null, 'RMA_Case_Comment_Email_Template2', 'Engineering_Escalated_By__c');


    //     Test.stopTest();

    // }

  /*static testMethod void shouldCreateNewCase2(){
    TriggerContextVariables.RUN_CASE_TRIGGER = false;

    Test.startTest();
    case ToBeUpdateCase = new case(id=[SELECT id from case where subject = 'Case Created with ParentId' LIMIT 1][0].id);
    ToBeUpdateCase.ParentId = [SELECT id from case where subject='Case Created for new Test Classesss'][0].Id;
    update ToBeUpdateCase;
    user portalUser = null;
    try{
      portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];     
    }
    catch(Exception e){
        
    }
    if(portalUser == null || portalUser.IsActive == false){
        Profile p;
        if(portalUser == null){
            p = [Select Id From Profile Where Name='Partner Community User' LIMIT 1];
        }    
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        portalUser = new User(Alias = uid, Email= uid + '@mydomain.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = (portalUser == null ? p.Id : portalUser.ProfileId), 
        TimeZoneSidKey='America/New_York', UserName= uid + '@mydomain.com');
        //insert portalUser;
      }
        if(portalUser != null && portalUser.IsActive == true){
          system.runAs(portalUser){
              case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
             FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
              insert feedItm;
           FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                          FeedItemId  = feedItm.Id,
                                          CreatedByID = portalUser.id);  //UserInfo.getUserId());
              insert feedComent;
          }
    }
    else{
      case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
         FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
          insert feedItm;
       FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                      FeedItemId  = feedItm.Id,
                                      CreatedByID = portalUser.id);  //UserInfo.getUserId());
          insert feedComent;
    }
    Test.stopTest();

  }

  static testMethod void shouldCreateNewCase3(){

    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    case ToBeUpdateCase = new case(id=[SELECT id from case where subject = 'Case Created with ParentId' LIMIT 1][0].id);
    ToBeUpdateCase.ParentId = [SELECT id from case where subject='Case Created for new Test Classesss'][0].Id;
    update ToBeUpdateCase;
    Test.startTest();
    user portalUser = null;
    try{
      portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];     
    }
    catch(Exception e){
        
    }
    if(portalUser == null || portalUser.IsActive == false){
        Profile p;
        if(portalUser == null){
            p = [Select Id From Profile Where Name='Partner Community User' LIMIT 1];
        }    
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        portalUser = new User(Alias = uid, Email= uid + '@mydomain.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = (portalUser == null ? p.Id : portalUser.ProfileId), 
        TimeZoneSidKey='America/New_York', UserName= uid + '@mydomain.com');
        //insert portalUser;
      }
        if(portalUser != null && portalUser.IsActive == true){
          system.runAs(portalUser){
            try{
              case cas2 = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Web_Case' LIMIT 1].Id);
              FeedItem feedItm2 = new FeedItem(ParentId = cas2.id,body= 'test');
              insert feedItm2;
              FeedComment feedComent2 =  new FeedComment(CommentBody = 'commentBody',
                                                         FeedItemId  = feedItm2.Id,
                                                         CreatedByID = portalUser.id);  //UserInfo.getUserId());
              insert feedComent2; 
          }
          catch(exception e){
                  
          }   
      }
    }
    else{
      case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
         FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
          insert feedItm;
       FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                      FeedItemId  = feedItm.Id,
                                      CreatedByID = portalUser.id);  //UserInfo.getUserId());
          insert feedComent;
    }
    Test.stopTest();
  }

  static testMethod void shouldCreateNewCase4(){
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    case ToBeUpdateCase = new case(id=[SELECT id from case where subject = 'Case Created with ParentId' LIMIT 1][0].id);
    ToBeUpdateCase.ParentId = [SELECT id from case where subject='Case Created for new Test Classesss'][0].Id;
    update ToBeUpdateCase;
    Test.startTest();
    user portalUser = null;
    try{
      portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];     
    }
    catch(Exception e){
        
    }
    if(portalUser == null || portalUser.IsActive == false){
        Profile p;
        if(portalUser == null){
            p = [Select Id From Profile Where Name='Partner Community User' LIMIT 1];
        }    
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        portalUser = new User(Alias = uid, Email= uid + '@mydomain.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = (portalUser == null ? p.Id : portalUser.ProfileId), 
        TimeZoneSidKey='America/New_York', UserName= uid + '@mydomain.com');
        //insert portalUser;
      }
        if(portalUser != null && portalUser.IsActive == true){
          system.runAs(portalUser){
            try{
              case cas4 = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Web_Case' LIMIT 1].Id);
              cas4.AccountId = portalUser.AccountId;
              update cas4;              
              FeedItem feedItm4 = new FeedItem(ParentId = cas4.id,body= 'test');
              insert feedItm4;
              FeedComment feedComent4 =  new FeedComment(CommentBody = 'commentBody',
                                                         FeedItemId  = feedItm4.Id,
                                                         CreatedByID = portalUser.id);  //UserInfo.getUserId());
              insert feedComent4; 
          }
          catch(exception e){
                  
          }   
      }
    }
    else{
      case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
         FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
          insert feedItm;
       FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                      FeedItemId  = feedItm.Id,
                                      CreatedByID = portalUser.id);  //UserInfo.getUserId());
          insert feedComent;
    }
    Test.stopTest();
  }

  static testMethod void shouldCreateNewCase5(){
    TriggerContextVariables.RUN_CASE_TRIGGER = false;
    case ToBeUpdateCase = new case(id=[SELECT id from case where subject = 'Case Created with ParentId' LIMIT 1][0].id);
    ToBeUpdateCase.ParentId = [SELECT id from case where subject='Case Created for new Test Classesss'][0].Id;
    update ToBeUpdateCase;
    Test.startTest();

    user portalUser = null;
    try{
      portalUser = [select id, IsActive, ProfileId, AccountId from user where profile.Name='Partner Community User' LIMIT 1];     
    }
    catch(Exception e){
        
    }
    if(portalUser == null || portalUser.IsActive == false){
        Profile p;
        if(portalUser == null){
            p = [Select Id From Profile Where Name='Partner Community User' LIMIT 1];
        }    
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8);
        portalUser = new User(Alias = uid, Email= uid + '@mydomain.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = (portalUser == null ? p.Id : portalUser.ProfileId), 
        TimeZoneSidKey='America/New_York', UserName= uid + '@mydomain.com');
        //insert portalUser;
      }
        if(portalUser != null && portalUser.IsActive == true){
          system.runAs(portalUser){
            Account acc = [Select Id from Account where Name = 'newAcc1' limit 1];
            case cas3 = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
            cas3.AccountId = portalUser.AccountId;
            update cas3;
            FeedItem feedItm3 = new FeedItem(ParentId = cas3.id,body= 'test');
            insert feedItm3;
            FeedComment feedComent3 =  new FeedComment(CommentBody = 'commentBody',
                                                      FeedItemId  = feedItm3.Id,
                                                      CreatedByID = portalUser.id);  //UserInfo.getUserId());
            insert feedComent3;                                 
      }
    }
    else{
      case cas = new case(id=[SELECT id from case where status='Closed' and RecordType.DeveloperName = 'Technical_Support' AND ParentId != null LIMIT 1].Id);
         FeedItem feedItm = new FeedItem(ParentId = cas.id,body= 'test');
          insert feedItm;
       FeedComment feedComent =  new FeedComment(CommentBody = 'commentBody',
                                      FeedItemId  = feedItm.Id,
                                      CreatedByID = portalUser.id);  //UserInfo.getUserId());
          insert feedComent;
    }
    Test.stopTest();
  }*/

  /** Add Feed Comments to cases and it should not update case status */
  static testmethod void shouldNotUpdateCaseStatus() {
     
    Test.startTest();
    List<FeedItem> lstFeedItem = new List<FeedItem>();
    List<FeedComment> feedcmntLst = new List<FeedComment>();
    
    //Prepare feedcomment
    for(Case currentCase: [SELECT Id, 
                                  RecordType.DeveloperName,
                                  Status 
                           FROM Case 
                           WHERE Status = 'In Progress']){
      lstFeedItem.add(new FeedItem(ParentId = currentCase.id,
                                   body     = 'test'));
    } //END FOR

       for(Case currentCase2: [SELECT Id, 
                                  RecordType.DeveloperName,
                                  Status 
                           FROM Case 
                           WHERE Status = 'Closed' and RecordType.DeveloperName = 'Technical_Support' ]){
      lstFeedItem.add(new FeedItem(ParentId = currentCase2.id,
                                   body     = 'test'));
    } //END FOR
    
    //Insert feed comments
    insert lstFeedItem;
    
      
    for(FeedItem currentFeedItem: lstFeedItem){

      //Add 2 comments to test the bulkification of the method
      feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                      FeedItemId  = currentFeedItem.Id,
                                      CreatedByID = UserInfo.getUserId()));

      feedcmntLst.add(new FeedComment(CommentBody = 'Case Status Will Change to In Progress',
                                      FeedItemId  = currentFeedItem.Id,
                                      CreatedByID = UserInfo.getUserId()));                                      
    }

    //Insert FeedComment
    insert feedcmntLst; 

    Test.stopTest();           

    //Assertions
    List<Case> inProgressCases = [SELECT Id        
                                  FROM Case 
                                  WHERE Status = 'In Progress'];

  //  System.assert(inProgressCases!=null && inProgressCases.size() == 3);
  } 
    
    @isTest
    static void fetchRecsTest(){
        RelatedListController.fetchRecs();
    }
}