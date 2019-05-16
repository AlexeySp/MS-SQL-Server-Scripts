declare @tableName nvarchar(300), @indexId nvarchar(300), @indexName nvarchar(300), @indexSize nvarchar(300), @dbName nvarchar(300), @query nvarchar(2000), @fillFactor int, @Rows nvarchar(300), @TotalSpaceMB nvarchar(300), @UsedSpaceMB nvarchar(300);

select @dbName = db_name() ;

IF OBJECT_ID('indexFragmentation', 'U') IS NOT NULL
DROP TABLE indexFragmentation;

create table indexFragmentation
([table Name] varchar(200), [index Name] varchar(200), index_id varchar(200), [rows] int, [TotalSpaceMB] int, [UsedSpaceMB] int, partition_number int, alloc_unit_type_desc varchar(200), index_level int, page_count int, avg_fragmentation_in_percent float, avg_page_space_used_in_percent float, indexCommand nvarchar(500));

declare indexCursor cursor for
with SpaceInfo(ObjectId, IndexId, TableName, IndexName
    ,Rows, TotalSpaceMB, UsedSpaceMB)
as
( 
    select  
        t.object_id as [ObjectId]
        ,i.index_id as [IndexId]
        ,s.name + '.' + t.Name as [TableName]
        ,i.name as [Index Name]
        ,sum(p.[Rows]) as [Rows]
        ,sum(au.total_pages) * 8 / 1024 as [Total Space MB]
        ,sum(au.used_pages) * 8 / 1024 as [Used Space MB]
    from    
        sys.tables t with (nolock) join 
            sys.schemas s with (nolock) on 
                s.schema_id = t.schema_id
            join sys.indexes i with (nolock) on 
                t.object_id = i.object_id
            join sys.partitions p with (nolock) on 
                i.object_id = p.object_id and 
                i.index_id = p.index_id
            cross apply
            (
                select 
                    sum(a.total_pages) as total_pages
                    ,sum(a.used_pages) as used_pages
                from sys.allocation_units a with (nolock)
                where p.partition_id = a.container_id 
            ) au
    where   
        i.object_id > 255
    group by
        t.object_id, i.index_id, s.name, t.name, i.name
)
select 
    IndexId, TableName, IndexName, Rows, TotalSpaceMB, UsedSpaceMB
from 
    SpaceInfo		
order by
    TotalSpaceMB desc
option (recompile);

open indexCursor

fetch next from indexCursor 
into @indexId, @tableName, @indexName, @Rows, @TotalSpaceMB, @UsedSpaceMB;

exec sp_executesql @query;

WHILE @@FETCH_STATUS = 0  
begin 
fetch next from indexCursor 
 into @indexId, @tableName, @indexName, @Rows, @TotalSpaceMB, @UsedSpaceMB;;
 
set @query = N'insert into indexFragmentation select ''' + @tableName + ''', ''' + @indexName + ''', ''' + @Rows + ''', ''' + @TotalSpaceMB + ''', '''+ @UsedSpaceMB + ''',index_id, partition_number, alloc_unit_type_desc, index_level, page_count, avg_fragmentation_in_percent, avg_page_space_used_in_percent, null from sys.dm_db_index_physical_stats' +
 N'(db_id(N''' + @dbName + '''), object_id(N''' + @tableName + '''), ' + @indexId + ',null, ''detailed'' )';

  exec sp_executesql @query;
end 
CLOSE indexCursor; 
DEALLOCATE indexCursor;  

Update indexFragmentation 
SET    indexCommand = 'ALTER INDEX ' + [index Name] + ' ON ' + [table Name] + ' REORGINIZE'
where avg_page_space_used_in_percent < 70 or avg_fragmentation_in_percent > 30;


Update indexFragmentation 
SET    indexCommand = 'ALTER INDEX ' + [index Name] + ' ON ' + [table Name] + ' REBUILD'
where avg_page_space_used_in_percent < 70 or avg_fragmentation_in_percent > 30;



select *
from indexFragmentation
where indexCommand is not null
order by totalSpaceMb desc;



