public class SquareBankAppIntASAcheduler implements Schedulable, Database.AllowsCallouts{

    private final Boolean updateSquare;
    private final Boolean updateSF;

    // Constructor with parameters
   /* public SquareBankAppInt(Boolean updateSquare, Boolean updateSF) {
        this.updateSquare = updateSquare;
        this.updateSF = updateSF;
    }
    
    // Default constructor performs both operations simultaneously
    public SquareBankAppInt() {
        this(true, true);
    }*/

   

    public void execute(SchedulableContext sc){

        SquareBankAppInt squareIntJob = new SquareBankAppInt(updateSquare, updateSF);
        System.enqueueJob(squareIntJob);

    }
    
}