# Unscoped

Tasks discovered but not yet assigned to a scope. Review and place into a scope before next push.

## Open Items

- [ ] **Production Action Cable config** — `config/environments/production.rb` still needs the Redis adapter wired with a distinct channel prefix so it doesn't collide with Sidekiq's Redis usage. Touches deployment, not any single capability. Likely rolled into whichever scope lands first in production, but hold here until we confirm timing with ops.
- [ ] **Test helper for channel broadcasts** — Session 01 wrote `test/models/post_broadcast_test.rb` with an inline broadcast matcher. If comments + reactions repeat the same assertions, extract a shared helper. Not urgent, but capture now so we don't forget to DRY.
- [ ] **Decide "catch up" strategy** (timestamp diff vs full feed refresh) — this decision feeds `scope-connection-survives-network-drops` but needs a spike before we commit. Park here until the live controller is working and we can experiment.
- [ ] **Confirm post card partial is idempotent when rendered from `ApplicationController.render`** — Session 01 did this for posts; comments may need the same treatment. Verify when starting the comments scope.

## Notes

Keep this file light. If an item sits here more than one session, force a decision: assign it or cut it.

