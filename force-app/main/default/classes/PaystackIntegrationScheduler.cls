public class PaystackIntegrationScheduler implements Schedulable {

    public void execute(SchedulableContext sc){
        //create and enqueue Paystack integration job
        PaystackIntegration paystackJob = new PaystackIntegration();

        System.enqueueJob(paystackJob);

        System.debug('Paystack integration job enqueued at: ' + Datetime.now());
    }
    
}