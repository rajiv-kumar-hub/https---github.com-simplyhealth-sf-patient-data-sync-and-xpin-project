@isTest
private class AccountTriggerHelper_Test {
/************************************************************************************************************************
    // Author: Sandeep Sekhon
    // Date:   06/12/2017
    // Project: Corporate Renewals
    // Description: This Test Class supports the AccountTriggerHelper class. 
         
    // SF-575   Jon Simmonds 08/03/2018 - Created new test method to prevent Account from being changed from Broker to Prospect
    // SF-1016  Jon Simmonds 06/03/2019 - Remove references to the custom setting fields SLA_Triggers_On__c and SLA_Transition_Date__c
    // SFM-2272 S.Sekhon     14/08/2020 - Test Birthdate_Text field populated when birthdate inserted or updated. 
       DG-180   Rajiv Kumar  12/01/2024 - Added test method for Oscar record processing
***************************************************************************************************************************/            
    // Use for Opportunity Dates
    private static final DateTime START_DATE = DateTime.Now().AddDays(- (DateTime.Now().Day() - 1)).Date();

    // Retrieve Account record type for Client
    private static RecordType AccClientRecType = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Client'];
    
    // Retrieve Opportunity Record Type for Cashplan Renewal
    public static RecordType RecTypeCashplanRenewal = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corporate_Cashplan_Renewal'];
    
    // Retrieve Opportunity Record Type for Dental New Business
    public static RecordType RecTypeDentalNewBus = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corp_Sales_New_Business'];
    
    
    static testMethod void createOppTest() {
    
        /*** Needed for reference only as called by Opportunity Trigger  ***/
        /*** Prevents test class failures on Opportunity related logic   ***/
        
        // Competitor Record type Id
        RecordType competitorRecordType = [select id from recordtype where developername = 'Competitor' and sobjecttype = 'Account'];
        
        // Create a Simplyhealth Competitor Account record
        Account simplyacc = new Account(AccountNumber = 'SH100000', Type = 'Competitor', RecordTypeId = competitorRecordType.Id, Name = 'Simplyhealth', BillingStreet = 'This There Street', BillingCity = 'This Here City', BillingPostalCode = 'AB56 9CD');
        insert simplyacc;
        
        /***********************************************************************/
    
    }

    /****** Scenario - Account with Cash Plan Broker set should update the corresponding Cash Plan Opportunities Cash_Plan_Broker__c ******/
    static testMethod void SetAccountCPBrokeronOpportunity() {

        createOppTest();

        // Create the Trigger Controller record. Set the Account Trigger on
        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True, Case_Trigger_On__c = True);
        insert triggerController;
    
      
        Test.startTest();
    
            // Broker Account from Test Data Factory      
            Account testBroker = TestDataFactory.createTestBrokerAccount(); 
   
   
            // Client Account with Broker    
            Account testAccount = new Account(AccountNumber = 'AA100000', Type = 'Client', RecordTypeId = AccClientRecType.Id, Name = 'New Business Test Acc', 
                                      BillingStreet = 'This There Street', BillingCity = 'This Here City', BillingPostalCode = 'AB12 3CD',
                                      Cashplan_Account_Manager__c = UserInfo.getUserId(), Dental_Account_Manager__c = UserInfo.getUserId(), 
                                      Cashplan_Broker__c = testBroker.Id,    Broker__c = testBroker.id);
            insert testAccount;


            // Retrieve existing values Account Broker with a new value
            Account oldAcc = [SELECT id, Cashplan_Broker__c, Broker__c FROM Account WHERE id = :testAccount.Id  ];
     
            //Create a Cash Plan opportunity for test Account    
            Opportunity opp1 =  new Opportunity (Name = 'Cash Plan Ren Opp 1', StageName = 'New Renewal', RecordTypeId = RecTypeCashplanRenewal.Id, 
                                         CloseDate = START_DATE.Date(), Funding_Method__c = 'Funded', Target_Audience__c = 1000, 
                                         AccountId = testAccount.Id, Cash_Plan_Broker__c = null );
            insert opp1;
    
    
            // Get new Broker Account from Test Data Factory      
            Account testBroker2 = TestDataFactory.createTestBrokerAccount2(); 
    
            // Update Account Broker with a new value
            Account updAcc = [SELECT id, Cashplan_Broker__c, Broker__c FROM Account WHERE id = :testAccount.Id  ];
            updAcc.Cashplan_Broker__c = testBroker2.Id;
     
            update updAcc;
        
            // Retrieve new Cash Plan Broker value from Opportunity    
            Opportunity oppNewCPBroker = [Select Cash_Plan_Broker__c From Opportunity Where Id = :opp1.Id];
      
        Test.stopTest();
    
        // Check Expected Result with Actual Result are the same
        System.assertEquals(oppNewCPBroker.Cash_Plan_Broker__c , testBroker2.Id);
        System.assertNotEquals(oldAcc.Cashplan_Broker__c, updAcc.Cashplan_Broker__c);
       
    }
    
   
    /****** Scenario - Account with Dental Broker set should update the corresponding Dental Opportunities Dental_Broker__c ******/ 
    static testMethod void SetAccountDenBrokeronOpportunity() {
    
        createOppTest();
         
        // Create the Trigger Controller record. Set the Account Trigger on
        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True, Case_Trigger_On__c = True);
        insert triggerController;

        Test.startTest();
    
            // Broker Account from Test Data Factory      
            Account testBroker = TestDataFactory.createTestBrokerAccount(); 
           
           
            // Client Account with Broker    
            Account testAccount = new Account(AccountNumber = 'AA100000', Type = 'Client', RecordTypeId = AccClientRecType.Id, Name = 'New Business Test Acc', 
                                              BillingStreet = 'This There Street', BillingCity = 'This Here City', BillingPostalCode = 'AB12 3CD',
                                              Cashplan_Account_Manager__c = UserInfo.getUserId(), Dental_Account_Manager__c = UserInfo.getUserId(), 
                                              Cashplan_Broker__c = testBroker.Id,    Broker__c = testBroker.id);
            insert testAccount;
    
             //Create a Dental opportunity for test Account  
            Opportunity opp2 =  new Opportunity (Name = 'Dental Ren Opp 2', StageName = 'New Renewal', RecordTypeId = RecTypeDentalNewBus.Id, 
                                                 CloseDate = START_DATE.Date(), Funding_Method__c = 'Funded', Target_Audience__c = 1000, 
                                                 AccountId = testAccount.Id, Dental_Broker__c = null );
            insert opp2;
        
            // Get new Broker Account from Test Data Factory      
            Account testBroker2 = TestDataFactory.createTestBrokerAccount2(); 
            
            // Update Account Broker with a new value
            Account updAcc = [SELECT id, Cashplan_Broker__c, Broker__c FROM Account WHERE id = :testAccount.Id  ];  
            updAcc.Broker__c = testBroker2.Id;
             
            update updAcc;
    

            // Retrieve new Dental Broker value from Opportunity    
            Opportunity oppNewDenBroker = [Select Dental_Broker__c From Opportunity Where Id = :opp2.Id];
    
    
        Test.stopTest();
    
        // Check Expected Result with Actual Result are the same
        System.assertEquals(oppNewDenBroker.Dental_Broker__c , testBroker2.Id);
    
    }
    

    // SF-575 Start - Jon Simmonds 08/03/2018 - Created new test method to prevent Account from being changed from Broker to Prospect    
    @isTest
    static void preventBrokerAccountBeingChangedToPropectAccount() {
    
        // Create Broker Account     
        // Account brokerAccount = TestDataFactory.createTestBrokerAccount();

        // Create the Trigger Controller record. Set the Account Trigger on
        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True, Case_Trigger_On__c = True);
        insert triggerController;
                
        // Retrieve Account Record Type for Broker
        RecordType RecTypeAccBroker = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Broker'];
        
        // Create a Broker Account record
        Account brokerAccount = new Account(OwnerId = UserInfo.getUserId(), Type = 'Broker', RecordTypeId = RecTypeAccBroker.Id, 
                                            Name = 'Test Broker Account', FCA_Membership_Ref__c = '123456', Broker_Status__c = 'Current', 
                                            BillingStreet = 'The Street', BillingCity = 'The City', BillingPostalCode = 'AB12 3CD',
                                            Phone = '1234567890', Website = 'www.unknowntestzz.co.uk'
                                           );
        insert brokerAccount;
        
        brokerAccount = [Select Id, RecordTypeId, Description From Account Where Id = :brokerAccount.Id];
        
        // Retrieve Account Record Type for Prospect
        RecordType RecTypeAccProspect = [Select Id From RecordType Where SobjectType = 'Account' and DeveloperName = 'Prospect'];
    
        String errorMessage;
        
        Test.startTest();
        
            try {
                // Amend the Account Record Type from Broker to Prospect
                brokerAccount.recordTypeId = RecTypeAccProspect.Id;
                brokerAccount.Description = 'A new description';
            
                update brokerAccount;
            
            }
            catch (Exception e) {
                // Retrieve the error message
                System.Assert(e.getMessage().contains('It is not possible to change a Broker Account to a Prospect Account'));
            }
            
        Test.stopTest();

    }
   
    
    // SF-2272 Test Birthdate_Text field is populated with birthdate as a text string  
    @isTest
    static void TestBirthdateTextisSet() {
    
    // Create the Trigger Controller record. Set the Account Trigger on
    Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True);
    insert triggerController;
    
    Test.startTest();
    
        Account personAcc1 = new Account(RecordTypeId = TestDataFactory.personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Dobby', LastName = 'Houseelf', 
                                         PersonBirthdate = Date.newInstance(1970, 7, 17), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                         BillingStreet = '100 Tigger Street', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP19 1RE', BillingCountry = 'UK',
                                         PersonEmail = 'Dobby.Houseelf@hotmail.co.uk.test', personhomephone = '01264719535', personmobilephone = '07545292313', Birthdate_text__pc = null,
                                         Data_Matching_LastName__c = '|HOUSEELF', Data_Matching_BillingPostCode__c = '|SP191RE'
                                         ); 
       
        Insert personAcc1;
       
    Test.stopTest();
    
    Account testAcc = [Select RecordTypeId, PersonBirthdate, Birthdate_text__pc From Account Where FirstName = 'Dobby' And LastName = 'Houseelf'];
    
    System.assertEquals('17/07/1970', testAcc.Birthdate_text__pc);
    
    }
    

    
    // Youperience 14/01/2020 - Created new test method to Validating the account billing street address
    @isTest
    static void testValidateAccountBillingAddress() {
        
        Trigger_Controller__c trcontrler = new Trigger_Controller__c();
            
            trcontrler.name='testtrigger';
            trcontrler.Account_trigger_on__c = true;
            insert trcontrler; 
        
        Test.startTest();
            
            Id dentPracticeRecTypes = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dental Practice').getRecordTypeId();
            Account acc = new Account();
            
            acc.Name='TestAccount';
            acc.RecordTypeId = dentPracticeRecTypes;
            acc.Practice_Type__c = 'Residence';
            acc.Patient_Mix__c='Mixed';
            acc.BillingStreet='teststreet';
            acc.BillingPostalCode = 'SN2 2FM';
            acc.BillingCity = 'TwinCity';
            acc.BillingCountry = 'United Kingdom';
            
            insert acc;
            
        Test.stopTest();
    }
    
    // Youperience 14/01/2020 - Created new test method to Validating the account billing street address with The Street can be a max of 50 characters, with 25 characters on each line error
    @isTest
    static void testValidateAccountBillingAddressWithError() {
    
        Trigger_Controller__c trcontrler = new Trigger_Controller__c();
            
            trcontrler.name='testtrigger';
            trcontrler.Account_trigger_on__c = true;
            insert trcontrler; 
        
        Test.startTest();
            Id dentPracticeRecTypes = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Dental_Practice'].Id;
            Account acc = new Account();
            acc.Name='TestAccount';
            acc.RecordTypeId = dentPracticeRecTypes;
            acc.Practice_Type__c = 'Residence';
            acc.Patient_Mix__c='Mixed';
            acc.BillingStreet='Test address with more then 50 characters or more then 25 characters in a line';
            acc.BillingPostalCode = 'SN2 2FM';
            acc.BillingCity = 'TwinCity';
            acc.BillingCountry = 'United Kingdom';
            try {
                    insert acc;
                }
                catch (Exception e) {
                    // Retrieve the error message
                    System.Assert(e.getMessage().contains('Please update the Address. The Street can be a max of 50 characters, with 25 characters on each line.'));
                }
                
        Test.stopTest();
    }
    
    // Youperience 14/01/2020 - Created new test method to Validating the account billing street address without Billing Address
    @isTest
    static void testValidateAccountWithoutBillingAddress() {
        
        Trigger_Controller__c trcontrler = new Trigger_Controller__c();
            
            trcontrler.name='testtrigger';
            trcontrler.Account_trigger_on__c = true;
            insert trcontrler; 
        
        Test.startTest();
        
            Id dentPracticeRecTypes = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Dental_Practice'].Id;
            Account acc = new Account();
            acc.Name='TestAccount';
            acc.RecordTypeId = dentPracticeRecTypes;
            acc.Practice_Type__c = 'Residence';
            acc.Patient_Mix__c='Mixed';
            try {
                    insert acc;
                }
                catch (Exception e) {
                    // Retrieve the error message
                    System.Assert(e.getMessage().contains('The following Address fields should not be blank: Street, Post Code,  Country and City'));
                }
                
        Test.stopTest();
    }

    // Arivu 14/08/2022 - If an account is having both Pulse and Ski ADPs then the change in the account should only update the Ski 
    //                    ADP and the Pulse PADP shoul not be updated and en entry in the integration Log should be created with the 
    //                    transaction type as Update Pulse Client  
    @isTest
    static void testPulseSkiAccountUpdate(){

        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Ski__c = true);
        insert dataSyncing;

        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True);
        insert triggerController;

        List<Account_Directory_Person__c> adpList = new List<Account_Directory_Person__c>();
        Account_Directory_Person__c skiCustomer = new Account_Directory_Person__c(Name = 'Pulse Ski',
                                                                                  Address_Line_1__c = '100 The Street',
                                                                                  City__c = 'Andover',
                                                                                  State__c = 'Hants',
                                                                                  Post_Code__c = 'SP10 3LJ',
                                                                                  Country__c = 'United Kingdom',
                                                                                  Country_Code__c = 'UK',
                                                                                  External_System_Id__c = 'SC_987654321',
                                                                                  External_System__c = 'Ski',
                                                                                  Ski_Entity__c = 'Customer',
                                                                                  First_Name__c = 'Pulse',
                                                                                  Last_Name__c = 'Ski',
                                                                                  Status__c = 'Active',
                                                                                  Date_of_Birth__c = Date.newInstance(1980, 2, 17),
                                                                                  Salutation__c = 'Mr',
                                                                                  Email__c = 'Pulse.Ski@hotmail.co.uk',
                                                                                  Phone_Number__c = '01264555888');   
        adpList.add(skiCustomer);                                                                                  

        Account_Directory_Person__c skiPerson = new Account_Directory_Person__c(Name = 'Pulse Ski',
                                                                                Address_Line_1__c = '100 The Street',
                                                                                City__c = 'Andover',
                                                                                State__c = 'Hants',
                                                                                Post_Code__c = 'SP10 3LJ',
                                                                                Country__c = 'United Kingdom',
                                                                                Country_Code__c = 'UK',
                                                                                External_System_Id__c = 'SP_123-456-789',
                                                                                External_System__c = 'Ski',
                                                                                Ski_Entity__c = 'Person',
                                                                                First_Name__c = 'Pulse',
                                                                                Last_Name__c = 'Ski',
                                                                                Status__c = 'Active',
                                                                                Date_of_Birth__c = Date.newInstance(1980, 2, 17),
                                                                                Salutation__c = 'Mr',
                                                                                Email__c = 'Pulse.Ski@hotmail.co.uk',
                                                                                Phone_Number__c = '01264555888');  
        adpList.add(skiPerson);        

        Account_Directory_Person__c pulseCustomer = new Account_Directory_Person__c(Name = 'Pulse Ski',
                                                                                    Address_Line_1__c = '100 The Street',
                                                                                    City__c = 'Andover',
                                                                                    State__c = 'Hants',
                                                                                    Post_Code__c = 'SP10 3LJ',
                                                                                    Country__c = 'United Kingdom',
                                                                                    Country_Code__c = 'UK',
                                                                                    External_System_Id__c = 'P_123456',
                                                                                    External_System__c = 'Pulse',
                                                                                    First_Name__c = 'Pulse',
                                                                                    Last_Name__c = 'Ski',
                                                                                    Status__c = 'Active',
                                                                                    Date_of_Birth__c = Date.newInstance(1980, 2, 17),
                                                                                    Salutation__c = 'Mr',
                                                                                    Email__c = 'Pulse.Ski@hotmail.co.uk',
                                                                                    Phone_Number__c = '01264555888');   
        adpList.add(pulseCustomer);    

        Database.insert(adpList);

        Account acc = [SELECT Id, LastName FROM Account];
        acc.LastName = 'SkiModified';   

        Test.startTest();
            Database.update(acc);                                                           
        Test.stopTest();

        Account_Directory_Person__c pulseADP = [SELECT Id, Last_Name__c FROM Account_Directory_Person__c 
                                                WHERE External_System__c = 'Pulse'];
        System.assertNotEquals('SkiModified', pulseADP.Last_Name__c);     
        
        List<Integration_Log__c> intLog = [SELECT Id, Transaction_Type__c FROM Integration_Log__c];
        System.assertEquals('Update Pulse Client', intLog[1].Transaction_Type__c);

        List<Account_Directory_Person__c> skiADPs = [SELECT Id, Last_Name__c FROM Account_Directory_Person__c 
                                                     WHERE External_System__c = 'Ski'];   
        System.assertEquals('SkiModified', skiADPs[0].Last_Name__c);                                                                                                  
        System.assertEquals('SkiModified', skiADPs[1].Last_Name__c);                                                                                                  

    }

    /**
        Method:  testOscarAccountUpdate
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Updating an Account record should update linked Oscar ADP record
    **/  
    @isTest
    static void testOscarAccountUpdate(){

        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Oscar__c = true);
        insert dataSyncing;

        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True);
        insert triggerController;

        Account_Directory_Person__c oscarAdpRecord = new Account_Directory_Person__c(Name = 'Test Oscar',
                                                                                  Address_Line_1__c = '100 The Street',
                                                                                  City__c = 'Andover',
                                                                                  State__c = 'Hants',
                                                                                  Post_Code__c = 'SP10 3LJ',
                                                                                  Country__c = 'United Kingdom',
                                                                                  Country_Code__c = 'UK',
                                                                                  External_System_Id__c = 'O_987654321',
                                                                                  External_System__c = 'Oscar',
                                                                                  First_Name__c = 'FirstName',
                                                                                  Last_Name__c = 'LastName',
                                                                                  Status__c = 'Active',
                                                                                  Date_of_Birth__c = Date.newInstance(1978, 2, 17),
                                                                                  Salutation__c = 'Mr',
                                                                                  Email__c = 'Oscar.Ski@hotmail.co.uk',
                                                                                  Phone_Number__c = '01264555888');   
        Database.insert(oscarAdpRecord);

        Account acc = [SELECT Id, LastName FROM Account Where Lastname = 'LastName'];
        acc.LastName = 'AmendedInSF';   

        Test.startTest();
            Database.update(acc);                                                           
        Test.stopTest();

        Account_Directory_Person__c oscarADP = [SELECT Id, Last_Name__c FROM Account_Directory_Person__c 
                                                WHERE External_System__c = 'Oscar' And First_Name__c = 'FirstName'];
        System.assertEquals('AmendedInSF', oscarADP.Last_Name__c);                                                                                                 

    }

    /**
        Method:  testOscarAdpPlatformEventTrigger
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Updating an Account record should trigger a platform event
    **/  
    @isTest
    static void testOscarAdpPlatformEventTrigger(){

        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Oscar__c = true);
        insert dataSyncing;

        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True);
        insert triggerController;

        // create a record on Platform_Event_Controller__c for checking that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        Platform_Event_Controller__c objSendToOscar = new Platform_Event_Controller__c(Name='Send Person Account Data',Send__c=true);
        insert objSendToOscar;

        Account_Directory_Person__c oscarAdpRecord = new Account_Directory_Person__c(Name = 'Test Oscar',
                                                                                  Address_Line_1__c = '100 The Street',
                                                                                  City__c = 'Andover',
                                                                                  State__c = 'Hants',
                                                                                  Post_Code__c = 'SP10 3LJ',
                                                                                  Country__c = 'United Kingdom',
                                                                                  Country_Code__c = 'UK',
                                                                                  External_System_Id__c = 'O_987654321',
                                                                                  External_System__c = 'Oscar',
                                                                                  First_Name__c = 'FirstName',
                                                                                  Last_Name__c = 'LastName',
                                                                                  Status__c = 'Active',
                                                                                  Date_of_Birth__c = Date.newInstance(1978, 2, 17),
                                                                                  Salutation__c = 'Mr',
                                                                                  Email__c = 'Oscar.Ski@hotmail.co.uk',
                                                                                  Phone_Number__c = '01264555888');   
        Database.insert(oscarAdpRecord);

        Account acc = [SELECT Id, LastName FROM Account Where Lastname = 'LastName'];
        acc.LastName = 'AmendedInSF';   

        Test.startTest();
            Database.update(acc);                                                           
        Test.stopTest();

        system.assert(PlatformEventHelper.adpProcessResults[0].isSuccess());
        System.assertEquals(1, PlatformEventHelper.adpProcessResults.size());                                                                                              

    }

    /**
        Method:  testOscarSkiAccountUpdate
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Updating an Account record which is shared between Oscar and Ski
    **/
    static void testOscarSkiAccountUpdate(){

        Integration_Data_Syncing__c dataSyncing = new Integration_Data_Syncing__c(Update_Salesforce_Data_To_Ski__c = true, Update_Salesforce_Data_To_Oscar__c = true);
        insert dataSyncing;

        Trigger_Controller__c triggerController = new Trigger_Controller__c(Account_Trigger_On__c = True);
        insert triggerController;

        List<Account_Directory_Person__c> adpList = new List<Account_Directory_Person__c>();
        Account_Directory_Person__c skiCustomer = new Account_Directory_Person__c(Name = 'Pulse Ski',
                                                                                  Address_Line_1__c = '100 The Street',
                                                                                  City__c = 'Andover',
                                                                                  State__c = 'Hants',
                                                                                  Post_Code__c = 'SP10 3LJ',
                                                                                  Country__c = 'United Kingdom',
                                                                                  Country_Code__c = 'UK',
                                                                                  External_System_Id__c = 'SC_987654321',
                                                                                  External_System__c = 'Ski',
                                                                                  Ski_Entity__c = 'Customer',
                                                                                  First_Name__c = 'Pulse',
                                                                                  Last_Name__c = 'Ski',
                                                                                  Status__c = 'Active',
                                                                                  Date_of_Birth__c = Date.newInstance(1980, 2, 17),
                                                                                  Salutation__c = 'Mr',
                                                                                  Email__c = 'Pulse.Ski@hotmail.co.uk',
                                                                                  Phone_Number__c = '01264555888');   
        adpList.add(skiCustomer);                                                                                  

        Account_Directory_Person__c skiPerson = new Account_Directory_Person__c(Name = 'Pulse Ski',
                                                                                Address_Line_1__c = '100 The Street',
                                                                                City__c = 'Andover',
                                                                                State__c = 'Hants',
                                                                                Post_Code__c = 'SP10 3LJ',
                                                                                Country__c = 'United Kingdom',
                                                                                Country_Code__c = 'UK',
                                                                                External_System_Id__c = 'SP_123-456-789',
                                                                                External_System__c = 'Ski',
                                                                                Ski_Entity__c = 'Person',
                                                                                First_Name__c = 'Pulse',
                                                                                Last_Name__c = 'Ski',
                                                                                Status__c = 'Active',
                                                                                Date_of_Birth__c = Date.newInstance(1980, 2, 17),
                                                                                Salutation__c = 'Mr',
                                                                                Email__c = 'Pulse.Ski@hotmail.co.uk',
                                                                                Phone_Number__c = '01264555888');  
        adpList.add(skiPerson);        

        Account_Directory_Person__c oscarCustomer = new Account_Directory_Person__c(Name = 'Test Oscar',
                                                                                  Address_Line_1__c = '100 The Street',
                                                                                  City__c = 'Andover',
                                                                                  State__c = 'Hants',
                                                                                  Post_Code__c = 'SP10 3LJ',
                                                                                  Country__c = 'United Kingdom',
                                                                                  Country_Code__c = 'UK',
                                                                                  External_System_Id__c = 'O_987654321',
                                                                                  External_System__c = 'Oscar',
                                                                                  First_Name__c = 'FirstName',
                                                                                  Last_Name__c = 'LastName',
                                                                                  Status__c = 'Active',
                                                                                  Date_of_Birth__c = Date.newInstance(1978, 2, 17),
                                                                                  Salutation__c = 'Mr',
                                                                                  Email__c = 'Oscar.Ski@hotmail.co.uk',
                                                                                  Phone_Number__c = '01264555888');     

        adpList.add(oscarCustomer);
        
        Database.insert(adpList);

        Account acc = [SELECT Id, LastName FROM Account];
        acc.LastName = 'SFModified';   

        Test.startTest();
            Database.update(acc);                                                           
        Test.stopTest();

        Account_Directory_Person__c oscarADP = [SELECT Id, Last_Name__c FROM Account_Directory_Person__c 
                                                WHERE External_System__c = 'Oscar'];
        System.assertEquals('SFModified', oscarADP.Last_Name__c);     
        
        List<Account_Directory_Person__c> skiADPs = [SELECT Id, Last_Name__c FROM Account_Directory_Person__c 
                                                     WHERE External_System__c = 'Ski'];   

        System.assertEquals('SFModified', skiADPs[0].Last_Name__c);                                                                                                  
        System.assertEquals('SFModified', skiADPs[1].Last_Name__c);                                                                                                  

    }

    

}