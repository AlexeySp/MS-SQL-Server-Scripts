IF OBJECT_ID ( 'logErrorInfo', 'P' ) IS NOT NULL   
    DROP PROCEDURE usp_GetErrorInfo;  
GO  

CREATE PROCEDURE logErrorInfo
    @PROCEDURE_NAME varchar(100)
    --could be resolved in MS SQL 2016+ into a source object as declare @procedure_name = @PROCEDURE_NAME varchar(100) = OBJECT_NAME(@@PROCID);
AS  
--INSERT INTO [db_name].[schema_name].[logging_table_name]
SELECT  
     ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,COALESCE(ERROR_PROCEDURE(), @PROCEDURE_NAME) AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;
;  
GO   

--Example 
CREATE PROCEDURE HowToUseIt AS
BEGIN
    BEGIN TRY
        declare @PROCEDURE_NAME varchar(100) = OBJECT_NAME(@@PROCID);
        select 1/0;
    END TRY
    BEGIN CATCH
        EXEC logErrorInfo @PROCEDURE_NAME;
    END CATCH
END

EXEC HowToUseIt;