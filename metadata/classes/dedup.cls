public with sharing class dedup {
    public List<Account> accountList{get;set;}
    public List<Account> selectedAccounts{get; set;}
    public Id objSelectedAccountId {get;set;}
    public List<cAccount> graxMatches {get; set;}
    public String currentRecordId { get;set;}
    public Account currentRow{get;set;}
    public String finalUrl{get;set;}
    public List<cAccount> finalMatches{get;set;}
  	public List<Account> salesforceAccounts{get;set;}
    
    public dedup(ApexPages.StandardController controller)
    {
        System.debug('Current record'+controller.getRecord());
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        currentRow = [select id,Name,WebSite,BillingPostalCode,BillingCity from Account where id = :currentRecordId ];
       System.debug(currentRecordId );
    }
    public PageReference getDatalakeMatches(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        System.debug('Connection Established');
        request.setEndpoint('https://grax-dev-ravitatiko.herokuapp.com/graxproxy/api/enrich/matches');
        request.setMethod('GET');
        request.setHeader('Content-Type','application/json');
        request.setHeader('Connection','keep-alive');
        request.setHeader('Content-Length','0');
        request.setHeader('x-api-key', 'n3ohoPxYOE1lwC9MNlCsv22CHmJlngCG4eJJoqUw');
        request.setHeader('authorizationtoken', 'b46072d5a3a7071b4cbf91f680804b8afc8fed04e209f0c655756cf26e452be3');
        request.setHeader('licensetoken', 'U2FsdGVkX1/SniLKqWipdDuMlwvIVaahqtilR7rCnozbZrknlWHev48cXCcZjKX3Y4Ns0QLyXEAGy38qBrrjrE31YRWtSeVcNkv42onAkYo=');
        request.setHeader('Authorization',
                          'Basic bjNvaG9QeFlPRTFsd0M5TU5sQ3N2MjJDSG1KbG5nQ0c0ZUpKb3FVdzpiNDYwNzJkNWEzYTcwNzFiNGNiZjkxZjY4MDgwNGI4YWZjOGZlZDA0ZTIwOWYwYzY1NTc1NmNmMjZlNDUyYmUz');
        System.debug('Connection Continued');
        String accountName = currentRow.name;
        Id accountId=currentRow.Id;
        String billingCity = currentRow.billingCity;
        String billingPostalCode = currentRow.billingPostalCode;
        String name = currentRow.name;
        String website = currentRow.website;
        if(billingCity == null){
            billingCity ='';
        }
            if(billingPostalCode == null){
            billingPostalCode ='';
        }
         if(website == null){
            website ='';
        }
         List<Id> graxMatchIds = new List<Id>();
       	String payload = '{"objectType":"Account","Name":"' 
            + name 
            +'","website":"'
            + website 
            + '","BillingPostalCode":"'
            + billingPostalCode 
            + '","sfdcorgid":"'
           + '00D2v000000QW94EAG'//UserInfo.getOrganizationId() 
            + '","BillingCity":"'
            + billingCity 
            + '"}';
        
        System.debug('Payload :'+payload);
        request.setBody(payload);
        Map<String,Object> accMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(currentRow));
        String input=JSON.serializePretty(accMap);
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            system.debug('Before JSon Deserialised');
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
             system.debug('results'+results);
            List<Object> matches = (List<Object>) results.get('data');
              system.debug('matches'+matches);
            graxMatches = new List<cAccount>();
            for(Object account : matches)
            {
                Map<String,Object> duplicateRecord = (Map<String,Object>) account;        
                 system.debug('duplicateRecord '+duplicateRecord );
                Map<String,Object> doc = (Map<String,Object>) duplicateRecord.get('doc');
                 system.debug('doc '+doc );
                Account acc = new Account();
                cAccount cAcc;
                acc.Id=(String)doc.get('Id');
                acc.Name=(String)doc.get('Name');
                acc.Website=(String)doc.get('Website');
                acc.BillingPostalCode=(String)doc.get('BillingPostalCode');
                acc.BillingCity=(String)doc.get('BillingCity');
                System.debug('Id'+acc.Id);
                 System.debug('Name'+ acc.Name);
                 System.debug('Website'+acc.Website);
                
                cAcc = new cAccount(acc);
                cAcc.score = (Decimal)duplicateRecord.get('score');
                // array of IDs from salesforce
                graxMatchIds.add(acc.Id); 
                 System.debug('graxMatchIds: '+graxMatchIds);
                graxMatches.add(cAcc);
                System.debug('graxMatches: '+graxMatches);
            }   
            salesforceAccounts = [select id ,Name from Account where id in :graxMatchIds ];
            System.debug('All account: '+salesforceAccounts);
            finalMatches=new List<cAccount>();
            for(cAccount graxMatch: graxMatches){
                for(Account salesforceAccount: salesforceAccounts){
                    if(salesforceAccount.Id == graxMatch.sObj.Id){
                		finalMatches.add(graxMatch);
                    }
                }
               
            }
        }   
        return null;
    }
    
    public String processRedirect(){
    String cids = '';
    selectedAccounts= new List<Account>();
    integer i =0;
       for(cAccount cAcc : finalMatches) {
            if(cAcc.selected == true){
                Account acc = cAcc.sObj;
                String id = (String) acc.get('Id');
                if(i != 0){
                    cids += '&';
                }
                String tmp ='cid=' + id;
                cids+=tmp;
                selectedAccounts.add(cAcc.sObj);
                i++;
            }
        }
        finalUrl = 'https://na85.salesforce.com/merge/accmergewizard.jsp?'+cids + '&goNext=1';
        System.debug('final URL :' + finalUrl);
        return null;
    }
  
    public class cAccount {
        public Account sObj {get; set;}
        public Boolean selected {get; set;}
        public Decimal score {get; set;}
        public cAccount(Account c) {
            sObj = c;
            selected = false;
        }
    }
    
}