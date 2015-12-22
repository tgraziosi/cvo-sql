SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE  PROCEDURE	[dbo].[ib_reconciliation_sp]
			@debug_flag		integer	 = 0,
			@trial_flag 		integer	 =  0  
			



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

	DECLARE @ib_recon			INTEGER
	DECLARE @sql				NVARCHAR(3200)
	DECLARE @pcn				varchar(16)

	SET @procedure_name='ib_reconciliation_sp'
		
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

		SELECT @return_value = 0, @ib_recon = 0
		
	
	SELECT @location = @procedure_name + ': Location ' + 'Check if #ib_recon exists' + ', line: ' + RTRIM(LTRIM(STR(48))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ib_recon') IS NULL) BEGIN
			SELECT @ib_recon = 1
		END
		IF @ib_recon = 0 BEGIN
				
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

				RETURN -100
		END
		
	SELECT @location = @procedure_name + ': Location ' + 'Insert into #ib_recon header records' + ', line: ' + RTRIM(LTRIM(STR(57))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #ib_recon (	record_type,	journal_ctrl_num,	ib_trx_ctrl_num,
					trx_type,	ib_trx_desc,		date_applied,
					from_org_id,	to_org_id,		account_code,
					amount,		total_dr,		total_cr,
					total)	 
			SELECT	DISTINCT 1,		'',			'',
					0,		'',			0,
					h.controlling_org_id,	h.detail_org_id,'',
					0,		0,			0,
					0	
			FROM #ibhdr h
			 	INNER JOIN #ibdet d
					ON  h.id =d.id
			GROUP BY      h.controlling_org_id, h.detail_org_id
		
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














	


	SELECT @location = @procedure_name + ': Location ' + 'Insert into #ib_recon detail records' + ', line: ' + RTRIM(LTRIM(STR(89))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #ib_recon (	record_type,	journal_ctrl_num,	ib_trx_ctrl_num,
					trx_type,	ib_trx_desc,		date_applied,
					from_org_id,	to_org_id,		account_code,
					amount,		total_dr,		total_cr,
					total)	 
			SELECT		2,		l.trx_ctrl_num,		h.trx_ctrl_num,
					h.trx_type,	t.description,		DATEDIFF(DD,'1/1/80', h.date_applied)+722815,
					h.controlling_org_id,h.detail_org_id,	d.account_code,
					d.amount,	0,			0,
					0	
			FROM #ibhdr h
			 	INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=1
	
				INNER JOIN iblink l
					ON h.id = l.id
					AND l.sequence_id=2  --  To have the jounal
				
				INNER JOIN ibtrxtype t
					ON h.trx_type = t.trx_type
		
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


	SELECT @location = @procedure_name + ': Location ' + 'Insert into #ib_recon detail records - INVERSE' + ', line: ' + RTRIM(LTRIM(STR(113))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #ib_recon (	record_type,	journal_ctrl_num,	ib_trx_ctrl_num,
					trx_type,	ib_trx_desc,		date_applied,
					from_org_id,	to_org_id,		account_code,
					amount,		total_dr,		total_cr,
					total)	 
			SELECT		2,		l.trx_ctrl_num,		h.trx_ctrl_num,
					h.trx_type,	t.description,		DATEDIFF(DD,'1/1/80', h.date_applied)+722815,
					h.detail_org_id,h.controlling_org_id, 	d.account_code,
					d.amount ,	0,			0,
					0	
			FROM #ibhdr h
			 	INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=2
	
				INNER JOIN iblink l
					ON h.id = l.id
					AND l.sequence_id=2  --  To have the jounal

				INNER JOIN ibtrxtype t
					ON h.trx_type = t.trx_type
		
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


		
	
	SELECT @location = @procedure_name + ': Location ' + 'Table for debits' + ', line: ' + RTRIM(LTRIM(STR(139))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		SELECT controlling_org_id, detail_org_id, SUM(d.amount )debit INTO #temp_org_debit
			FROM #ibhdr h
			INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=1
					AND d.amount >0
		GROUP BY controlling_org_id, detail_org_id
		UNION 
		SELECT  detail_org_id,controlling_org_id, SUM(d.amount )debit
			FROM #ibhdr h
			INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=2
					AND d.amount >0
		GROUP BY controlling_org_id, detail_org_id
		
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


	SELECT controlling_org_id, detail_org_id, sum(debit) debit INTO #org_debit FROM #temp_org_debit GROUP BY controlling_org_id, detail_org_id

	SELECT @location = @procedure_name + ': Location ' + 'Table for credit' + ', line: ' + RTRIM(LTRIM(STR(159))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		SELECT controlling_org_id, detail_org_id, SUM(d.amount )credit INTO #temp_org_credit
			FROM #ibhdr h
			INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=1
					AND d.amount <0
		GROUP BY controlling_org_id, detail_org_id
		UNION 
		SELECT  detail_org_id,controlling_org_id, SUM(d.amount )credit
			FROM #ibhdr h
			INNER JOIN #ibdet d
					ON  h.id =d.id
					AND d.sequence_id=2
					AND d.amount <0
		GROUP BY controlling_org_id, detail_org_id
		
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

	
	SELECT controlling_org_id, detail_org_id, sum(credit) credit INTO #org_credit FROM #temp_org_credit GROUP BY controlling_org_id, detail_org_id

	
	SELECT @location = @procedure_name + ': Location ' + 'Update Debit' + ', line: ' + RTRIM(LTRIM(STR(180))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ib_recon 
			SET total_dr = d.debit
		FROM  #ib_recon i
			INNER JOIN #org_debit d
				ON i.from_org_id = d.controlling_org_id
				AND i.to_org_id = d.detail_org_id
		
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


	SELECT @location = @procedure_name + ': Location ' + 'Update Credit' + ', line: ' + RTRIM(LTRIM(STR(189))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ib_recon 
			SET total_cr = d.credit
		FROM  #ib_recon i
			INNER JOIN #org_credit d
				ON i.from_org_id = d.controlling_org_id
				AND i.to_org_id = d.detail_org_id
		
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





	SELECT @location = @procedure_name + ': Location ' + 'Update total' + ', line: ' + RTRIM(LTRIM(STR(201))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ib_recon 
			SET total = total_dr  + total_cr
		WHERE record_type =1
	
		
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

	
	
	SELECT @location = @procedure_name + ': Location ' + 'Update reconciled_flag only if is a final process' + ', line: ' + RTRIM(LTRIM(STR(209))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		IF @trial_flag = 1 		
		BEGIN			
			UPDATE ibdet
			SET  reconciled_flag =1
			FROM ibdet d
				INNER JOIN #ibdet t
				ON d.id = t.id
				AND d.sequence_id = t.sequence_id
		
		END

DROP TABLE #org_credit
DROP TABLE #org_debit
DROP TABLE #temp_org_credit
DROP TABLE #temp_org_debit


    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value


GO
GRANT EXECUTE ON  [dbo].[ib_reconciliation_sp] TO [public]
GO
