/**********************************************************************************************
    Class:   AccountTriggerHelper
    Date:    01/12/2017
    Name:    Sandeep Sekhon
    Project: Helper class for the Account trigger
    
***********************************************************************************************
Amendments:
Date         Name          Description
01/12/2017   S.Sekhon      SF-237: Created method UpdateOpportunityBroker to populate Broker fields on 
                                   Open opportunities related to Client or Prospect Accounts.
07/03/2018   Jon Simmonds  SF-575: Created a method to prevent an Account being changed from a Broker
                                   to a Prospect account.
19/02/2020   Jon Simmonds  SFM-478 Added new method syncDataMatchingFields
20/05/2020   Jon Simmonds  SFM-1609 Added the new method setOriginalSource
14/08/2020   S.Sekhon      SFM-2272: Added method setBirthdate_Text to Populate Birthdate Text field so it can be used for 
                                     Global search and in the Duplicate Rule for Person Account.     
12/05/2022   Arivu Sugumar IE-625: Change to handle Ski system also
14/06/2022   Jon Simmonds  IE-628: Added the new method updatePersonDirectoryRecords that updates associated Account_Directory_Person__c records
                                   from a manual update to the Person Accounnt. Salesforce to Ski sync.
29/07/2022   S.Sekhon      IE-1161: Salesforce Individual Account - Changes to Name, DOB & Email values in Person Account.   

09/08/2022   Arivu Sugumar IE-1325: Detect the case change(lower to upper or upper to lower) also in name. 

14/04/2023   Arivu Sugumar COR-52: Handle null value in first name.        

16/06/2023   Arivu Sugumar COR-396: Account creation from broker portal by quoterequest service.   
29/11/2023   Rajiv Kumar   DG-180:: Amended setOriginalSource method to include Oscar original source.
                                    Amended updatePersonDirectoryRecords mothod to update Oscar ADP record.
***********************************************************************************************/
public class AccountTriggerHelper {
    
    public static Id dentalPracticeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dental_Practice').getRecordTypeId();
    private static AccountTriggerHelper instance;
   
    public static AccountTriggerHelper getInstance(){
        if (instance == null) {
            instance = new AccountTriggerHelper();
        }
    return instance;
    }       

    // ACCOUNT RECORD TYPES
    // Retrieve Account Record Type for Client
    public static RecordType RecTypeClient = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Client'];
    
    // SF-575 Jon Simmonds 07/03/2018 - Added DeveloperName 
    // Retrieve Account Record Type for Prospect
    public static RecordType RecTypeProspect = [Select Id, DeveloperName From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Prospect'];

    // SF-575 Start - Jon Simmonds 07/03/2018 - Added variable to hold the Account Broker record type
    // Retrieve Account Record Type for Broker
    public static RecordType AccRecTypeBroker = [Select Id, DeveloperName From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Broker'];
    // SF-575 End - Jon Simmonds 07/03/2018 - Added variable to hold the Account Broker record type

    // OPPORTUNITY RECORD TYPES
    // Retrieve Opportunity Record Type for Dental Renewal
    public static RecordType RecTypeDentalRenewal = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corp_Renewal'];
    
    // Retrieve Opportunity Record Type for Dental New Business
    public static RecordType RecTypeDentalNewBus = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corp_Sales_New_Business'];
   
    // Retrieve Opportunity Record Type for Cashplan Renewal
    public static RecordType RecTypeCashplanRenewal = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corporate_Cashplan_Renewal'];
    
    // Retrieve Opportunity Record Type for Cashplan New Business
    public static RecordType RecTypeCashplanNewBus = [Select Id From RecordType  Where SobjectType = 'Opportunity' and DeveloperName = 'Corporate_Cashplan_New_Business'];
    
    
    // Retrieve Person Account Record Type for Individual Client
    public static RecordType RecTypeIndClient = [Select Id From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Individual_Client'];
     
    // Retrieve Account Record Type for Individual Prospect
    public static RecordType RecTypeIndProspect = [Select Id, DeveloperName From RecordType  Where SobjectType = 'Account' and DeveloperName = 'Individual_Prospect'];

    /********* Method: Called from Opportunity trigger to Update Broker on new Opps ********
    // Start 01/12/2017 S.Sekhon - SF:237    
    // When a new Client or Prospect Account is updated check the Dental and Cash Plan values
    // if they have changed get related Open opportunities and reflect the broker change on
    // these Opportunities.
    ****************************************************************************************/ 
    public void UpdateOpportunityBroker(List<Account> triggerNew, Map<Id, Account> triggerOldMap ) {
                

        // List of Opportunities that will be updated related to triggered Accounts
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
    
        // List of Account Ids that Open Opps need to be retrieved for
        List<Id> accIds = new List<Id>();
    
        // Create a map to hold the List of Opportunites for the Account
        Map<Id, List<Opportunity>> accIdWithOpplstMap = new Map<Id,List<Opportunity>>();

        // Account Variable to hold Old Account values
        Account oldAccountValues;
    
    
            // Loop around the trigger to build Account-Opportunities Map and Account Id List
            for(Account acc : triggerNew) {
       
                if (acc.recordTypeId == RecTypeClient.Id  ||  acc.RecordTypeId == RecTypeProspect.Id){
                    accIds.add(acc.Id);                 
                }
            }
                              
                // Populate map with the Account Id as key and all related Open opportunities.            
                for(Account acco : [SELECT id, (SELECT id, Name, RecordTypeId  
                                                FROM   Opportunities 
                                                WHERE  IsClosed = false  
                                                ) 
                                    FROM   Account 
                                    WHERE  id in :accIds]) {
                                    
                    accIdWithOpplstMap.put(acco.Id,acco.Opportunities);
                    }                  
        
        List<Opportunity> opps = new List<Opportunity>();
           
        // Loop around the trigger to process Dental and Cash plan opportunities   
        for(Account acc : triggerNew) {
        
            // For Client and Prospect Accounts retrieve the old values
            if (acc.recordTypeId == RecTypeClient.Id  ||  acc.RecordTypeId == RecTypeProspect.Id) {  
            
                oldAccountValues = triggerOldMap.get(acc.id);   
         
                // Check the Account to determine if the Previous Dental Broker has Changed from the triggered record Dental Broker
                // retrieve any open Dental Opps for the Account if broker has changed
                if (acc.Broker__c <> oldAccountValues.Broker__c ) {
                      
                    system.debug('@@@@@@ 1 Old Dental Broker ' + oldAccountValues.Broker__c); 
                    system.debug('@@@@@@ 2 New Dental Broker ' + acc.Broker__c);     
              
                    // Retrieve the related opps from the Map using Account Id as key           
                    opps = accIdWithOpplstMap.get(acc.id);
                
                    system.debug('@@@@@@ 3 Dental opps returned for update are ' + opps);
                
                        // loop around the retrieved Dental Opportunities and update the Dental Broker
                        for(Opportunity o : opps)  {
                    
                            if (o.RecordTypeId == RecTypeDentalRenewal.id || o.RecordTypeId == RecTypeDentalNewBus.Id  ) {
                    
                            o.Dental_Broker__c = acc.Broker__c;                 
                            oppsToUpdate.add(o);
                  
                            system.debug('@@@@@@ 4 Dental opps to uopdate ' + oppsToUpdate);                    
                            }         
                        } 
                }
        

                if (acc.Cashplan_Broker__c <> oldAccountValues.Cashplan_Broker__c ) {
           
                    system.debug('@@@@@@ 7 Old Cash Plan Broker ' + oldAccountValues.Cashplan_Broker__c); 
                    system.debug('@@@@@@ 8 New Cash Plan Broker ' + acc.Cashplan_Broker__c);     
              
                    // Retrieve the related opps from the Map using Account Id as key           
                    opps = accIdWithOpplstMap.get(acc.id);
                
                    system.debug('@@@@@@ 9 Cash Plan Opps returned for update are ' + opps);
                    
                    // loop around the retrieved Opportunities and update the Cash Plan Broker
                        for(Opportunity o : opps)  {
                        
                            if (o.RecordTypeId == RecTypeCashPlanRenewal.id || o.RecordTypeId == RecTypeCashPlanNewBus.Id  ) {
                            
                            o.Cash_Plan_Broker__c = acc.Cashplan_Broker__c;
                            oppsToUpdate.add(o);
                  
                            system.debug('@@@@@@ 10 Cash plan opps to uopdate ' + oppsToUpdate);           
                            }
                        }
                 }       
            }
       }
           
        update oppsToUpdate; 

        }

        
    // SF-575 Start - Jon Simmonds 07/03/2018 - Created new method to prevent Account from being changed from Broker to Prospect
    /**
        Method:  accountRecordtypeChangeCheck
        Author:  Jon Simmonds
        Date:    07/03/2018
        Purpose: This method is fired from the before update trigger.
                 It will prevent an Account from being changed from a Broker Account to a Propsect Account
    **/
    public void accountRecordtypeChangeCheck(List<Account> triggerNew, Map<Id, Account> triggerOldMap ) {
    
        System.debug('SIMMODEBUG - Inside accountRecordtypeChangeCheck call');
        
        // Variable to hold the old Account values
        Account oldAccountValues;
        
        // Loop through the updated Account records
        for(Account acc : triggerNew) {
            
            // Retrieve the Old Account values for current Account in loop
            oldAccountValues = triggerOldMap.get(acc.id);
            
            System.debug('SIMMODEBUG - Inside oldAccountValues.RecordTypeId = ' + oldAccountValues.RecordTypeId);
            System.debug('SIMMODEBUG - Inside acc.RecordTypeId = ' + acc.RecordTypeId);
            
            // If the Account Record Type has been changed from Broker to Prospect add an error to prevent this
            if(oldAccountValues.RecordTypeId == AccRecTypeBroker.Id &&
               acc.RecordTypeId == RecTypeProspect.Id) {
                acc.addError('It is not possible to change a Broker Account to a Prospect Account');
            }
        }
    
    }
    // SF-575 End - Jon Simmonds 07/03/2018 - Created new method to prevent Account from being changed from Broker to Prospect


    /**
        Method:  syncDataMatchingFields
        Author:  Jon Simmonds
        Date:    19/02/2020
        Ticket:  SFM-478 ETL syncing
        Purpose: Ensure the data matching fields used for the ETL process are kept in sync
    **/
    public void syncDataMatchingFields(List<Account> triggerNew) {
    
        // Update the data matching fields from the latest values so they are kept in sync
        for(Account acc : triggerNew) {
            acc.Data_Matching_BillingPostCode__c = EtlStringHelpers.stripString(acc.BillingPostalCode);
            acc.Data_Matching_LastName__c = EtlStringHelpers.stripString(acc.LastName);
            acc.Data_Matching_FirstName__c = EtlStringHelpers.stripString(acc.FirstName);
            acc.Data_Matching_Name__c = EtlStringHelpers.stripString(acc.Name);
        }
    
    }


    /**
        Method:  setOriginalSource
        Author:  Jon Simmonds
        Date:    20/05/2020
        Ticket:  SFM-1609
        Purpose: Set the original source field if Account created in Zeus org
    **/
    public void setOriginalSource(List<Account> triggerNew) {
    
        // The Original Source is automatically set to Pulse if the Account record has been created via the ETL
        // So if the value is not already Pulse it means the Account record has been created within the Zeus org
        for(Account acc : triggerNew) {
        System.debug('FRESH86 Inside setOriginalSource loop Original_Source__c value = ' + acc.Original_Source__c);
            // IE-625 - Include Ski
            // DG-180 - Added Oscar
            if(acc.Original_Source__c != 'Pulse' && 
               acc.Original_Source__c != 'Ski' &&
               acc.Original_Source__c != 'Broker Portal' &&
               acc.Original_Source__c != 'Oscar') {
            System.debug('FRESH86 Inside setOriginalSource set to Zeus');
                acc.Original_Source__c = 'Zeus';
            }
        
        }
    
    }
    
    /**
        Method:  setBirthdateText
        Author:  Sandeep Sekhon
        Date:    14/08/2020
        Ticket:  SFM-2272
        Purpose: Set the Birthdate_text field for Global search and Duplicate Rule usage if a personbirthdate has been set.
    **/
    public void setBirthdateText(List<Account> accounts) {
   
        for(Account acc : accounts) {
        
            if ((acc.recordTypeId == RecTypeIndClient.Id || acc.RecordTypeId == RecTypeIndProspect.Id ) && acc.PersonbirthDate <> null){                  
                Date d = Date.Valueof(acc.PersonbirthDate);   
                String dateStr = d.format();
                acc.Birthdate_text__pc = dateStr;                           
            }
                      
        }
    }
    
    
    /**
    Class:     validateAccountBillingStreetAddr 
    Author:    Kishore Reddy (Youperience)
    Date :     10/09/2019
    Purpose :  Validating the account billing street address  
    **/
    public void validateAccountBillingStreetAddr(List<Account> AccountLst){
        
        Boolean linescountflg = false;
        String AccountBillingStreetAddr;      
        
        for(Account accDetails : AccountLst){
            try{ 
                if(accDetails.RecordTypeId == dentalPracticeId && (accDetails.BillingStreet == null || accDetails.Billingstreet =='' || accDetails.BillingPostalCode == null || accDetails.BillingCity == null || accDetails.BillingCountry == null) 
                && (accDetails.Corporate_Partner__c != true) && (accDetails.Practice_Type__c == 'Dental Practice'  || accDetails.Practice_Type__c == 'Residence' || accDetails.Practice_Type__c == 'Ex-Dental Practice' ||accDetails.Practice_Type__c == 'Corporate Partnerships' || accDetails.Practice_Type__c == 'Prospect' || accDetails.Practice_Type__c == 'Other')){
                    accDetails.addError('The following Address fields should not be blank: Street, Post Code,  Country and City');
                }
                else if(accDetails.RecordTypeId == dentalPracticeId
                 && (accDetails.Corporate_Partner__c != true) && (accDetails.Practice_Type__c == 'Dental Practice'  || accDetails.Practice_Type__c == 'Residence' || accDetails.Practice_Type__c == 'Ex-Dental Practice' ||accDetails.Practice_Type__c == 'Corporate Partnerships' || accDetails.Practice_Type__c == 'Prospect' || accDetails.Practice_Type__c == 'Other')){
                    Integer LinesCount = accDetails.BillingStreet.countMatches('\n');
                    system.debug('Line count is:'+LinesCount);
                    List<string> billingStreetLines = accDetails.BillingStreet.split('\n');                 
                    system.debug('billingStreetLines :'+billingStreetLines);
                    if(LinesCount <= 2){
                       for(String billingStreetstr : billingStreetLines){
                           AccountBillingStreetAddr = billingStreetstr.remove('\n').trim();
                           system.debug('length of string is:'+AccountBillingStreetAddr+' lenght '+AccountBillingStreetAddr.Length());
                           if(AccountBillingStreetAddr.length() > 25){
                               linescountflg = true;
                           }
                        } 
                    }
                    system.debug('total lenghe '+accDetails.BillingStreet.Length() +' LinesCount '+ LinesCount +' linescountflg '+linescountflg +'accDetails.BillingStreet '+accDetails.BillingStreet);
                    if(accDetails.BillingStreet.trim().Length() > 52 || LinesCount > 2 || linescountflg == true ){
                        accDetails.addError('Please update the Address. The Street can be a max of 50 characters, with 25 characters on each line.');
                    }
                    else
                    {
                        accDetails.BillingStreet = accDetails.BillingStreet;
                    }
                }
                
            }
            Catch(Exception e){
                if(e.getMessage().contains('List index out of bounds')){
                    accDetails.addError('Please update the Address. The Street can be a max of 50 characters, with 25 characters on each line.');
                }
            
            }
        }
        
    }

    // IE-628 Start - Jon Simmonds 14/06/2022
    public void updatePersonDirectoryRecords(Map<Id, Account> oldMap, List<Account> personAccounts) {
    
        List<Id> accountIds = new List<Id>();
        
        for(Account acc: personAccounts) {
            if(oldMap.get(acc.Id).BillingStreet != acc.BillingStreet ||
               oldMap.get(acc.Id).BillingCity != acc.BillingCity ||
               oldMap.get(acc.Id).BillingState != acc.BillingState ||
               oldMap.get(acc.Id).BillingPostalCode != acc.BillingPostalCode ||
               oldMap.get(acc.Id).BillingCountry != acc.BillingCountry ||
               oldMap.get(acc.Id).PersonBirthdate != acc.PersonBirthdate ||
               oldMap.get(acc.Id).PersonEmail != acc.PersonEmail ||
               oldMap.get(acc.Id).PersonMobilePhone != acc.PersonMobilePhone ||
               oldMap.get(acc.Id).PersonOtherPhone != acc.PersonOtherPhone ||
               oldMap.get(acc.Id).PersonHomePhone != acc.PersonHomePhone ||
               oldMap.get(acc.Id).Account_Status__c != acc.Account_Status__c ||
               oldMap.get(acc.Id).Salutation != acc.Salutation ||
               //IE-1325, COR-52: Detect the case change(lower to upper or upper to lower) also in name using compareTo method
               (oldMap.get(acc.Id).FirstName != null && acc.FirstName != null && oldMap.get(acc.Id).FirstName.compareTo(acc.FirstName) != 0) ||
               //COR-52
               (oldMap.get(acc.Id).FirstName == null && acc.FirstName != null  ) ||               
               oldMap.get(acc.Id).LastName.compareTo(acc.LastName) != 0 ||
               oldMap.get(acc.Id).Known_As__c != acc.Known_As__c ||
               oldMap.get(acc.Id).Sex__pc != acc.Sex__pc ||   
               //DG-180: Added condition to check gender
               oldMap.get(acc.Id).Gender__pc != acc.Gender__pc         
            ) {
                System.debug('SIMMO AccountTriggerHelper updatePersonDirectoryRecords Person Account values have changed');
                accountIds.add(acc.Id);
            }
        }
        
        //DG-180: Added gender
        List<Account_Directory_Person__c> directoryPersons = [Select Name, Address_Line_1__c, City__c, State__c, Post_Code__c, Country__c, 
                                                                     Date_of_Birth__c, Email__c, Mobile_Phone_Number__c, Other_Phone_Number__c,
                                                                     Phone_Number__c, Salutation__c, First_Name__c, Last_Name__c, Known_As__c,
                                                                     Status__c, Sex__c, Account__c, External_System__c, External_System_Id__c, Gender__c
                                                                     From Account_Directory_Person__c
                                                                     Where Account__c IN :accountIds];
        
        Map<Id, List<Account_Directory_Person__c>> personAccountDirectories = new Map<Id, List<Account_Directory_Person__c>>();
        for(Account_Directory_Person__c adp: directoryPersons) {
            if(personAccountDirectories.containsKey(adp.Account__c)) {
                personAccountDirectories.get(adp.Account__c).add(adp);
            } else {
                List<Account_Directory_Person__c> directories = new List<Account_Directory_Person__c>();
                directories.add(adp);
                personAccountDirectories.put(adp.Account__c, directories);
            }
        }
        
        List<Account_Directory_Person__c> updatedDirectoryRecs = new List<Account_Directory_Person__c>();
        List<Account_Directory_Person__c> updatedOscarLinkedDirectoryRecs = new List<Account_Directory_Person__c>(); //DG-180
        Set<Id> adpIdsForPlatformEvent = new Set<Id>(); //DG-180
        
        for(Account acc: personAccounts) {
            if(personAccountDirectories.containsKey(acc.Id)) {
                List<Account_Directory_Person__c> directoryRecs = personAccountDirectories.get(acc.Id);
                for(Account_Directory_Person__c adp: directoryRecs) {
                    if(adp.External_System__c == 'Ski') {
                        adp.Name = acc.FirstName + ' ' + acc.LastName;
                        adp.Address_Line_1__c = acc.BillingStreet;
                        adp.City__c = acc.BillingCity;
                        adp.State__c = acc.BillingState;
                        adp.Post_Code__c = acc.BillingPostalCode;
                        if(String.isBlank(acc.BillingCountry)) {
                            adp.Country__c = 'United Kingdom';
                        } else {
                            adp.Country__c = acc.BillingCountry;
                        }
                        adp.Date_of_Birth__c = acc.PersonBirthdate;
                        adp.Email__c = acc.PersonEmail;
                        adp.Mobile_Phone_Number__c = acc.PersonMobilePhone;
                        adp.Other_Phone_Number__c = acc.PersonOtherPhone;
                        adp.Phone_Number__c = acc.PersonHomePhone;
                        adp.Salutation__c = acc.Salutation;
                        adp.First_Name__c = acc.FirstName;
                        adp.Last_Name__c = acc.LastName;
                        adp.Known_As__c = acc.Known_As__c;
                        adp.Status__c = acc.Account_Status__c;
                        adp.Sex__c = acc.Sex__pc;
                        updatedDirectoryRecs.add(adp);
                    }
                    // DG-180 - Start :: Update Oscar ADP record
                    if(adp.External_System__c == 'Oscar') {
                        adp.Name = acc.FirstName + ' ' + acc.LastName;
                        adp.Address_Line_1__c = acc.BillingStreet;
                        adp.City__c = acc.BillingCity;
                        adp.State__c = acc.BillingState;
                        adp.Post_Code__c = acc.BillingPostalCode;
                        if(String.isBlank(acc.BillingCountry)) {
                            adp.Country__c = 'United Kingdom';
                        } else {
                            adp.Country__c = acc.BillingCountry;
                        }
                        adp.Date_of_Birth__c = acc.PersonBirthdate;
                        adp.Email__c = acc.PersonEmail;
                        adp.Mobile_Phone_Number__c = acc.PersonMobilePhone;
                        adp.Phone_Number__c = acc.PersonHomePhone;
                        adp.Salutation__c = acc.Salutation;
                        adp.First_Name__c = acc.FirstName;
                        adp.Last_Name__c = acc.LastName;
                        adp.Known_As__c = acc.Known_As__c;
                        adp.Status__c = acc.Account_Status__c;
                        adp.Gender__c = acc.Gender__pc;
                        updatedOscarLinkedDirectoryRecs.add(adp);
                    }
                    // DG-180 - End
                    if(adp.External_System__c == 'Pulse'&& !IntegrationsHelper.communityUserUpdate) {
                        Utilities.addIntegrationLogRecord('AccountTriggerHelper', 'updatePersonDirectoryRecords',
                                                      'The Pulse customer record for ' + adp.First_Name__c + ' ' + adp.Last_Name__c + ' needs to be manually updated, Pulse client code = ' + adp.External_System_Id__c, 
                                                      'Update Pulse Client');
                    }
                }
            }
        }
        
        if(!updatedDirectoryRecs.isEmpty()) {
            System.debug('SIMMO1986 - AccountTriggerHelper IntegrationsHelper.salesforceToSkiSync = ' + IntegrationsHelper.salesforceToSkiSync);
            IntegrationsHelper.salesforceToSkiSync = true;
            System.debug('SIMMO1986 - AccountTriggerHelper IntegrationsHelper.salesforceToSkiSync = ' + IntegrationsHelper.salesforceToSkiSync);
            Database.update(updatedDirectoryRecs);
        }
        // DG-180 - Start
        if(!updatedOscarLinkedDirectoryRecs.isEmpty()) {
            System.debug('Oscar - AccountTriggerHelper IntegrationsHelper.salesforceToOscarSync = ' + IntegrationsHelper.salesforceToOscarSync);
            IntegrationsHelper.salesforceToOscarSync = true;
            System.debug('Oscar - AccountTriggerHelper IntegrationsHelper.salesforceToOscarSync = ' + IntegrationsHelper.salesforceToOscarSync);
            Database.SaveResult[] srList = Database.update(updatedOscarLinkedDirectoryRecs, false);

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed, and add it to a list which can be passed to platform event
                    adpIdsForPlatformEvent.add(sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }

        if(!adpIdsForPlatformEvent.isEmpty()) {
            PlatformEventHelper.PushAccDirPersonMessage(adpIdsForPlatformEvent);
        }
        // DG-180 - End
    }
    // IE-628 End - Jon Simmonds 14/06/2022
    
    // IE-1161 Start - Sandeep Sekhon 28/07/2022
    public void updateIndividualRecords(Map<Id, Account> oldMap, List<Account> personAccounts) {
    
        List<Id> accountIds = new List<Id>();
        List<Id> individualIds = new List<Id>();  //acc.PersonIndividual
        
        for(Account acc: personAccounts) {
            if(oldMap.get(acc.Id).PersonBirthdate != acc.PersonBirthdate ||
               oldMap.get(acc.Id).PersonEmail != acc.PersonEmail ||
               oldMap.get(acc.Id).Salutation != acc.Salutation ||
               //IE-1325, COR-52: Detect the case change(lower to upper or upper to lower) also in name using compareTo method
               (oldMap.get(acc.Id).FirstName != null && acc.FirstName != null && oldMap.get(acc.Id).FirstName.compareTo(acc.FirstName) != 0) ||
               //COR-52
               (oldMap.get(acc.Id).FirstName == null && acc.FirstName != null  ) ||               
               oldMap.get(acc.Id).LastName.compareTo(acc.LastName) != 0               
            ) {
                accountIds.add(acc.Id);
                individualIds.add(acc.PersonIndividualId);              
            }
        }
        
        List<Individual> IndividualPersons = [Select Id, Salutation, FirstName, LastName, BirthDate, Email__c 
                                              From   Individual
                                              Where  Id IN :individualIds];
        
        Map<Id, List<Individual>> personIndividualsMap = new Map<Id, List<Individual>>();
        
        for(Individual indp: IndividualPersons) {
            if(personIndividualsMap.containsKey(indp.Id)) {
                personIndividualsMap.get(indp.Id).add(indp);
            } else {
                List<Individual> indpers = new List<Individual>();
                indpers.add(indp);
                personIndividualsMap.put(indp.Id, indpers);            
            }
        }
        
        List<Individual> updatedIndividualRecs = new List<Individual>();
        
        for(Account acc: personAccounts) {
            if(personIndividualsMap.containsKey(acc.PersonIndividualId)) {
                List<Individual> individualRecs = personIndividualsMap.get(acc.PersonIndividualId);
                
                for(Individual indiv: individualRecs) {                                            
                        indiv.BirthDate = acc.PersonBirthdate;
                        indiv.Email__c = acc.PersonEmail;
                        indiv.Salutation = acc.Salutation;
                        indiv.FirstName = acc.FirstName;
                        indiv.LastName = acc.LastName;

                        updatedIndividualRecs.add(indiv);                                  
                }
            }
        }
        
        if(!updatedIndividualRecs.isEmpty()) {        
            Database.update(updatedIndividualRecs);
        } 
    }
    // IE-1161 End - Sandeep Sekhon 28/07/2022

}