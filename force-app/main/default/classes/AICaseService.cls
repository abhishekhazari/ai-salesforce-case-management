public with sharing class AICaseService {
    private static final String OPENAI_API_KEY = 'REPLACE_WITH_API_KEY';

    public static void processCase(Id caseId) {
        Case c = [
            SELECT Id, Subject, Description, AI_Response__c, AI_Priority__c, AI_Processed__c, Customer_Summary__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        String descriptionText = c.Description != null ? c.Description : '';

        if (String.isBlank(descriptionText)) {
            c.AI_Response__c = 'No case description provided.';
            c.AI_Priority__c = 'Low';
            c.AI_Processed__c = true;
            c.Customer_Summary__c = 'Empty description.';
            update c;
            return;
        }

        String lowerText = descriptionText.toLowerCase();
        String priority = 'Low';

        if (lowerText.contains('urgent') || lowerText.contains('down') || lowerText.contains('error')) {
            priority = 'High';
        } else if (lowerText.contains('issue') || lowerText.contains('problem')) {
            priority = 'Medium';
        }

        String prompt =
            'You are a support triage assistant. ' +
            'Read this Salesforce case description and return a short helpful customer response in 2 sentences max. ' +
            'Case description: ' + descriptionText;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.openai.com/v1/responses');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + OPENAI_API_KEY);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        String requestBody = JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4.1-mini',
            'input' => prompt
        });

        req.setBody(requestBody);

        String aiText = 'AI response could not be generated.';

        try {
            HttpResponse res = http.send(req);

           if (res.getStatusCode() == 200) {
    Map<String, Object> responseMap =
        (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

    List<Object> outputList = (List<Object>) responseMap.get('output');

    if (outputList != null && !outputList.isEmpty()) {
        Map<String, Object> firstOutput = (Map<String, Object>) outputList[0];
        List<Object> contentList = (List<Object>) firstOutput.get('content');

        if (contentList != null && !contentList.isEmpty()) {
            Map<String, Object> firstContent = (Map<String, Object>) contentList[0];
            aiText = (String) firstContent.get('text');
        } else {
            aiText = 'No content returned from OpenAI.';
        }
    } else {
        aiText = 'No output returned from OpenAI.';
    }
} else {
    aiText = 'OpenAI call failed. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody();
}
        } catch (Exception e) {
            aiText = 'Callout exception: ' + e.getMessage();
        }

        c.Customer_Summary__c = 'Customer reported: ' + descriptionText;
        c.AI_Response__c = aiText;
        c.AI_Priority__c = priority;
        c.AI_Processed__c = true;

        update c;
    }
}