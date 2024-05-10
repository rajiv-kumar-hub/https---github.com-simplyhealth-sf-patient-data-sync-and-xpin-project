/**
    Class:   EtlSyncMethods
    Author:  Jon Simmonds
    Date:    18/12/2019
    Purpose: Sync logic between ADP/ADG and Person Account/Account
**/
/***********************************************************************************************
Date         Name          Description
27/11/2023   Rajiv Kumar   DG-180:: Amended code to populate Care_Status__c.
29/11/2023   Rajiv Kumar   DG-180:: Amended SetMasterPersonAccountDirectory to set Oscar record as Master record
                                    only if there is no Ski data link populated on Account record
***********************************************************************************************/

public without sharing class EtlSyncMethods {
           
    public static void SetMasterPersonAccountDirectory(List<Account_Directory_Person__c> newPersonAccDirs) {
    
        // Retrieve the Id values of the Accounts related to the Person Account Directory records
        Set<Id> accountIds = EtlListHelpers.getForeignKeys(newPersonAccDirs, 'Account__c');
        
        // Retrieve the Account details
        List<Account> relatedAccounts = [SELECT Id,
                                                Master_Account_Directory_Person__c,
                                                External_Client_Id__pc,
                                                Ski_Data_Link__c,
                                                (SELECT Id, Status__c, External_System__c, External_System_Id__c FROM Account_Directory_Persons__r ORDER BY LastModifiedDate DESC)
                                         FROM Account
                                         WHERE id IN :accountIds];
                                  
        List<Account> accountsToUpdate = new List<Account>();
        
        for(Account_Directory_Person__c updPerAccDir: newPersonAccDirs) {
            System.Debug('EtlSyncMethods SetMasterPersonAccountDirectory: updated Directory Status updPerAccDir.Status__c = ' + updPerAccDir.Status__c);
        }

        // Loop through the related Account records
        for (Account acc : relatedAccounts) {
       
            // If only 1 Directory record linked to the Person Account
            if(acc.Account_Directory_Persons__r.size() == 1) {
                acc.Master_Account_Directory_Person__c = acc.Account_Directory_Persons__r[0].id;
                accountsToUpdate.add(acc);         
            }

            // If there are more than one Directory record linked to the Person Account
            if(acc.Account_Directory_Persons__r.size() > 1) {
                Integer count = 0;
                // Loop through Directory records in last modified order
                while(count < acc.Account_Directory_Persons__r.size()) {
                    // Only use the Directory record as Master if status is NOT Depersonalised
                    if(acc.Account_Directory_Persons__r[count].Status__c != 'Depersonalised') {                        
                        // DG-180 - If the latest ADP is from Pulse and the associated Account is NOT linked to Ski data
                        // OR the latest ADP is from Ski then just set it as the master
                        if(acc.Account_Directory_Persons__r[count].External_System__c == 'Pulse' && !acc.Ski_Data_Link__c ||
                           acc.Account_Directory_Persons__r[count].External_System__c == 'Oscar' ||
                           acc.Account_Directory_Persons__r[count].External_System__c == 'Ski') {
                            acc.Master_Account_Directory_Person__c = acc.Account_Directory_Persons__r[count].id;
                            acc.External_Client_Id__pc = acc.Account_Directory_Persons__r[count].External_System_Id__c;
                            accountsToUpdate.add(acc);
                            break;
                        }
                    }
                    count++;
                }
            }
        }
        updateAccounts(accountsToUpdate);
    }

    /**
        Class:   SetMasterGroupAccountDirectory
        Author:  Jon Simmonds
        Date:    25/12/2019
        Purpose: Check the Account Group Directory record set as the Master on the related Account.
                 If its different to what is currently considered the master Account Group Directory master
                 update the Account record with the new master id
    **/        
    public static void SetMasterGroupAccountDirectory(List<Account_Directory_Group__c> newAccGroupDirs) {
    
        Id prospectAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        
        Set<Id> accountIds = EtlListHelpers.getForeignKeys(newAccGroupDirs, 'Account__c');
        List<Account> relatedAccounts = [SELECT Id,
                                                Master_Account_Directory_Group__c,
                                                External_Group_Id__c,
                                                RecordTypeId,
                                                (SELECT Id, External_System__c, External_System_Group_Id__c FROM Account_Directory_Groups__r ORDER BY LastModifiedDate DESC)
                                         FROM Account
                                         WHERE id IN :accountIds];
                                  
        List<Account> accountsToUpdate = new List<Account>();
        
        for(Account acc : relatedAccounts){
            if(acc.Account_Directory_Groups__r.size() == 1){
                acc.Master_Account_Directory_Group__c = acc.Account_Directory_Groups__r[0].id;
                acc.External_Group_Id__c = acc.Account_Directory_Groups__r[0].External_System_Group_Id__c;
                accountsToUpdate.add(acc);
            }

            if(acc.Account_Directory_Groups__r.size() > 1){
                Integer count = 0;
                while(count < acc.Account_Directory_Groups__r.size()){
                    if(acc.Account_Directory_Groups__r[count].External_System__c == 'Broker Portal' && acc.RecordTypeId != prospectAccRecTypeId){
                        count++;
                        continue;
                    }
                    if (acc.Master_Account_Directory_Group__c != acc.Account_Directory_Groups__r[count].id){
                        acc.Master_Account_Directory_Group__c = acc.Account_Directory_Groups__r[count].id;
                        acc.External_Group_Id__c = acc.Account_Directory_Groups__r[count].External_System_Group_Id__c;
                        accountsToUpdate.add(acc);
                        break;
                    }                      
                    count++;
                }
            }
        }
        updateAccounts(accountsToUpdate);
    }
    
    /**
        Method:  updateAccounts
        Author:  Jon Simmonds
        Date:    20/01/2020
        Purpose: Update a list of Account records and capture exceptions
                 Update is based on partial success
    **/
    private static void updateAccounts(List<Account> accounts) {
    
        List<Etl_Exception__c> etlExceptions = new List<Etl_Exception__c>();
        
        Database.SaveResult[] srList = Database.update(accounts, false);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {             
                for(Database.Error err : sr.getErrors()) {
                    Etl_Exception__c etlEx = new Etl_Exception__c();
                    etlEx.Status_Code__c = String.valueOf(err.getStatusCode());
                    etlEx.Exception_Message__c = err.getMessage().substring(0,254);
                    etlEx.Exception_Fields__c = String.valueOf(err.getFields());
                    etlEx.Sobject__c = 'Account';
                    etlEx.Apex_Class__c = 'EtlSyncMethods';
                    etlEx.Apex_Method__c = 'updateAccounts';
                    etlEx.Record_Id__c = sr.getId();
                    etlEx.Line_Number__c = 103;
                    etlExceptions.add(etlEx);
                }
            }
        }
        
        if(etlExceptions.size() > 0) {
            Database.insert(etlExceptions);
        }
    }

    /**
        Class:   SyncDataBetweenAccDirPersonAndAccount
        Author:  Jon Simmonds
        Date:    11/10/2020
        Jira:    STB-96
        Purpose: Sync data between the Person Account Directory records and related Account records
    **/
    public static void SyncDataBetweenAccDirPersonAndAccount(List<Account_Directory_Person__c> newAccPersonDirs) {

        List<Id> associatedAccountIds = new List<Id>();
        
        for(Account_Directory_Person__c newAccPersonDir: newAccPersonDirs) {
            if(newAccPersonDir.Account__c != null) {
                associatedAccountIds.add(newAccPersonDir.Account__c);
            }
        }
        
        //STB-4674 ::Added Email bounce related fields
        //DG-180 :: Added Care_Status__c field
        Map<ID, Account> associatedAccountsMap = new Map<ID, Account>([Select Id, Salutation, FirstName, LastName, PersonBirthdate, PersonEmail, Gender__pc, PersonMobilePhone, PersonOtherPhone, PersonHomePhone,
                                                                              Phone, National_Insurance_Number__pc, Account_Status__c, Known_As__c, External_Client_Id__pc, Master_Account_Directory_Person__c, 
                                                                              BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Original_Source__c, Web_Registered__c, Date_Web_Registered__c,
                                                                              Marketing_Preference_Email__pc, Marketing_Preference_Phone__pc, Marketing_Preference_Post__pc, Marketing_Preference_SMS__pc, Sex__pc,
                                                                              PersonIndividual.Salutation, PersonIndividual.Firstname, PersonIndividual.Lastname, PersonIndividual.BirthDate, PersonIndividual.Email__c,
                                                                              PersonIndividual.Marketing_Pref_Confirm_Date__c, PersonIndividual.Marketing_Pref_Confirmed_In_System__c, 
                                                                              PersonIndividual.Marketing_by_Email__c, PersonIndividual.Marketing_by_Phone__c ,
                                                                              PersonIndividual.Marketing_by_Post__c, PersonIndividual.Marketing_by_SMS__c,
                                                                              PersonIndividual.Servicing_Preference__c, PersonIndividual.Servicing_Pref_Confirm_Date__c,
                                                                              PersonIndividual.Servicing_Pref_Confirmed_In_System__c, PersonIndividual.Servicing_By_Email__c,
                                                                              PersonIndividual.Servicing_Online__c, PersonIndividual.Servicing_By_Phone__c,Ski_Data_Link__c,
                                                                              PersonIndividual.Servicing_by_Post__c, PersonIndividual.Servicing_By_Sms__c, PersonIndividual.Id, Email_Bounce_Date__c, Email_Bounce_Reason__c,
                                                                              Care_Status__c, Oscar_Data_Link__c, Payer__c, IsPayer__c, Treating_Dentist__c, Owning_Dentist__c, Dental_Practice__c
                                                                       FROM Account
                                                                       Where Id IN :associatedAccountIds]);
                                                                                       
        Set<Account> accSetToBeUpdated = new Set<Account>();
        Boolean updateAcc = false;
        List<Individual> indsToBeUpdated = new List<Individual>();
        Boolean updateInd = false;
        
        for(Account_Directory_Person__c newAccPersonDir: newAccPersonDirs) {
            
            if(associatedAccountsMap.containsKey(newAccPersonDir.Account__c)) {
            
                System.debug('SIMMOETL newAccPersonDir.Is_Master_Account_Directory_Person__c = ' + newAccPersonDir.Is_Master_Account_Directory_Person__c);
                System.debug('SIMMOETL newAccPersonDir.Id = ' + newAccPersonDir.Id);
                
                Account associatedAccount = associatedAccountsMap.get(newAccPersonDir.Account__c);
                System.debug('SIMMOETL associatedAccount.Master_Account_Directory_Person__c = ' + associatedAccount.Master_Account_Directory_Person__c);
               //IE-625 - If the update is from Pulse and the Account is in Ski then do not update
                if (associatedAccount.Ski_Data_Link__c && newAccPersonDir.External_System__c == 'Pulse'){
                    Utilities.addIntegrationLogRecord('EtlSyncMethods', 'SyncDataBetweenAccDirPersonAndAccount', 
                                                      'Update from Pulse for Account Directory Record '+ newAccPersonDir.Id +' which is linked to the Ski Account '+ associatedAccount.Id, 
                                                      'Pulse Overwrite Ski');
                }else {

                    Individual associatedIndividual = new Individual();
                    if(String.isNotBlank(associatedAccount.PersonIndividual.Id)) {
                        associatedIndividual.Id = associatedAccount.PersonIndividual.Id;
                    }
                    updateAcc = false;
                    updateInd = false;
                    
                    // Only sync values if the Directory record is the Master
                    if(associatedAccount.Master_Account_Directory_Person__c == newAccPersonDir.Id) {

                        // IE-625 - Update only if the value of the fields are not null 
                        if( String.isNotBlank(newAccPersonDir.Salutation__c) && associatedAccount.Salutation != newAccPersonDir.Salutation__c) {
                            associatedAccount.Salutation = newAccPersonDir.Salutation__c;
                            updateAcc = true;
                        }                
        
                        //IE-1325, COR-52 - Check if the name changed using compareTo so that it will detect case change also
                        if (associatedAccount.FirstName != null && newAccPersonDir.First_Name__c != null){
                            if(associatedAccount.FirstName.compareTo(newAccPersonDir.First_Name__c) != 0) {
                                associatedAccount.FirstName = newAccPersonDir.First_Name__c;
                                updateAcc = true;
                            }
                        } else {
                            if(String.isBlank(associatedAccount.FirstName) && String.isNotBlank(newAccPersonDir.First_Name__c)) {
                                associatedAccount.FirstName = newAccPersonDir.First_Name__c;
                                updateAcc = true;
                            }
                        }
        
                        if(associatedAccount.LastName.compareTo(newAccPersonDir.Last_Name__c) != 0) {
                            associatedAccount.LastName = newAccPersonDir.Last_Name__c;
                            updateAcc = true;
                        }
    
                        if(associatedAccount.BillingStreet != newAccPersonDir.Address_Line_1__c) {
                            associatedAccount.BillingStreet = newAccPersonDir.Address_Line_1__c;
                            updateAcc = true;
                        }
        
                        if(associatedAccount.BillingCity != newAccPersonDir.City__c) {
                            associatedAccount.BillingCity = newAccPersonDir.City__c;
                            updateAcc = true;
                        }
    
                        if(associatedAccount.BillingState != newAccPersonDir.State__c) {
                            associatedAccount.BillingState = newAccPersonDir.State__c;
                            updateAcc = true;
                        }
        
                        if(associatedAccount.BillingPostalCode != newAccPersonDir.Post_Code__c) {
                            associatedAccount.BillingPostalCode = newAccPersonDir.Post_Code__c;
                            updateAcc = true;
                        }                              
    
                        if(associatedAccount.BillingCountry != newAccPersonDir.Country__c) {
                            associatedAccount.BillingCountry = newAccPersonDir.Country__c;
                            updateAcc = true;
                        }
        
                        if(associatedAccount.PersonBirthdate != newAccPersonDir.Date_of_Birth__c) {
                            associatedAccount.PersonBirthdate = newAccPersonDir.Date_of_Birth__c;
                            updateAcc = true;
                        }
    
                        if(String.isNotBlank(newAccPersonDir.Email__c) &&
                            associatedAccount.PersonEmail != newAccPersonDir.Email__c) {
                            associatedAccount.PersonEmail = newAccPersonDir.Email__c;
                            updateAcc = true;
                        }
        
                        if(associatedAccount.External_Client_Id__pc != newAccPersonDir.External_System_Id__c) {
                            associatedAccount.External_Client_Id__pc = newAccPersonDir.External_System_Id__c;
                            updateAcc = true;
                        }
    
                        //DG-180 - Amended code to check if the gender is blank or not on ADP record, which was previously checking account record
                        if(String.isNotBlank(newAccPersonDir.Gender__c) && associatedAccount.Gender__pc != newAccPersonDir.Gender__c) {
                            associatedAccount.Gender__pc = newAccPersonDir.Gender__c;
                            updateAcc = true;
                        }
        
                        if(String.isNotBlank(newAccPersonDir.Mobile_Phone_Number__c) &&
                           associatedAccount.PersonMobilePhone != newAccPersonDir.Mobile_Phone_Number__c) {
                            associatedAccount.PersonMobilePhone = newAccPersonDir.Mobile_Phone_Number__c;
                            updateAcc = true;
                        }
     
                        if(String.isNotBlank(newAccPersonDir.Other_Phone_Number__c) &&
                           associatedAccount.PersonOtherPhone != newAccPersonDir.Other_Phone_Number__c) {
                            associatedAccount.PersonOtherPhone = newAccPersonDir.Other_Phone_Number__c;
                            updateAcc = true;
                        }
        
                        if(String.isNotBlank(newAccPersonDir.Phone_Number__c) &&
                           associatedAccount.PersonHomePhone != newAccPersonDir.Phone_Number__c) {
                            associatedAccount.PersonHomePhone = newAccPersonDir.Phone_Number__c;
                            updateAcc = true;
                        }
    
                        if( String.isNotBlank(newAccPersonDir.National_Insurance_Number__c) &&
                            associatedAccount.National_Insurance_Number__pc != newAccPersonDir.National_Insurance_Number__c) {
                            associatedAccount.National_Insurance_Number__pc = newAccPersonDir.National_Insurance_Number__c;
                            updateAcc = true;
                        }
        
                        if(String.isNotBlank(newAccPersonDir.Phone_Number__c) &&
                           associatedAccount.Phone != newAccPersonDir.Phone_Number__c) {
                            associatedAccount.Phone = newAccPersonDir.Phone_Number__c;
                            updateAcc = true;
                        }
    
                        if(associatedAccount.Account_Status__c != newAccPersonDir.Status__c) {
                            associatedAccount.Account_Status__c = newAccPersonDir.Status__c;
                            updateAcc = true;
                        }
        
                        if( associatedAccount.Known_As__c != newAccPersonDir.Known_As__c) {
                            associatedAccount.Known_As__c = newAccPersonDir.Known_As__c;
                            updateAcc = true;
                        } 
    
                        if( String.isNotBlank(newAccPersonDir.Web_Registered__c) && 
                            associatedAccount.Web_Registered__c != newAccPersonDir.Web_Registered__c ) {
                            associatedAccount.Web_Registered__c  = newAccPersonDir.Web_Registered__c;
                            updateAcc = true;
                        }
                        
                        if( newAccPersonDir.Date_Web_Registered__c != null && 
                            associatedAccount.Date_Web_Registered__c != newAccPersonDir.Date_Web_Registered__c ) {
                            associatedAccount.Date_Web_Registered__c  = newAccPersonDir.Date_Web_Registered__c;
                            updateAcc = true;
                        }

                        //STB-4674 - Start
                        if( String.isNotBlank(newAccPersonDir.Email_Bounce_Reason__c) && 
                            associatedAccount.Email_Bounce_Reason__c != newAccPersonDir.Email_Bounce_Reason__c ) {
                            associatedAccount.Email_Bounce_Reason__c  = newAccPersonDir.Email_Bounce_Reason__c;
                            updateAcc = true;
                        }
                        
                        if( newAccPersonDir.Email_Bounce_Date__c != null && 
                            associatedAccount.Email_Bounce_Date__c != newAccPersonDir.Email_Bounce_Date__c ) {
                            associatedAccount.Email_Bounce_Date__c  = newAccPersonDir.Email_Bounce_Date__c;
                            updateAcc = true;
                        }
                        //STB-4674 - End

                        //DG-180 - Start
                        if(newAccPersonDir.External_System__c == 'Oscar'){
                            if( String.isNotBlank(newAccPersonDir.Care_Status__c) && 
                                associatedAccount.Care_Status__c != newAccPersonDir.Care_Status__c ) {
                                associatedAccount.Care_Status__c  = newAccPersonDir.Care_Status__c;
                                updateAcc = true;
                            }

                            if((associatedAccount.IsPayer__c != newAccPersonDir.IsPayer__c)) {
                                associatedAccount.IsPayer__c = newAccPersonDir.IsPayer__c;
                                updateAcc = true;
                            }

                            if(String.isNotBlank(newAccPersonDir.External_Payer_Id__c) || 
                                (String.isBlank(newAccPersonDir.External_Payer_Id__c) && String.isNotBlank(associatedAccount.Payer__c))) {
                                Id payerAccountId = EtlPersonAccountProcessing.getPayerAccountLinkedToADPRecord(newAccPersonDir);
                                system.debug('after EtlPersonAccountProcessing.getPayerAccountLinkedToADPRecord method calling: '+ payerAccountId);
                                if (payerAccountId != associatedAccount.Payer__c){
                                    associatedAccount.Payer__c = payerAccountId;
                                    updateAcc = true;
                                }
                            }

                            //If details have been removed in the source system, or if linked dental practice and dentist records have been passed which does not exist in Salesforce.
                            //Dentist (contacts) are related to Dental Practice (Account), so if account can not find, then linked contacts will also not be present in Salesforce.
                            if(String.isBlank(newAccPersonDir.Dental_Practice_Id__c)){
                                if(String.isNotBlank(associatedAccount.Dental_Practice__c)) {
                                    associatedAccount.Dental_Practice__c = '';
                                    updateAcc = true;
                                }
                                if(String.isNotBlank(associatedAccount.Treating_Dentist__c)) {
                                    associatedAccount.Treating_Dentist__c = '';
                                    updateAcc = true;
                                }
                                if(String.isNotBlank(associatedAccount.Owning_Dentist__c)) {
                                    associatedAccount.Owning_Dentist__c = '';
                                    updateAcc = true;
                                }

                            }else{
                                                            
                                if(String.isNotBlank(newAccPersonDir.Dental_Practice_Id__c) || 
                                    (
                                        (String.isBlank(newAccPersonDir.Dental_Practice_Id__c) && String.isNotBlank(associatedAccount.Dental_Practice__c)) ||
                                        (String.isBlank(newAccPersonDir.Treating_Dentist_Id__c) && String.isNotBlank(associatedAccount.Treating_Dentist__c)) ||
                                        (String.isBlank(newAccPersonDir.Owning_Dentist_Id__c) && String.isNotBlank(associatedAccount.Owning_Dentist__c))
                                    )) {
                                        Map<String,String> dentistAndPracticeDetails = EtlPersonAccountProcessing.getDentistsAndPracticeLinkedToADP(newAccPersonDir);
                                        String dentalPracticeId = dentistAndPracticeDetails.get('DentalPraticeId');
                                        String treatingDentistId = dentistAndPracticeDetails.get('TreatingDentistId');
                                        String owningDentistId = dentistAndPracticeDetails.get('OwningDentistId');
                                    
                                        if (String.isNotBlank(dentalPracticeId) != String.isNotBlank(associatedAccount.Dental_Practice__c)){
                                            associatedAccount.Dental_Practice__c = dentalPracticeId;
                                            updateAcc = true;
                                        }
                                        if (String.isNotBlank(treatingDentistId) != String.isNotBlank(associatedAccount.Treating_Dentist__c)){
                                            associatedAccount.Treating_Dentist__c = treatingDentistId;
                                            updateAcc = true;
                                        }
                                        if (String.isNotBlank(owningDentistId) != String.isNotBlank(associatedAccount.Owning_Dentist__c)){
                                            associatedAccount.Owning_Dentist__c = owningDentistId;
                                            updateAcc = true;
                                        }
                                }
                            }

                            if(!associatedAccount.Oscar_Data_Link__c) {
                                associatedAccount.Oscar_Data_Link__c = true;
                                updateAcc = true;
                            }
                        }
                        //DG-180 - End

                        // IE-625 - update Sex and Marketing prefs if it is changed
                        if(String.isNotBlank(newAccPersonDir.Sex__c) && associatedAccount.Sex__pc != newAccPersonDir.Sex__c) {
                            associatedAccount.Sex__pc  = newAccPersonDir.Sex__c;
                            updateAcc = true;
                        }              

                        if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Email__c) &&
                            associatedAccount.Marketing_Preference_Email__pc != newAccPersonDir.Mkt_Pref_Email__c ) {
                            associatedAccount.Marketing_Preference_Email__pc  = newAccPersonDir.Mkt_Pref_Email__c;
                            updateAcc = true;
                        }                        

                        if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Phone__c) &&
                            associatedAccount.Marketing_Preference_Phone__pc != newAccPersonDir.Mkt_Pref_Phone__c ) {
                            associatedAccount.Marketing_Preference_Phone__pc  = newAccPersonDir.Mkt_Pref_Phone__c;
                            updateAcc = true;
                        }                                    

                        if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Post__c) &&
                            associatedAccount.Marketing_Preference_Post__pc != newAccPersonDir.Mkt_Pref_Post__c ) {
                            associatedAccount.Marketing_Preference_Post__pc  = newAccPersonDir.Mkt_Pref_Post__c;
                            updateAcc = true;
                        }                        

                        if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Sms__c) &&
                            associatedAccount.Marketing_Preference_SMS__pc != newAccPersonDir.Mkt_Pref_Sms__c ) {
                            associatedAccount.Marketing_Preference_SMS__pc  = newAccPersonDir.Mkt_Pref_Sms__c;
                            updateAcc = true;
                        }                        
    
                        // If any field values have been amended then add Account record to those that need updating
                        if(updateAcc == true) {
                            // Add account to a Set to ensure no duplicate Accounts
                            accSetToBeUpdated.add(associatedAccount);
                        }
                        
                        System.debug('SIMMOETL associatedAccount.PersonIndividual.Firstname = ' + associatedAccount.PersonIndividual.Firstname);
                        System.debug('SIMMOETL newAccPersonDir.First_Name__c = ' + newAccPersonDir.First_Name__c);
                        
                        System.debug('SIMMOETL associatedIndividual.Id = ' + associatedIndividual.Id);
                        
                        if(String.isNotBlank(associatedIndividual.Id)) {
                        
                            System.debug('SIMMOETL Inside Individual If');
                        
                            if(String.isNotBlank(newAccPersonDir.Salutation__c) && associatedAccount.PersonIndividual.Salutation != newAccPersonDir.Salutation__c) {
                                associatedIndividual.Salutation = newAccPersonDir.Salutation__c;
                                updateInd = true;
                            }
                            
                            // IE-1325, COR-52: Detect the case change(lower to upper or upper to lower) also in name using compareTo 
                            if (associatedAccount.PersonIndividual.Firstname != null && newAccPersonDir.First_Name__c != null){
                                if(associatedAccount.PersonIndividual.Firstname.compareTo(newAccPersonDir.First_Name__c) != 0) {
                                    associatedIndividual.Firstname = newAccPersonDir.First_Name__c;
                                    updateInd = true;
                                }
                            } else {
                                if (String.isBlank(associatedAccount.PersonIndividual.Firstname) && String.isNotBlank(newAccPersonDir.First_Name__c)){
                                    associatedIndividual.Firstname = newAccPersonDir.First_Name__c;
                                    updateInd = true;
                                }
                            }                             
                            
                            if(associatedAccount.PersonIndividual.Lastname.compareTo(newAccPersonDir.Last_Name__c) != 0) {
                                associatedIndividual.Lastname = newAccPersonDir.Last_Name__c;
                                updateInd = true;
                            }
                            
                            if(associatedAccount.PersonIndividual.BirthDate != newAccPersonDir.Date_of_Birth__c) {
                                associatedIndividual.BirthDate = newAccPersonDir.Date_of_Birth__c;
                                //associatedAccount.PersonIndividual.BirthDate = newAccPersonDir.Date_of_Birth__c;
                                updateInd = true;
                            }
                            
                            if(String.isNotBlank(newAccPersonDir.Email__c) &&
                               associatedAccount.PersonIndividual.Email__c != newAccPersonDir.Email__c) {
                                associatedIndividual.Email__c = newAccPersonDir.Email__c;
                                updateInd = true;
                            }
                            
                            if( newAccPersonDir.Mkt_Pref_Confirm_Date__c != null &&
                                associatedAccount.PersonIndividual.Marketing_Pref_Confirm_Date__c != newAccPersonDir.Mkt_Pref_Confirm_Date__c) {
                                associatedIndividual.Marketing_Pref_Confirm_Date__c = newAccPersonDir.Mkt_Pref_Confirm_Date__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Confirmed_In_System__c)  &&
                                associatedAccount.PersonIndividual.Marketing_Pref_Confirmed_In_System__c != newAccPersonDir.Mkt_Pref_Confirmed_In_System__c) {
                                associatedIndividual.Marketing_Pref_Confirmed_In_System__c = newAccPersonDir.Mkt_Pref_Confirmed_In_System__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Email__c) &&
                                associatedAccount.PersonIndividual.Marketing_by_Email__c != newAccPersonDir.Mkt_Pref_Email__c) {
                                associatedIndividual.Marketing_by_Email__c = newAccPersonDir.Mkt_Pref_Email__c;
                                updateInd = true;
                            }
                            
                            System.debug('SIMMOETL associatedAccount.PersonIndividual.Marketing_by_Email__c = ' + associatedAccount.PersonIndividual.Marketing_by_Email__c);
                            System.debug('SIMMOETL newAccPersonDir.Mkt_Pref_Email__c = ' + newAccPersonDir.Mkt_Pref_Email__c);
                            System.debug('SIMMOETL associatedIndividual.Marketing_by_Email__c = ' + associatedIndividual.Marketing_by_Email__c);
                            
                            if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Phone__c) &&
                                associatedAccount.PersonIndividual.Marketing_by_Phone__c != newAccPersonDir.Mkt_Pref_Phone__c) {
                                associatedIndividual.Marketing_by_Phone__c = newAccPersonDir.Mkt_Pref_Phone__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Post__c) &&
                                associatedAccount.PersonIndividual.Marketing_by_Post__c != newAccPersonDir.Mkt_Pref_Post__c) {
                                associatedIndividual.Marketing_by_Post__c = newAccPersonDir.Mkt_Pref_Post__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Mkt_Pref_Sms__c) &&
                                associatedAccount.PersonIndividual.Marketing_by_SMS__c != newAccPersonDir.Mkt_Pref_Sms__c) {
                                associatedIndividual.Marketing_by_SMS__c = newAccPersonDir.Mkt_Pref_Sms__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Servicing_Preference__c) &&
                                associatedAccount.PersonIndividual.Servicing_Preference__c != newAccPersonDir.Servicing_Preference__c) {
                                associatedIndividual.Servicing_Preference__c = newAccPersonDir.Servicing_Preference__c;
                                updateInd = true;
                            }
                            
                            if( newAccPersonDir.Srv_Pref_Confirm_Date__c != null &&
                                associatedAccount.PersonIndividual.Servicing_Pref_Confirm_Date__c != newAccPersonDir.Srv_Pref_Confirm_Date__c) {
                                associatedIndividual.Servicing_Pref_Confirm_Date__c = newAccPersonDir.Srv_Pref_Confirm_Date__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Confirmed_In_System__c) &&
                                associatedAccount.PersonIndividual.Servicing_Pref_Confirmed_In_System__c != newAccPersonDir.Srv_Pref_Confirmed_In_System__c) {
                                associatedIndividual.Servicing_Pref_Confirmed_In_System__c = newAccPersonDir.Srv_Pref_Confirmed_In_System__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Email__c) &&
                                associatedAccount.PersonIndividual.Servicing_By_Email__c != newAccPersonDir.Srv_Pref_Email__c) {
                                associatedIndividual.Servicing_By_Email__c = newAccPersonDir.Srv_Pref_Email__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Online__c) &&
                                associatedAccount.PersonIndividual.Servicing_Online__c != newAccPersonDir.Srv_Pref_Online__c) {
                                associatedIndividual.Servicing_Online__c = newAccPersonDir.Srv_Pref_Online__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Phone__c) &&
                                associatedAccount.PersonIndividual.Servicing_By_Phone__c != newAccPersonDir.Srv_Pref_Phone__c) {
                                associatedIndividual.Servicing_By_Phone__c = newAccPersonDir.Srv_Pref_Phone__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Post__c) &&
                                associatedAccount.PersonIndividual.Servicing_by_Post__c != newAccPersonDir.Srv_Pref_Post__c) {
                                associatedIndividual.Servicing_by_Post__c = newAccPersonDir.Srv_Pref_Post__c;
                                updateInd = true;
                            }
                            
                            if( String.isNotBlank(newAccPersonDir.Srv_Pref_Sms__c) &&
                                associatedAccount.PersonIndividual.Servicing_By_Sms__c != newAccPersonDir.Srv_Pref_Sms__c) {
                                associatedIndividual.Servicing_By_Sms__c = newAccPersonDir.Srv_Pref_Sms__c;
                                updateInd = true;
                            }
                            
                            If(updateInd == true) {
                                indsToBeUpdated.add(associatedIndividual);
                            }
                        }
                    }                    
                }                                                                                                
            }
        }
        
        if(!accSetToBeUpdated.isEmpty()) {
            // Convert set to list so it can be used for update
            List<Account> accsToBeUpdated = new List<Account>(accSetToBeUpdated);
            Database.update(accsToBeUpdated);
        }
        if(!indsToBeUpdated.isEmpty()) {
            Map<String, Individual> individualMap = new Map<String, Individual>();
            for(Individual ind: indsToBeUpdated) {
                individualMap.put(ind.Id, ind);
            }
            
            List<Individual> dedupedIndividualList = new List<Individual>();
            dedupedIndividualList.addAll(individualMap.values());
            
            Database.update(dedupedIndividualList);
        }
    
    }


    /**
        Class:   SyncDataBetweenAccDirGroupAndAccount
        Author:  Jon Simmonds
        Date:    06/05/2020
        Purpose: Sync data between the Group Account Directory records and related Account records
   **/
    public static void SyncDataBetweenAccDirGroupAndAccount(List<Account_Directory_Group__c> newAccDirGroups) {

        Id prospectAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        
        List<Id> associatedAccountIds = new List<Id>();
        for(Account_Directory_Group__c newAccDirGroup: newAccDirGroups) {
            if(String.isNotBlank(newAccDirGroup.Account__c)) {
                associatedAccountIds.add(newAccDirGroup.Account__c);
            }
        }
        
        Map<ID, Account> associatedAccountsMap = new Map<ID, Account>([Select Id, RecordTypeId, Name, BillingStreet , BillingCity, BillingCountry, External_Group_Id__c, ParentId, Master_Account_Directory_Group__c, 
                                                                              BillingPostalCode, Account_Status__c, Type, Website, BillingState, Original_Source__c, Is_Primary_Group__c 
                                                                       FROM Account
                                                                       Where Id IN :associatedAccountIds]);
                                                                       
        Set<Account> accSetToBeUpdated = new Set<Account>();
        Boolean updateAcc = false;
        
        for(Account_Directory_Group__c newAccDirGroup: newAccDirGroups) {
            
            if(associatedAccountsMap.containsKey(newAccDirGroup.Account__c)) {
                Account associatedAccount = associatedAccountsMap.get(newAccDirGroup.Account__c);
                updateAcc = false;
                
                if(associatedAccount.Master_Account_Directory_Group__c == newAccDirGroup.Id) {
                
                    if(newAccDirGroup.External_System__c == 'Broker Portal' &&
                        associatedAccount.RecordTypeId != prospectAccRecTypeId) {
                        continue;
                    }

                    if(associatedAccount.Name != newAccDirGroup.Name) {
                        associatedAccount.Name = newAccDirGroup.Name;
                        updateAcc = true;
                    }

                    if(associatedAccount.BillingStreet != newAccDirGroup.Address_Line_1__c) {
                        associatedAccount.BillingStreet = newAccDirGroup.Address_Line_1__c;
                        updateAcc = true; 
                    }

                    if(associatedAccount.BillingCity != newAccDirGroup.City__c) {
                        associatedAccount.BillingCity = newAccDirGroup.City__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.BillingState != newAccDirGroup.State__c) {
                        associatedAccount.BillingState = newAccDirGroup.State__c;
                        updateAcc = true; 
                    }

                    if(associatedAccount.BillingCountry != newAccDirGroup.Country__c) {
                        associatedAccount.BillingCountry = newAccDirGroup.Country__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.BillingPostalCode != newAccDirGroup.Post_Code__c) {
                        associatedAccount.BillingPostalCode = newAccDirGroup.Post_Code__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.Website != newAccDirGroup.Website__c) {
                        associatedAccount.Website = newAccDirGroup.Website__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.ParentId != newAccDirGroup.Parent_Account__c) {
                        associatedAccount.ParentId = newAccDirGroup.Parent_Account__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.External_Group_Id__c != newAccDirGroup.External_System_Group_Id__c) {
                        associatedAccount.External_Group_Id__c = newAccDirGroup.External_System_Group_Id__c;
                        updateAcc = true;
                    }                

                    if(associatedAccount.Account_Status__c != newAccDirGroup.Status__c) {
                        associatedAccount.Account_Status__c = newAccDirGroup.Status__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.Is_Primary_Group__c != newAccDirGroup.Is_Primary_Group__c) {
                        associatedAccount.Is_Primary_Group__c = newAccDirGroup.Is_Primary_Group__c;
                        updateAcc = true;
                    }

                    if(associatedAccount.Type == 'Client' && newAccDirGroup.Type__c != 'Group') {
                        if(newAccDirGroup.Type__c == 'Intermediary Site') {
                            associatedAccount.Type = 'Broker';
                            updateAcc = true;
                        }
                    }
                    if(associatedAccount.Type == 'Broker' && newAccDirGroup.Type__c != 'Intermediary Site') {
                        if(newAccDirGroup.Type__c == 'Group') {
                            associatedAccount.Type = 'Client';
                            updateAcc = true;
                        }
                    }
                
                    if(updateAcc == true) {
                        accSetToBeUpdated.add(associatedAccount);
                    }
                }                                                                                     
            }
        }
        
        if(!accSetToBeUpdated.isEmpty()) {
            List<Account> accsToBeUpdated = new List<Account>(accSetToBeUpdated);
            Database.update(accsToBeUpdated);
        }
    } 
}