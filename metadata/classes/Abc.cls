public class Abc
{
  public List<cAccount> accList {get; set;}
  public List<Account> selectedAccounts{get; set;}
//Adding the Records to inner class and to get the values for page block table.
  public List<cAccount> getAccounts(){
        if(accList == null){
            accList = new List<cAccount>();
            for(Account acc : [select Id from Account ]){
                  accList.add(new cAccount(acc));
            }
         }
       return accList;
   }  
//on button click it will show the list of records what we have selected.
  public PageReference processSelected(){     
        selectedAccounts= new List<Account>();
        for(cAccount cCon : getAccounts()) {
            if(cCon.selected == true){
                selectedAccounts.add(cCon.con);
            }
        }            
        return null;
   }
  //  Inner class for capture the records
  public class cAccount {
        public Account con {get; set;}
        public Boolean selected {get; set;}
        public cAccount(Account c) {
            con = c;
            selected = false;
        }
   }
     
}