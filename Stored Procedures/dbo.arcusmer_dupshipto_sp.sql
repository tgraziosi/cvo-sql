SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                






















CREATE PROCEDURE [dbo].[arcusmer_dupshipto_sp]
AS

DECLARE @seqid			SMALLINT,
		@maxseqid		SMALLINT,
		@object_id		VARCHAR(16),
		@table_name		VARCHAR(128),
		@custid			SMALLINT,
		@maxcustid		SMALLINT,
		@cust_code		VARCHAR(12),
		@old_ship_to	VARCHAR(8),
		@new_ship_to	VARCHAR(8),
		@column_name	VARCHAR(128),
		@shipto_column	VARCHAR(128),
		@buf			VARCHAR(512),
		@str_msg_err	VARCHAR(255),
		@str_msg_ps		VARCHAR(255),
		@error			INTEGER

SELECT @custid = MIN(rec_id) FROM #arcusmer_shipto_tmp


WHILE @custid IS NOT NULL
BEGIN 

	SELECT	@cust_code = customer_code,
			@old_ship_to = shipto,
			@new_ship_to = new_shipto
	FROM	#arcusmer_shipto_tmp
	WHERE	@custid = rec_id

	SELECT	@seqid = MIN(sequence_id)
	FROM	arcusmerobjects
	WHERE	shipto_flag = 1


	WHILE @seqid IS NOT NULL
	BEGIN

		SELECT 	@object_id	= object_id, 
				@table_name	= table_name, 
				@column_name	= column_name,
				@shipto_column  = shipto_column
		FROM 	arcusmerobjects
		WHERE	sequence_id = @seqid
		AND		shipto_flag = 1


		IF ((SELECT 1 FROM syscolumns col, sysobjects obj WHERE col.id = obj.id and obj.name = @table_name AND obj.type = 'U' AND col.name = @column_name)
		  = (SELECT 1 FROM syscolumns col, sysobjects obj WHERE col.id = obj.id and obj.name = @table_name AND obj.type = 'U' AND col.name = @shipto_column))
		BEGIN

			SELECT @buf = 'UPDATE ' + @table_name + ' SET ' + @shipto_column + ' = ''' + @new_ship_to + ''' WHERE ' + @column_name + ' = ''' + @cust_code + ''' AND ' + @shipto_column + ' = ''' + @old_ship_to + ''''

			EXEC (@buf)

			SELECT @error = @@ERROR
			
			IF @error > 0 
			BEGIN
				EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
				EXEC appgetstring_sp 'STR_UPDATING', @str_msg_ps OUT
				SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + RTRIM(LTRIM(CONVERT(CHAR,@custid))) + '-' + RTRIM(LTRIM(CONVERT(CHAR,@seqid))) + ' ' + @str_msg_ps + ' ' + @table_name + '.' + @shipto_column + ' =  "' + @new_ship_to + '"'
		
				SELECT @buf
			END
		END

		SELECT 	@seqid = min(sequence_id)
		FROM	arcusmerobjects
		WHERE	sequence_id > @seqid
		AND		shipto_flag = 1

	END

	SELECT 	@custid = min(rec_id)
	FROM	#arcusmer_shipto_tmp
	WHERE	rec_id > @custid

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcusmer_dupshipto_sp] TO [public]
GO
