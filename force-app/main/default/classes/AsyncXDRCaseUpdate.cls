public  class AsyncXDRCaseUpdate implements Queueable {
    List<Case> xdrCases=new List<Case>(); 

    public AsyncXDRCaseUpdate(List<Case> xdrCases) {
        this.xdrCases=xdrCases;        
    }

    public void execute(QueueableContext context){  

        if(xdrCases!=null && !xdrCases.isEmpty()){     
           
            update xdrCases;
        }
    }  
}