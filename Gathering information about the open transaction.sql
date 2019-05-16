SELECT  st.session_id ,
        st.is_user_transaction ,
        dt.database_transaction_begin_time ,
        dt.database_transaction_log_record_count ,
        dt.database_transaction_log_bytes_used
FROM    sys.dm_tran_session_transactions st
        JOIN sys.dm_tran_database_transactions dt ON st.transaction_id = dt.transaction_id
                                                     AND dt.database_id = DB_ID('master')
WHERE   st.session_id = <SPID>