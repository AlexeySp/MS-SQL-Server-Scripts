DECLARE @FileName NVARCHAR(260)
SELECT  @FileName = SUBSTRING(path, 0,
                              LEN(path) - CHARINDEX('\', REVERSE(path)) + 1)
        + '\Log.trc'
FROM    sys.traces
WHERE   is_default = 1 ;
SELECT  loginname ,
        hostname ,
        applicationname ,
        databasename ,
        objectName ,
        starttime ,
        e.name AS EventName ,
        databaseid
FROM    sys.fn_trace_gettable(@FileName, DEFAULT) AS gt
        INNER JOIN sys.trace_events e ON gt.EventClass = e.trace_event_id
WHERE   ( gt.EventClass = 47 -- Object:Deleted Event
-- from sys.trace_events
          OR gt.EventClass = 164
        ) -- Object:Altered Event from sys.trace_events
        AND gt.EventSubClass = 0
        AND gt.DatabaseID = DB_ID('AdventureWorks')
