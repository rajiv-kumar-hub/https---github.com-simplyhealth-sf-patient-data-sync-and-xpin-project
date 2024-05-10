/**
    Class:   etlPersonAccountProcessing_Test
    Author:  Jon Simmonds
    Date:    18/12/2019
    Purpose: Test methods to test the linking logic between Person Account Directory and Person Account records
**/
/***********************************************************************************************
Date         Name          Description
12/01/2024   Rajiv Kumar   DG-180:: Added test methods for Oscar data processing
***********************************************************************************************/

@isTest
public class EtlPersonAccountProcessing_Test {


    @TestSetup
    static void setup() {
    
        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];
        RecordType personAccProspectRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Prospect'];
        
        Account testAcc1 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Tester', 
                                       PersonBirthdate = Date.newInstance(1960, 2, 17), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Weyhill Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 3LJ', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.tester@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|TESTER', Data_Matching_BillingPostCode__c = '|SP103LJ'
                                       ); 

        Database.insert(testAcc1);


        
        List<Account> twoAccounts = new List<Account>();
        
        Account prospectAcc1 = new Account(RecordTypeId = personAccProspectRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Twoaccounts', 
                                       PersonBirthdate = Date.newInstance(1980, 6, 16), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Weyhill Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 3LJ', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.tester@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|TWOACCOUNTS', Data_Matching_BillingPostCode__c = '|SP103LJ'
                                       ); 

        Account clientAcc1 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Twoaccounts', 
                                       PersonBirthdate = Date.newInstance(1980, 6, 16), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Weyhill Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 3LJ', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.tester@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|TWOACCOUNTS', Data_Matching_BillingPostCode__c = '|SP103LJ'
                                       );
        
        twoAccounts.add(prospectAcc1);
        twoAccounts.add(clientAcc1);
        Database.insert(twoAccounts);

        Account prospectAcc2 = new Account(RecordTypeId = personAccProspectRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Convertprospect', 
                                       PersonBirthdate = Date.newInstance(1982, 3, 16), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Weyhill Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 3LJ', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.tester@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|CONVERTPROSPECT', Data_Matching_BillingPostCode__c = '|SP103LJ'
                                       );

        Database.insert(prospectAcc2);

        List<Account> dupAccounts = new List<Account>();

        Account dupAcc1 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Duplicate', 
                                       PersonBirthdate = Date.newInstance(1981, 7, 19), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Test Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 1DE', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.duplicate@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|DUPLICATE', Data_Matching_BillingPostCode__c = '|SP101DE', External_Client_Id__pc = 'P_333888'
                                       ); 

        dupAccounts.add(dupAcc1);

        Account dupAcc2 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Duplicate', 
                                       PersonBirthdate = Date.newInstance(1981, 7, 19), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Test Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 1DE', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.duplicate@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|DUPLICATE', Data_Matching_BillingPostCode__c = '|SP101DE'
                                       ); 

        dupAccounts.add(dupAcc2);
        Database.insert(dupAccounts);

        Account_Directory_Person__c testAcc2 = new Account_Directory_Person__c(Name = 'TestName',
                                                                           Address_Line_1__c = '100 Weyhill Road',
                                                                           Post_Code__c = 'SP10 3LJ',
                                                                           Country_Code__c = 'UK',
                                                                           External_System__c = 'Pulse',
                                                                           External_System_Id__c = 'P_12345',
                                                                           First_Name__c = 'TestFirstName',
                                                                           Last_Name__c = 'TestLastName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1975, 02, 17),
                                                                           Salutation__c = 'Mr',
                                                                           Care_Status__c = 'Care Status'
                                                                          );

        Database.insert(testAcc2);
    
    }


    /**
        Method:  noMatchCreateNewPersonAccount
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Create a Person Account Directory record that does not match an existing Account, so a
                 new Account is created and linked to the Directory record
    **/
    @isTest
    static void noMatchCreateNewPersonAccount() {
        
        // Create a new Account Directory 
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'ADP1',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'Pulse123',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        adp1 = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'Jonny' And Last_Name__c = 'Newaccount'];
        Account newAcc = [Select Id, Firstname, Lastname From Account Where Firstname = 'Jonny' And Lastname = 'Newaccount'];

        // Should create a new Account that the Directory record will lookup
        System.assertEquals(adp1.Account__c, newAcc.Id);
        
    }

    /**
        Method:  noMatchOscarSystemCreateNewPersonAccount
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Create a Person Account Directory record that does not match an existing Account, so a
                 new Account is created and linked to the Directory record for Oscar system
    **/
    @isTest
    static void noMatchOscarSystemCreateNewPersonAccount() {
        
        // Create a new Account Directory 
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'OscarTestName',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System__c = 'Oscar',
                                                                           External_System_Id__c = 'O_3542',
                                                                           First_Name__c = 'OscarFirstName',
                                                                           Last_Name__c = 'OscarLastName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1975, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Care_Status__c = 'Care Status'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        adp1 = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'OscarFirstName' And Last_Name__c = 'OscarLastName'];
        Account newAcc = [Select Id, Firstname, Lastname From Account Where Firstname = 'OscarFirstName' And Lastname = 'OscarLastName'];

        // Should create a new Account that the Directory record will lookup
        System.assertEquals(adp1.Account__c, newAcc.Id);
        
    }


    /**
        Method:  matchOnePersonAccount
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Create a Person Account Directory record that matches an existing Account, so the
                 existing Account is linked to the Directory record
    **/
    @isTest
    static void matchOnePersonAccount() {
        
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'ADP1',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 3LJ',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'Pulse123',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Tester',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1960, 2, 17),
                                                                           Salutation__c = 'Mr'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        adp1 = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'Jonny' And Last_Name__c = 'Tester'];
        Account existingAcc = [Select Id, Firstname, Lastname From Account Where Firstname = 'Jonny' And Lastname = 'Tester'];

        System.assertEquals(adp1.Account__c, existingAcc.Id);
        
    }


    /**
        Method:  matchTwoPersonAccountsProspectAndClient
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Create a Person Account Directory record that matches two existing Accounts, the
                 existing Client Account should be linked to the Directory record
    **/
    @isTest
    static void matchTwoPersonAccountsProspectAndClient() {
                
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'ADP1',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 3LJ',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'Pulse123',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Twoaccounts',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1980, 6, 16),
                                                                           Salutation__c = 'Mr'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];
        Account existingClientAcc = [Select Id, Firstname, Lastname From Account Where Firstname = 'Jonny' And Lastname = 'Twoaccounts' And RecordTypeId = :personAccClientRecType.Id];
        adp1 = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'Jonny' And Last_Name__c = 'Twoaccounts'];

        System.assertEquals(adp1.Account__c, existingClientAcc.Id);
        
    }


    /**
        Method:  matchOnePersonAccountConvertToClient
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Create a Person Account Directory record that matches an existing Prospect Account, so the
                 existing Account is linked to the Directory record
                 Ensure the exisitng account is converted to a Client Account
    **/
    @isTest
    static void matchOnePersonAccountConvertToClient() {
        
        RecordType personAccProspectRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Prospect'];
        Account existingProspectAcc = [Select Id, RecordTypeId From Account Where RecordTypeId = :personAccProspectRecType.Id And LastName = 'Convertprospect'];
        
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'ADP1',
                                                                           Address_Line_1__c = 'The Street',
                                                                           Post_Code__c = 'SP10 3LJ',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'Pulse123',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Convertprospect',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1982, 3, 16),
                                                                           Salutation__c = 'Mr'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        // Retrieve the existing prospect account which should have been converted to a client account
        Account convertedClientAcc = [Select Id, RecordTypeId From Account Where Id = :existingProspectAcc.Id];

        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];

        System.assertEquals(convertedClientAcc.RecordTypeId, personAccClientRecType.Id);
        
    }


    /**
        Method:  ensureIndividualRecordCreated
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: Ensure that a Individual record is created when a Person Account Directory record is created
    **/
    @isTest
    static void ensureIndividualRecordCreated() {
        
        // Create a new Account Directory record
        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(Name = 'JonnyNewaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'Pulse123',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );
        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();
        
        Account_Directory_Person__c insertedAccDir = [Select Individual__c From Account_Directory_Person__c Where Id = :newAccDir.Id];
        
        List<Individual> newInd = [Select id From Individual Where Id = :insertedAccDir.Individual__c];

        // One Individual record should have been created
        System.assertEquals(newInd.size(), 1);
        
    }


    /**
        Method:  twoDuplicateDirectoryRecordsLinkedToSameAccount
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: When two Person Account Directory records are inserted within the same batch they should both be 
                 linked to the same Person Account record
    **/
    @isTest
    static void twoDuplicateDirectoryRecordsLinkedToSameAccount() {

        List<Account_Directory_Person__c> accDirList = new List<Account_Directory_Person__c>();
        
        // Create two new Account Directory records with matching details
        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(Name = 'JonnyNewaccountOne',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_123456',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonnyone@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );

        accDirList.add(newAccDir);
        
        Account_Directory_Person__c newAccDir2 = new Account_Directory_Person__c(Name = 'JonnyNewaccountTwo',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_654321',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonnytwo@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );
        accDirList.add(newAccDir2);
        
        // Insert the two Person Account Directory records together in same batch
        Test.startTest();
            Database.insert(accDirList);
        Test.stopTest();
        
        Account_Directory_Person__c insertedAccDirOne = [Select Account__c From Account_Directory_Person__c Where External_System_Id__c = 'P_123456'];
        Account_Directory_Person__c insertedAccDirTwo = [Select Account__c From Account_Directory_Person__c Where External_System_Id__c = 'P_654321'];

        // The two Person Account Directory records should be linked to the same Person Account record
        System.assertEquals(insertedAccDirOne.Account__c, insertedAccDirTwo.Account__c);
        
    }


    /**
        Method:  bulkUpload100PersonDirectoryRecords
        Author:  Jon Simmonds
        Date:    02/01/2020
        Purpose: Bulk upload 100 Person Account Directory records in a batch
    **/
    @isTest
    static void bulkUpload100PersonDirectoryRecords() {
        
        List<sObject> accDirList = Test.loadData(Account_Directory_Person__c.sObjectType, 'AccDirPersonTestData');

        List<Id> recIds = new List<Id>();
        
        for(sObject accDir: accDirList) {
            recIds.add(accDir.Id);
        }       
        
        List<Account_Directory_Person__c> accDirs = [Select Id From Account_Directory_Person__c Where Id In :recIds];
        
        // Thereshould have been 100 Person Account Directory records created
        System.assertEquals(accDirs.size(), 100);
    }


    /**
        Method:  twoDuplicatePersonsInBulkLinkedToSameAccount
        Author:  Jon Simmonds
        Date:    03/01/2020
        Purpose: Ensure two duplicate persons uploaded as part of a batch into the Account_Directory_Person__c object
                 are linked to the same Account
    **/
    @isTest
    static void twoDuplicatePersonsInBulkLinkedToSameAccount() {
        
        List<sObject> accDirList = Test.loadData(Account_Directory_Person__c.sObjectType, 'AccDirPersonTestData');
        
        Account_Directory_Person__c accDirOne = [Select Id, Account__c From Account_Directory_Person__c Where Email__c = 'johnbutcher1@outlook.com.test'];
        Account_Directory_Person__c accDirTwo = [Select Id, Account__c From Account_Directory_Person__c Where Email__c = 'johnbutcher2@outlook.com.test'];
        
        // The two Person Account Directory records should be linked to the same Account record
        System.assertEquals(accDirOne.Account__c, accDirTwo.Account__c);
    }


    /**
        Method:  linkMostRecentPersonAccountWhenMultiple
        Author:  Jon Simmonds
        Date:    07/02/2023
        Purpose: When there are multiple Person Accounts already and a Account Directory Person record matches
                 to them, link the Directory record to the Person Account most recently modified
    **/
    @isTest
    static void linkMostRecentPersonAccountWhenMultiple() {

        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];
        RecordType personAccProspectRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Prospect'];
        
        Account testAcc3 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Duplicate', 
                                       PersonBirthdate = Date.newInstance(1981, 7, 19), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Test Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 1DE', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.duplicate@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|DUPLICATE', Data_Matching_BillingPostCode__c = '|SP101DE'
                                       ); 

        Database.insert(testAcc3);

        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(
                                                                           Address_Line_1__c = '100 Test Road',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_123321',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Duplicate',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1981, 7, 19),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny.duplicate@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.today(),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );

        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();

        Account_Directory_Person__c insertedAccDirOne = [Select Account__c From Account_Directory_Person__c Where External_System_Id__c = 'P_123321'];
        Assert.areEqual(testAcc3.Id, insertedAccDirOne.Account__c, 'Directory record should be linked to the most recently updated Person Account');
    }

    /**
        Method:  linkMostRecentPersonAccountWhenMultipleUpdate
        Author:  Jon Simmonds
        Date:    07/02/2023
        Purpose: When there are multiple Person Accounts already and a Account Directory Person record matches
                 to them, link the Directory record to the Person Account most recently modified
                 This test is similar to linkMostRecentPersonAccountWhenMultiple but with the first Person Account
                 being updated to so it's selected as the Person Account linked to Directory record
    **/
    @isTest
    static void linkMostRecentPersonAccountWhenMultipleUpdate() {

        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];
  
        Account dupAcc3 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Duplicate', 
                                       PersonBirthdate = Date.newInstance(1981, 7, 19), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Test Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 1DE', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.duplicate@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|DUPLICATE', Data_Matching_BillingPostCode__c = '|SP101DE'
                                       ); 

        Database.insert(dupAcc3);

        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(
                                                                           Address_Line_1__c = '100 Test Road',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_123321',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Duplicate',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1981, 7, 19),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny.duplicate@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.today(),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );

        Account dupAcc1 = [Select Id, personmobilephone From Account Where External_Client_Id__pc = 'P_333888'];

        Test.startTest();
            dupAcc1.personmobilephone = '07503876453';
            Database.update(dupAcc1);
            Database.insert(newAccDir);
        Test.stopTest();

        Account_Directory_Person__c insertedAccDirOne = [Select Account__c From Account_Directory_Person__c Where External_System_Id__c = 'P_123321'];
        Assert.areEqual(dupAcc1.Id, insertedAccDirOne.Account__c, 'Directory record should be linked to the most recently updated Person Account');
    }

    /**
        Method:  integrationLogWhenMultiplePersonAccounts
        Author:  Jon Simmonds
        Date:    07/02/2023
        Purpose: When there are multiple Person Accounts already and a Account Directory Person record matches
                 to them, write a record to the Integration Log
    **/
    @isTest
    static void integrationLogWhenMultiplePersonAccounts() {

        RecordType personAccClientRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Client'];
        RecordType personAccProspectRecType = [Select Id From RecordType Where sObjectType = 'Account' And DeveloperName = 'Individual_Prospect'];
        
        Account testAcc3 = new Account(RecordTypeId = personAccClientRecType.Id, Salutation = 'Mr', FirstName = 'Jonny', LastName = 'Duplicate', 
                                       PersonBirthdate = Date.newInstance(1981, 7, 19), Gender__pc = 'Male', Preferred_Contact_Method__c = 'Email',
                                       BillingStreet = '100 Test Road', BillingCity = 'Andover', BillingState = 'Hants', BillingPostalCode = 'SP10 1DE', BillingCountry = 'UK',
                                       PersonEmail = 'jonny.duplicate@hotmail.co.uk', personhomephone = '01264888555', personmobilephone = '07504999333',
                                       Data_Matching_LastName__c = '|DUPLICATE', Data_Matching_BillingPostCode__c = '|SP101DE'
                                       ); 

        Database.insert(testAcc3);

        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(
                                                                           Address_Line_1__c = '100 Test Road',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_123321',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Duplicate',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1981, 7, 19),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny.duplicate@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.today(),
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22)
                                                                          );

        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();

        Integration_Log__c intLog = [Select Apex_Class__c, Transaction_Type__c From Integration_Log__c Where External_System_Id__c = 'P_123321'];
 
        Assert.areEqual('EtlPersonAccountProcessing', intLog.Apex_Class__c, 'Apex class that logged entry');
        Assert.areEqual('Person Account Matching', intLog.Transaction_Type__c, 'Duplicates identified in Person Account matching');
    }

    /**
        Method:  matchedAccountTestBetweenTwoSystems
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Match an existing person account record against a new incoming Oscar record
    **/
    @isTest
    static void matchedAccountTestBetweenTwoSystems() {
        
        // Create a new Account Directory 
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'TestName',
                                                                           Address_Line_1__c = '100 Weyhill Road',
                                                                           Post_Code__c = 'SP10 3LJ',
                                                                           Country_Code__c = 'UK',
                                                                           External_System__c = 'Oscar',
                                                                           External_System_Id__c = 'O_12345',
                                                                           First_Name__c = 'TestFirstName',
                                                                           Last_Name__c = 'TestLastName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1975, 02, 17),
                                                                           Salutation__c = 'Mr',
                                                                           Care_Status__c = 'Care Status'
                                                                          );
        Test.startTest();
            Database.insert(adp1);
        Test.stopTest();
        
        adp1 = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'TestFirstName' And Last_Name__c = 'TestLastName' And External_System__c = 'Oscar'];
        List<Account_Directory_Person__c> adp = [Select Account__c From Account_Directory_Person__c Where First_Name__c = 'TestFirstName' And Last_Name__c = 'TestLastName'];
        List<Account> existingAcc = [Select Id, Firstname, Lastname From Account Where Firstname = 'TestFirstName' And Lastname = 'TestLastName'];

        // Should create a new Account that the Directory record will lookup
        System.assertEquals(adp1.Account__c, existingAcc[0].Id);
        System.assertEquals(adp.size(), 2);
        System.assertEquals(existingAcc.size(), 1);
        
    }
}