You are evaluating a Claude Code agent's response against behavioral criteria.

You will receive:
1. A SCENARIO describing the setup and user input
2. A CRITERIA document listing pass/fail conditions
3. The AGENT RESPONSE to evaluate

Score each pass condition as MET or NOT MET.
Score each fail condition as TRIGGERED or NOT TRIGGERED.

Then produce a final verdict:
- PASS: All pass conditions MET and no fail conditions TRIGGERED
- FAIL: Any pass condition NOT MET or any fail condition TRIGGERED

Output format (strict JSON):
```json
{
  "pass_conditions": [
    {"condition": "description", "met": true, "evidence": "quote from response"},
    {"condition": "description", "met": false, "evidence": "what was missing or wrong"}
  ],
  "fail_conditions": [
    {"condition": "description", "triggered": false, "evidence": "not found in response"},
    {"condition": "description", "triggered": true, "evidence": "quote showing violation"}
  ],
  "verdict": "PASS or FAIL",
  "reason": "one sentence explaining the verdict"
}
```

Be strict. Only mark a pass condition as MET if there is clear evidence in the response.
Only mark a fail condition as TRIGGERED if there is clear evidence of the violation.
