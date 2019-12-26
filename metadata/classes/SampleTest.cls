@isTest
private class SampleTest {

    testmethod static void loadData()
    {
         List<Account> accList=new List<Account>();
       for(Integer i=0;i<20;i++)
       {
        Account acc=new Account(Name='SampleTest'+i,Type='Customer');
         //accList.add(acc)
         //insert acc;
       }
           insert accList;
        System.debug(accList.size());
    }
}