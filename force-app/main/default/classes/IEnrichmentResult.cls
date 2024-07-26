public interface  IEnrichmentResult {
    
    Type getSourceType();
    Type getDestinationType();
    List<IEnrichmentResult> wrapResponse(List<Sobject> reponse);
   
}