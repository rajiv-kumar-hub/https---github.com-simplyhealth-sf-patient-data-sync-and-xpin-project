/**
    Class:   EtlPersonSyncMethods_Test
    Author:  Jon Simmonds
    Date:    24/12/2019
    Purpose: Test methods to test the linking logic between Person Account Directory and Person Account records
**/
/***********************************************************************************************
Date         Name          Description
17/08/2020   Rajiv Kumar   SFM-1953::Amended Account Directpry Person record creation by adding 
                           Marketing/Servicing Confirmed in System fields
13/09/2022   S.Sekhon      IE-1453: Due to introduction of Ski records add External_System__c = 'Pulse' to methods:
                           duplicatePersonDirectoryWithEmailPhoneValues
12/01/2024   Rajiv Kumar   DG-180:: Amended test methods for Oscar data syncing
***********************************************************************************************/
@isTest
public class EtlPersonSyncMethods_Test {

    @TestSetup
    static void setup() {
    
        // Create a new Account Directory record
        Account_Directory_Person__c adp1 = new Account_Directory_Person__c(Name = 'Jonny Newaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_12345678',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mobile_Phone_Number__c = '07504909303',
                                                                           Other_Phone_Number__c = '01264333222',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update'
                                                                          );

        Database.insert(adp1);

        // Create a new Account Directory record linked to Oscar record
        Account_Directory_Person__c adp2 = new Account_Directory_Person__c(Name = 'TestName',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           First_Name__c = 'TestFirstName',
                                                                           Last_Name__c = 'TestLastName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1975, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'testname@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mobile_Phone_Number__c = '07504909303',
                                                                           Other_Phone_Number__c = '01264333222',
                                                                           Care_Status__c = 'Care Status Check',
                                                                           External_System__c = 'Oscar',
                                                                           External_System_Id__c = 'O_12345'
                                                                           );

        Database.insert(adp2);

        // Create a new Account Directory record
        Account_Directory_Person__c adp3 = new Account_Directory_Person__c(Name = 'TestAnotherName',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           First_Name__c = 'AnotherFirstName',
                                                                           Last_Name__c = 'AnotherLastName',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1975, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'testname@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mobile_Phone_Number__c = '07504909303',
                                                                           Other_Phone_Number__c = '01264333222',
                                                                           Care_Status__c = 'Care Status Check',
                                                                           External_System__c = 'Pulse',
                                                                           External_System_Id__c = 'P_12345'
                                                                           );

        Database.insert(adp3);
    }


    /**
        Method:  updateFirstNameOnDirectoryAndSyncToPersonAccount
        Author:  Jon Simmonds
        Date:    24/12/2019
        Purpose: Ensure when the Firstname on a Account_Directory_Person__c is updated
                 on an existing record, the related Person Account record is also updated
    **/
    @isTest
    static void updateFirstNameOnDirectoryAndSyncToPersonAccount() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select First_Name__c, Perform_Data_Matching__c, Account__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.First_Name__c = 'Newfirstname';
            existingPersonAccDir.Perform_Data_Matching__c = true;
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Firstname value 
        Account updatedAcc = [Select FirstName From Account Where Id = :existingPersonAccDir.Account__c];
        
        // The related Person Account firstname value should have been updated automatically
        System.assertEquals(updatedAcc.FirstName, 'Newfirstname');
    }


    /**
        Method:  updateLastNameOnDirectoryAndSyncToPersonAccount
        Author:  Jon Simmonds
        Date:    24/12/2019
        Purpose: Ensure when the Lastname on a Account_Directory_Person__c is updated
                 on an existing record, the related Person Account record is also updated
    **/
    @isTest
    static void updateLastNameOnDirectoryAndSyncToPersonAccount() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select Last_Name__c, Perform_Data_Matching__c, Account__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.Last_Name__c = 'Newlastname';
            existingPersonAccDir.Perform_Data_Matching__c = true;
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Lastname value 
        Account updatedAcc = [Select Lastname From Account Where Id = :existingPersonAccDir.Account__c];
        
        // The related Person Account lastname value should have been updated automatically
        System.assertEquals(updatedAcc.LastName, 'Newlastname');
    }


    /**
        Method:  updateEmailOnDirectoryAndSyncToPersonAccount
        Author:  Jon Simmonds
        Date:    24/12/2019
        Purpose: Ensure when the Email Address on a Account_Directory_Person__c is updated
                 on an existing record, the related Person Account record is also updated
    **/
    @isTest
    static void updateEmailOnDirectoryAndSyncToPersonAccount() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select Email__c, Perform_Data_Matching__c, Account__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.Email__c = 'newemail@hotmail.co.uk';
            existingPersonAccDir.Perform_Data_Matching__c = true;
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Email value 
        Account updatedAcc = [Select PersonEmail From Account Where Id = :existingPersonAccDir.Account__c];
        
        Boolean isSandboxorg = [SELECT isSandbox FROM Organization LIMIT 1].isSandbox;
        
        String expectedEmailAddress = 'newemail@hotmail.co.uk';
        // If in a sandbox add .test to the end
        if(isSandboxorg) {
            expectedEmailAddress += '.test';
        }
        
        // The related Person Account email value should have been updated automatically
        System.assertEquals(updatedAcc.PersonEmail, expectedEmailAddress);
    }


    /**
        Method:  updatePhoneOnDirectoryAndSyncToPersonAccount
        Author:  Jon Simmonds
        Date:    24/12/2019
        Purpose: Ensure when the Phone value on a Account_Directory_Person__c is updated
                 on an existing record, the related Person Account record is also updated
    **/
    @isTest
    static void updatePhoneOnDirectoryAndSyncToPersonAccount() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select Phone_Number__c, Perform_Data_Matching__c, Account__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.Phone_Number__c = '01256333444';
            existingPersonAccDir.Perform_Data_Matching__c = true;
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the phone value 
        Account updatedAcc = [Select PersonHomePhone From Account Where Id = :existingPersonAccDir.Account__c];
        
        // The related Person Account phone value should have been updated automatically
        System.assertEquals(updatedAcc.PersonHomePhone, existingPersonAccDir.Phone_Number__c);
    }


    /**
        Method:  updateMarketingPrefOnDirectoryAndSyncToIndividual
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: Ensure when the Marketing Preferences values on a Account_Directory_Person__c are updated
                 on an existing record, the related Individual record is also updated
    **/
    @isTest
    static void updateMarketingPrefOnDirectoryAndSyncToIndividual() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select Mkt_Pref_Email__c, Mkt_Pref_Phone__c, Mkt_Pref_Post__c, Mkt_Pref_Sms__c, Account__c, Individual__c,
                                                                   Mkt_Pref_Confirmed_In_System__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.Mkt_Pref_Email__c = 'Yes';
            existingPersonAccDir.Mkt_Pref_Phone__c = 'Yes';
            existingPersonAccDir.Mkt_Pref_Post__c = 'Yes';
            existingPersonAccDir.Mkt_Pref_Sms__c = 'Yes';
            existingPersonAccDir.Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update';
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the phone value 
        Individual updatedInd = [Select Marketing_by_Email__c, Marketing_by_Phone__c, Marketing_by_Post__c, Marketing_by_SMS__c From Individual Where Id = :existingPersonAccDir.Individual__c];
        
        // The related Individual Marketing Preferences values should have been updated automatically from No to Yes
        System.assertEquals(updatedInd.Marketing_by_Email__c, 'Yes');
        System.assertEquals(updatedInd.Marketing_by_Phone__c, 'Yes');
        System.assertEquals(updatedInd.Marketing_by_Post__c, 'Yes');
        System.assertEquals(updatedInd.Marketing_by_SMS__c , 'Yes');
    }


    /**
        Method:  updateServicingPrefOnDirectoryAndSyncToIndividual
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: Ensure when the Servicing Preferences values on a Account_Directory_Person__c are updated
                 on an existing record, the related Individual record is also updated
    **/
    @isTest
    static void updateServicingPrefOnDirectoryAndSyncToIndividual() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select Srv_Pref_Email__c, Srv_Pref_Online__c, Srv_Pref_Phone__c, Srv_Pref_Post__c, Srv_Pref_Sms__c, Srv_Pref_Confirmed_In_System__c , Account__c, Individual__c
                                                            From Account_Directory_Person__c
                                                            Where Name = 'Jonny Newaccount'];
                                                            
        Test.startTest();
            existingPersonAccDir.Srv_Pref_Email__c = 'Yes';
            existingPersonAccDir.Srv_Pref_Online__c = 'No';
            existingPersonAccDir.Srv_Pref_Phone__c = 'Yes';
            existingPersonAccDir.Srv_Pref_Post__c = 'Yes';
            existingPersonAccDir.Srv_Pref_Sms__c = 'Yes';
            existingPersonAccDir.Srv_Pref_Confirmed_In_System__c = 'Salesforce Update';
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the phone value 
        Individual updatedInd = [Select Servicing_By_Email__c, Servicing_By_Phone__c, Servicing_by_Post__c, Servicing_By_Sms__c, Servicing_Online__c From Individual Where Id = :existingPersonAccDir.Individual__c];
        
        // The related Individual Servicing Preferences values should have been updated automatically from No to Yes (except online Yes to No)
        System.assertEquals(updatedInd.Servicing_By_Email__c, 'Yes');
        System.assertEquals(updatedInd.Servicing_By_Phone__c, 'Yes');
        System.assertEquals(updatedInd.Servicing_by_Post__c, 'Yes');
        System.assertEquals(updatedInd.Servicing_By_Sms__c, 'Yes');
        System.assertEquals(updatedInd.Servicing_Online__c, 'No');
    }


    /**
        Method:  insertMarketingPrefOnDirectoryAndSyncToIndividual
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: Ensure when a Account_Directory_Person__c record is created the Marketing Preference values
                 are synced to the newly created Individual record
    **/
    @isTest
    static void insertMarketingPrefOnDirectoryAndSyncToIndividual() {
    
        // Create a new Account Directory record
        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(Name = 'TommyNewaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_87654321',
                                                                           First_Name__c = 'Tommy',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'Yes',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'Yes',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update'
                                                                          );
                                                            
        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account Directory record with related Individual marketing preference values
        Account_Directory_Person__c updatedInd = [Select Individual__r.Marketing_by_Email__c,
                                                         Individual__r.Marketing_by_Phone__c,
                                                         Individual__r.Marketing_by_Post__c,
                                                         Individual__r.Marketing_by_SMS__c
                                                  From Account_Directory_Person__c Where Id = :newAccDir.Id];
        
        // The related Individual Marketing Preferences values should have been synced
        System.assertEquals(updatedInd.Individual__r.Marketing_by_Email__c, 'No');
        System.assertEquals(updatedInd.Individual__r.Marketing_by_Phone__c, 'Yes');
        System.assertEquals(updatedInd.Individual__r.Marketing_by_Post__c, 'No');
        System.assertEquals(updatedInd.Individual__r.Marketing_by_SMS__c, 'Yes');
    }


    /**
        Method:  insertServicingPrefOnDirectoryAndSyncToIndividual
        Author:  Jon Simmonds
        Date:    01/01/2020
        Purpose: Ensure when a Account_Directory_Person__c record is created the Servicing Preference values
                 are synced to the newly created Individual record
    **/
    @isTest
    static void insertServicingPrefOnDirectoryAndSyncToIndividual() {
    
        // Create a new Account Directory record
        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(Name = 'TommyNewaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_87654321',
                                                                           First_Name__c = 'Tommy',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'jonny@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'Yes',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'Yes',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update'
                                                                          );
                                                            
        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account Directory record with related Individual servicing preference values
        Account_Directory_Person__c updatedInd = [Select Individual__r.Servicing_By_Email__c,
                                                         Individual__r.Servicing_By_Phone__c,
                                                         Individual__r.Servicing_by_Post__c,
                                                         Individual__r.Servicing_By_Sms__c,
                                                         Individual__r.Servicing_Online__c
                                                  From Account_Directory_Person__c Where Id = :newAccDir.Id];
        
        // The related Individual Servicing Preferences values should have been synced
        System.assertEquals(updatedInd.Individual__r.Servicing_By_Email__c, 'No');
        System.assertEquals(updatedInd.Individual__r.Servicing_Online__c, 'Yes');
        System.assertEquals(updatedInd.Individual__r.Servicing_By_Phone__c, 'No');
        System.assertEquals(updatedInd.Individual__r.Servicing_by_Post__c, 'No');
        System.assertEquals(updatedInd.Individual__r.Servicing_By_Sms__c, 'No');
        
    }


    /**
        Method:  insertKnownAsOnDirectoryAndSyncToPersonAccount
        Author:  Jon Simmonds
        Date:    09/10/2020
        Purpose: Ensure when a Account_Directory_Person__c record is created the Known As value
                 is synced to the newly created Person Account record
    **/
    @isTest
    static void insertKnownAsOnDirectoryAndSyncToPersonAccount() {
    
        // Create a new Account Directory record
        Account_Directory_Person__c newAccDir = new Account_Directory_Person__c(Name = 'Mickey Droy',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_87654321',
                                                                           First_Name__c = 'Mickey',
                                                                           Last_Name__c = 'Droy',
                                                                           Known_As__c = 'Big Mick',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1961, 08, 16),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'mickeydroy@hotmail.co.uk',
                                                                           Phone_Number__c = '01264555888',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'Yes',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'Yes',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update'
                                                                          );
                                                            
        Test.startTest();
            Database.insert(newAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account Directory record with associated Account
        Account_Directory_Person__c insertedAccDir = [Select Account__c, Account__r.Known_As__c From Account_Directory_Person__c Where Id = :newAccDir.Id];

        // Retrieve the Known As value from the associated Account
        Account perAccount = [Select Known_As__c From Account Where Id = :insertedAccDir.Account__c];
        
        // The related Individual Servicing Preferences values should have been synced
        System.assertEquals(newAccDir.Known_As__c, insertedAccDir.Account__r.Known_As__c);
        
    }

    /**
        Method:  doNotOverrideEmailPhoneWithNullFromDuplicatePerson
        Author:  Jon Simmonds
        Date:    29/10/2021
        Purpose: When a duplicate Account Directory Person record is created with the email address and 
                 phone number fields set to null, it should link to the existing Person Account and Individual
                 records but should not overwrite the existing values for the email address and phone number fields.
    **/
    @isTest
    static void doNotOverrideEmailPhoneWithNullFromDuplicatePerson() {

        // Create a duplicate Account Person Directory record with email address and phone numbers set to null
        Account_Directory_Person__c dupAccDir = new Account_Directory_Person__c(Name = 'Jonny Newaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_12743212',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = null,
                                                                           Phone_Number__c = null,
                                                                           Mobile_Phone_Number__c = null,
                                                                           Other_Phone_Number__c = null,
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Perform_Data_Matching__c = true
                                                                          );                                                            
        Test.startTest();
            Database.insert(dupAccDir);
        Test.stopTest();
        
        // Retrieve the original Person Account Directory record with associated Person Account and email and phone number values
        Account_Directory_Person__c originalAccDir = [Select Account__c, Email__c, Phone_Number__c, Mobile_Phone_Number__c, Other_Phone_Number__c
                                                      From Account_Directory_Person__c Where External_System_Id__c = 'P_12345678'];

        // Retrieve the email address and phone number values from the associated Person Account and Individual
        Account perAccount = [Select PersonEmail, PersonMobilePhone, PersonOtherPhone, PersonHomePhone, PersonIndividual.Email__c From Account Where Id = :originalAccDir.Account__c];
        
        // Ensure the Person Account and Individual still have the values from the original Account Directory Person record
        System.assertEquals(originalAccDir.Email__c, perAccount.PersonEmail);
        System.assertEquals(originalAccDir.Phone_Number__c, perAccount.PersonHomePhone);
        System.assertEquals(originalAccDir.Mobile_Phone_Number__c, perAccount.PersonMobilePhone);
        System.assertEquals(originalAccDir.Other_Phone_Number__c, perAccount.PersonOtherPhone);
        System.assertEquals(originalAccDir.Email__c, perAccount.PersonIndividual.Email__c);  
    }

    /**
        Method:  duplicatePersonDirectoryWithEmailPhoneValues
        Author:  Jon Simmonds
        Date:    29/10/2021
        Purpose: When a duplicate Account Directory Person record is created with the email address and 
                 phone number values, it should link to the existing Person Account and Individual
                 records and overwrite the existing values for the email address and phone number fields.
    **/
    @isTest
    static void duplicatePersonDirectoryWithEmailPhoneValues() {

        // Create a duplicate Account Person Directory record with email address and phone numbers values
        Account_Directory_Person__c dupAccDir = new Account_Directory_Person__c(Name = 'Jonny Newaccount',
                                                                           Address_Line_1__c = '100 The Street',
                                                                           Post_Code__c = 'SP10 1DE',
                                                                           Country_Code__c = 'UK',
                                                                           External_System_Id__c = 'P_12743212',
                                                                           First_Name__c = 'Jonny',
                                                                           Last_Name__c = 'Newaccount',
                                                                           Status__c = 'Active',
                                                                           Date_of_Birth__c = Date.newInstance(1971, 08, 09),
                                                                           Salutation__c = 'Mr',
                                                                           Email__c = 'newemail@address.co.uk',
                                                                           Phone_Number__c = '01264111111',
                                                                           Mobile_Phone_Number__c = '07504111111',
                                                                           Other_Phone_Number__c = '01256111111',
                                                                           Mkt_Pref_Email__c = 'No',
                                                                           Mkt_Pref_Phone__c = 'No',
                                                                           Mkt_Pref_Post__c = 'No',
                                                                           Mkt_Pref_Sms__c = 'No',
                                                                           Mkt_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Mkt_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Srv_Pref_Email__c = 'No',
                                                                           Srv_Pref_Online__c = 'Yes',
                                                                           Srv_Pref_Phone__c = 'No',
                                                                           Srv_Pref_Post__c = 'No',
                                                                           Srv_Pref_Sms__c = 'No',
                                                                           Srv_Pref_Confirm_Date__c = Date.newInstance(2019, 12, 22),
                                                                           Srv_Pref_Confirmed_In_System__c = 'Salesforce Update',
                                                                           Perform_Data_Matching__c = true,
                                                                           External_System__c = 'Pulse'
                                                                          );                                                            
        Test.startTest();
            Database.insert(dupAccDir);
        Test.stopTest();
        
        // Retrieve values for duplicate Account Directory record from database
        dupAccDir = [Select Email__c, Phone_Number__c, Mobile_Phone_Number__c, Other_Phone_Number__c 
                     From Account_Directory_Person__c Where External_System_Id__c = 'P_12743212'];
        
        // Retrieve the original Person Account Directory record with associated Person Account and email and phone number values
        Account_Directory_Person__c originalAccDir = [Select Account__c From Account_Directory_Person__c Where External_System_Id__c = 'P_12345678'];

        // Retrieve the email address and phone number values from the associated Person Account and Individual
        Account perAccount = [Select PersonEmail, PersonMobilePhone, PersonOtherPhone, PersonHomePhone, PersonIndividual.Email__c From Account Where Id = :originalAccDir.Account__c];
        
        // Ensure the Person Account and Individual have the values from the new Account Directory Person record
        System.assertEquals(dupAccDir.Email__c, perAccount.PersonEmail);
        System.assertEquals(dupAccDir.Phone_Number__c, perAccount.PersonHomePhone);
        System.assertEquals(dupAccDir.Mobile_Phone_Number__c, perAccount.PersonMobilePhone);
        System.assertEquals(dupAccDir.Other_Phone_Number__c, perAccount.PersonOtherPhone);
        System.assertEquals(dupAccDir.Email__c, perAccount.PersonIndividual.Email__c);  
    }
    
    /**
        Method:  updateCareStatusOnDirectoryAndSyncToPersonAccount
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Ensure when the Care Status on a Account_Directory_Person__c is updated
                 on an existing record, the related Person Account record is also updated
    **/
    @isTest
    static void updateCareStatusOnDirectoryAndSyncToPersonAccount() {
    
        Account_Directory_Person__c existingPersonAccDir = [Select First_Name__c, Perform_Data_Matching__c, Account__c
                                                            From   Account_Directory_Person__c
                                                            Where  First_Name__c = 'TestFirstName'
                                                            And    Last_Name__c = 'TestLastName'];
                                                            
        Test.startTest();
            existingPersonAccDir.Care_Status__c = 'New Care Status';
            existingPersonAccDir.Perform_Data_Matching__c = true;
            Database.update(existingPersonAccDir);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Care Status field value 
        Account updatedAcc = [Select Care_Status__c From Account Where Id = :existingPersonAccDir.Account__c];
        
        // The related Person Account Care Status field value should have been updated automatically
        System.assertEquals(updatedAcc.Care_Status__c, 'New Care Status');
    }

    /**
        Method:  validateOscarDataLinkOnPersonAccount
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Ensure when an Oscar record is inserted in Account object, Oscar Data Link field is set to true
    **/
    @isTest
    static void validateOscarDataLinkOnPersonAccount() {
    
        Test.startTest();
            // Create a new Account Directory record linked to Oscar record
            Account_Directory_Person__c adp = new Account_Directory_Person__c(Name = 'TestName',
                                                                              Address_Line_1__c = '100 The Street',
                                                                              Post_Code__c = 'SP10 1DE',
                                                                              Country_Code__c = 'UK',
                                                                              First_Name__c = 'FirstName',
                                                                              Last_Name__c = 'LastName',
                                                                              Status__c = 'Active',
                                                                              Date_of_Birth__c = Date.newInstance(1975, 08, 09),
                                                                              Salutation__c = 'Mr',
                                                                              Email__c = 'testname@hotmail.co.uk',
                                                                              Phone_Number__c = '01264555888',
                                                                              Mobile_Phone_Number__c = '07504909303',
                                                                              Other_Phone_Number__c = '01264333222',
                                                                              Care_Status__c = 'Care Status Check',
                                                                              External_System__c = 'Oscar',
                                                                              External_System_Id__c = 'O_12345'
                                                                             );

            Database.insert(adp);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Oscar Data Link field value 
        Account updatedAcc = [Select Care_Status__c, Oscar_Data_Link__c From Account Where Firstname = 'FirstName' And Lastname = 'LastName'];
        
        // Oscar_Data_Link__c should be set to true
        System.assertEquals(updatedAcc.Oscar_Data_Link__c, true);
    }

    /**
        Method:  updateOscarDataLinkOnPersonAccount
        Author:  Rajiv Kumar
        Date:    12/01/2024
        Purpose: DG-180 - Ensure when an oscar record is linked to Account, Oscar_Data_Link__c is set to true
    **/
    @isTest
    static void updateOscarDataLinkOnPersonAccount() {
    
        Account accDetailsBeforOscarDataLink = [Select Oscar_Data_Link__c From Account Where Firstname = 'AnotherFirstName' And Lastname = 'AnotherLastName'];
                                                            
        Test.startTest();
            // Create a new Account Directory record linked to Oscar record
            Account_Directory_Person__c adp = new Account_Directory_Person__c(Name = 'TestAnotherName',
                                                                            Address_Line_1__c = '100 The Street',
                                                                            Post_Code__c = 'SP10 1DE',
                                                                            Country_Code__c = 'UK',
                                                                            First_Name__c = 'AnotherFirstName',
                                                                            Last_Name__c = 'AnotherLastName',
                                                                            Status__c = 'Active',
                                                                            Date_of_Birth__c = Date.newInstance(1975, 08, 09),
                                                                            Salutation__c = 'Mr',
                                                                            Email__c = 'testname@hotmail.co.uk',
                                                                            Phone_Number__c = '01264555888',
                                                                            Mobile_Phone_Number__c = '07504909303',
                                                                            Other_Phone_Number__c = '01264333222',
                                                                            Care_Status__c = 'Care Status Check',
                                                                            External_System__c = 'Oscar',
                                                                            External_System_Id__c = 'O_2345'
                                                                        );

            Database.insert(adp);
        Test.stopTest();
        
        // Retrieve the related Person Account record and the Care Status field value 
        Account accDetailsAfterOscarDataLink = [Select Oscar_Data_Link__c From Account Where Firstname = 'AnotherFirstName' And Lastname = 'AnotherLastName'];
        
        //As there is no Oscar record linked, value should be set to false
        System.assertEquals(accDetailsBeforOscarDataLink.Oscar_Data_Link__c, false);
        //Once Oscar record is linked, value should be set to true
        System.assertEquals(accDetailsAfterOscarDataLink.Oscar_Data_Link__c, true);
    }

}