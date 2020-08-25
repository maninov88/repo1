/*****************************************************************************************
Name              : GRAXBatchToCreateBulkTestScenarios
Description       : Creates test records for each specified SObject in the variable "objectNames"
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich    	03/09/2020          David Mackey        9558 -- Create scripts for Data Load (https://app.clubhouse.io/hardingpoint/story/9558/create-scripts-for-data-load)
******************************************************************************************/

public without sharing class GRAXBatchToCreateBulkTestScenarios implements Database.Batchable<Integer>, Database.Stateful {
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
    private Long currentObjectRecsInserted = 0;
    
    public GRAXBatchToCreateBulkTestScenarios(Integer currentIndex){
    	this.currentIndex = currentIndex;
    	
    	this.objectNamesSorted = objectNamesSortedStatic;
    }
    
    public Iterable<Integer> start(Database.BatchableContext BC) {
    	if(objectNamesSorted == null){
    		objectNamesSorted = new List<String>(objectNames.keySet());
    	}
    	
        // Calculate how many time we need to iterate over the "execute" method to create all the required records for this object        
        Long currentObjectNumOfRecs = objectNames.get(objectNamesSorted[currentIndex]);
        
        List<Integer> intList = new List<Integer>();
        
        // Count how many times we will insert chunks of 10,000
        for(Integer i = 0; i < Math.ceil(currentObjectNumOfRecs / 10000.0); i++){
            intList.add(i); 
        }
        
        return intList;
    }
    
    public void execute(Database.BatchableContext BC, List<Integer> scope) {
    	List<SObject> recs2Ins = new List<SObject>();
    	
    	// Create a single record with all the values populated
    	SObject masterRec = mock(objectNamesSorted[currentIndex]);
    	
    	// Determine how many records have to be inserted on this "execute"
    	Long currentObjectNumOfRecs = objectNames.get(objectNamesSorted[currentIndex]);
    	Long numOfRecs2Ins = (currentObjectNumOfRecs - currentObjectRecsInserted) < 10000 ? (currentObjectNumOfRecs - currentObjectRecsInserted) : 10000;
    	
        for(Integer i = 0; i < numOfRecs2Ins; i++) {
        	SObject rec = masterRec.clone();
        	recs2Ins.add(rec);
        }
        
        currentObjectRecsInserted += numOfRecs2Ins;
        
        //Database.insert(recs2Ins, false);
        insert recs2Ins;
    }
    
    public void finish(Database.BatchableContext BC) {
    	currentIndex = currentIndex + 1;
    	
    	if(currentIndex < objectNamesSorted.size()){
	    	GRAXBatchToCreateBulkTestScenarios.objectNamesSortedStatic = this.objectNamesSorted;
	    	GRAXBatchToCreateBulkTestScenarios b = new GRAXBatchToCreateBulkTestScenarios(currentIndex);
	    	b.objectNames = this.objectNames;
	    	if(!Test.isRunningTest()) Database.executeBatch(b, 1);
    	}
    }
    
    
    private static SObject mock(String sobjectName) {
        SObject o = createObjectInstance(sobjectName, null, true);

        for (Schema.DescribeFieldResult f : getDescribeFieldsResultForObject(sobjectName).values()) {
            if (f.isCreateable()) {
                Schema.DisplayType fieldDisplayType = f.getType();
                
                if (fieldDisplayType == DisplayType.Boolean) {
                	Integer rnd = Math.abs(Crypto.getRandomInteger());
                	Integer idx = Math.mod(rnd, 2);
                    o.put(f.getName(), idx == 1);
                }
                else if (fieldDisplayType == DisplayType.Currency) {
                    o.put(f.getName(), Decimal.valueOf(generateRandomNumber(f.getPrecision(), f.getScale())));
                }
                else if (fieldDisplayType == DisplayType.Date) {
                    o.put(f.getName(), Date.today());
                }
                else if (fieldDisplayType == DisplayType.DateTime) {
                    o.put(f.getName(), System.now());
                }
                else if (fieldDisplayType == DisplayType.Double) {
                	System.debug(JSON.serializePretty(f));
                    o.put(f.getName(), Double.valueOf(generateRandomNumber(f.getPrecision(), f.getScale())));
                }
                else if (fieldDisplayType == DisplayType.Email) {
                    o.put(f.getName(), 'foo@foo.com');
                }
                else if (fieldDisplayType == DisplayType.Integer) {
                    o.put(f.getName(), Integer.valueOf(generateRandomNumber(f.getDigits(), 0)));
                }
                else if (fieldDisplayType == DisplayType.Percent) {
                    o.put(f.getName(), Double.valueOf(generateRandomNumber(f.getPrecision(), f.getScale())));
                }
                else if (fieldDisplayType == DisplayType.Phone) {
                    o.put(f.getName(), '555-555-1212');
                }
                else if (fieldDisplayType == DisplayType.String) {
                    o.put(f.getName(), getRandomTexts(0, f.getLength()));
                }
                else if (fieldDisplayType == DisplayType.TextArea) {
                    o.put(f.getName(), getRandomTexts(0, 4000));
                }
                else if (fieldDisplayType == DisplayType.Time) {
                    o.put(f.getName(), System.now().time());
                }
                else if (fieldDisplayType == DisplayType.URL) {
                    o.put(f.getName(), 'http://foo.com');
                }
                else if (fieldDisplayType == DisplayType.PickList) {
                    o.put(f.getName(), f.getPicklistValues()[0].getValue());
                }
            }
        }
        return o;
    }
    
    private static Map<String, Schema.SObjectType> globalDescribe;
	private static Map<String, Schema.DescribeSObjectResult> objectsFullDescribe {get; set;}
	private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldsDescribeByObject;

	private static void loadGlobalDescribe(){
		if(globalDescribe == null){
			globalDescribe = Schema.getGlobalDescribe();
		}
	}
	
	private static void loadObjectDescribe(String objName){
		if(objectsFullDescribe == null){
			objectsFullDescribe = new Map<String, Schema.DescribeSObjectResult>();
		}

		if(!objectsFullDescribe.containsKey(objName) && sObjectExists(objName)){
			objectsFullDescribe.put(objName, globalDescribe.get(objName).getDescribe());
		}
	}

	private static void loadObjectAndFieldsDescribe(String objName){
		if(fieldsDescribeByObject == null){
			fieldsDescribeByObject = new Map<String, Map<String, Schema.DescribeFieldResult>>();
		}

		if(!fieldsDescribeByObject.containsKey(objName) && sObjectExists(objName)){
			Schema.DescribeSObjectResult objDesc = getObjectDescribe(objName);

			Map<String, Schema.DescribeFieldResult> fieldsDescribe = new Map<String, Schema.DescribeFieldResult>();

			// Get the describe of each field of the object
			Map<String, Schema.SObjectField> objDescFieldsMap = objDesc.fields.getMap();
			for(String fieldAPIName: objDescFieldsMap.keySet()){
				Schema.DescribeFieldResult fldDescRes = objDescFieldsMap.get(fieldAPIName).getDescribe();
				fieldsDescribe.put(fldDescRes.getName(), fldDescRes);
			}
			fieldsDescribeByObject.put(objDesc.getName(), fieldsDescribe);
		}
	}
	
	private static Boolean sObjectExists( String objName ){
		loadGlobalDescribe();

		return globalDescribe.containsKey( objName );
	}
	
	private static Schema.SObjectType getSObjectType(String objName) {
		loadGlobalDescribe();

		return globalDescribe.get(objName);
	}
	
	private static Schema.DescribeSObjectResult getObjectDescribe(String objName){
		loadObjectDescribe(objName);

		return objectsFullDescribe.get(objName);
	}
	
	private static Map<String, Schema.DescribeFieldResult> getDescribeFieldsResultForObject(String objName){
		loadObjectAndFieldsDescribe(objName);

		return fieldsDescribeByObject.get(objName);
	}
    
    private static SObject createObjectInstance(String objName, Id recordId, Boolean loadDefaultValues){
		SObject result = getSObjectType(objName).newSObject(recordId);

		if(loadDefaultValues){
			result = getSObjectType(objName).newSObject(recordId, true);
		}

		return result;
	}
	
	private static String generateRandomString(Integer len, Boolean includeLineBrake){
		return generateRandomString(len, includeLineBrake, false);
	}
	
	private static String generateRandomString(Integer len, Boolean includeLineBrake, Boolean onlyNumbers){
		String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz ,;&*+-/=_!?<>|@#$%^()';
		if(onlyNumbers){
			chars = '0123456789';
		}
		Integer baseCharactersLength = chars.length() + (includeLineBrake ? 1 : 0);
		String randStr = '';
		while (randStr.length() < len){
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), baseCharactersLength);
			if(!includeLineBrake || idx < baseCharactersLength - 1){
				randStr += chars.substring(idx, idx+1);
			}else{
				randStr += includeLineBrake ? '\n' : ' ';
			}
		}

		return randStr;
	}
	
	private static String generateRandomNumber(Integer digits, Integer decimals) {
	 	String result = generateRandomString(digits > 2 ? digits - 2 : digits, false, true);
	 	if(decimals > 0){
	 		result += '.' + generateRandomString(decimals, false, true);
	 	}
	 	
	 	return result;
	}
	
	private static String getRandomTexts(Integer minLength, Integer maxLength) {
		List<String> words = new List<String>{
		  'lorem', 'ipsum', 'dolor', 'sit', 'amet', 'tempor', 'aboreant',
		  'instructor', 'eu', 'nos', 'a', 'quo', 'magna', 'primis', 'labore', 'usi', 'virtute', 'fabellas', 'vis', 'duis',
		  'scripta', 'salutandi', 'laudem', 'commune', 'nam', 'laoreet', 'propriae', 'corrumpit', 'ea', 'partem',
		  'inermis', 'conclusion', 'ius', 'sint', 'impedit', 'deterruis', 'eam', 'elit', 'nusquam', '\n'
		};
		Map<Integer, List<String>> wordsMap = new Map<Integer, List<String>>{
		  0 => new List<String>{
			''
		  },
		  1 => new List<String>{
			'a'
		  },
		  2 => new List<String>{
			'eu', 'ea'
		  },
		  3 => new List<String>{
			'sit', 'nos', 'usi', 'nam', 'eam', 'vis', 'quo', 'ius'
		  },
		  4 => new List<String>{
			'amet', 'duis', 'elit', 'sint'
		  },
		  5 => new List<String>{
			'lorem', 'ipsum', 'dolor', 'magna'
		  },
		  6 => new List<String>{
			'tempor', 'partem', 'labore', 'primis', 'nusquam', 'laudem'
		  },
		  7 => new List<String>{
			'inermis', 'laoreet', 'commune', 'scripta', 'virtute', 'impedit'
		  },
		  8 => new List<String>{
			'aboreant', 'fabellas', 'propriae'
		  },
		  9 => new List<String>{
			'deterruis', 'corrumpit', 'salutandi'
		  },
		  10 => new List<String>{
			'instructor', 'conclusion'
		  }
		};
		String result = '';
		Integer rnd = 0;
		Integer randomLength = 0;
		Integer newLength = 0;
		String previousWord = '';
		String selectedWord = '';

		Integer numWords = words.size();
		
		result = '';
		randomLength = Math.mod(Math.abs(Crypto.getRandomInteger()), (maxLength - minLength)) + minLength;
		do {
			rnd = Math.mod(Math.abs(Crypto.getRandomInteger()), numWords);
			selectedWord = words[rnd];
			
			if (previousWord != selectedWord && newLength <= randomLength) {
				newLength = result.length() + selectedWord.length();
				result += selectedWord + ' ';
			}
		} while (newLength < randomLength);

		result = result.trim();
		if (result.length() < randomLength) {
			Integer additionalLength = randomLength - result.length() - 1;
			List<String> additionalWords = wordsMap.get(additionalLength);
			rnd = Math.mod(Math.abs(Crypto.getRandomInteger()), additionalWords.size());
			result += ' ' + additionalWords[rnd];
		}

		// capitalize text and add it to the output list
		return result.capitalize();
	}
}