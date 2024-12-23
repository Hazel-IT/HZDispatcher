Example usage:
```sql
BEGIN
    HZLogging.InitialiseSession('Hazel', HZLogging.gc_LOG_LEVEL_CUSTOM_NOISY); /* OMIT if an RDT program as session is already initialised */
    HZLogging.PrintOutputToConsole(); /* OMIT if no console logging is required */

    HZLogging.Log('Useful debugging message here');
END;
/
```