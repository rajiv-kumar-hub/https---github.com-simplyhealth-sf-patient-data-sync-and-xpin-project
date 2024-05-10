/**********************************************************************************************
    Trigger: AccountTrigger
    Date:    02/08/2017
    Name:    Jon Simmonds
    Details: Reengineered when the Action Plans package was uninstalled.
             This trigger was removed with the package so it has been reintroduced but with only
             our code.

***********************************************************************************************
***********************************************************************************************
Date         Name          Description
24/02/2017   S.Sekhon      Added After Insert context and call to class AutoCreateOpportunity
31/03/2017   S.Sekhon      Added to After Insert context call to class AutoCreateEntitlement
05/07/2017   S.Sekhon      CR-369: Added After Update context so an Entitlement is added to an Account 
                                   when it's updated from Prospect to Client.
21/09/2017   S.Sekhon      SF-11: Added revised call to AutoCreateEntitlement for Cash Plan.
                                  Added call to AutoCreateEntitlement for Dental.
31/10/2017   S.Sekhon      SF-334: The Dental and Cash Plan Entitlement Process is being consolidated
                                   therefore replaced call to CreateStdDentalEntitlement with 
                                   CreateStandardEntitlement.
04/11/2017   Jon Simmonds  Added the Account Trigger Contoller logic.
06/11/2017   S.Sekhon      Removed reference to redundant Opportunity call on:
                           AutoCreateOpportunity AutoCreateOppHelper = AutoCreateOpportunity.getInstance();
01/12/2017   S.Sekhon      SF-237: Add call to After Update event to populate new Dental and Cash Plan Broker
                                   fields on Opportunity.  
04/12/2017   S.Sekhon      SF-397: Activate Standard Entitlements and Remove call to CreateStdCashPlanEntitlement  
17/01/2018   S.Sekhon      SF-295: Added before delete context to expire Entitlements when Accounts are merged. 
31/01/2018   S.Sekhon      SF-421: Added Call to New method CreateMarketingEntitlement.
07/03/2018   Jon Simmonds  SF-575: Added Before Update to trigger.
                                   Added call to method to prevent Account from being changed from Broker to Prospect   
02/07/2019   P.Leman        Added platform event for synchronisation with Oscar          
19/02/2020   Jon Simmonds  SFM-478: Ensure the ETL data matching fields are kept in sync
17/03/2020   Jon Simmonds  Restructured the Trigger Controller logic for the ETL load, so nothing happens if controller off
20/05/2020   Jon Simmonds  SFM-1609: Added call to the setOriginalSource method      
30/06/2020   Jon Simmonds  SFM-1936: Only call methods in the After Trigger if there are corporate Accounts 
14/08/2020   S.Sekhon      SFM-2272: Added call Populate Birthdate Text field so it can be used for Global search 
                                     and in the Duplicate Rule for Person Account.
06/06/2022   Jon Simmonds  IE-628: Added call to helper method that updates related Ski Account Directory Person records   
29/07/2022   S.Sekhon      IE-1161: Added updateIndividualRecords to after update 
29/11/2023   Rajiv Kumar   DG-180:: Amended code to handle Oscar records.
***********************************************************************************************/
trigger AccountTrigger on Account (after insert, after update, after delete, after undelete, before delete, before update, before insert) {

    // Jon Simmonds 04/11/2017 - Retrieve Trigger Controller value for the Account Trigger 
    Trigger_Controller__c triggerController = Trigger_Controller__c.getOrgDefaults();
        
    // Jon Simmonds 14/09/2017 - Only run the trigger code if the trigger controller is set to True
    if(triggerController.Account_Trigger_On__c) {

              
        // Entitlements 
        AutoCreateEntitlement AutoCreateEntHelper = AutoCreateEntitlement.getInstance();
          
        // S.Sekhon 01/12/2017 - SF-237
        AccountTriggerHelper AccountTriggerObjHelper = AccountTriggerHelper.getInstance();
        
        //S.Sekhon 17/01/2018 - SF-295
        AccountMergeTriggerHelper AccountMergeObjHelper = AccountMergeTriggerHelper.getInstance();
           
        if (Trigger.isbefore) {
        
        // SFM-2272: 14/08/2020   S.Sekhon Create a List to hold Person Accounts 
        List<Account> PersonAccs = new List<Account>();
            
            if(Trigger.isInsert){
                system.debug('Trigger.isInsert'+Trigger.isInsert);
                
                // SFM-478 Jon Simmonds 19/02/2020 - Ensure data matching fields are kept in sync
                AccountTriggerObjHelper.syncDataMatchingFields(Trigger.new);
                
                // SFM-1609 Jon Simmonds 21/05/2020 - Set original source value
                AccountTriggerObjHelper.setOriginalSource(Trigger.new);
                
                // SFM-2272: 14/08/2020   S.Sekhon Fire for Person Accounts only 
                for (Account pAcc : trigger.New){ 
                    if(pAcc.isPersonAccount) {                    
                    PersonAccs.add(pAcc);          
                        
                    }
                }
                // If Person Account records exist 
                if(PersonAccs.size() > 0) {                
                    AccountTriggerObjHelper.setBirthdateText(PersonAccs);
                }
                // END SFM-2272
                
                AccountTriggerObjHelper.validateAccountBillingStreetAddr(trigger.new);
                UtilGenerateUUID.UtilGenerateUUIDKeyAccount(trigger.new);
            }
        
            // SF-575 Start - Jon Simmonds 07/03/2018 - Call method to prevent Account from being changed from Broker to Prospect
            if (Trigger.isUpdate) {            
                // Prevent the Account from being changed from Broker to Prospect
                AccountTriggerObjHelper.accountRecordtypeChangeCheck(Trigger.new, Trigger.OldMap);
                
                // SFM-478 Jon Simmonds 19/02/2020 - Ensure data matching fields are kept in sync
                AccountTriggerObjHelper.syncDataMatchingFields(Trigger.new);
                
                // SFM-2272: 14/08/2020   S.Sekhon Fire for Person Accounts if PresonBirthdate changes 
                for (Account pAcc : trigger.New){ 
                    if(pAcc.isPersonAccount) { 
                        if(pAcc.PersonBirthdate != trigger.oldmap.get(pAcc.id).PersonBirthdate) {
                            // Add the account to the List of changed accounts
                            PersonAccs.add(pAcc);  
                        }
                    }
                }  
                // If Person Account records exist 
                if(PersonAccs.size() > 0) {              
                    AccountTriggerObjHelper.setBirthdateText(PersonAccs);
                }
                // END SFM-2272
                
                //Code added by kishore-youperience : For validating billingstreet address length               
                AccountTriggerObjHelper.validateAccountBillingStreetAddr(trigger.new);
            }
            //Code added by kishore-youperience : For validating billingstreet address length
            
            // SF-575 End - Jon Simmonds 07/03/2018 - Call method to prevent Account from being changed from Broker to Prospect
        
            if (Trigger.isdelete) {      
                try {
                    AccountMergeObjHelper.ExpireMergedAccountEntitlement(trigger.Old);
                }
                catch (Exception e) {
 
                    for (Account account : trigger.Old) {
                        
                        if(e.getMessage().contains('There is currently an Active Open Ended Entitlement record')) {
                            account.addError('Merge failed: There is currently an Active Open Ended Entitlement record on the Account being merged, please amend or end date the entitlement on this Account accordingly before merging.');
                        }
                        
                        else if (e.getMessage().contains('The End Date on the new Entitlement record falls between the Start Date and End Date of the currently Active Entitlement record.')) {
                            account.addError('Merge failed: The Entitlement record end date to be merged fall between the Entitlement dates on the master Account. Please amend or end date the Entitlement on the Account to be merged accordingly. ');
                        }                       
                        else {
                            account.addError('Exception: ' + e.getMessage());
                        }
                        break;
                    }

                }
        
            }
        }


        if (Trigger.isAfter) {
        
            List<Account> corporateAccounts = new List<Account>();
        
            // SFM-1936 Start - Jon Simmonds 30/06/2020 - Create a list of all Corporate Accounts
            // Only run this code when Insert and Update as will hit a null exception when merge delete
            if(Trigger.isInsert || Trigger.isUpdate) {
                
                for(Account acc: Trigger.New) {
                    if(acc.isPersonAccount == false) {
                        corporateAccounts.add(acc);                      
                    }
                      
                }
                            
            }
            // SFM-1936 End - Jon Simmonds 30/06/2020 - Create a list of all Corporate Accounts
        
            if (Trigger.isInsert) {
            
                // SFM-1936 Start - Jon Simmonds 30/06/2020 - Only call these methods if there are corporate Accounts
                if(corporateAccounts.size() > 0) {
                    System.debug('SIMMO86 Account Trigger - Call methods in After Insert');
                    AutoCreateEntHelper.CreateStandardEntitlement(corporateAccounts);
                
                    // S.Sekhon 31/01/2018 - SF-421  
                    AutoCreateEntHelper.CreateMarketingEntitlement(corporateAccounts);
                }
                // SFM-1936 End - Jon Simmonds 30/06/2020 - Only call these methods if there are corporate Accounts
    
            }
                    
             if (Trigger.isUpdate) {
               
                // SFM-1936 Start - Jon Simmonds 30/06/2020 - Only call these methods if there are corporate Accounts
                if(corporateAccounts.size() > 0) {
                    AutoCreateEntHelper.CreateStandardEntitlement(corporateAccounts);
                    
                    // S.Sekhon 04/12/2017 - SF-237          
                    AccountTriggerObjHelper.UpdateOpportunityBroker (corporateAccounts, Trigger.OldMap);
                    
                    // S.Sekhon 31/01/2018 - SF-421  
                    AutoCreateEntHelper.CreateMarketingEntitlement(corporateAccounts);
                }
                // SFM-1936 End - Jon Simmonds 30/06/2020 - Only call these methods if there are corporate Accounts  

                // IE-628 Start - Call helper method to update related Ski Person Directory records
                List<Account> personAccounts = new List<Account>();
                Integration_Data_Syncing__c dataSyncing = Integration_Data_Syncing__c.getInstance();
                System.debug('SIMMO dataSyncing.Update_Salesforce_Data_To_Ski__c ' + dataSyncing.Update_Salesforce_Data_To_Ski__c);
                //DG-180 - Added additonal condition to check for Oscar custom setting
                System.debug('Oscar dataSyncing.Update_Salesforce_Data_To_Oscar__c ' + dataSyncing.Update_Salesforce_Data_To_Oscar__c);
                if(dataSyncing.Update_Salesforce_Data_To_Ski__c || dataSyncing.Update_Salesforce_Data_To_Oscar__c) {
                    System.debug('SIMMO Sync Person Account data to Directory object in Trigger');
                    for(Account acc: Trigger.New) {
                        if(acc.isPersonAccount == true) {
                            personAccounts.add(acc);
                        }
                    }
                    if(!personAccounts.isEmpty()) {
                        AccountTriggerObjHelper.updatePersonDirectoryRecords(Trigger.oldMap, personAccounts);
                        
                        // IE-1161                       
                        AccountTriggerObjHelper.updateIndividualRecords(Trigger.oldMap, personAccounts);
                    }
                }
                // IE-628 End - Call helper method to update related Ski Person Directory records                        
            }
            
            // Peter Leman - Youperience - 26/06/2019 - Push Event
            if (!Trigger.isDelete) {
                PlatformEventHelper.PushAccountMessage(trigger.newMap.keySet(), trigger.operationType.name());
            }
        }
           
    }
    
}