@IsTest
private class DTL_SampleTransactionTest {

    @IsTest
    static void capture_and_replay_should_match() {
        Test.startTest();
        DTL_SampleTransaction.CaptureRequest req = new DTL_SampleTransaction.CaptureRequest();
        req.a = 10;
        req.b = 5;
        req.threshold = 12;
        DTL_SampleTransaction.capture(req);
        Test.stopTest();

        // Find newest trace
        DTL_Trace__c t = [
            SELECT Id, ExpectedOutputsJson__c, ReplayDiffJson__c, ReplayOutputsJson__c
            FROM DTL_Trace__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Test.startTest();
        DTL_ReplayEngine.ReplayResult rr = DTL_ReplayEngine.replay(t.Id);
        Test.stopTest();

        System.assertEquals(true, rr.success, 'Replay should succeed with no diffs.');
        System.assertNotEquals(null, rr.replayOutputsJson);
        System.assertEquals('[]', rr.diffJson, 'No diffs expected.');
    }

    @IsTest
    static void replay_should_fail_when_expected_differs() {
        // Create trace, then tamper expected
        DTL_SampleTransaction.CaptureRequest req = new DTL_SampleTransaction.CaptureRequest();
        req.a = 1; req.b = 1; req.threshold = 10;
        DTL_SampleTransaction.capture(req);

        DTL_Trace__c t = [
            SELECT Id, ExpectedOutputsJson__c
            FROM DTL_Trace__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String,Object> expected = DTL_Json.parseObject(t.ExpectedOutputsJson__c);
        expected.put('score', 999); // force mismatch
        t.ExpectedOutputsJson__c = DTL_Json.stringify(expected);
        update t;

        DTL_ReplayEngine.ReplayResult rr = DTL_ReplayEngine.replay(t.Id);
        System.assertEquals(false, rr.success, 'Replay should detect diff.');
        System.assert(rr.diffJson.contains('mismatch'), 'Diff should contain mismatch.');
    }
}
