CREATE TABLE [dbo].[glrefact]
(
[timestamp] [timestamp] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glrefact_del_trg]
	ON [dbo].[glrefact]
	FOR DELETE AS
BEGIN

	--Return if ep_temp_glref_acct_type has not have any records in it
	If ((select count(*) from deleted i, ep_temp_glref_acct_type t 
		where i.account_mask = t.account_mask) = 0)
		Return

	--Return if chart of account has not set up yet.
	If ((select count(*) from ep_temp_glchart ) = 0)
		Return
	
	--Note: At this point all the record in ep_temp_glref_acct_type are sorted in the order of
	-- reference_flag which are Excluded(1), Required(3), Optional(4)

	--Updating ep_temp_glchart with new modified_dt
	update ep_temp_glchart
	set modified_dt = getdate()
	from deleted d
	where account_code like d.account_mask

	--Set records in epcoa to deleted
	update epcoa
	set deleted_flg = 1
	from ep_temp_glref r, deleted d
	where 	epcoa.reference_code = r.reference_code and
		epcoa.account_code like d.account_mask and
		epcoa.deleted_dt is null 
	
	--Deleted record off from ep_temp_glref_acct_type  
	delete ep_temp_glref_acct_type  
	from deleted d
	where ep_temp_glref_acct_type.account_mask = d.account_mask

	--Reverse the deleted flag
	UPDATE	epcoa
	SET	deleted_flg = 0
	FROM	ep_temp_glref r, ep_temp_glref_acct_type e
	WHERE 	epcoa.reference_code = r.reference_code 
	AND	epcoa.deleted_dt is NULL 
	AND	epcoa.deleted_flg = 1 
	AND	r.reference_type = e.reference_type
	AND	epcoa.account_code LIKE e.account_mask

	--Set records in epcoa to deleted
	update epcoa
	set 	deleted_dt = getdate(),
		inactive_dt = getdate(),
		modified_dt = getdate(),
		deleted_flg = 0
	from 	ep_temp_glref r
	where 	epcoa.reference_code = r.reference_code and
		epcoa.deleted_dt is null and
		epcoa.deleted_flg = 1 

	--Insert the records that not exists
	INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt, deleted_dt)
	SELECT newid(), g.account_code, g.account_description, g.active_dt, 
		GETDATE(), r.reference_code, r.description, GETDATE(), GETDATE()
	FROM ep_temp_glchart g (nolock), ep_temp_glref r (nolock), deleted d, ep_temp_glref_acct_type et--,glchart_proc gc, glref_proc gr  --ggr 
	WHERE  g.account_code LIKE d.account_mask
	AND	et.account_mask = d.account_mask
	AND	r.reference_type = et.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND  g.account_code not In
	  ( SELECT DISTINCT e.account_code 
	    FROM epcoa e
	    WHERE e.account_code = g.account_code 
	    AND e.reference_code = r.reference_code)	

END
GO
DISABLE TRIGGER [dbo].[glrefact_del_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glrefact_ins_trg]
	ON [dbo].[glrefact]
	FOR INSERT AS
BEGIN

	--Return if glratyp has not have any records in it
	If ((SELECT count(*) FROM inserted i, glratyp t 
		WHERE i.account_mask = t.account_mask) = 0)
		Return

	--Return if chart of account has not SET up yet.
	If ((SELECT count(*) FROM ep_temp_glchart ) = 0)
		Return
	
	--Populate ep_temp_glref_acct_type
	
	INSERT Into ep_temp_glref_acct_type
		Select distinct i.account_mask,i.reference_flag,glratyp.reference_type
		from glrefact glrefact, glratyp glratyp, ep_temp_glref r, inserted i 
        	where glrefact.account_mask=glratyp.account_mask
        	and r.reference_type=glratyp.reference_type
        	and i.account_mask = glrefact.account_mask 
        	--Order by i.account_mask

		/*SELECT i.account_mask, i.reference_flag, t.reference_type			ggr
		FROM inserted i, glratyp t 
		WHERE i.account_mask = t.account_mask 
		Order by i.account_mask*/

	--Convert all reference_flag optional flag FROM 2 to 4
	UPDATE ep_temp_glref_acct_type
	SET reference_flag = 4
	WHERE reference_flag = 2

	--Updating ep_temp_glchart with new modified_dt
	UPDATE ep_temp_glchart
	SET modified_dt = GETDATE()
	FROM inserted i
	WHERE account_code LIKE i.account_mask

	INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
	SELECT newid(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
	FROM ep_temp_glchart g (nolock), ep_temp_glref r (nolock), inserted i, ep_temp_glref_acct_type et--, glchart_proc gc, glref_proc gr  --ggr
	WHERE 	g.account_code LIKE i.account_mask
	AND	et.account_mask = i.account_mask
	AND	r.reference_type = et.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
       -- AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND 	g.account_code not In
		( SELECT DISTINCT e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)

	--SET account to inactive if inactive flag is on
	--Case of Required
	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM inserted i
	WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.reference_code IS NULL 
	AND	i.reference_flag = 3
	AND	(epcoa.inactive_dt IS NULL OR 
		 epcoa.inactive_dt > GETDATE())

	-- SET all the account that have reference code to inactive
	--Case of Required
	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r, inserted i
	WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.reference_code = r.reference_code 
--	AND	r.reference_type = i.reference_type 
	AND	i.reference_flag = 1
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())


	--SET account to inactive if inactive flag is on
	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r (nolock), ep_temp_glchart g, inserted i
	WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE i.account_mask 
	AND	epcoa.reference_code = r.reference_code 
--	AND	r.reference_type = i.reference_type 
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

END
GO
DISABLE TRIGGER [dbo].[glrefact_ins_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[glrefact_integ_upd_trg]
	ON [dbo].[glrefact]
	FOR UPDATE AS
BEGIN	

	DELETE epintegrationrecs 
	WHERE action = 'U' AND type = 5 
		AND id_code IN ( SELECT id_code FROM Inserted, epintegrationrecs WHERE mask = account_mask )
		AND mask IN ( SELECT account_mask FROM Inserted, epintegrationrecs WHERE mask = account_mask )
	
	INSERT INTO epintegrationrecs 
	SELECT Distinct  REF.reference_type, INS.account_mask, 5, 'U', 0 
	FROM Inserted INS
		INNER JOIN glratyp RYP ON  INS.account_mask = RYP.account_mask 
		INNER JOIN glref REF ON REF.reference_type = RYP.reference_type
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask

END

GO
DISABLE TRIGGER [dbo].[glrefact_integ_upd_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[glrefact_integration_del_trg]
	ON [dbo].[glrefact]
	FOR DELETE AS
BEGIN

	CREATE TABLE #Type (ObjectExists INT)	

	DECLARE @query VARCHAR(8000)

	CREATE TABLE #TEMPCoas
		(
		guid VARCHAR(50) DEFAULT NEWID() NOT NULL,
		account_code VARCHAR(32) NOT NULL,
		account_description VARCHAR(50) NOT NULL,
		reference_type VARCHAR(8) NULL,
		reference_code VARCHAR(32) NULL,
		reference_description VARCHAR(40) NULL,
		active_date INTEGER NULL,
		inactive_date INTEGER NULL,
		status VARCHAR(1) NOT NULL
		)

	CREATE UNIQUE INDEX hist_index1
	ON #TEMPCoas (account_code, reference_code, reference_type)

	CREATE UNIQUE INDEX hist_index2
	ON #TEMPCoas (guid)

	DECLARE @DATETIME DATETIME
	SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

	/*--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------*/

	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type,REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date, 'D'
	FROM deleted DEL 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE DEL.account_mask
		INNER JOIN glratyp TYP ON  TYP.account_mask = DEL.account_mask
		INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE REF.status_flag = 0 AND CHRT.inactive_flag = 0 
	AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
	

	/*--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------*/
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date, 'I'
	FROM deleted DEL 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE DEL.account_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE CHRT.inactive_flag = 0 
	AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END


	/*--------------------------------------------------------------INSERT ACCOUNTS------*/

	UPDATE HIST
	SET HIST.status = COAS.status
	FROM glchart_history HIST, #TEMPCoas COAS
	WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

	DROP TABLE #TEMPCoas

	
END

GO
DISABLE TRIGGER [dbo].[glrefact_integration_del_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[glrefact_integration_ins_trg]
	ON [dbo].[glrefact]
	FOR INSERT AS
BEGIN

	CREATE TABLE #TEMPCoas
		(
		guid VARCHAR(50) DEFAULT NEWID() NOT NULL,
		account_code VARCHAR(30) NOT NULL,
		account_description VARCHAR(40) NOT NULL,
		reference_type VARCHAR(8) NULL,
		reference_code VARCHAR(32) NULL,
		reference_description VARCHAR(40) NULL,
		active_date INTEGER NULL,
		inactive_date INTEGER NULL,
		status VARCHAR(1) Default('N'),
		reference_flag INT
		)

	CREATE UNIQUE INDEX hist_index1
	ON #TEMPCoas (account_code, reference_code, reference_type)

	CREATE UNIQUE INDEX hist_index2
	ON #TEMPCoas (guid)

	CREATE TABLE #TEMPCoasDeleted
	(
		guid VARCHAR(50) NOT NULL DEFAULT (NEWID()),
		account_code VARCHAR(32) NOT NULL,
		account_description VARCHAR(40) NOT NULL,
		reference_code VARCHAR(32) NULL,
		status varchar(1)
	)

	CREATE UNIQUE INDEX hist_index1
	ON #TEMPCoasDeleted (account_code, reference_code)

	CREATE UNIQUE INDEX hist_index2
	ON #TEMPCoasDeleted (guid)

	DECLARE @DATETIME DATETIME
	SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

	--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------
	/*---Is DISTINCT because the two reference types can has the same reference code, and the mask asosiated to the reference types can match with the same account---*/
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status,reference_flag)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type,REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date, 
	CASE WHEN INS.reference_flag = 1 THEN 'N' ELSE 
		CASE WHEN INS.reference_flag = 2 OR INS.reference_flag = 3 THEN 'I' 
		END			
	END,
	INS.reference_flag
	FROM Inserted INS
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE INS.account_mask
		INNER JOIN glratyp TYP ON  TYP.account_mask = INS.account_mask
		INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE REF.status_flag = 0 AND CHRT.inactive_flag = 0 
	AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END

	
	--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCE CODE, BUT THAT HAS A REFERENCES CODES MARKED AS NOT REQUIRED------
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status,reference_flag)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date, 
	CASE WHEN INS.reference_flag = 1 OR INS.reference_flag = 2 THEN 'I' ELSE 
		CASE WHEN INS.reference_flag = 3 THEN 'D' 
		END			
	END,
	INS.reference_flag
	FROM Inserted INS
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE INS.account_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE  CHRT.inactive_flag = 0 
	AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END

--------------------------------------------------------------GET ACCOUNTS PREVIOUSLY DELETED------

	INSERT #TEMPCoasDeleted (account_code, account_description,	reference_code,status)
	SELECT COAS.account_code, COAS.account_description, COAS.reference_code,COAS.status
	FROM glchart_history HIST
		INNER JOIN #TEMPCoas COAS ON HIST.account_code = COAS.account_code AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

--------------------------------------------------------------CHNAGE STATUS FOR ALL ACCOUNT PREVIOUSLY DELETED------
	UPDATE HIST
		SET HIST.status = COAS.status
	FROM glchart_history HIST, #TEMPCoasDeleted COAS
	WHERE HIST.account_code = COAS.account_code
		AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')
		AND NOT COAS.status = 'N'

	DELETE COAS
	FROM #TEMPCoas COAS, #TEMPCoasDeleted DEL
	WHERE COAS.account_code = DEL.account_code AND ISNULL(COAS.reference_code,'') = ISNULL(DEL.reference_code,'')

--------------------------------------------------------------INSERT ACCOUNTS------
	
	INSERT glchart_history (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT 	account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status 
	FROM #TEMPCoas
	WHERE NOT status = 'N'

	DROP TABLE #TEMPCoas

END

GO
DISABLE TRIGGER [dbo].[glrefact_integration_ins_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[glrefact_integration_upd_trg]
	ON [dbo].[glrefact]
	FOR UPDATE AS
BEGIN	

	CREATE TABLE #Type (ObjectExists INT)	

	DECLARE @query VARCHAR(8000)

	CREATE TABLE #TEMPCoas
		(
		guid VARCHAR(50) DEFAULT NEWID() NOT NULL,
		account_code VARCHAR(32) NOT NULL,
		account_description VARCHAR(40) NOT NULL,
		reference_type VARCHAR(8) NULL,
		reference_code VARCHAR(32) NULL,
		reference_description VARCHAR(40) NULL,
		active_date INTEGER NULL,
		inactive_date INTEGER NULL,
		status VARCHAR(1) Default('N'),
		)

	CREATE UNIQUE INDEX hist_index1
	ON #TEMPCoas (account_code, reference_code, reference_type)

	CREATE UNIQUE INDEX hist_index2
	ON #TEMPCoas (guid)

	DECLARE @DATETIME DATETIME
	SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

	/*--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------*/
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type, REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date,
	CASE WHEN DEL.reference_flag = 1 AND (INS.reference_flag = 2 OR INS.reference_flag = 3) THEN 'I' ELSE 
		CASE WHEN DEL.reference_flag = 2 AND INS.reference_flag = 1 THEN 'D' ELSE 
			CASE WHEN DEL.reference_flag = 2 AND INS.reference_flag = 3 THEN 'N' ELSE 
				CASE WHEN DEL.reference_flag = 3 AND INS.reference_flag = 1 THEN 'D' ELSE 
					CASE WHEN DEL.reference_flag = 3 AND INS.reference_flag = 2 THEN 'N' 
					END
				END
			END
		END			
	END
	FROM glchart CHRT
		INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
		INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
		INNER JOIN deleted DEL ON  TYP.account_mask = DEL.account_mask
		INNER JOIN Inserted INS ON TYP.account_mask = INS.account_mask 
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE REF.status_flag = 0 AND CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END


	/*--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------*/
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date,
	CASE WHEN DEL.reference_flag = 1 AND INS.reference_flag = 2 THEN 'N' ELSE 
		CASE WHEN DEL.reference_flag = 1 AND INS.reference_flag = 3 THEN 'D' ELSE 
			CASE WHEN DEL.reference_flag = 2 AND INS.reference_flag = 1 THEN 'N' ELSE 
				CASE WHEN DEL.reference_flag = 2 AND INS.reference_flag = 3 THEN 'D' ELSE 
					CASE WHEN DEL.reference_flag = 3 AND (INS.reference_flag = 1 OR INS.reference_flag = 2) THEN 'I'
					END
				END
			END
		END			
	END
	FROM glchart CHRT
		INNER JOIN Inserted INS ON CHRT.account_code LIKE INS.account_mask
		INNER JOIN deleted DEL ON  INS.account_mask = DEL.account_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE  CHRT.inactive_flag = 0 
	AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END

/*--------------------------------------------------------------INSERT ACCOUNTS------*/

	UPDATE HIST
	SET	HIST.status = COAS.status 
	FROM glchart_history HIST, #TEMPCoas COAS
	WHERE HIST.account_code = COAS.account_code
		AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')
		AND NOT COAS.status = 'N'

	INSERT glchart_history (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT 	COAS.account_code, COAS.account_description, COAS.reference_type, COAS.reference_code, COAS.reference_description, COAS.active_date, COAS.inactive_date, COAS.status 
	FROM #TEMPCoas COAS
		LEFT JOIN glchart_history HIST ON COAS.account_code = HIST.account_code AND ISNULL(COAS.reference_code,'') = ISNULL(HIST.reference_code,'') AND COAS.reference_code = HIST.reference_code
	WHERE HIST.account_code IS NULL
		AND NOT COAS.status = 'N'

	DROP TABLE #TEMPCoas


END

GO
DISABLE TRIGGER [dbo].[glrefact_integration_upd_trg] ON [dbo].[glrefact]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glrefact_upd_trg]
	ON [dbo].[glrefact]
	FOR UPDATE AS
BEGIN
	--Note: This trigger is assumed that the user CANNOT modified Account Mask because,
	-- it's not allowing in eFinancials application.

	--Return the process if there is no change in the following columns
	if ((	SELECT count(*) FROM inserted i, deleted d
		WHERE 	d.reference_flag <> i.reference_flag) = 0)
		Return
			
	--If there is no records in ep_temp_glref_acct_type, it indicates that the
	--account mask in glratyp table need to be populate before calling this process
	If ((SELECT count(*) 
		FROM ep_temp_glref_acct_type t, inserted i, deleted d
		WHERE 	d.account_mask = t.account_mask 
		or	i.account_mask = t.account_mask) = 0)
		Return

	--UPDATE Excluded(1), Required(3)
	UPDATE ep_temp_glref_acct_type 
	SET reference_flag = i.reference_flag
	FROM inserted i 
	WHERE ep_temp_glref_acct_type.account_mask = i.account_mask AND
		i.reference_flag <> 2

	--UPDATE Optional(4)
	UPDATE ep_temp_glref_acct_type 
	SET reference_flag = 4
	FROM inserted i 
	WHERE ep_temp_glref_acct_type.account_mask = i.account_mask AND
		i.reference_flag = 2

	--Updating ep_temp_glchart with new modified_dt
	UPDATE ep_temp_glchart
	SET modified_dt = GETDATE()
	FROM inserted i
	WHERE ep_temp_glchart.account_code like i.account_mask

	--INSERT the account that not exist in epcoa
	INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
	SELECT NEWID(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
	FROM ep_temp_glchart g (nolock), ep_temp_glref r (nolock), inserted i, ep_temp_glref_acct_type et--,glchart_proc gc, glref_proc gr  --ggr
	WHERE 	g.account_code LIKE i.account_mask 
	AND	et.account_mask = i.account_mask
	AND	r.reference_type = et.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND	g.account_code NOT IN
		( SELECT distinct e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)

	UPDATE epcoa
	SET 	inactive_dt = g.inactive_dt,
		deleted_dt = NULL, 
	    	modified_dt = GETDATE() 
	FROM	ep_temp_glref r, ep_temp_glchart g, inserted i, ep_temp_glref_acct_type e
	WHERE 	epcoa.account_code like i.account_mask 
	AND	epcoa.account_code = g.account_code 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = e.reference_type
	AND	e.account_mask = i.account_mask
	AND	(e.reference_flag = 4 or e.reference_flag = 3)

	--Case of Optional
	UPDATE epcoa
	SET 	inactive_dt = g.inactive_dt,
		deleted_dt = NULL, 
	    	modified_dt = GETDATE() 
	FROM ep_temp_glchart g, inserted i
	WHERE 	epcoa.account_code like i.account_mask 
	AND	epcoa.account_code = g.account_code 
	AND	epcoa.reference_code is NULL 
	AND	i.reference_flag = 2

	--Case of Required
	UPDATE epcoa
	SET 	inactive_dt = GETDATE(),
		deleted_dt = GETDATE(), 
	    	modified_dt = GETDATE() 
	FROM	inserted i
	WHERE 	epcoa.account_code like i.account_mask 
	AND	epcoa.reference_code is NULL 
	AND	i.reference_flag = 3

	--Case of Excluded
	-- SET all the account that have reference code to inactive
	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM	ep_temp_glref g, inserted i, ep_temp_glref_acct_type e
	WHERE 	epcoa.account_code like i.account_mask 
	AND	epcoa.reference_code = g.reference_code 
	AND	g.reference_type = e.reference_type
	AND	e.account_mask = i.account_mask
	AND	e.reference_flag = 1 
	AND	(epcoa.inactive_dt IS NULL OR epcoa.inactive_dt > GETDATE())

	--SET account to inactive if inactive flag is on
	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r (nolock), ep_temp_glchart g, inserted i, ep_temp_glref_acct_type e
	WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code like i.account_mask 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = e.reference_type
	AND	i.account_mask = e.account_mask
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

END
GO
DISABLE TRIGGER [dbo].[glrefact_upd_trg] ON [dbo].[glrefact]
GO
CREATE UNIQUE CLUSTERED INDEX [glrefact_ind_0] ON [dbo].[glrefact] ([account_mask]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glrefact_ind_1] ON [dbo].[glrefact] ([account_mask], [reference_flag]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glrefact] TO [public]
GO
GRANT SELECT ON  [dbo].[glrefact] TO [public]
GO
GRANT INSERT ON  [dbo].[glrefact] TO [public]
GO
GRANT DELETE ON  [dbo].[glrefact] TO [public]
GO
GRANT UPDATE ON  [dbo].[glrefact] TO [public]
GO
