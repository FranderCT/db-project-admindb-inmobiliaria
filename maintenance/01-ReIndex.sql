use AltosDelValle
GO

EXEC sp_MSforeachtable 'ALTER INDEX ALL ON ? REBUILD';
GO