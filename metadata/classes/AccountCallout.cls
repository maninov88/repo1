public class AccountCallout {
    
    public static List<Account> accList{get;set;}
    public static HttpResponse makeGetCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
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
        //request.setBody('{"objectType":"Account", "Name":"United Oil & Gas", "BillingCity":"Singapore"} ');
        String input= '{"objectType":"Account", "Name":"United Oil & Gas", "BillingCity":"Singapore"}';
        
        request.setBody(input);
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if (response.getStatusCode() == 200) {
            
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            //   Account results = (Account)JSON.deserialize(response.getBody(), Account.class);
            System.debug(results);
            List<Object> datas = (List<Object>) results.get('data');
            System.debug('Results.get(data)'+datas );
            System.debug('Received the following accounts:');
            accList=new List<Account>();
            for(Object account:datas)
            {
                Map<String,Object> oneAccount=(Map<String,Object>) account;
                //  System.debug('Docs'+oneAccount.get('doc'));          
                Map<String,Object> updatedDoc=(Map<String,Object>) oneAccount.get('doc');
                System.debug('Updated Name'+updatedDoc.get('Name')) ;
                System.debug('Updated City'+updatedDoc.get('BillingCity')) ;
                Account acc=new Account();
                acc.Name=(String)updatedDoc.get('Name');
                acc.BillingCity=(String)updatedDoc.get('BillingCity');
                accList.add(acc);
            }   
            
        }   
        return response;
    }
    
}