public with sharing class AICaseQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;

    public AICaseQueueable(Id caseId) {
        this.caseId = caseId;
    }

    public void execute(QueueableContext context) {
        AICaseService.processCase(caseId);
    }
}