/**
    Author:  Jon Simmonds
    Date:    06/12/2019
    Purpose: When the ETL from Pulse to Salesforce loads person details the data is inserted or updated on the Account_Directory_Person__c
             object which means it will use this trigger to manage the load of the data.
             The main purpose of the trigger logic is the deduplication of person accounts and to manage the links between the 
             custom Account_Directory_Person__c object and standard Account object.

Amendments:             
Date         Name          Description
14/06/2022   Jon Simmonds  IE-628 and IE-780 Ensure Salesforce to Ski updates do not fire any logic in the trigger.
                           The IntegrationsHelper.salesforceToSkiSync static variable is set before an update to the
                           Account_Directory_Person__c records when manually updated from the UI.

**/
Trigger AccountDirectoryPersonTrigger on Account_Directory_Person__c (before insert, before update, after insert, after update) {

    System.debug('In AccountDirectoryPersonTrigger IntegrationsHelper.salesforceToSkiSync = ' + IntegrationsHelper.salesforceToSkiSync);

    if(FeatureFlagsInstance.Instance.AccountPersonTriggerActive) {
        
        if(Trigger.isBefore) {
        
            if(Trigger.isInsert) {
                EtlEmailInvalidator.invalidatePersonAccountEmailAddresses(Trigger.New);
                EtlPersonAccountProcessing.linkPersonDirectoryToPersonAccounts(Trigger.New);             
            }
            // DG-180
            if(Trigger.isUpdate && !(IntegrationsHelper.salesforceToSkiSync || IntegrationsHelper.salesforceToOscarSync)) {              
                EtlEmailInvalidator.invalidatePersonAccountEmailAddresses(Trigger.New);
                EtlPersonAccountProcessing.linkPersonDirectoryToPersonAccounts(Trigger.New);
            }
            else {
                System.Debug('AccountDirectoryPersonTrigger DO NOT UPDATE IN BEFORE TRIGGER');
            }
        }
        
                
        if (Trigger.isAfter) {
            
            //DG-180 - Added additonal condition to check for Oscar custom setting
            Integration_Data_Syncing__c dataSyncing = Integration_Data_Syncing__c.getInstance();
            System.debug('SIMMO dataSyncing.Sync_ADP_Data_With_Person_Account__c ' + dataSyncing.Sync_ADP_Data_With_Person_Account__c);
                                                                      
            if(Trigger.isInsert) {
                                
                EtlSyncMethods.SetMasterPersonAccountDirectory(Trigger.New);

                //DG-180: Only sync record if flag has been set.On initial load of Oscar data, the flag will be set to false, so that ADP records don't sync with existing record.
                if(dataSyncing.Sync_ADP_Data_With_Person_Account__c) {
            
                    List<Account_Directory_Person__c> accDirsLinkedToExistingAccs = new List<Account_Directory_Person__c>();
                    
                    for(Account_Directory_Person__c accDir: Trigger.New) {
                        if(accDir.Data_Match_Alert_Type__c == 'LINKED_TO_EXISTING_ACCOUNT') {
                            accDirsLinkedToExistingAccs.add(accDir);
                        }
                    }
                    
                    //DG-180: Amended code to replace Trigger.New with accDirsLinkedToExistingAccs in the paramters
                    if(accDirsLinkedToExistingAccs.size() > 0) {
                        EtlSyncMethods.SyncDataBetweenAccDirPersonAndAccount(accDirsLinkedToExistingAccs);
                    }
                }
         
            }                  
            //DG-180: Added logic to check Oscar Sync custom setting
            if(Trigger.isUpdate && !(IntegrationsHelper.salesforceToSkiSync || IntegrationsHelper.salesforceToOscarSync)) {   
                
                EtlSyncMethods.SetMasterPersonAccountDirectory(Trigger.New);
                EtlSyncMethods.SyncDataBetweenAccDirPersonAndAccount(Trigger.New);
                
            }
            else {
                System.Debug('AccountDirectoryPersonTrigger DO NOT UPDATE IN AFTER TRIGGER');
            }
        }
    }
}