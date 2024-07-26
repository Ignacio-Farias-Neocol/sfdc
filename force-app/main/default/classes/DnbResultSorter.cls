public  class DnbResultSorter implements Comparator<DnbResult> {

    public Integer compare(DnbResult dnb1, DnbResult dnb2) {

        Integer returnValue = 0;
        
        if(dnb1 == null && dnb2 == null) {
            returnValue = 0;
        } else if(dnb1 == null) {
            
            returnValue = -1; 
        } else if(dnb2 == null) {
            
            returnValue = 1;
        } else if ((dnb1.ConfidenceCode == null) && (dnb2.ConfidenceCode == null)) {
           
            returnValue = 0;
        } else if (dnb1.ConfidenceCode == null){
            
            returnValue = -1;
        } else if (dnb2.ConfidenceCode == null){
           
            returnValue = 1;
        } else if (dnb1.ConfidenceCode < dnb2.ConfidenceCode) {
           
            returnValue = -1;
        } else if (dnb1.ConfidenceCode > dnb2.ConfidenceCode) {
           
            returnValue = 1;
        }

        return returnValue;
    }    
}