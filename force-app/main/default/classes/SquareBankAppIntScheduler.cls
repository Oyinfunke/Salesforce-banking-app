public class SquareBankAppIntScheduler implements Schedulable, Database.AllowsCallouts{

    private final Boolean updateSquare;
    private final Boolean updateSF;

    // Constructor with parameters
    public SquareBankAppIntScheduler(Boolean updateSquare, Boolean updateSF) {
        this.updateSquare = updateSquare;
        this.updateSF = updateSF;
    }
    
    // Default constructor performs both operations simultaneously
    public SquareBankAppIntScheduler() {
        this(true, true);
    }

   

    public void execute(SchedulableContext sc){

        SquareBankAppInt squareIntJob = new SquareBankAppInt(updateSquare, updateSF);
        System.enqueueJob(squareIntJob);

    }
    
}