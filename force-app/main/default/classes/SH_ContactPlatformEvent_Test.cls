/**********************************************************************************************
Class:     SH_ContactPlatformEvent_Test
Date:      04/11/2019
Name:      Youperience
Details:   Test class for validating platform events

***********************************************************************************************
***********************************************************************************************
Date         Name           Description
14/01/2020   Youperience    Change the DeveloperName from Name field when referencing Record Types.
17/08/2020   Rajiv Kumar    SFM-1953: Amended leadInsertIndividual_Update_Test by adding 
                            Marketing/Servicing Confirmed in System fields
12/05/2021   Arivu  S       STB-1856 - Amended leadInsertIndividual_Test after the LeadytriggerHelper 
							rewrite
12/01/2024   Rajiv Kumar    DG-180:: Added test method to push ADP records to Oscar.                          
***********************************************************************************************/
// Test method for contact platform event. To verify contact message Successfully published  
@isTest
private class SH_ContactPlatformEvent_Test {
    // Retrieve Account record type for Client
    static Id dentPracticeRecTypes = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dental_Practice').getRecordTypeId();
    
    @isTest 
    public static void PushContactMessag_test(){
        
        //retrieved dentist record type for contact
        List<RecordType> dentistRecTypes = [SELECT Id From RecordType where DeveloperName = 'Dentist' limit 1];
        
        //Retrieve user
        User userForTesting = [SELECT Id FROM User Where Name !='Interface User' limit 1];
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send To Oscar',Send__c=true);
        insert objSendToOscar;
        
        system.runAs(userForTesting)
        {
            //create account trigger controller record 
            Account accnt = new Account(Name='SHtestAccount1',Patient_Mix__c = 'Mixed',BillingStreet='testBilling',BillingCity='testBCity',
                                        BillingCountry='UnitedKingdom',RecordtypeId=dentPracticeRecTypes,
                                        BillingPostalCode = 'SN2 212');  
            insert accnt;
            
            test.startTest();
            //create contact trigger controller record.Set contact trigger on. 
            Contact cont = new Contact(RecordtypeId=dentistRecTypes[0].id,LastName='Cont1LastName',AccountId=accnt.id,Salutation='Mrs');
            insert cont;
            test.stopTest();
        }
        System.assertEquals(1, PlatformEventHelper.ContactOscarEvents.size());
        
    }
    
    // Test method for Account platform event. To verify Account message Successfully published 
    @isTest 
    public static void PushAccountMessag_test(){
        
        //retrieve user for assigning account owner
        User usr = [select Id from User WHERE IsActive=true AND Id =: userInfo.getUserId()];
        
        //For runing account trigger. create record on Trigger_Controller__c
        Trigger_Controller__c trgcntrler = new Trigger_Controller__c();
        trgcntrler.Account_Trigger_On__c=true;
        insert trgcntrler; 
        
        System_Account_Owner__c systAccnt = new System_Account_Owner__c();
        systAccnt.System_Owner_ID__c = usr.Id;
        insert systAccnt; 
        
        //create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send To Oscar',Send__c=true);
        insert objSendToOscar;
        
        test.startTest();
        //Create the Trigger Controller record. Set the Account Trigger on 
        Account accnt1 = new Account(Name='SHtestAccount2',Patient_Mix__c = 'Mixed',Practice_Type__c = 'Residence', recordtypeId=dentPracticeRecTypes,
                                     BillingStreet='testBilling2',BillingCity='testBCity2',BillingCountry='UnitedKingdom2',
                                     BillingPostalCode = 'SN2 212');
        insert accnt1; 
        test.stopTest();
        System.assertEquals(1, PlatformEventHelper.accProcessResults.size());
        system.assert(PlatformEventHelper.accProcessResults.size() >= 1);
        
    }
    
    // Test method for user platform event. To verify User message Successfully published  
    @isTest 
    public static void PushUserMessag_test(){
        //Retrieve user
        User userForTesting = [SELECT Id FROM User Where Name !='Interface User' limit 1];
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send To Oscar',Send__c=true);
        insert objSendToOscar;
        
        //Retrieve profile id for assigning user to system administrator profile
        Id  usrprfId = [Select Id from profile where Profile.Name='Professionals Dental Sales User' ].id;
        
        
        test.startTest();
        //Create the Trigger Controller record. Set the user Trigger on 
        user usr = new User(FirstName='TestFname',Lastname='TestL4Name',isActive=true,senderEmail='testsnderEmail@test.com',username='mrTestUser@testorg.com',
                            Email='testuser22@test.com',CommunityNickname='test213user',Alias='testUser',ProfileId=usrprfId,languagelocalekey='en_US',
                            emailencodingkey='UTF-8',localesidkey='en_US',timezonesidkey='America/Los_Angeles');
        insert usr;
        test.stopTest();
        System.assertEquals(1, PlatformEventHelper.UserOscarEvents.size());
        
    }
    
    // Test method for AccountTeam platform event. To verify Accountteam message Successfully published 
    @isTest 
    public static void PushAccountTeamMemberMessage_Test(){
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send To Oscar',Send__c=true);
        insert objSendToOscar;
        
        //For runing account trigger. create record on Trigger_Controller__c
        Trigger_Controller__c trgcntrler = new Trigger_Controller__c();
        trgcntrler.Account_Trigger_On__c=true;
        insert trgcntrler; 
        
        //retrieve user record for assigning assign as a accountteammember
        User usr = [select ID from User WHERE IsActive=true AND UserType='Standard' LIMIT 1];
        
        //Retrieve user
        User userForTesting = [SELECT Id FROM User Where Name !='Interface User' limit 1];
        
        //create account 
        Account accnt = new Account(Name='SHtestAccount1',recordtypeId=dentPracticeRecTypes,Patient_Mix__c = 'Mixed',
                                    BillingStreet='testBilling',BillingCity='testBCity',BillingCountry='UnitedKingdom',BillingPostalCode = 'SN2 212');
        insert accnt;
        Test.startTest();
        system.runAs(userForTesting)
        {
            AccountTeamMember newTeam = new AccountTeamMember(AccountId = accnt.ID,TeamMemberRole = 'Area manager',UserId = usr.ID);
            insert newTeam;
        }
        Test.stopTest();
        
        System.assertEquals(1, PlatformEventHelper.AccountTeamMemberOscarEvents.size());
    }
    // Test method for regfacbenefit platform event. To verify regfacbenfit message Successfully published 
    @isTest 
    public static void pushRegFacBenefit_Test(){
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send To Oscar',Send__c=true);
        insert objSendToOscar;
        
        //Retrieve user
        User userForTesting = [SELECT Id FROM User Where Name !='Interface User' limit 1];
        
        system.runAs(userForTesting)
        {
            //Create the Account record since reg fac need accountId
            Account accnt = new Account(Name='SHtestAccount1',Patient_Mix__c = 'Mixed',BillingStreet='testBilling',BillingCity='testBCity',
                                        RecordtypeId=dentPracticeRecTypes,BillingCountry='UnitedKingdom',BillingPostalCode = 'SN2 212');
            insert accnt;
            
            //Create the Reg_Fac__c record.
            Reg_Fac__c regfacObj = new Reg_Fac__c();
            regfacObj.Account__c = accnt.Id;
            regfacObj.Name = 'RegFacTestName';
            regfacObj.Notes__c = 'testNotes';
            insert regfacObj;
            
            test.startTest();
            //Create the Trigger Controller record on Reg_Fac_Benefit__c
            Reg_Fac_Benefit__c regfacBen = new Reg_Fac_Benefit__c(Reg_Fac__c=regfacObj.id,Treating_Item__c='Other',B_Allowance__c=12,C_Allowance__c=32);
            insert regfacBen;
            test.stopTest();
            
            System.assertEquals(1, PlatformEventHelper.RegFacBenefitEvents.size());
            delete regfacBen;
            
        }
    }
    
    // Test method for verifying individual and contact objects have to sync. 
    @isTest static void createUpdatingIndividual_Test(){
        
        //create account record since trigger control record on contact
        Account accnt = new Account(Name='SHtestAccount1',Patient_Mix__c = 'Mixed',BillingStreet='testBilling',BillingCity='testBCity',
                                    RecordtypeId=dentPracticeRecTypes,BillingCountry='UnitedKingdom',BillingPostalCode = 'SN2 212');
        insert accnt;
        
        Test.startTest();
        //Create the Trigger Controller record on contact
        Contact cont = new Contact(LastName='Cont1LastName',AccountId=accnt.id,Email='contactEmail@test.com');
        insert cont;
        test.stopTest();
        
        //retrieve newly created individual
        List<Individual> individualLst = [SELECT Id FROM Individual where Email__c =: cont.Email];
        System.assertEquals(1, individualLst.size());
        
    }
    
    // Test method for verifying individual and contact objects have to sync. 
    @isTest static void createUpdatingIndividual_Update_Test(){
        
        //create account record since trigger control record on contact
        Account accnt = new Account(Name='SHtestAccount1',Patient_Mix__c = 'Mixed',BillingStreet='testBilling',BillingCity='testBCity',
                                    RecordtypeId=dentPracticeRecTypes,BillingCountry='UnitedKingdom',BillingPostalCode = 'SN2 212');
        insert accnt;
        Individual individualSObj = new Individual();
        individualSObj.RecordTypeId = Schema.SObjectType.Individual.getRecordTypeInfosByDeveloperName().get('Professional').getRecordTypeId();
        individualSObj.FirstName = 'Cont1FirstName';
        individualSObj.LastName = 'Cont2LastName';
        individualSObj.Email__c = 'contactEmail@test.com';
        individualSObj.Marketing_by_Email__c = 'No';
        individualSObj.Marketing_by_Phone__c = 'No';
        individualSObj.Marketing_by_Post__c = 'No';
        individualSObj.Marketing_by_SMS__c = 'No';
        insert individualSObj;
        Test.startTest();
        //Create the Trigger Controller record on contact
        Contact cont = new Contact(LastName='Cont1LastName',AccountId=accnt.id,Email='contactEmail@test.com');
        insert cont;
        test.stopTest();
        
        //retrieve newly created individual
        List<Individual> individualLst = [SELECT Id FROM Individual where Email__c =: cont.Email];
        System.assertEquals(1, individualLst.size());
        
    }
    
    // Test method for verifying individual and lead objects have to sync. 
    @isTest static void leadInsertIndividual_Test(){
        List<lead> ldsLst = new list<Lead>(); 
        
        test.startTest();
        //Create the Trigger Controller record on Lead  
        Lead ld = new lead(Firstname='leadFirstName',lastName='ldLastName',Email='leadtest@test.com',Company='testCompany',Street='Kent');
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        ldsLst.add(ld);
        Lead ld2 = new lead(Firstname='leadFirstName2',lastName='ldLastName2',Email='leadtest@test.com',Company='testCompany',Street='Kent');
        ld2.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Corporate_Lead_Generation').getRecordTypeId();
        ldsLst.add(ld2);
        insert ldsLst;
        test.stopTest();  
        //retrieve newly created individual
        List<Individual> individualLst = [SELECT Id FROM Individual where Email__c =: 'leadtest@test.com'];
        
        System.assertEquals(1, individualLst.size());
        
    }
    
    // Test method for verifying individual and lead objects have to sync. 
    @isTest static void leadInsertIndividual_Update_Test(){
        Individual individualSObj = new Individual();
        individualSObj.RecordTypeId = Schema.SObjectType.Individual.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        individualSObj.FirstName = 'Cont1FirstName';
        individualSObj.LastName = 'Cont2LastName';
        individualSObj.Email__c = 'leadtest@test.com';
        individualSObj.Marketing_by_Email__c = 'No';
        individualSObj.Marketing_by_Phone__c = 'No';
        individualSObj.Marketing_by_Post__c = 'No';
        individualSObj.Marketing_by_SMS__c = 'No';
        individualSObj.Marketing_Pref_Confirmed_In_System__c = 'Salesforce Update';
        insert individualSObj; 
        
        test.startTest();
        //Create the Trigger Controller record on Lead  
        Lead ld = new lead(Firstname='leadFirstName',lastName='ldLastName',Email='leadtest@test.com',Company='testCompany',Street='Kent');
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        insert ld;
        LeadHandler.LeadFirstRun = true;
        ld.Marketing_Preference_SMS__c = 'Yes';
        update ld;
        test.stopTest();  
        //retrieve newly created individual
        List<Individual> individualLst = [SELECT Id FROM Individual where Email__c =: 'leadtest@test.com'];
        
        System.assertEquals(1, individualLst.size());
        
    }
    
    // Test method for case Contact role
    @isTest static void caseContactRole_Test(){
        List<Id> contIds = new List<Id>();
        //retrieve dentist record  
        List<RecordType> dentistRecTypes = [SELECT Id From RecordType where DeveloperName = 'Dentist' limit 1];
        
        //retrieved Professionals Dental record type for Case
        Id professionDetalrecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professionals_Dental').getRecordTypeId();
        
        //create account record since contact have to associate to account.
        Account accnt = new Account(Name='SHtestAccount1',Patient_Mix__c = 'Mixed',BillingStreet='testBilling',BillingCity='testBCity',
                                    RecordtypeId=dentPracticeRecTypes,BillingCountry='UnitedKingdom',BillingPostalCode = 'SN2 212');
        insert accnt;
        
        //create contact record
        Contact cont = new Contact(RecordtypeId=dentistRecTypes[0].id,LastName='Cont1LastName',AccountId=accnt.id,Salutation='Mrs');
        insert cont;
        contIds.add(cont.id);
        
        //create case record
        Case cs = new Case();
        cs.Type='testtypest';
        cs.Status = 'Scheduled';
        cs.Origin = 'Email';
        cs.AccountId=accnt.Id;
        cs.ContactId = cont.Id;
        cs.RecordTypeId=professionDetalrecTypeId;
        cs.Scheduled_Date__c = System.today() + 5;
        insert cs;
        
        //Create the Trigger Controller record on CaseContactRole
        CaseContactRole csContactRole = new CaseContactRole();
        csContactRole.CasesId=cs.id;
        csContactRole.ContactId=cont.Id;
        insert csContactRole;
        
        Test.startTest();
        //Apex Controller for DisplayCaseFromCaseContactRole Component
        CaseListForContactController caseController = new CaseListForContactController();
        CaseListForContactController.CaseListForContactDisplayFromRole(contIds);
        Test.stopTest();
        
        //retrieve newly created casecontactrole 
        List<CaseContactRole> caseContLst = [SELECT Id FROM CaseContactRole WHERE Id=: csContactRole.Id];
        
        System.assertEquals(1, caseContLst.size());
        system.assertNotEquals(null, CaseListForContactController.CaseListForContactDisplayFromRole(contIds));
        
    }

    //DG-180::START
    // Test method for person account platform event. To verify person account change message Successfully published 
    @isTest 
    public static void pushPersonAccDataToOscar_Test(){
        
        //For runing account trigger. create record on Trigger_Controller__c
        Trigger_Controller__c trgcntrler = new Trigger_Controller__c();
        trgcntrler.Account_Trigger_On__c=true;
        insert trgcntrler; 
        
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send Person Account Data',Send__c=true);
        insert objSendToOscar;
        
        //Retrieve user
        User userForTesting = [SELECT Id FROM User WHERE Name !='Interface User' limit 1];

        // Create a new Account Directory 
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'OscarADPData',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'O_12345',
                                                                           First_Name__c = 'FName',
                                                                           Last_Name__c = 'LName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Care_Status__c = 'Care Status',
                                                                           External_System__c = 'Oscar'
        );

        insert adp1;
        
        //Add a record for custom setting which allows ADP record to be pushed to Oscar using Platform event.
        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Oscar__c = true);
        insert dataSyncing;
        
        system.runAs(userForTesting)
        {
            
            Account accDtl = [Select Id, Firstname, Lastname, PersonEmail From Account Where Firstname = 'FName' And Lastname = 'LName'];
            accDtl.PersonEmail = 'testemail@test.co.uk';
            test.startTest();
            	update accDtl;
            test.stopTest();
            
        }
        system.assert(PlatformEventHelper.adpProcessResults[0].isSuccess());
        System.assertEquals(1, PlatformEventHelper.adpProcessResults.size());

    }
    
    // Test method for person account platform event. To verify when custom setting does not allow Platform event to be published.
    @isTest 
    public static void chkIfPersonAccDataShouldNotBePublished_Test(){
        
        //For runing account trigger. create record on Trigger_Controller__c
        Trigger_Controller__c trgcntrler = new Trigger_Controller__c();
        trgcntrler.Account_Trigger_On__c=true;
        insert trgcntrler; 
        
        
        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send Person Account Data',Send__c=false);
        insert objSendToOscar;
        
        //Retrieve user
        User userForTesting = [SELECT Id FROM User WHERE Name !='Interface User' limit 1];

        // Create a new Account Directory 
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'OscarADPData',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'O_12345',
                                                                           First_Name__c = 'FName',
                                                                           Last_Name__c = 'LName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Care_Status__c = 'Care Status',
                                                                           External_System__c = 'Oscar'
        );

        insert adp1;
        
        //Add a record for custom setting which allows ADP record to be pushed to Oscar using Platform event.
        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Oscar__c = true);
        insert dataSyncing;
        
        system.runAs(userForTesting)
        {
            
            Account accDtl = [Select Id, Firstname, Lastname, PersonEmail From Account Where Firstname = 'FName' And Lastname = 'LName'];
            accDtl.PersonEmail = 'testemail@test.co.uk';
            test.startTest();
            	update accDtl;
            test.stopTest();
            
        }
        
        System.assert(PlatformEventHelper.adpProcessResults == null);

    }
    
    @isTest 
    public static void personAccDataPlatformEvent_Test(){
        Test.startTest();
            Database.SaveResult sr = EventBus.publish(
                new PersonAccountUpdate__e(
                	Address_Line_1__c = 'Test Address Line 1',
                	Action__c = 'after_update',
                	City__c = 'Test City',
                    Country__c = 'Test Country',
                    Date_of_Birth__c = Date.newInstance(1982, 3, 16),
                    Email__c = 'testemail@test.co.uk',
                    External_Person_Id__c = 'O_123',
                    External_System__c = 'Oscar',
                    First_Name__c = 'Test FirstName',
                    Last_Name__c = 'Test LastName',
                    Mobile_Phone_Number__c = '423423',
                    Phone_Number__c = '213123',
                    Post_Code__c = 'SP10',
                    Salutation__c = 'Mr.',
                    State__c = 'Test State' ));
        Test.stopTest();
        
        // Force delivery of event if it happens in async process
        Test.getEventBus().deliver();
        
        System.assertEquals(true, sr.isSuccess());
    
    }
}