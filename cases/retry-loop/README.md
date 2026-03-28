# Retry Loop

This case shows a join attempt where authentication repeats before the first association request.

Use it when users report "the client keeps trying to join but never finishes."

Fixture:
- `sample-data/jsonl/wpa_induction_fixture.jsonl`

Primary signal:
- `wd_auth_assoc_loops_jsonl(...)` returns `status = 'retry_loop'`

Workflow:
1. Start with the capture report.
2. Use the sessionized view to prove the repeated authentication attempt.
3. Follow the next-step guidance to inspect RSN or AKM mismatches.
