public class GetAccount {
    public String objectType {get;set;}
    public String Name {get;set;}
    public String BillingCity {get;set;}
    
    
    public static List<GetAccount> parse(String jsonInput)
    {
        JSONParser parser = JSON.createParser(jsonInput);
        List<GetAccount> accList = new List<GetAccount>();
        while(parser.nextToken() != JSONToken.END_ARRAY)
        { // we started with an array of objects
            GetAccount acc = new GetAccount();
            while(parser.nextToken() != JSONToken.END_OBJECT)
            { // loop through each object
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME) 
                { //token should be field name
                    String attr = parser.getText(); //get the text of the field name
                    parser.nextToken(); // move the pointer
                    //start mapping the fields
                    if(attr == 'objectType') 
                    { 
                        acc.objectType = parser.getText();
                    } else if(attr == 'Name') 
                    {
                        acc.Name = parser.getText();
                    } else if(attr == 'BillingCity')
                    {
                        acc.BillingCity = parser.getText();
                    } 
                }
            }
         accList.add(acc);    
        }
        
        return accList;
    }
   
}