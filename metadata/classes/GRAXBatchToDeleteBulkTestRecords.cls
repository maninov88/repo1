/*****************************************************************************************
Name              : GRAXBatchToDeleteBulkTestRecords
Description       : Deletes test records for each specified SObject in the variable "objectNames"
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich    	03/10/2020          David Mackey        9558 -- Create scripts for Data Load (https://app.clubhouse.io/hardingpoint/story/9558/create-scripts-for-data-load)
******************************************************************************************/

public without sharing class GRAXBatchToDeleteBulkTestRecords implements Database.Batchable<SObject>, Database.Stateful {
	public Map<String, Long> objectNames = new Map<String, Long>{
    	'fragment1__c' => 1900000,
		'fragment2__c' => 1850000,
		'fragment3__c' => 1800000,
		'fragment4__c' => 1750000,
		'fragment5__c' => 1700000,
		'fragment6__c' => 1650000,
		'fragment7__c' => 1600000,
		'fragment1_wide__c' => 900000,
		'fragment2_wide__c' => 850000,
		'fragment3_wide__c' => 700000,
		'fragment4_wide__c' => 650000,
		'fragment5_wide__c' => 600000,
		'fragment6_wide__c' => 650000,
		'fragment7_wide__c' => 500000,
		'wide_nofragment__c' => 1900000
    };
    private List<String> objectNamesSorted;
    public static List<String> objectNamesSortedStatic;
    
    private Integer currentIndex = 0;
    
    public GRAXBatchToDeleteBulkTestRecords(Integer currentIndex){
    	this.currentIndex = currentIndex;
    	
    	this.objectNamesSorted = objectNamesSortedStatic;
    }
    
    public Database.querylocator start(Database.BatchableContext BC) {
    	if(objectNamesSorted == null){
    		objectNamesSorted = new List<String>(objectNames.keySet());
    	}
    	
        // Calculate how many time we need to iterate over the "execute" method to create all the required records for this object        
        Long currentObjectNumOfRecs = objectNames.get(objectNamesSorted[currentIndex]);
        
        String query = 'SELECT Id FROM ' + objectNamesSorted[currentIndex] + ' LIMIT ' + currentObjectNumOfRecs;

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
    	delete scope;
        Database.emptyRecycleBin(scope);
    }
    
    public void finish(Database.BatchableContext BC) {
    	currentIndex = currentIndex + 1;
    	
    	if(currentIndex < objectNamesSorted.size()){
	    	GRAXBatchToDeleteBulkTestRecords.objectNamesSortedStatic = this.objectNamesSorted;
	    	GRAXBatchToDeleteBulkTestRecords b = new GRAXBatchToDeleteBulkTestRecords(currentIndex);
	    	b.objectNames = this.objectNames;
	    	if(!Test.isRunningTest()) Database.executeBatch(b, 2000);
    	}
    }    
}