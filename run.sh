#!/bin/ash
JAVA_FLAGS="-XX:+UseZGC -XX:AllocatePrefetchStyle=1 -XX:+ZGenerational -XX:+UnlockExperimentalVMOptions
-XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC
-XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M
-XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000
-XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority
-XX:+ParallelRefProcEnabled -Dlog4j2.formatMsgNoLookups=true"

/minecraft/bin/startup.sh

/minecraft/bin/downscaler.sh &

exec /minecraft/bin/mc-server-runner java $JAVA_FLAGS -XX:+UseCGroupMemoryLimitForHeap -XX:MaxRAMFraction=1 -Xms${MIN_MEMORY:-1G} -Xmx${MAX_MEMORY:-1G} -jar server.jar