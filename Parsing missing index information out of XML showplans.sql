WITH XMLNAMESPACES
(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT  MissingIndexNode.value('(MissingIndexGroup/@Impact)[1]', 'float') AS impact ,
        OBJECT_NAME(sub.objectid, sub.dbid) AS calling_object_name ,
        MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Database)[1]',
                               'VARCHAR(128)') + '.'
        + MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Schema)[1]',
                                 'VARCHAR(128)') + '.'
        + MissingIndexNode.value('(MissingIndexGroup/MissingIndex/@Table)[1]',
                                 'VARCHAR(128)') AS table_name ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="EQUALITY"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS equality_columns ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="INEQUALITY"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS inequality_columns ,
        STUFF(( SELECT  ',' + c.value('(@Name)[1]', 'VARCHAR(128)')
                FROM    MissingIndexNode.nodes('MissingIndexGroup/MissingIndex/
ColumnGroup[@Usage="INCLUDE"]/Column') AS t ( c )
              FOR
                XML PATH('')
              ), 1, 1, '') AS include_columns ,
        sub.usecounts AS qp_usecounts ,
        sub.refcounts AS qp_refcounts ,
        qs.execution_count AS qs_execution_count ,
        qs.last_execution_time AS qs_last_exec_time ,
        qs.total_logical_reads AS qs_total_logical_reads ,
        qs.total_elapsed_time AS qs_total_elapsed_time ,
        qs.total_physical_reads AS qs_total_physical_reads ,
        qs.total_worker_time AS qs_total_worker_time ,
        StmtPlanStub.value('(StmtSimple/@StatementText)[1]', 'varchar(8000)') AS statement_text
FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY qs.plan_handle ORDER BY qs.statement_start_offset ) AS StatementID ,
                    qs.*
          FROM      sys.dm_exec_query_stats qs
        ) AS qs
        JOIN ( SELECT   x.query('../../..') AS StmtPlanStub ,
                        x.query('.') AS MissingIndexNode ,
                        x.value('(../../../@StatementId)[1]', 'int') AS StatementID ,
                        cp.* ,
                        qp.*
               FROM     sys.dm_exec_cached_plans AS cp
                        CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
                        CROSS APPLY qp.query_plan.nodes('/ShowPlanXML/BatchSequence/
Batch/Statements/StmtSimple/
QueryPlan/MissingIndexes/
MissingIndexGroup') mi ( x )
             ) AS sub ON qs.plan_handle = sub.plan_handle
                         AND qs.StatementID = sub.StatementID
