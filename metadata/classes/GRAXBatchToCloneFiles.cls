/*****************************************************************************************
Name              : GRAXBatchToCloneFiles
Description       : Gets onesample Account with Attachments / ContentDocument records and clones them to the specified number of records
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich      06/26/2020          Sohil Sheth        14451 -- Script to Load Attachments and Content in SDO (https://app.clubhouse.io/hardingpoint/story/14451/script-to-load-attachments-and-content-in-sdo)
******************************************************************************************/

/*
GRAXBatchToCloneFiles b = new GRAXBatchToCloneFiles('0016g00000699ao', 'Attachment', 7, 4);
Database.executeBatch(b, 1);
*/

public without sharing class GRAXBatchToCloneFiles implements Database.Batchable<Integer>, Database.Stateful {  
    private Id sampleAccountId;
    private String fileObjectName;
    private Integer totalNumOfFiles;
    private Integer numOfFilesPerAccount;
    
    private Id currentAccountId;
    private Integer currentAccountNumOfFiles;
    private Integer totalInsertedFiles;
    private Decimal numOfFilesPerTransaction = 100.0;
    
    public GRAXBatchToCloneFiles(Id sampleAccountId, String fileObjectName, Integer totalNumOfFiles, Integer numOfFilesPerAccount){
      this.sampleAccountId = sampleAccountId;
      this.fileObjectName = fileObjectName;
      this.totalNumOfFiles = totalNumOfFiles;
      this.numOfFilesPerAccount = numOfFilesPerAccount;
      
      this.currentAccountNumOfFiles = 0;
      this.totalInsertedFiles = 0;
    }
    
    public Iterable<Integer> start(Database.BatchableContext BC) {
      // Calculate how many time we need to iterate over the "execute" method to create all the required records for this object 
        // Each execute transaction will create up to 100 files
        Long numberOfAccounts = (Long)Math.ceil(totalNumOfFiles / (Double)numOfFilesPerAccount);
        
        Long totalIterations = (Long)(numberOfAccounts * Math.ceil(numOfFilesPerAccount / numOfFilesPerTransaction));
        
        List<Integer> intList = new List<Integer>();
        
        // Count how many times we will insert chunks of 100
        for(Integer i = 0; i < totalIterations; i++){
            intList.add(i); 
        }
        
        return intList;
    }
    
    public void execute(Database.BatchableContext BC, List<Integer> scope) {
      if(currentAccountNumOfFiles == 0){
        // Clone sample Account
        List<Account> accs = new List<Account>();
        Account sampleAccount = [SELECT Id, Name From Account Where Id =:sampleAccountId LIMIT 1];
        Account acc = sampleAccount.clone();
        acc.Name += '_' + scope[0];
          insert acc;
          
          currentAccountId = acc.Id;
      }
      
      Integer currentTransactionNumOfFiles = 0;
      
      Set<Id> parentIds = new Set<Id>{sampleAccountId};
      String query = 'SELECT Id, Body, Name FROM Attachment WHERE ParentId IN : parentIds';
      
      if(fileObjectName == 'ContentDocument'){
        // Get Id's of the ContentDocuments related to Sample Account
        for(ContentDocumentLink cdl : [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: sampleAccountId ORDER BY ContentDocumentId]){
        parentIds.add(cdl.ContentDocumentId);
      }
      
      query = 'SELECT Id, Title, VersionData FROM ContentVersion WHERE ContentDocumentId IN : parentIds';
      }
      
      List<SObject> clonedFiles2Ins = new List<SObject>();
      
      while(totalInsertedFiles < totalNumOfFiles && currentAccountNumOfFiles < numOfFilesPerAccount && currentTransactionNumOfFiles < numOfFilesPerTransaction){
      
        for(SObject att : Database.query(query)) {
        
        SObject clonedFile;
        if(fileObjectName == 'ContentDocument'){
          ContentVersion contVer = new ContentVersion();
          contVer.Title = (String)att.get('Title');
          contVer.PathOnClient = (String)att.get('Title');
          contVer.VersionData = (Blob)att.get('VersionData');
          contVer.FirstPublishLocationId = currentAccountId;
          clonedFile = contVer;
        }else{
          Attachment req_att = new Attachment();
          req_att.Name = (String)att.get('Name');
          req_att.ParentId = currentAccountId;
          req_att.Body = (Blob)att.get('Body');
          clonedFile = req_att;
        }
        
        if(totalInsertedFiles < totalNumOfFiles && currentAccountNumOfFiles < numOfFilesPerAccount && currentTransactionNumOfFiles < numOfFilesPerTransaction){
          clonedFiles2Ins.add(clonedFile);
          
          currentTransactionNumOfFiles++;
          currentAccountNumOfFiles++;
          totalInsertedFiles++;
        }else{
          break;
        }
      }
      }
      
      if(!clonedFiles2Ins.isEmpty()){
        insert clonedFiles2Ins;
      }
      
      // Set the counter back to 0 for next iteration
      if(currentAccountNumOfFiles >= numOfFilesPerAccount){  
        currentAccountNumOfFiles = 0;
      }
    }
    
    public void finish(Database.BatchableContext BC) {
      
    }
}