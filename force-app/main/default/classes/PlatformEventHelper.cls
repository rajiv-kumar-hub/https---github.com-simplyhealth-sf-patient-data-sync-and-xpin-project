/**********************************************************************************************
    Class:   PlatformEventHelper
    Date:    02/07/2019
    Name:    Peter Leman - Youperience
    Project: Pivotal Replacement
    
***********************************************************************************************
***********************************************************************************************
Date         Name          Description
02/07/2019   P.Leman       Initial draft
30/08/2019   J.O'Hare      Updated Platform Event Fields
14/01/2020   Youperience   Change the DeveloperName to Name field when referencing Record Types
02/03/2020   Youperience   Suppress Account Team Platform Event Messages when associated Account is a Corporate Partner
09/04/2020   S.Sekhon      Add Debug to trap Attempt to de-reference a null object error.
11/04/2020   S.Sekhon      SF-1573: Amend method PushContactMessage to prevent exception Attempt to de-reference a null object error
                                    when no recordtype on contact.
29/11/2023   Rajiv Kumar   DG-180:: Added PushAccDirPersonMessage method to push ADP records to Oscar.
***********************************************************************************************/
public class PlatformEventHelper{

    public static boolean userFirstRun = true;
    public static boolean accountFirstRun = true;
    public static boolean accountTeamFirstRun = true;
    public static boolean contactFirstRun = true;
    public static boolean regFacBenefitFirstRun = true;
    public static string ParentName;
    public static Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
    public static Platform_Event_Controller__c objSendPersonAccData = Platform_Event_Controller__c.getValues('Send Person Account Data');
    @testVisible private static List<ContactUpdateForOscar__e> ContactOscarEvents = new List<ContactUpdateForOscar__e>();
    @testVisible private static List<UserUpdateForOscar__e> UserOscarEvents = new List<UserUpdateForOscar__e>();
    @testVisible private static List<AccountUpdateForOscar__e> AccountOscarEvents = new List<AccountUpdateForOscar__e>();
    @testVisible private static List<RegFacBenefitUpdateForOscar__e> RegFacBenefitEvents = new List<RegFacBenefitUpdateForOscar__e>();
    @testVisible private static List<AccountTeamMemberUpdateForOscar__e> AccountTeamMemberOscarEvents = new List<AccountTeamMemberUpdateForOscar__e>();
    @testVisible private static List<PersonAccountUpdate__e> AccDirPersonOscarEvents = new List<PersonAccountUpdate__e>(); //DG-180
    @testVisible private static List<Database.SaveResult> adpProcessResults; //DG-180
    @testVisible private static List<Database.SaveResult> accProcessResults; //DG-180

    // @future (callout=true)
    public static void PushAccountMessage(Set<Id> AccountList, String myAction){
    
        system.debug('@@@ API : Account Platform Event - Process Starts');
        Set<String> usrSet = new Set<string>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        //Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
                
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        If(!usrSet.contains(UserInfo.getUserName()) && objSendToOscar !=NULL && objSendToOscar.Send__c ) {
        
           // List<AccountUpdateForOscar__e> AccountOscarEvents = new List<AccountUpdateForOscar__e>();
            
            for(Account myAccount : [SELECT Id, RecordType.Name, Parent.Name, Parent.Corporate_Partner__c ,External_ID__c, Practice_Type__c, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                                        Website, Practice_Email__c, Fax, Phone, Company_Type__c, Description, Practice_Emergency_Phone__c, Practice_Main_Phone__c, Practice_Office_Phone__c, Corporate_Partner__c, Territory_Post_Code__c
                                        FROM Account 
                                        WHERE Id IN :AccountList]){
                                        
                                            String strRecordDevName = Schema.SObjectType.Account.getRecordTypeInfosById().get(myAccount.RecordTypeId).getDeveloperName();
                                            system.debug('@@@ API : Account Platform Event - Found Record Type : ' + strRecordDevName ); 
                                            
                                            if (myAccount.Parent.Corporate_Partner__c) {ParentName = myAccount.Parent.Name;} Else {ParentName = Null;}                               
                                            
                                            if (strRecordDevName == 'Dental_Practice' && (myAccount.Practice_Type__c == 'Dental Practice'  || myAccount.Practice_Type__c == 'Residence' || myAccount.Practice_Type__c == 'Ex-Dental Practice' || myAccount.Practice_Type__c == 'Corporate Partnerships' || myAccount.Practice_Type__c == 'Prospect' || myAccount.Practice_Type__c == 'Other')) {
                                                AccountOscarEvents.add(new AccountUpdateForOscar__e(
                                                    AccountID__c = myAccount.Id,
                                                    Action__c = myAction,
                                                    CorporatePartner__c = myAccount.Corporate_Partner__c,
                                                    AddressName__c = myAccount.Name,
                                                    AddressStreet__c = myAccount.BillingStreet,
                                                    Country__c = myAccount.BillingCountry,
                                                    PostCode__c = myAccount.BillingPostalCode,
                                                    PostTown__c = myAccount.BillingCity,
                                                    County__c = myAccount.BillingState,
                                                    Email__c = myAccount.Practice_Email__c,
                                                    LocationID__c = myAccount.External_ID__c,
                                                    LocationType__c = myAccount.Practice_Type__c,
                                                    RecordType__c = myAccount.RecordType.Name,
                                                    ParentAccountName__c = ParentName,
                                                    Notes__c = myAccount.Description,
                                                    Practice_Emergency_Phone__c = myAccount.Practice_Emergency_Phone__c,
                                                    Practice_Main_Phone__c = myAccount.Practice_Main_Phone__c,
                                                    Practice_Office_Phone__c = myAccount.Practice_Office_Phone__c,
                                                    TerritoryPostCode__c = MyAccount.Territory_Post_Code__c,
                                                    Website__c = myAccount.Website
                                                ));
                                            }                                        
                                        }
    
            // Call method to publish events
            if(!AccountOscarEvents.isEmpty()){
                accProcessResults = EventBus.publish(AccountOscarEvents);
                AccountOscarEvents.clear();
            	// Inspect publishing result for each event
                for (Database.SaveResult sr : accProcessResults) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }       
                }    
            }
            
            
            system.debug('@@@ API : Account Platform Event - Process Ends');
            
            
        }
    }

    // @future (callout=true)
    public static void PushContactMessage(Set<Id> ContactList, String myAction){
    
        system.debug('@@@ API : Contact Platform Event - Process Starts');
        //List<String> userNameLst = [SELECT Username__c FROM Interface_User__mdt];
        Set<String> usrSet = new Set<string>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        //Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
                        
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True       
        If(!usrSet.contains(UserInfo.getUserName()) && objSendToOscar !=NULL  && objSendToOscar.Send__c) {
        
            //List<ContactUpdateForOscar__e> ContactOscarEvents = new List<ContactUpdateForOscar__e>();
            
            for(Contact myContact : [SELECT Id, RecordType.Name, Account.Parent.Name, Account.External_ID__c, External_ID__c, Account.Id, GDC_Number__c, Key_Client__c, MobilePhone, HomePhone,
                                            Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingCountry,
                                            Account.BillingState, Salutation, Firstname, Lastname, Other_Initials_Middle_Name__c, Gender__c, Birthdate, Email,
                                            Simplyhealth_Group_Mailings__c, Mailings__c, Mail_Patients_about_Implants__c, Associated_Companies__c, RecordTypeId
                                     FROM   Contact 
                                     WHERE  Id IN :ContactList])
            {
                                        
                system.debug('@@@ API : Contact Platform Event - myContact Record Type : ' + myContact.RecordType.Name );
                system.debug('@@@ API : Contact Platform Event - myContact contact Id : ' + myContact.Id + ' Account Id ' + myContact.Account.Id);
                system.debug('@@@ API : Contact Platform Event - myContact Name : ' + myContact.Firstname + '  '+ myContact.Lastname);
                
                if (myContact.recordTypeId <> null ) {
                                 
                    String strRecordDevName = Schema.SObjectType.Contact.getRecordTypeInfosById().get(myContact.RecordTypeId).getDeveloperName();
                    system.debug('@@@ API : Contact Platform Event - Found Record Type : ' + strRecordDevName );
                                                
                    if (strRecordDevName  == 'Dentist') {
                        
                        ContactOscarEvents.add(new ContactUpdateForOscar__e (
                        ContactID__c = myContact.Account.External_ID__c,
                        Action__c = myAction,
                        External_ID__c = myContact.External_ID__c,
                        ParentAccountName__c = myContact.Account.Parent.Name,
                        RecordType__c = myContact.RecordType.Name,
                        AddressName__c = myContact.Account.Name,
                        AddressStreet__c = myContact.Account.BillingStreet,
                        AssociatedCompanies__c = myContact.Associated_Companies__c,
                        AxaMailings__c = myContact.Simplyhealth_Group_Mailings__c,
                        AccountID__c = myContact.Account.Id,
                        Country__c = myContact.Account.BillingCountry,
                        County__c = myContact.Account.BillingState,
                        DenplanMailings__c = myContact.Mailings__c,
                        DOB__c = myContact.Birthdate,
                        Email__c = myContact.Email,
                        Firstname__c = myContact.Firstname,
                        GDCNo__c = myContact.GDC_Number__c,
                        KeyClient__c = myContact.Key_Client__c,
                        ImplantMailings__c = myContact.Mail_Patients_about_Implants__c,
                        Initials__c = myContact.Other_Initials_Middle_Name__c,
                        Lastname__c = myContact.Lastname,
                        Postcode__c = myContact.Account.BillingPostalCode,
                        PostTown__c = myContact.Account.BillingCity,
                        Sex__c = myContact.Gender__c,
                        Title__c = myContact.Salutation,
                        Mobile__c = myContact.MobilePhone,
                        Home_Phone__c = myContact.HomePhone ));
                    }                                    
                }
            }        
    
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(ContactOscarEvents);
            
            system.debug('@@@ API : Contact Platform Event - Process Ends');
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }       
            }
        }
    }
    
    // @future (callout=true)
    public static void PushUSerMessage(Set<Id> UserList, String myAction){
    
        system.debug('@@@ API : User Platform Event - Process Starts');
        Set<String> usrSet = new Set<string>();
        Set<String> profileNameSet = new set<String>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        //retrieve platform event professional dental users
        for(Professional_Dental_User_profile__mdt profileNamesObj : [SELECT ProfileName__c FROM Professional_Dental_User_profile__mdt]){
            profileNameSet.add(profileNamesObj.ProfileName__c );
        }
        
        
        //Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
                        
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        If(!usrSet.contains(UserInfo.getUserName()) && objSendToOscar !=NULL && objSendToOscar.Send__c) {
        
            //List<UserUpdateForOscar__e> UserOscarEvents = new List<UserUpdateForOscar__e>();
            
            for(User myUser : [SELECT Id, Firstname, Lastname, Legacy_ID__c, Username, Email ,IsActive, Department, Phone, Fax, SenderEmail, MobilePhone, Title, ManagerId, 
                                        Manager.Firstname, Manager.Lastname, Manager.Legacy_ID__c, External_ID__c
                                        FROM User 
                                        WHERE Id IN :UserList AND Profile.Name IN:profileNameSet]){
                                            UserOscarEvents.add(new UserUpdateForOscar__e(
                                                isActive__c = myUser.IsActive,
                                                Action__c = myAction,
                                                SFDC_Username__c = myUser.Username,
                                                User_Firstname__c = myUser.Firstname,
                                                User_Lastname__c = myUser.Lastname,
                                                UserLegacyID__c = myUser.Legacy_ID__c,
                                                UserId__c = myUser.External_ID__c,
                                                Department__c = myUser.Department,
                                                Phone__c = myUser.Phone,
                                                EMail__c = myUser.Email,
                                                Mobile__c = myUser.MobilePhone,
                                                JobTitle__c = myUser.Title                                
                                            ));                               
                                        }
    
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(UserOscarEvents);
            
            system.debug('@@@ API : User Platform Event - Process Ends');
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }       
            }
        }
    }
    
    //For pushing regfac message
    // @future (callout=true)
    public static void PushRegFacBenfitMessage(Set<Id> regFacBenefitList, String myAction){
    
        //List<RegFacBenefitUpdateForOscar__e> RegFacBenefitEvents = new List<RegFacBenefitUpdateForOscar__e>();
        Set<String> usrSet = new Set<string>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        //Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
        
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        If(!usrSet.contains(UserInfo.getUserName()) && objSendToOscar !=NULL && objSendToOscar.Send__c) {
        
            for(Reg_Fac_Benefit__c myRegFacBeneFit : [SELECT Id, Name, A_Allowance__c, Additional_Benefits__c, B_Allowance__c, C_Allowance__c, D_Allowance__c, E_Allowance__c, External_ID__c, Legacy_ID__c,Reg_Fac__r.Notes__c, Reg_Fac__r.Name, Reg_Fac__r.External_ID__c,Treating_Item__c
                                        FROM Reg_Fac_Benefit__c WHERE Id IN :regFacBenefitList ALL ROWS]){
                                        RegFacBenefitEvents.add(new RegFacBenefitUpdateForOscar__e(A_Allowance__c = myRegFacBeneFit.A_Allowance__c,
                                        Additional_Benefits__c = myRegFacBeneFit.Additional_Benefits__c,
                                        Reg_Fac_Benefit__c = myRegFacBenefit.Name,
                                        B_Allowance__c = myRegFacBeneFit.B_Allowance__c,
                                        C_Allowance__c = myRegFacBeneFit.C_Allowance__c,
                                        D_Allowance__c = myRegFacBeneFit.D_Allowance__c,
                                        E_Allowance__c = myRegFacBeneFit.E_Allowance__c,
                                        External_ID__c = myRegFacBeneFit.External_ID__c,
                                        Reg_Fac__c = myRegFacBeneFit.Reg_Fac__r.External_ID__c,
                                        Treating_Item__c = myRegFacBeneFit.Treating_Item__c,
                                        Action__c = myAction
                                        )); 
            }
            
            
            List<Database.SaveResult> results = EventBus.publish(RegFacBenefitEvents);
            system.debug('@@@ API : User Platform Event - Process Ends');
            // Inspect publishing result for each event
            
            for (Database.SaveResult sr : results) {
            System.debug('published event enter.');
                if(sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }       
            }
        }
    }        
        
    //For pushing account team message
    // @future (callout=true)
    public static void PushAccountTeamMemberMessage(Set<Id> accTeamMemIdSet, String myAction){
        
        // Running the Platform event publish
        system.debug('@@@ API : AccountTeamMember Platform Event - Process Starts');
        Set<String> usrSet = new Set<string>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        //Platform_Event_Controller__c objSendToOscar = Platform_Event_Controller__c.getValues('Send To Oscar');
        
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True
        If(!usrSet.contains(UserInfo.getUserName()) && objSendToOscar !=NULL && objSendToOscar.Send__c) {

           //List<AccountTeamMemberUpdateForOscar__e> AccountTeamMemberOscarEvents = new List<AccountTeamMemberUpdateForOscar__e>();
            
            for(AccountTeamMember myAccountTeamMember : [SELECT AccountId, Account.Name, Account.External_ID__c, Account.Corporate_Partner__c,
                                                         UserId, User.Firstname, User.Lastname, User.External_ID__c,
                                                         TeamMemberRole, LastModifiedDate 
                                                         FROM AccountTeamMember WHERE Id in: accTeamMemIdSet ALL ROWS]){
                                                             if(!myAccountTeamMember.Account.Corporate_Partner__c){
                                                             AccountTeamMemberOscarEvents.add(new AccountTeamMemberUpdateForOscar__e(
                                                                 Action__c = myAction,
                                                                 Account_External_Id__c = myAccountTeamMember.Account.External_ID__c,
                                                                 User_External_Id__c = myAccountTeamMember.User.External_ID__c,
                                                                 TeamMemberRole__c = myAccountTeamMember.TeamMemberRole
                                                             ));
                                                             }
                                                         }
            
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(AccountTeamMemberOscarEvents);
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }       
            }
        }        
    }
     
    
    //For creating and updating contacts in individual
    public static void createUpdatingIndividual(List<Contact> contactLst){
        Individual individualSObj = new Individual();
        Individual individualUpdateSObj = new Individual();
        Contact contactUpdateIndIdObj = new Contact();
        Map<String,Individual> IndividualEmailMap = new Map<String,Individual>();
        Map<String,Contact> contactEmailMap = new Map<String,Contact>();
        List<Individual> individualLst = new List<Individual>();
        List<Individual> individualUpdLst = new List<Individual>();
        List<Contact> contactIndividualIdUpdateLst = new List<Contact>();
        Map<String,Contact> contactEmailExistingMap = new Map<String,Contact>();
        Contact contUpdateSObj = new Contact();
        Set<String> IndividualEmailSet = new Set<String>();
        Set<String> individualUpdEmailSet = new Set<String>();
        Map<String,String> individualEmailIdMap = new Map<String,String>();
       
        Id individualRecordTypeId = Schema.SObjectType.Individual.getRecordTypeInfosByDeveloperName().get('Professional').getRecordTypeId();
            for(Contact contEmailSObj : contactLst){
                if(contEmailSObj.Email != Null) {
                contactEmailMap.put(contEmailSObj.Email,contEmailSObj);
                }
            }
            if(!contactEmailMap.isEmpty()){
                for(Individual indsObj : [SELECT Id,FirstName,LastName,Email__c FROM Individual WHERE RecordTypeId = :individualRecordTypeId and Email__c IN :contactEmailMap.keySet()]){
                    IndividualEmailMap.put(indsObj.Email__c,indsObj);
                }
            }
            
            //Check contact exist or not in individual object.
            for(Contact contSObj : contactLst){
                if((!IndividualEmailMap.containsKey(contSObj.Email)) && contSObj.Email != Null){
                    if(!individualEmailSet.contains(contSObj.Email)){
                        individualSObj = new Individual();
                        individualSObj.RecordTypeId = individualRecordTypeId;
                        individualSObj.FirstName=contSObj.FirstName;
                        individualSObj.LastName=contSObj.LastName;
                        individualSObj.Email__c=contSObj.Email;
                        individualSObj.Marketing_by_Email__c = contSObj.Marketing_Preference_Email__c;
                        individualSObj.Marketing_by_Phone__c = contSObj.Marketing_Preference_Phone__c;
                        individualSObj.Marketing_by_Post__c = contSObj.Marketing_Preference_Post__c;
                        individualSObj.Marketing_by_SMS__c = contSObj.Marketing_Preference_SMS__c;
                        IndividualEmailSet.add(contSObj.Email);
                        individualLst.add(individualSObj);
                    }  
                 }
                
                //if contact email exists in individual object then update the individual details with contact details.
                 if(IndividualEmailMap.containsKey(contSObj.Email) && (contSObj.LastName != IndividualEmailMap.get(contSObj.Email).LastName || contSObj.FirstName != IndividualEmailMap.get(contSObj.Email).FirstName)){
                     if(!individualUpdEmailSet.contains(contSObj.Email)){
                         individualUpdateSObj = new Individual(Id = IndividualEmailMap.get(contSObj.Email).Id);
                         individualUpdateSObj.Firstname = contSObj.FirstName; 
                         individualUpdateSObj.Lastname = contSObj.LastName;
                         individualUpdateSObj.Email__c = contSObj.Email;
                         individualUpdEmailSet.add(contSObj.Email);
                         individualUpdLst.add(individualUpdateSObj);
                     }
                 }
            }
            //if contact is not exist in individual then we will create individual
            if(!individualLst.isEmpty()){
                database.Insert(individualLst);
            }
            //for populating map of individual
            if(!individualLst.isEmpty()){
                for(Individual indSObj : [SELECT Id,Name,Email__c FROM Individual WHERE Id IN : individualLst]){
                    individualEmailIdMap.put(indSObj.Email__c,indSObj.Id);
                } 
            }
            
            
            //if contact is exist in individual then we will update individual
            if(!individualUpdLst.isEmpty()){
                database.update(individualUpdLst);
            }
            system.debug('individualLst is:'+individualLst);
            
            //update individualId in contact
            if(!individualLst.isEmpty()){
                for(Contact contSObj : contactLst){
                    if(individualEmailSet.contains(contSObj.Email)){
                        contactUpdateIndIdObj = new Contact(Id=contSObj.Id);
                        contactUpdateIndIdObj.IndividualId = individualEmailIdMap.get(contSObj.Email);
                        contactIndividualIdUpdateLst.add(contactUpdateIndIdObj);        
                    }
                }
            }
            
            if(!IndividualEmailMap.isEmpty()){
                for(Contact contSObj : contactLst){
                    if(IndividualEmailMap.containsKey(contSObj.Email)){
                        contUpdateSObj = New Contact(Id = contSObj.Id,IndividualId = IndividualEmailMap.get(contSObj.Email).Id);
                        contactIndividualIdUpdateLst.add(contUpdateSObj);
                    }
                }
            }
            
           
            if(!contactIndividualIdUpdateLst.isEmpty()){
                database.update(contactIndividualIdUpdateLst);
            }
    }

    //DG-180 - Start :: Push ADP records to Oscar
    // @future (callout=true)
    public static void PushAccDirPersonMessage(Set<Id> accDirPersonList){
    
        system.debug('@@@ API : ADP Platform Event - Process Starts');
        Set<String> usrSet = new Set<string>();
        for(Interface_User__mdt usrSObj : [SELECT Username__c FROM Interface_User__mdt]){
            usrSet.add(usrSObj.UserName__c);
        }
        
        // check that logged in user is NOT in the "Exclude from Sending Platform Events" list and Custom Setting for Send to Oscar is True       
        If(!usrSet.contains(UserInfo.getUserName()) && objSendPersonAccData !=NULL  && objSendPersonAccData.Send__c) {
        
            for(Account_Directory_Person__c accDirPersonRec : [SELECT Id, Address_Line_1__c, City__c, Country__c, Date_of_Birth__c, External_System_Id__c, Email__c, External_System__c, 
                                            First_Name__c, Last_Name__c, Mobile_Phone_Number__c, Phone_Number__c, Post_Code__c, Salutation__c, State__c, Gender__c
                                     FROM   Account_Directory_Person__c
                                     WHERE  Id IN :accDirPersonList])
            {
                AccDirPersonOscarEvents.add(new PersonAccountUpdate__e (
                                                Address_Line_1__c = accDirPersonRec.Address_Line_1__c,
                                                Action__c = 'after_update',
                                                City__c = accDirPersonRec.City__c,
                                                Country__c = accDirPersonRec.Country__c,
                                                Date_of_Birth__c = accDirPersonRec.Date_of_Birth__c,
                                                Email__c = accDirPersonRec.Email__c,
                                                External_Person_Id__c = accDirPersonRec.External_System_Id__c,
                                                External_System__c = accDirPersonRec.External_System__c,
                                                First_Name__c = accDirPersonRec.First_Name__c,
                                                Last_Name__c = accDirPersonRec.Last_Name__c,
                                                Mobile_Phone_Number__c = accDirPersonRec.Mobile_Phone_Number__c,
                                                Phone_Number__c = accDirPersonRec.Phone_Number__c,
                                                Post_Code__c = accDirPersonRec.Post_Code__c,
                                                Salutation__c = accDirPersonRec.Salutation__c,
                                                State__c = accDirPersonRec.State__c,
                                                Gender__c =  accDirPersonRec.Gender__c
                                                )
                                            );
            }        
    
            // Call method to publish events
            if(!AccDirPersonOscarEvents.isEmpty()){
            	adpProcessResults = EventBus.publish(AccDirPersonOscarEvents);
                AccDirPersonOscarEvents.clear();
                system.debug('@@@ API : ADP Platform Event - Process Ends');
                // Inspect publishing result for each event
                for (Database.SaveResult sr : adpProcessResults) {
                    if (sr.isSuccess()) {
                    System.debug('Successfully published event.' + sr.getId());
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }       
                }
            }
        } 
    } 
}