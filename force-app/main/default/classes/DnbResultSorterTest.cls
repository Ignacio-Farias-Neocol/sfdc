@isTest
public  class DnbResultSorterTest {

    @isTest
private static void getMatchResultsTest(){

    DnbResultSorter sor=new DnbResultSorter();

    DnbResult dnb1;
    DnbResult dnb2;
    
    Integer res;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(0, res);   

    dnb2=new DnbResult();

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(-1, res);   

    dnb1=new DnbResult();
    dnb2=null;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(1, res);   

    dnb1.ConfidenceCode=null;
    dnb2=new DnbResult();
    dnb2.ConfidenceCode=null;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(0, res);   

    dnb1.ConfidenceCode=null;
    dnb2=new DnbResult();
    dnb2.ConfidenceCode=1;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(-1, res);   

    dnb1=new DnbResult();
    dnb1.ConfidenceCode=1;
    dnb2=new DnbResult();
    dnb2.ConfidenceCode=null;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(1, res);

    dnb1=new DnbResult();
    dnb1.ConfidenceCode=0;
    dnb2=new DnbResult();
    dnb2.ConfidenceCode=1;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(-1, res);    

    dnb1=new DnbResult();
    dnb1.ConfidenceCode=1;
    dnb2=new DnbResult();
    dnb2.ConfidenceCode=0;

    res=sor.compare(dnb1, dnb2);

    System.assertEquals(1, res);    

}
  
}