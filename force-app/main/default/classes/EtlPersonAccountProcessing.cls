/**
    Class:   EtlPersonAccountProcessing
    Author:  Jon Simmonds
    Date:    18/12/2019
    Purpose: For every Person Account Directory record attempt to find an existing Account record that matches on Lastname, Postcode, DOB
             and Initial.
             If a match is found link the existing Account to the Person Account Directory record.
             If no match is found create a new Account record and link it to the Person Account Directory record.
**/
/***********************************************************************************************
Date         Name          Description
13/07/2020   Rajiv Kumar   SFM-1952:: Added Individual object record type id when creating new records.
                           Also set the Marketing/Servicing confirmed in System field to Pulse (with Pulse
                           being the source system; this also allows the BMIS system to select records 
                           that have been updated in Salesforce when updating Pulse)
20/07/2020   Jon Simmonds  SFM-2188 - Added the First Name field to the Individual Map as this ensures the correct Individual
                           record is returned when there are twins in the same batch.
20/07/2020   Jon Simmonds  SFM-2191 - Amended the initialMatch method as it was returning a match when there was only one character
                           in the Directory records First Name value, even if the values did not match.
                           Also amended so when there is a full firstname is compares the first two characters
09/10/2020   Jon Simmonds  STB-96 - Added the Known_As__c field
09/05/2022   Arivu Sugumar IE-625 - Changed to handle data from Ski system using the MemberService custom API built in salesforce
08/12/2022   Rajiv Kumar   STB-4674  Updated Method createNewAccount to add Email_Bounce_Date__c and Email_Bounce_Reason__c field.
27/11/2023   Rajiv Kumar   DG-180:: Amended code to populate Care_Status__c.
***********************************************************************************************/
public class EtlPersonAccountProcessing {

    public static List<Id> individualAccountRecordTypeIds;
    public static RecordType individualProspectRT;
    public static RecordType individualClientRT;
    public static RecordType individualConsumerRT;
    public static List<Individual> individuals;
    public static Map<String, Individual> individualsMap;
    public static List<Etl_Exception__c> etlExceptions = new List<Etl_Exception__c>();
    
    // static initialization code block is only initialized once on the first use of the class
    static {
        individualAccountRecordTypeIds = new List<Id>();
        for(RecordType recType : [Select id, DeveloperName From recordtype
                                  Where sobjecttype = 'Account'
                                  And   (DeveloperName = 'Individual_Prospect' OR DeveloperName = 'Individual_Client')]) {
            individualAccountRecordTypeIds.add(recType.Id);
            if(recType.DeveloperName == 'Individual_Prospect') {
                individualProspectRT = recType;
            }
            if(recType.DeveloperName == 'Individual_Client') {
                individualClientRT = recType;
            }
        }
    }


    /**
        Class:   ToBeMatched
        Author:  Jon Simmonds
        Date:    16/12/2019
        Purpose: This is an inner class that holds the details for a Account_Directory_Person__c and Account that
                 need to be matched 
    **/
    public class ToBeMatched {
        public Account_Directory_Person__c accDir { get; private set; }
        public Account Account { get; private set; }
        public boolean matched { get; private set; }
        
        public ToBeMatched(Account_Directory_Person__c accDir, Account acc) {
            this.account = acc;
            this.accDir = accDir;
            this.Matched = false;
        }
        
        public void Match() {
            if (this.accDir != null && this.Account != null && this.Account.id != null) {
                this.accDir.Account__c = this.Account.id;
                this.accDir.Individual__c = this.Account.PersonIndividualId;
                this.matched = true;
            }
        }
    }
    
        
    /**
        Method:  linkPersonDirectoryToPersonAccounts
        Author:  Jon Simmonds
        Date:    10/12/2019
        Purpose: Initial method called from AccountDirectoryPersonTrigger to process Account_Directory_Person__c records.
                 Will attempt to match new Account_Directory_Person__c records to an existing Person Account record and link the
                 records, if no match found will create a new Person Account record and link to the Account_Directory_Person__c record.
    **/
    public static List<Account_Directory_Person__c> linkPersonDirectoryToPersonAccounts(List<Account_Directory_Person__c> personAccDirs) {
    
        List<Account_Directory_Person__c> personAccsDirsToLink = new List<Account_Directory_Person__c>();
        
        // If the Person Account is marked for Data Matching and not already linked to an Account add to list for processing
        for (Account_Directory_Person__c personAcc : personAccDirs) {
            personAcc.Name = personAcc.First_Name__c + ' ' + personAcc.Last_Name__c;      
            if(personAcc.Perform_Data_Matching__c) {
                if(String.isBlank(personAcc.Account__c)) {
                    personAccsDirsToLink.add(personAcc);
                } else {
                    personAcc.Perform_Data_Matching__c = false;
                }
            }
        }
        
        matchPersonDirectoryToPersonAccount(personAccsDirsToLink);
        
        if(etlExceptions.size() > 0) {
            Database.insert(etlExceptions);
            etlExceptions.clear();
        }
        
        return personAccDirs;
    }


    /**
        Method:  matchPersonDirectoryToPersonAccount
        Author:  Jon Simmonds
        Date:    10/12/2019
        Purpose: Will attempt to match new Account_Directory_Person__c records to an existing Person Account record and link the
                 records, if no match found will create a new Person Account record and link to the Account_Directory_Person__c record.
    **/
    public static void matchPersonDirectoryToPersonAccount(List<Account_Directory_Person__c> personAccsDirsToLink) {
    
        System.Debug('EtlPersonAccountProcessing: Inside matchPersonDirectoryToPersonAccount');
        
        individuals = new List<Individual>();
        individualsMap = new Map<String, Individual>();
        
        if (personAccsDirsToLink.size() > 0) {
        
            // Retrieve a list of Account records that match on Lastname, Postcode and DOB
            List<Account> accountCandidates = getAccountsThatMatchOnEverything(personAccsDirsToLink); 

            System.Debug('EtlPersonAccountProcessing: Strict Account Matches on Lastname, Postcode and DOB : ' + accountCandidates.size());

            // Create an Account map of matching Accounts
            // Key for each Account is Lastname, Postcode and DOB
            Map<string, Map<string, Map<Date, List<Account>>>> AccountLastNamePostCodeDOBMap = buildAccountLastNamePostCodeDOBMap(accountCandidates);
            
            List<Account> newAccounts = new List<Account>();
            List<ToBeMatched> accAndAccDirToBeMatched = new List<ToBeMatched>();          
            List<Account> accountsToUpdate = new List<Account>(); 
            
            for (Account_Directory_Person__c accDir: personAccsDirsToLink) {

                // Retrieve accounts that match the Account directory record on Lastname, Postcode, DOB and Initial
                List<Account> candidateMatcheswithInitialMatches = getCandidateMatchesWithInitialsMatch(AccountLastNamePostCodeDOBMap, accDir);
                
                System.debug('EtlPersonAccountProcessing: candidateMatcheswithInitialMatches size = ' + candidateMatcheswithInitialMatches.size());
                
                // If two Accounts are matched to the Account Directory record on Lastname, Postcode, DOB and Initial
                // And one of the Accounts is a Individual Client and the other is a Individual Prospect so duplicates of same individual
                // Remove the prospect account
                if (IsDuplicateClientAndProspectMatch(accDir, candidateMatcheswithInitialMatches)) {
                    if (candidateMatcheswithInitialMatches[0].RecordTypeId == individualProspectRT.Id) {
                        candidateMatcheswithInitialMatches.remove(0);
                    } else if (candidateMatcheswithInitialMatches[1].RecordTypeId == individualProspectRT.Id) {
                        candidateMatcheswithInitialMatches.remove(1);
                    }
                }

                if (candidateMatcheswithInitialMatches.isEmpty()) {
                    System.Debug('EtlPersonAccountProcessing: No Person Accounts matched so create a new Person Account record');
                    Account newAccount = createNewAccount(accDir);
                    newAccounts.add(newAccount);
                    addlastNamePostCodeDOB(newAccount, AccountLastNamePostCodeDOBMap);  
                    accDir.Data_Match_Alert_Type__c = 'NEW_ACCOUNT_CREATED';
                    accAndAccDirToBeMatched.add(new ToBeMatched(accDir, newAccount));
                } else {

                    Account matchedAccount;

                    if (candidateMatcheswithInitialMatches.size() == 1) {
                        System.Debug('EtlPersonAccountProcessing: One Person Account matched');
                        matchedAccount = candidateMatcheswithInitialMatches[0];
                    }
                    
                    if (candidateMatcheswithInitialMatches.size() > 1) {
                        DateTime mostRecentModified = Datetime.newInstance(1970, 1, 01);
                        for(Account acc: candidateMatcheswithInitialMatches) {
                            if(acc.LastModifiedDate > mostRecentModified) {
                                mostRecentModified = acc.LastModifiedDate;
                                matchedAccount = acc;
                            }
                        }
                        Utilities.addIntegrationLogRecord('EtlPersonAccountProcessing',
                                              'matchPersonDirectoryToPersonAccount',
                                              'Duplicate Person Accounts matched to Account Directory Person record for: ' +
                                              accDir.First_Name__c + ' ' + accDir.Last_Name__c + ', ' + accDir.Address_Line_1__c +
                                              ', ' + accDir.Post_Code__c + ', DOB: ' + accDir.Date_of_Birth__c.format() +
                                              ', Matched Person Account Id: ' + matchedAccount.Id, 
                                              null, 
                                              'Person Account Matching',
                                              accDir.External_System_Id__c);
                    }

                    // If matched to an existing Account record
                    if (matchedAccount.id != null) {
                
                        System.Debug('EtlPersonAccountProcessing: Set Id of the one Account matched');
                    
                        accDir.Account__c = matchedAccount.id;
                        accDir.Individual__c = matchedAccount.PersonIndividualId;
                        
                        // If the matched Account is a Prospect convert to a Client and update
                        if (matchedAccount.RecordTypeId == individualProspectRT.Id) {
                            // IE-625, IE-1205 - Account is in Ski system also
                            if (accDir.External_System__c == 'Ski' && matchedAccount.Ski_Data_Link__c == false) {
                                accountsToUpdate.add(new Account(Id = matchedAccount.Id, RecordTypeId = individualClientRT.Id, Ski_Data_Link__c = true));
                            }
                            else {
                                accountsToUpdate.add(new Account(Id = matchedAccount.Id, RecordTypeId = individualClientRT.Id));
                            }
                        } else {
                            // IE-625, IE-1205 - Account is in Ski system also
                            if (accDir.External_System__c == 'Ski' && matchedAccount.Ski_Data_Link__c == false) {
                                accountsToUpdate.add(new Account(Id = matchedAccount.Id, Ski_Data_Link__c = true));
                            }
                            //DG-180::START: Need to set the Oscar data link field, as on the initial load, data from Oscar will not be synced to Person account for existing records.
                            system.debug('Inside matchPersonDirectoryToPersonAccount before oscar data check');
                            if (accDir.External_System__c == 'Oscar') {
                                Boolean oscarDataLink = false, isPayer = false, updateRecord = false;
                                String careStatus, payerId, accDentalPracticeId, accTreatingDentistId, accOwningDentistId;

                                if(matchedAccount.Oscar_Data_Link__c == false){
                                    oscarDataLink = true;
                                    updateRecord = true;
                                }
                                system.debug('Inside matchPersonDirectoryToPersonAccount accDir.Care_Status__c - ' + accDir.Care_Status__c + ' matchedAccount.Care_Status__c ' + matchedAccount.Care_Status__c);
                                if(String.isNotBlank(accDir.Care_Status__c)&& 
                                    accDir.Care_Status__c != matchedAccount.Care_Status__c){
                                        careStatus = accDir.Care_Status__c; 
                                        updateRecord = true;
                                }
                                system.debug ('Inside matchPersonDirectoryToPersonAccount careStatus - ' + careStatus );
                                system.debug('Inside matchPersonDirectoryToPersonAccount accDir.IsPayer__c - ' + accDir.IsPayer__c + ' matchedAccount.IsPayer__c ' + matchedAccount.IsPayer__c);
                                if((accDir.IsPayer__c != matchedAccount.IsPayer__c)) {
                                    isPayer = accDir.IsPayer__c;
                                    updateRecord = true;
                                }
                                system.debug ('Inside matchPersonDirectoryToPersonAccount isPayer - ' + isPayer );

                                system.debug('Inside matchPersonDirectoryToPersonAccount accDir.External_Payer_Id__c - ' + accDir.External_Payer_Id__c + ' matchedAccount.Payer__c ' + matchedAccount.Payer__c);
                                if(String.isNotBlank(accDir.External_Payer_Id__c)){
                                    if(getPayerAccountLinkedToADPRecord(accDir) != matchedAccount.Payer__c){
                                        payerId = getPayerAccountLinkedToADPRecord(accDir);
                                        updateRecord = true;
                                    }
                                }
                                system.debug ('Inside matchPersonDirectoryToPersonAccount payerId - ' + payerId );

                                system.debug('Inside matchPersonDirectoryToPersonAccount accDir.Dental_Practice_Id__c - ' + accDir.Dental_Practice_Id__c + ' matchedAccount.Dental_Practice__c ' + matchedAccount.Dental_Practice__c);
                                //Get the Dentist and Dental Practice Ids linked to the patient record
                                if(String.isNotBlank(accDir.Dental_Practice_Id__c)){
                                    Map<String,String> dentistAndPracticeDetails = getDentistsAndPracticeLinkedToADP(accDir);
                                    if(dentistAndPracticeDetails.get('DentalPraticeId') != matchedAccount.Dental_Practice__c){
                                        accDentalPracticeId = dentistAndPracticeDetails.get('DentalPraticeId');
                                        updateRecord = true;
                                    }
                                    if(dentistAndPracticeDetails.get('TreatingDentistId') != matchedAccount.Treating_Dentist__c){
                                        accTreatingDentistId = dentistAndPracticeDetails.get('TreatingDentistId');
                                        updateRecord = true;
                                    }
                                    if(dentistAndPracticeDetails.get('OwningDentistId') != matchedAccount.Owning_Dentist__c){
                                        accOwningDentistId = dentistAndPracticeDetails.get('OwningDentistId');
                                        updateRecord = true;
                                    }
                                }
                                system.debug ('Inside matchPersonDirectoryToPersonAccount accDentalPracticeId - ' + accDentalPracticeId + ' - accTreatingDentistId - ' + accTreatingDentistId + '- accOwningDentistId - ' + accOwningDentistId);
                                
                                system.debug('Inside matchPersonDirectoryToPersonAccount before updateRecord data check - '+ updateRecord);
                                if(updateRecord){
                                    Account oscarAccData = new Account(Id = matchedAccount.Id);
                                    if(oscarDataLink){
                                        oscarAccData.Oscar_Data_Link__c = oscarDataLink;
                                    }
                                    if(String.isNotBlank(careStatus)){
                                        oscarAccData.Care_Status__c = careStatus;
                                    }
                                    if(isPayer){
                                        oscarAccData.IsPayer__c = isPayer;
                                    }
                                    if(String.isNotBlank(payerId)){
                                        oscarAccData.Payer__c = payerId;
                                    }
                                    if(String.isNotBlank(accDentalPracticeId)){
                                        oscarAccData.Dental_Practice__c = accDentalPracticeId;
                                    }
                                    if(String.isNotBlank(accTreatingDentistId)){
                                        oscarAccData.Treating_Dentist__c = accTreatingDentistId;
                                    }
                                    if(String.isNotBlank(accOwningDentistId)){
                                        oscarAccData.Owning_Dentist__c = accOwningDentistId;
                                    }

                                    accountsToUpdate.add(oscarAccData);

                                }
                                //DG-180::END
                            }
                            
                        }
                        
                    } else {
                        // Else matched to a newly created Account in this transaction so add to the ToBeMatched list
                        accAndAccDirToBeMatched.add(new ToBeMatched(accDir, matchedAccount));
                    }
                    
                    accDir.Data_Match_Alert_Type__c = 'LINKED_TO_EXISTING_ACCOUNT';
                }
            }

            // Create the Individual records
            insertIndividuals(individuals);
            
            // Link the new Account to the new Individual record
            for(Account newAcc: newAccounts) {
                // Start SFM-2188 Jon Simmonds 20/07/2020 - Add First Name when retrieving from the Individual map
                newAcc.PersonIndividualId = individualsMap.get(EtlStringHelpers.stripString(newAcc.FirstName) + EtlStringHelpers.stripString(newAcc.LastName) + EtlStringHelpers.stripString(newAcc.BillingPostalCode) + String.valueof(newAcc.PersonBirthdate)).Id;
                // End SFM-2188 Jon Simmonds 20/07/2020 - Add First Name when retrieving from the Individual map
            }
            
            // Create the new Accounts for the Person Account Directory records that did not match an existing Account
            insertAccounts(newAccounts);
            
            updateAccounts(accountsToUpdate);
            
            // Loop through the Accounts and Account Directory records that need to be matched
            for (ToBeMatched toMatch : accAndAccDirToBeMatched) {
                // Sets the Account Id on the Person Account Directory record
                toMatch.Match();
            }

        }
    }


    /**
        Method:  getAccountsThatMatchOnEverything
        Author:  Jon Simmonds
        Date:    16/12/2019
        Purpose: Retrieve a list of Accounts that match the batch of Account_Directory_Person__c records
                 on ALL field values in Lastname, Postcode and DOB.
    **/
    private static List<Account> getAccountsThatMatchOnEverything(List<Account_Directory_Person__c> personAccDirs) {
        
        Set<string> lastNames = new set<String>();
        Set<date> birthdates = new Set<date>();
        Set<string> postcodes = new Set<string>();
    
        for (Account_Directory_Person__c personAccDir : personAccDirs) {
        
            if(personAccDir.Date_of_Birth__c != null) {
                birthdates.add(personAccDir.Date_of_Birth__c);
            }
            
            if(personAccDir.Last_Name__c != null && !String.isEmpty(EtlStringHelpers.stripString(personAccDir.Last_Name__c))) {
                lastNames.add(EtlStringHelpers.stripString(personAccDir.Last_Name__c));
            }
                
            if(personAccDir.Post_Code__c != null && !String.isEmpty(EtlStringHelpers.stripString(personAccDir.Post_Code__c))) {
                postcodes.add(EtlStringHelpers.stripString(personAccDir.Post_Code__c));
            }
        }
        
        //IE-625, IE-1205 - Added new field Ski_Data_Link__c
        //DG-180: Added Oscar_Data_Link__c field
        return 
            [SELECT Id, Name, BillingPostalCode, PersonBirthdate, FirstName, LastName, 
                    RecordType.DeveloperName, Ski_Data_Link__c, LastModifiedDate, 
                    Data_Matching_FirstName__c, Data_Matching_LastName__c, Data_Matching_BillingPostCode__c, 
                    PersonIndividualId, Oscar_Data_Link__c, Payer__c, IsPayer__c, Care_Status__c, Dental_Practice__c, Treating_Dentist__c, Owning_Dentist__c
             FROM Account
             WHERE RecordTypeId IN :individualAccountRecordTypeIds
             AND Data_Matching_LastName__c IN :lastNames 
             AND Data_Matching_BillingPostCode__c IN :postcodes
             AND PersonBirthdate IN :birthdates
            ];
    }


    /**
        Method:  buildAccountLastNamePostCodeDOBMap
        Author:  Jon Simmonds
        Date:    16/12/2019
        Purpose: Build a map for the matched Accounts.
                 The key for each Account is Lastname, Postcode and DOB.
    **/
    private static Map<string, Map<string, Map<Date, List<Account>>>> buildAccountLastNamePostCodeDOBMap(List<Account> accountCandidates) {

        Map<string, Map<string, Map<Date, List<Account>>>> lastNamePostCodeDOBMap = new Map<string, Map<string, Map<Date, List<Account>>>>();
        
        for (Account acc : accountCandidates) {
            
            if (acc.Data_Matching_LastName__c != null && !string.isEmpty(acc.Data_Matching_LastName__c)
                && acc.Data_Matching_BillingPostCode__c != null && !string.isEmpty(acc.Data_Matching_BillingPostCode__c) 
                && acc.PersonBirthdate != null) {
                
                if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c) == null) {
                    lastNamePostCodeDOBMap.put(acc.Data_Matching_LastName__c, new Map<string, Map<Date, List<Account>>>());
                }
                if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c) == null) {
                    lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).put(acc.Data_Matching_BillingPostCode__c, new Map<Date, List<Account>>());
                }
                if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).get(acc.PersonBirthdate) == null) {
                    lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).put(acc.PersonBirthdate, new List<Account>());
                }
                lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).get(acc.PersonBirthdate).add(acc);
                
            }
        }
        
        return lastNamePostCodeDOBMap;
    }

    /**
        Method:  getCandidateMatchesWithInitialsMatch
        Author:  Jon Simmonds
        Date:    16/12/2019
        Purpose: Pass in a Account Directory record
                 Attempt to match the Account Directory with Accounts in the Map based on Lastname, Postcode and DOB AND Initial
                 Return a list of matched accounts
    **/
    private static List<Account> getCandidateMatchesWithInitialsMatch(Map<string, Map<string, Map<Date, List<Account>>>> lastNamePostCodeDOBMap, Account_Directory_Person__c accDir) {
    
        List<Account> possibleMatches = new List<Account>();
        
        if (lastNamePostCodeDOBMap.get(EtlStringHelpers.stripString(accDir.Last_Name__c)) != null 
            && lastNamePostCodeDOBMap.get(EtlStringHelpers.stripString(accDir.Last_Name__c)).get(EtlStringHelpers.stripString(accDir.Post_Code__c)) != null
            && lastNamePostCodeDOBMap.get(EtlStringHelpers.stripString(accDir.Last_Name__c)).get(EtlStringHelpers.stripString(accDir.Post_Code__c)).get(accDir.Date_of_Birth__c) != null) {
            
            for (Account acc : lastNamePostCodeDOBMap.get(EtlStringHelpers.stripString(accDir.Last_Name__c)).get(EtlStringHelpers.stripString(accDir.Post_Code__c)).get(accDir.Date_of_Birth__c)) {
                if (firstnameMatch(acc, accDir)) {
                    possibleMatches.add(acc);
                }
            }
            
        } 
        return possibleMatches;
    }
    

    /**
        Method:  firstnameMatch
        Author:  Jon Simmonds
        Date:    17/12/2019
        Purpose: Checks the first character of the first name between the Account Directory record and Account
                 Returns True if the first character matches on first name
                 
                 SFM-2191 Jon Simmonds 20/07/2020 - Amended the subString to 2 characters when there is only 1 character in the First Name value on the Directory record, this
                 is because with the subString set to 1 it was only comparing the | character so was always true, so will now compare | and first character.
                 When the First Name values have two characters or more the logic has been changed to compare the first two characters.
    **/
    public static boolean firstnameMatch(Account candidate, Account_Directory_Person__c accDir) {
        
        // Original code would have used the PSAAccountTypeMappings__c custom setting to retrieve the value Individual            
        String abbreviationsCategory = 'Individual';
        
        if(String.isNotBlank(candidate.FirstName) && String.isNotBlank(accDir.First_Name__c)) {
        
            // If there are two characters or more in the First Name values compare the full names else only compare the first character
            if(candidate.FirstName.Length() >= 2 && accDir.First_Name__c.Length() >= 2) {        
                return EtlStringHelpers.stripString(EtlStringHelpers.translateAbbreviations(candidate.FirstName, abbreviationsCategory)).substring(0,3).equalsIgnoreCase(EtlStringHelpers.stripString(EtlStringHelpers.translateAbbreviations(accDir.First_Name__c, abbreviationsCategory)).substring(0,3));
            }
            else if(candidate.FirstName.Length() >= 1 && accDir.First_Name__c.Length() >= 1) {
                return EtlStringHelpers.stripString(EtlStringHelpers.translateAbbreviations(candidate.FirstName, abbreviationsCategory)).substring(0,2).equalsIgnoreCase(EtlStringHelpers.stripString(EtlStringHelpers.translateAbbreviations(accDir.First_Name__c, abbreviationsCategory)).substring(0,2));
            }
            else {
                return false;
            }
        }
        else {
            return false;
        }
                          
    }


    /**
        Method:  IsDuplicateClientAndProspectMatch
        Author:  Jon Simmonds
        Date:    17/12/2019
        Purpose: Determines when two Accounts are matched to an Account Directory record by Lastname, Postcode, DOB and Initial
                 If one of the Accounts is a Individual Client and the other is a Individual Prospect return True as duplicates of same individual
    **/
    private static boolean IsDuplicateClientAndProspectMatch(Account_Directory_Person__c accDir, List<Account> candidateMatcheswithInitialMatches) {
        
        // If there are two potential Accounts matched on Lastname, Postcode, DOB and Initial
        if (candidateMatcheswithInitialMatches.size() == 2) {
        
            // If one of the Accounts is a Individual Client and the other is a Individual Prospect return True as duplicates of same individual
            if ((candidateMatcheswithInitialMatches[0].RecordType.DeveloperName == 'Individual_Client' && candidateMatcheswithInitialMatches[1].RecordType.DeveloperName == 'Individual_Prospect') || 
                (candidateMatcheswithInitialMatches[0].RecordType.DeveloperName == 'Individual_Prospect' && candidateMatcheswithInitialMatches[1].RecordType.DeveloperName == 'Individual_Client')) {
                return true;
            }
        }
        
        return false;
    }


    /**
        Method:  createNewAccount
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Create a new Account record for a Person Account Directory record
                 Create a new Individual record linked to new Account
    **/
    private static Account createNewAccount(Account_Directory_Person__c accDir) {
        Account acc = new Account();
        acc.Salutation = accDir.Salutation__c;
        acc.LastName = accDir.Last_Name__c;
        acc.FirstName = accDir.First_Name__c;
        acc.BillingStreet = accDir.Address_Line_1__c;
        acc.BillingCity = accDir.City__c;
        acc.BillingState = accDir.State__c;
        acc.BillingPostalCode = accDir.Post_Code__c;
        acc.BillingCountry = accDir.Country__c;
        acc.PersonBirthdate = accDir.Date_of_Birth__c;
        acc.PersonEmail = accDir.Email__c;
        acc.Gender__pc = accDir.Gender__c;
        acc.PersonMobilePhone = accDir.Mobile_Phone_Number__c;
        acc.PersonOtherPhone = accDir.Other_Phone_Number__c;
        acc.PersonHomePhone = accDir.Phone_Number__c;
        acc.National_Insurance_Number__pc = accDir.National_Insurance_Number__c;
        acc.Phone = accDir.Phone_Number__c;
        acc.Account_Status__c = accDir.Status__c;        
        acc.RecordTypeId = individualClientRT.Id;
        acc.External_Client_Id__pc = accDir.External_System_Id__c;        
        acc.Original_Source__c = accDir.External_System__c;
        if (accDir.External_System__c == 'Ski'){
            acc.Ski_Data_Link__c = true;
            if (String.isNotBlank(accDir.Sex__c)){
                acc.Sex__pc = accDir.Sex__c;
            }
        }
        acc.Marketing_Preference_Email__pc = accDir.Mkt_Pref_Email__c;
        acc.Marketing_Preference_Post__pc =  accDir.Mkt_Pref_Post__c;
        acc.Marketing_Preference_Phone__pc = accDir.Mkt_Pref_Phone__c;
        acc.Marketing_Preference_Sms__pc = accDir.Mkt_Pref_Sms__c;
        acc.Known_As__c = accDir.Known_As__c;
        
        acc.Data_Matching_BillingPostCode__c = EtlStringHelpers.stripString(acc.BillingPostalCode);
        acc.Data_Matching_LastName__c = EtlStringHelpers.stripString(acc.LastName);
        acc.Data_Matching_FirstName__c = EtlStringHelpers.stripString(acc.FirstName);
        acc.Email_Bounce_Date__c = accDir.Email_Bounce_Date__c;
        acc.Email_Bounce_Reason__c = accDir.Email_Bounce_Reason__c;
        //DG-180::START
        acc.Care_Status__c = accDir.Care_Status__c; 
        acc.IsPayer__c = accDir.IsPayer__c;
        if (accDir.External_System__c == 'Oscar'){
            acc.Oscar_Data_Link__c = true;
            //acc.Payer__c = String.isNotBlank(accDir.External_Payer_Id__c) ? getPayerAccountLinkedToADPRecord(accDir) : '';
            if(String.isNotBlank(accDir.External_Payer_Id__c)){
            	acc.Payer__c = getPayerAccountLinkedToADPRecord(accDir);     
            }
            //Get the Dentist and Dental Practice Ids linked to the patient record
            if(String.isNotBlank(accDir.Dental_Practice_Id__c)){
                Map<String,String> dentistAndPracticeDetails = getDentistsAndPracticeLinkedToADP(accDir);
                acc.Dental_Practice__c = dentistAndPracticeDetails.get('DentalPraticeId');
                acc.Treating_Dentist__c = dentistAndPracticeDetails.get('TreatingDentistId');
                acc.Owning_Dentist__c = dentistAndPracticeDetails.get('OwningDentistId');
            }
            
        }
        //DG-180::END
        Individual ind = new Individual();
        ind.RecordTypeId = Schema.SObjectType.Individual.getRecordTypeInfosByDeveloperName().get('Consumer').getRecordTypeId();
        ind.Salutation = accDir.Salutation__c;
        ind.firstname = accDir.First_Name__c;
        ind.lastname = accDir.Last_Name__c;
        ind.BirthDate = accDir.Date_of_Birth__c;
        ind.email__c = accDir.Email__c;
        ind.Marketing_Pref_Confirm_Date__c = accDir.Mkt_Pref_Confirm_Date__c;
        ind.Marketing_Pref_Confirmed_In_System__c = accDir.Mkt_Pref_Confirmed_In_System__c;
        ind.Marketing_by_Email__c = accDir.Mkt_Pref_Email__c;
        ind.Marketing_by_Phone__c = accDir.Mkt_Pref_Phone__c;
        ind.Marketing_by_Post__c = accDir.Mkt_Pref_Post__c;
        ind.Marketing_by_SMS__c = accDir.Mkt_Pref_Sms__c;
        ind.Servicing_Preference__c = accDir.Servicing_Preference__c;
        ind.Servicing_Pref_Confirm_Date__c = accDir.Srv_Pref_Confirm_Date__c;
        ind.Servicing_Pref_Confirmed_In_System__c = accDir.Srv_Pref_Confirmed_In_System__c;
        ind.Servicing_By_Email__c = accDir.Srv_Pref_Email__c;
        ind.Servicing_Online__c = accDir.Srv_Pref_Online__c;
        ind.Servicing_By_Phone__c = accDir.Srv_Pref_Phone__c;
        ind.Servicing_by_Post__c = accDir.Srv_Pref_Post__c;
        ind.Servicing_By_Sms__c = accDir.Srv_Pref_Sms__c;
                
        individuals.add(ind);
        individualsMap.put(EtlStringHelpers.stripString(accDir.First_Name__c) + EtlStringHelpers.stripString(accDir.Last_Name__c) + EtlStringHelpers.stripString(accDir.Post_Code__c) + String.valueof(accDir.Date_Of_Birth__c), ind);
        
        return acc;
    }


    /**
        Method:  addLastNamePostCodeDOB
        Author:  Jon Simmonds
        Date:    18/12/2019
        Purpose: Add a newly created Account record to the lastNamePostCodeDOBMap so it can be matched with any Account Directory records
                 that still have to be processed in this transaction 
    **/
    private static void addLastNamePostCodeDOB(Account acc, Map<string, Map<string, Map<Date, List<Account>>>> lastNamePostCodeDOBMap) {
    
        if (acc.Data_Matching_LastName__c != null && !string.isEmpty(acc.Data_Matching_LastName__c)
            && acc.Data_Matching_BillingPostCode__c != null && !string.isEmpty(acc.Data_Matching_BillingPostCode__c) 
            && acc.PersonBirthdate != null) {
            
            if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c) == null) {
                lastNamePostCodeDOBMap.put(acc.Data_Matching_LastName__c, new Map<string, Map<Date, List<Account>>>());
            }
            if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c) == null) {
                lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).put(acc.Data_Matching_BillingPostCode__c, new Map<Date, List<Account>>());
            }
            if (lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).get(acc.PersonBirthdate) == null) {
                lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).put(acc.PersonBirthdate, new List<Account>());
            }
            lastNamePostCodeDOBMap.get(acc.Data_Matching_LastName__c).get(acc.Data_Matching_BillingPostCode__c).get(acc.PersonBirthdate).add(acc);
            
        }
    }


    /**
        Method:  insertIndividuals
        Author:  Jon Simmonds
        Date:    17/01/2020
        Purpose: Insert a list of Individual records and capture any exceptions
                 Insert is based on partial success
    **/
    private static void insertIndividuals(List<Individual> individuals) {
    
        // Insert Individual records and allow partial success
        Database.SaveResult[] srList = Database.insert(individuals, false);

        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {              
                for(Database.Error err : sr.getErrors()) {
                    Etl_Exception__c etlEx = createException(err, 'Individual', 'insertIndividuals', sr.getId(), 501);
                    etlExceptions.add(etlEx);
                }
            }
        }
    }


    /**
        Method:  insertAccounts
        Author:  Jon Simmonds
        Date:    17/01/2020
        Purpose: Insert a list of Account records and capture exceptions
                 Insert is based on partial success 
    **/
    private static void insertAccounts(List<Account> accounts) {
    
        // Insert Account records and allow partial success
        Database.SaveResult[] srList = Database.insert(accounts, false);

        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {            
                for(Database.Error err : sr.getErrors()) {
                    Etl_Exception__c etlEx = createException(err, 'Account', 'insertAccounts', sr.getId(), 538);
                    etlExceptions.add(etlEx);
                }
            }
        }
    }


    /**
        Method:  updateAccounts
        Author:  Jon Simmonds
        Date:    17/01/2020
        Purpose: Update a list of Account records and capture exceptions
                 Update is based on partial success 
    **/
    private static void updateAccounts(List<Account> accounts) {
    
        // Update Account records and allow partial success
        Database.SaveResult[] srList = Database.update(accounts, false);

        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {             
                for(Database.Error err : sr.getErrors()) {
                    Etl_Exception__c etlEx = createException(err, 'Account', 'updateAccounts', sr.getId(), 574);
                    etlExceptions.add(etlEx);
                }
            }
        }
    }

    /**
        Method:  getPayerAccountLinkedToADPRecord
        Author:  Rajiv Kumar
        Date:    23/02/2024
        Purpose: DG-180: Added code to get the account linked to Patient's payer  
    **/
    public static Id getPayerAccountLinkedToADPRecord(Account_Directory_Person__c adpDetails){
        system.debug('Inside getPayerAccountLinkedToADPRecord method : '+ adpDetails.External_Payer_Id__c);
        return [
                SELECT Id, Account__c 
                FROM   Account_Directory_Person__c 
                WHERE  External_System_Id__c = :adpDetails.External_Payer_Id__c
            ].Account__c;
    }

    /**
        Method:  getDentistsAndPracticeLinkedToADP
        Author:  Rajiv Kumar
        Date:    23/02/2024
        Purpose: DG-180: Added code to get the practice and dentist linked to a Patient/Payer record   
    **/
    public static Map<String, String> getDentistsAndPracticeLinkedToADP(Account_Directory_Person__c adpDetails){
       
        system.debug('Inside getDentistLinkedToADPRecord method : '+ adpDetails.Dental_Practice_Id__c);
        List<Account> accDetails = [SELECT Id, External_ID__c, (SELECT id, External_ID__c FROM contacts) FROM account where External_ID__c = :adpDetails.Dental_Practice_Id__c];
        Map<String, String> dentistAndPracticeMap = new Map<String,String>();
       
        if (accDetails.size() > 0) {
        	dentistAndPracticeMap.put('DentalPraticeId', accDetails[0].Id);
            List<Contact> lstContacts = accDetails[0].Contacts;
            for (contact contactDetails : lstContacts) {
                system.debug('Contact: '+ contactDetails.External_ID__c);
                if(contactDetails.External_ID__c == adpDetails.Treating_Dentist_Id__c){
                    dentistAndPracticeMap.put('TreatingDentistId', contactDetails.Id);     
                }
                if(contactDetails.External_ID__c == adpDetails.Owning_Dentist_Id__c){
                    dentistAndPracticeMap.put('OwningDentistId', contactDetails.Id);     
                }
            }
        }

        return dentistAndPracticeMap;
    }

    /**
        Method:  getDentalPracticeLinkedToADPRecord
        Author:  Rajiv Kumar
        Date:    23/02/2024
        Purpose: DG-180: Added code to get the dental practice linked to a Patient/Payer record 
    **/
    public static Id getDentalPracticeLinkedToADPRecord(Account_Directory_Person__c adpDetails){
        system.debug('Inside getDentalPracticeLinkedToADPRecord method : '+ adpDetails.Dental_Practice_Id__c);
        return [
                SELECT Id 
                FROM   Account 
                WHERE  External_Id__c = :adpDetails.Dental_Practice_Id__c
            ].Id;
    }


    /**
        Method:  createException
        Author:  Jon Simmonds
        Date:    27/02/2020
        Purpose: Create an exception 
    **/
    private static Etl_Exception__c createException(Database.Error err, String objecttype, String methodName, String recordId, Integer lineNumber) {
    
        Etl_Exception__c etlEx = new Etl_Exception__c();
        
        etlEx.Status_Code__c = String.valueOf(err.getStatusCode());
        etlEx.Exception_Message__c = err.getMessage();
        etlEx.Exception_Fields__c = String.valueOf(err.getFields());
        etlEx.Sobject__c = objecttype;
        etlEx.Apex_Class__c = 'EtlPersonAccountProcessing';
        etlEx.Apex_Method__c = methodName;
        etlEx.Record_Id__c = recordId;
        etlEx.Line_Number__c = lineNumber;
        
        return etlEx;
    }                                              
}