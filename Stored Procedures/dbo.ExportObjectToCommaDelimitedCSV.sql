SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ExportObjectToCommaDelimitedCSV]
	(
	@SourceObjectSchema VARCHAR(20),
	@SourceObjectName VARCHAR(100),
	@DestinationLocation VARCHAR(MAX),
	@TextQualifier CHAR(1) = NULL,
	@DebugMode BIT = 0
	)
AS

--Local variables
DECLARE @FileName VARCHAR(255)
DECLARE @Row VARCHAR(MAX)
DECLARE @Cmd NVARCHAR(4000)
DECLARE @SQL VARCHAR(MAX)
DECLARE @Cursor CURSOR
DECLARE @ColumnName VARCHAR(100)
DECLARE @Fields VARCHAR(MAX)
DECLARE @FileFields VARCHAR(MAX)
DECLARE @Values VARCHAR(MAX)

/*------------------------------------------------------------
	Stage 1: Create temp table for export data.
-------------------------------------------------------------*/
SELECT 
	@Fields = COALESCE(@Fields + '] VARCHAR(1024),' + CHAR(13), '') + '[' +[COLUMN_NAME]
FROM 
	information_schema.columns
WHERE
	TABLE_NAME = @SourceObjectName

SET @Fields = @Fields + '] VARCHAR(1024)'

SET @SQL = '
			IF EXISTS (SELECT * FROM [tempdb].[dbo].[sysobjects] WHERE ID = OBJECT_ID(N''tempdb..##' + @SourceObjectName + '''))
				DROP TABLE ##' + @SourceObjectName +'
			
			CREATE TABLE ##' + @SourceObjectName + '
				(
				' + @Fields + '
				)

			INSERT INTO ##' + @SourceObjectName + '
			SELECT * FROM [' + @SourceObjectSchema + '].[' + @SourceObjectName + ']
					
			ALTER TABLE ##' + @SourceObjectName + '
			ADD [Order] INT

			UPDATE ##' + @SourceObjectName + ' SET [Order] = 2
			
			'
		
SET @Fields = NULL
		
-----------------
IF @DebugMode = 1
	BEGIN
		PRINT '------------------------------------------'
		PRINT 'Create temp table for export data:'
		PRINT @SQL
		PRINT '------------------------------------------'
	END
-----------------
EXEC(@SQL)

/*------------------------------------------------------------
	Stage 2: Dynamically build insert statement to add 
			object fields names to temp table as data.
-------------------------------------------------------------*/

--Get fields names from temp table
SELECT 
	@Fields = COALESCE(@Fields + '],' + CHAR(13), '') + '[' +[COLUMN_NAME]
FROM 
	[tempdb].information_schema.columns
WHERE
	TABLE_NAME = '##' + @SourceObjectName

--Get fields names for CSV file
SELECT 
	@FileFields = COALESCE(@FileFields + '],' + CHAR(13), '') + '[' +[COLUMN_NAME]
FROM 
	information_schema.columns
WHERE
	TABLE_SCHEMA = @SourceObjectSchema
	AND TABLE_NAME = @SourceObjectName

--Get values for dynamic insert
SELECT 
	@Values = COALESCE(@Values + ''',' + CHAR(13), '') + '''' +[COLUMN_NAME]
FROM 
	information_schema.columns
WHERE
	TABLE_SCHEMA = @SourceObjectSchema
	AND TABLE_NAME = @SourceObjectName

--Add missing string parts after row coalesce
SET @Fields = @Fields + ']'
SET @FileFields = @FileFields + ']'
SET @Values = @Values + '''' + ', ''1'''

--Add column names to temp table as data
SET @SQL = '
			INSERT INTO ##' + @SourceObjectName + '
				(
				' + @Fields + '
				)
			VALUES
				(
				' + @Values + '
				)
			'
-----------------
IF @DebugMode = 1
	BEGIN
		PRINT '------------------------------------------'
		PRINT 'Add column names to temp table as data:'
		PRINT @SQL
		PRINT '------------------------------------------'
	END
-----------------
EXEC(@SQL)


/*------------------------------------------------------------
	Stage 3: Concatenate text qualifer to field values.
-------------------------------------------------------------*/
IF @TextQualifier IS NULL
	BEGIN
		-----------------
		IF @DebugMode = 1
			BEGIN
				PRINT '------------------------------------------'
				PRINT 'Text qualifier not set'
				PRINT '------------------------------------------'
			END
		-----------------
	END
ELSE
	BEGIN
		--Set field qualifiers for CSV file
		SET @Cursor = CURSOR FOR
								SELECT 
									[COLUMN_NAME]
								FROM 
									information_schema.columns
								WHERE
									TABLE_SCHEMA = @SourceObjectSchema
									AND TABLE_NAME = @SourceObjectName

		OPEN @Cursor
		FETCH NEXT FROM @Cursor INTO
									@ColumnName

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
	
			SET @SQL =

			'
			UPDATE
				##' + @SourceObjectName + '
			SET
				[' + @ColumnName + '] = QUOTENAME([' + @ColumnName + '], ''' + @TextQualifier + ''') 
			'

			-----------------
			IF @DebugMode = 1
				BEGIN
					PRINT '------------------------------------------'
					PRINT 'Set field qualifiers for CSV file:'
					PRINT @SQL
					PRINT '------------------------------------------'
				END
			-----------------

			EXEC(@SQL)
			FETCH NEXT FROM @Cursor INTO
										@ColumnName
		END --end cursor block		
		CLOSE @Cursor

END --end if block
DEALLOCATE @Cursor --last use of cursor


/*------------------------------------------------------------
	Stage 4: Create CSV file.
-------------------------------------------------------------*/
SELECT
	@FileName = @SourceObjectName + '_' + REPLACE(CONVERT(VARCHAR, GETDATE(), 103),'/','') + REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':','') + '.csv'

SET @Cmd = 'bcp "SELECT ' + @FileFields + ' FROM ##' + @SourceObjectName + ' ORDER BY [Order]" queryout "' + @DestinationLocation + '\' + @FileName + '" -T -c -t,'

IF @DebugMode = 1
	BEGIN
		BEGIN TRY
			EXEC [master].[dbo].[xp_cmdshell] @Cmd

			--User feedback
			SELECT 
				'Your file has been created:' AS 'Message',
				@DestinationLocation + '\' + @FileName AS 'Location'
		END TRY
		BEGIN CATCH
			SELECT
				'CSV file not created' AS 'Info',
				ERROR_MESSAGE() AS 'Error Message'
		END CATCH
	END
ELSE
	BEGIN
		BEGIN TRY
			EXEC [master].[dbo].[xp_cmdshell] @Cmd, NO_OUTPUT

			--User feedback
			SELECT 
				'Your file has been created:' AS 'Message',
				@DestinationLocation + '\' + @FileName AS 'Location'
		END TRY
		BEGIN CATCH
			SELECT
				'CSV file not created' AS 'Info',
				ERROR_MESSAGE() AS 'Error Message'
		END CATCH
	END

--Clean up
SET @SQL = '
			IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE ID = OBJECT_ID(N''tempdb..##' + @SourceObjectName + '''))
			DROP TABLE ##' + @SourceObjectName +'
			'
EXEC(@SQL)

GO
