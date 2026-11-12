# EMQX cores crashloop after a power loss

Symptom: both `database/emqx` core pods in `CrashLoopBackOff` (zigbee2mqtt with them). Each core's
Mnesia waits for tables it thinks a peer holds, and the peers it waits for are dead cores still in
the cluster view. The liveness probe kills the container before the wait ends (UNVERIFIED: about
2.5 min, operator default probe).

1. List the cores and pick one to bring up (`<core>`; container `emqx`, UNVERIFIED: the operator names it):

   ```bash
   kubectl -n database get pods -l apps.emqx.io/instance=emqx -o wide
   ```

2. Let `<core>` start fresh (delete its pod, or wait out its back-off). As soon as its container
   runs, repeat this every ~8 s until every table returns `yes` and the pod turns Ready. Loading
   one table only moves the wait to the next, and an exec between runs fails with
   `container not found`: just repeat.

   ```bash
   kubectl -n database exec <core> -c emqx -- emqx eval \
     "[{T, mnesia:force_load_table(T)} || T <- mnesia:system_info(tables), T =/= schema]."
   ```

3. Leave the other core alone: on its next start it copies from the healthy one.
4. Remove the dead cores, or the next power loss wedges the same way. Force-leave each name
   exactly as it appears under `stopped_nodes`:

   ```bash
   kubectl -n database exec <core> -c emqx -- emqx ctl cluster status
   kubectl -n database exec <core> -c emqx -- emqx ctl cluster force-leave '<name from stopped_nodes>'
   ```

5. `emqx ctl cluster status` lists only the two current pods under `running_nodes`.
