public with sharing class AIController {
    private static final String OPENAI_API_KEY = 'REPLACE_WITH_API_KEY';

    @AuraEnabled
    public static String getAIResponse(String description) {
        if (String.isBlank(description)) {
            return 'No case description provided.';
        }

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.openai.com/v1/responses');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + OPENAI_API_KEY);
        req.setTimeout(120000);

        String prompt =
            'You are a customer support AI assistant. ' +
            'Read this case description and return only a short helpful customer response in 2 sentences max. ' +
            'Case description: ' + description;

        String requestBody = JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-4.1-mini',
            'input' => prompt
        });

        req.setBody(requestBody);

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
                        return (String) firstContent.get('text');
                    }
                }

                return 'No AI response returned.';
            }

            return 'OpenAI call failed. Status: ' + res.getStatusCode();
        } catch (Exception e) {
            return 'Callout exception: ' + e.getMessage();
        }
    }
}