select *
from sys.dm_exec_requests
cross apply sys.dm_exec_sql_text(sql_handle);

