USE AltosDelValle;
GO

SELECT 
    t.NAME AS TableName,
    SUM(p.row_count) AS RowCounts,  -- Corregido: usando p.row_count en lugar de p.rows
    SUM(a.total_pages) * 8 AS TotalSpaceKB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.OBJECT_ID
INNER JOIN 
    sys.dm_db_partition_stats p ON i.OBJECT_ID = p.OBJECT_ID
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    i.type <= 1
GROUP BY 
    t.NAME
ORDER BY 
    TotalSpaceKB DESC;
GO



