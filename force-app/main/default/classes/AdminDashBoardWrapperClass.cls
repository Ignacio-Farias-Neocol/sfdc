/**
 *  @author Jade Global
 *  @date 2021-12-15
 *  @description  Wrapper class to parse the json request and response for Admin dashboard integration.
 */
public class AdminDashBoardWrapperClass {
    public List<Deployments> deployments = new List<Deployments>();
    public class Deployments {
        public String mspName;
        public String mspAccountID;
        public String deploymentName;
        public Map<String, Contacts> contact = new Map<String, Contacts>();
        public String theater;
        public List<Products> products = new List<Products>();
        public List<Sensors> sensors = new List<Sensors>();
        public OpportunityOwner opportunityOwner;
    }
    
    public class Contacts {
        public string name;
        public string mobile;
        public string email;
    }
    
    public class Products {
        public string name;
        public Integer quantity;
        public string code;
    }
    public class Sensors {
        public string name;
        public string installSite;        
    }
    
    public class OpportunityOwner{
        public string name;
        public string mobile;
        public string email;
    }
    
    public class Response {
        public string message;
        public string mspAccountID;
        public string mspName;
    }
}