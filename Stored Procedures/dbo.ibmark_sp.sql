SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



CREATE  PROCEDURE	[dbo].[ibmark_sp]
			@process_ctrl_num	nvarchar(16)= '' OUTPUT,
			@where_clause	nvarchar(3000)= NULL,
			@from_id	uniqueidentifier=NULL,
			@to_id	uniqueidentifier= NULL,
			@from_date_entered	datetime	= NULL,
			@to_date_entered	datetime	= NULL,
			@from_date_applied	datetime	= NULL,
			@to_date_applied	datetime	= NULL,
			@from_trx_type	integer	= NULL,
			@to_trx_type	integer	= NULL,
			@from_controlling_org_id	nvarchar(30)	= NULL,
			@to_controlling_org_id	nvarchar(30)	= NULL,
			@from_detail_org_id	nvarchar(30)	= NULL,
			@to_detail_org_id	nvarchar(30)	= NULL,
			@from_currency_code	nvarchar(16)	= NULL,
			@to_currency_code	nvarchar(16)	= NULL,
			@debug_flag	integer	 = NULL



AS

-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"

DECLARE @ibio_exists			INTEGER
DECLARE @iberror_exists		INTEGER
DECLARE @error_code		INTEGER

 
DECLARE @userid			INTEGER
DECLARE @username			NVARCHAR(30)
DECLARE @company_code		NVARCHAR(8)
DECLARE @wc				NVARCHAR(3000)
DECLARE @flag				INTEGER
DECLARE @sql				NVARCHAR(3200)
DECLARE @pcn				varchar(16)

SET @procedure_name='ibmark_sp'

    -- #include "STANDARD ENTRY.INC"
    SET NOCOUNT ON
    SELECT @location = @procedure_name + ': Location ' + 'STANDARD ENTRY' + ', line: ' + RTRIM(LTRIM(STR(3))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
    SELECT @version='1.0'
    IF @debug_flag > 0
        BEGIN
        SELECT 'PS_SIGNAL'='DIAGNOSTIC ON'
        END
    SELECT @buf = @procedure_name + ': Entry (version ' + @version + ') at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END
    SELECT @return_value = 0, @transaction_started = 0
    -- end "STANDARD ENTRY.INC"


SELECT @return_value = 0

SELECT @location = @procedure_name + ': Location ' + 'Get userid' + ', line: ' + RTRIM(LTRIM(STR(44))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret = ibget_userid_sp @userid OUTPUT, @username OUTPUT

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

IF @ret <> 0 BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -130
END

SELECT @location = @procedure_name + ': Location ' + 'Get company_code' + ', line: ' + RTRIM(LTRIM(STR(52))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @company_code = company_code FROM glco

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

IF @rowcount = 0 BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -110
END

SELECT @location = @procedure_name + ': Location ' + 'Generate process_ctrl_num' + ', line: ' + RTRIM(LTRIM(STR(60))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret = pctrladd_sp @pcn OUTPUT, 'Inter-branch posting', @userid, 6000, @company_code, 0

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

IF @ret <> 0 BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -120
END

SELECT @location = @procedure_name + ': Location ' + 'Check for ranges' + ', line: ' + RTRIM(LTRIM(STR(68))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF @where_clause IS NULL AND
@from_id IS NULL AND
@to_id IS NULL AND
@from_date_entered IS NULL AND
@to_date_entered IS NULL AND
@from_date_applied IS NULL AND
@to_date_applied IS NULL AND
@from_trx_type IS NULL AND
@to_trx_type IS NULL AND
@from_controlling_org_id IS NULL AND
@to_controlling_org_id IS NULL AND
@from_detail_org_id IS NULL AND
@to_detail_org_id IS NULL AND
@from_currency_code IS NULL AND
@to_currency_code IS NULL BEGIN
	SELECT @process_ctrl_num = @pcn
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN 0
END

SELECT @location = @procedure_name + ': Location ' + 'Build where_clause' + ', line: ' + RTRIM(LTRIM(STR(89))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @wc = '1=1 ', @flag = 0
IF @from_id IS NOT NULL AND @to_id IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_id)) + ''' AND ''' + RTRIM(LTRIM(@to_id)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_date_entered IS NOT NULL AND @to_date_entered IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_date_entered)) + ''' AND ''' + RTRIM(LTRIM(@to_date_entered)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_date_applied IS NOT NULL AND @to_date_applied IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_date_applied)) + ''' AND ''' + RTRIM(LTRIM(@to_date_applied)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_trx_type IS NOT NULL AND @to_trx_type IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_trx_type)) + ''' AND ''' + RTRIM(LTRIM(@to_trx_type)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_controlling_org_id IS NOT NULL AND @to_controlling_org_id IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_controlling_org_id)) + ''' AND ''' + RTRIM(LTRIM(@to_controlling_org_id)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_detail_org_id IS NOT NULL AND @to_detail_org_id IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_detail_org_id)) + ''' AND ''' + RTRIM(LTRIM(@to_detail_org_id)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @from_currency_code IS NOT NULL AND @to_currency_code IS NOT NULL BEGIN
	SELECT @wc = @wc + ' AND id BETWEEN ''' + RTRIM(LTRIM(@from_currency_code)) + ''' AND ''' + RTRIM(LTRIM(@to_currency_code)) + ''''
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	SELECT @flag = 1
END

IF @flag = 1 BEGIN
	SELECT @where_clause = @wc
END

IF @where_clause IS NULL OR  (DATALENGTH(ISNULL(RTRIM(LTRIM(@where_clause)),0))=0)  BEGIN
	
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

	RETURN -100
END

SELECT @location = @procedure_name + ': Location ' + 'Mark transactions' + ', line: ' + RTRIM(LTRIM(STR(142))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @sql = 'UPDATE ibifc SET process_ctrl_num = ''' + RTRIM(LTRIM(@process_ctrl_num)) + ''' WHERE ' + RTRIM(LTRIM(@where_clause)) + ' AND state_flag = 0 AND process_ctrl_num IS BLANK'
BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
EXEC (@sql)

    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END



    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @rowcount
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibmark_sp] TO [public]
GO
