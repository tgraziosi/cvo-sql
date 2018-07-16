CREATE TABLE [dbo].[glchart]
(
[timestamp] [timestamp] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[new_flag] [smallint] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consol_detail_flag] [smallint] NOT NULL,
[consol_type] [smallint] NOT NULL,
[active_date] [int] NOT NULL,
[inactive_date] [int] NOT NULL,
[inactive_flag] [smallint] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[revaluate_flag] [smallint] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glchart_del_trg]
	ON [dbo].[glchart]
	FOR  DELETE AS
BEGIN
	--Clean up ep_temp_glchart
	DELETE ep_temp_glchart
	FROM deleted d
	WHERE d.account_code = ep_temp_glchart.account_code

	--update the records if they already exists
	UPDATE epcoa
	SET 	deleted_dt = GETDATE()
	FROM deleted d
	WHERE d.account_code = epcoa.account_code

	--Set all deleted account to inactive if the record already exists
	UPDATE epcoa
	SET 	inactive_dt = GETDATE(),
		modified_dt = GETDATE()
	FROM deleted d
	WHERE 	d.account_code = epcoa.account_code and
		(epcoa.inactive_dt IS NULL OR
		 epcoa.inactive_dt > GETDATE())
	
	--insert into epcoa with no reference code
	INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		 modified_dt, deleted_dt)
	SELECT	NEWID(), d.account_code, d.account_description, CASE WHEN d.active_date <> 0 then dateadd(dd, d.active_date - 657072, '1/1/1800') ELSE NULL END, GETDATE(), 
		GETDATE(), GETDATE()
	FROM	deleted d--,glchart_proc gc									--ggr
	WHERE	d.account_code NOT IN (SELECT account_code FROM epcoa)
	--AND  d.account_code  LIKE gc.account_code_mask						                --ggr

	--populate epcoa with the account_code-reference_code permutations
	INSERT INTO epcoa (guid, account_code, account_description, reference_code, reference_description, 
		modified_dt, inactive_dt, active_dt, deleted_dt)
	SELECT NEWID(), d.account_code, d.account_description, r.reference_code, r.description, GETDATE(),
		GETDATE(), CASE WHEN d.active_date <> 0 then dateadd(dd, d.active_date - 657072, '1/1/1800') ELSE NULL END,
		GETDATE()
	FROM deleted d, ep_temp_glref r, ep_temp_glref_acct_type v --,glchart_proc gc,glref_proc gr
	WHERE d.account_code LIKE v.account_mask
	AND v.reference_type = r.reference_type
	--AND  d.account_code  LIKE gc.account_code_mask						                --ggr
	--AND  r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND d.account_code NOT IN (SELECT DISTINCT e.account_code 
				  FROM epcoa e
				  WHERE e.account_code = d.account_code 
				  AND	e.reference_code = r.reference_code)
        
	GROUP BY d.account_code, r.reference_code, d.account_description, r.description, d.inactive_date, d.active_date
	ORDER BY d.account_code

END
GO
DISABLE TRIGGER [dbo].[glchart_del_trg] ON [dbo].[glchart]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glchart_ins_trg]
	ON [dbo].[glchart]
	FOR INSERT AS
BEGIN
	--Populate ep_temp_glchart with the inserted records
	INSERT INTO ep_temp_glchart (account_code, account_description,
		account_type, currency_code, active_dt, inactive_dt, modified_dt, inactive_flag, 
		seg1_code, seg2_code, seg3_code, seg4_code)
	SELECT	account_code, account_description, account_type, currency_code, 
		CASE WHEN active_date <> 0 THEN DATEADD(dd, active_date - 657072, '1/1/1800') ELSE NULL END,
		CASE WHEN inactive_date <> 0 THEN DATEADD(dd, inactive_date - 657072, '1/1/1800') ELSE NULL END, 
		GETDATE(), inactive_flag, seg1_code, seg2_code, seg3_code, seg4_code
	FROM 	inserted,  glchart_proc gc									--ggr			
        WHERE 	inserted.account_code  LIKE gc.account_code_mask						--ggr
	ORDER BY account_code
        
        
        /*INSERT INTO ep_temp_glref (reference_code,description,reference_type,status_flag )      --ggr
        SELECT r.reference_code,r.description,r.reference_type,r.status_flag      --ggr
        FROM glref r, glref_proc gr						  --ggr
        WHERE r.reference_code LIKE gr.ref_code_mask			  --ggr 	*/

        
	--Update inactive_dt when inactive flag is changed from active to inactive
	UPDATE	ep_temp_glchart
	SET	inactive_dt = GETDATE()
	FROM 	inserted i
	WHERE 	ep_temp_glchart.account_code = i.account_code AND
		i.inactive_flag = 1 AND
		(ep_temp_glchart.inactive_dt IS NULL OR
		 ep_temp_glchart.inactive_dt > GETDATE())

	--Delete all account that is already exist in epcoa table
	DELETE epcoa
	FROM epcoa e, inserted i
	WHERE e.account_code = i.account_code

	--insert into epcoa with no reference code
	INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		 modified_dt)
	SELECT	NEWID(), g.account_code, g.account_description, g.active_dt, g.inactive_dt, 
		g.modified_dt
	FROM	ep_temp_glchart g (nolock), inserted i--, glchart_proc gc									--ggr	
	WHERE 	i.account_code = g.account_code
        --AND     g.account_code  LIKE gc.account_code_mask										--ggr

	--populate epcoa with the account_code-reference_code permutations
	INSERT INTO epcoa (guid, account_code, account_description, reference_code, reference_description, 
		modified_dt, inactive_dt, active_dt)
	SELECT NEWID(), i.account_code, i.account_description, r.reference_code, r.description, GETDATE(),
		CASE WHEN i.inactive_date <> 0 then dateadd(dd, i.inactive_date - 657072, '1/1/1800') ELSE NULL END, 
		CASE WHEN i.active_date <> 0 then dateadd(dd, i.active_date - 657072, '1/1/1800') ELSE NULL END
	FROM inserted i, ep_temp_glref r, ep_temp_glref_acct_type v--, glchart_proc gc, glref_proc gr				--ggr
	WHERE i.account_code LIKE v.account_mask
	AND v.reference_type = r.reference_type
        --AND r.reference_code LIKE gr.ref_code_mask 							--ggr
        --AND i.account_code  LIKE gc.account_code_mask							--ggr
	GROUP BY i.account_code, r.reference_code, i.account_description, r.description, i.inactive_date, i.active_date
	ORDER BY i.account_code

	--Set account to inactive if inactive flag is on
	UPDATE epcoa
	SET inactive_dt = GETDATE()
	FROM ep_temp_glref r (nolock), inserted i--, glchart_proc gc, glref_proc gr				--ggr
	WHERE 	epcoa.account_code = i.account_code 
	AND	epcoa.reference_code = r.reference_code 
	--AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
       -- AND     i.account_code  LIKE gc.account_code_mask						--ggr
--	AND	r.reference_type = @sRefType and
	AND	(i.inactive_flag = 1 or r.status_flag = 1)	
	
	--Case of Required
	-- set all the account that have reference code as null to inactive
	UPDATE 	epcoa
	SET 	inactive_dt = GETDATE(),
		modified_dt = GETDATE()
	FROM 	inserted i, ep_temp_glref_acct_type v--,  glchart_proc gc    				--ggr
	WHERE 	epcoa.account_code = i.account_code 
	AND	epcoa.reference_code IS NULL
	AND	epcoa.account_code LIKE v.account_mask
	--AND     i.account_code  LIKE gc.account_code_mask					--ggr
	AND	v.reference_flag = 3
	AND	(inactive_dt IS NOT NULL OR inactive_dt > GETDATE())

	--Case of Exclusive
	-- set all the account that have reference code to inactive
	UPDATE	epcoa
	SET 	inactive_dt = GETDATE(),
		modified_dt = GETDATE()
	FROM	inserted i, ep_temp_glref_acct_type v--, glref_proc gr, glchart_proc gc				--ggr
	WHERE 	epcoa.account_code = i.account_code
	AND	epcoa.reference_code IS NOT NULL
        --AND     epcoa.reference_code LIKE gr.ref_code_mask 					--ggr
	AND	epcoa.account_code LIKE v.account_mask
        --AND     i.account_code  LIKE gc.account_code_mask					--ggr
	AND	v.reference_flag = 1
	AND	(inactive_dt IS NOT NULL OR inactive_dt > GETDATE())
END
GO
DISABLE TRIGGER [dbo].[glchart_ins_trg] ON [dbo].[glchart]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glchart_insert] ON [dbo].[glchart] FOR INSERT
AS
BEGIN                                                   
	/* FRx glchart insert trigger code to keep the server-based GL Index */
	/* up to date when the chart of accounts changes. */                         

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	DECLARE
		@OnlyActive	smallint,
		@NatSegNum	tinyint, 
		@MaxSegs		tinyint

	SELECT	@MaxSegs = max_segs,
				@NatSegNum = natural_seg,
				@OnlyActive = only_active_accts
	FROM		frl_entity
	WHERE		entity_num = 1

	/* Insert frl_acct_code record */
	INSERT	frl_acct_code(
				entity_num, acct_code, acct_type,
				acct_status, acct_desc, normal_bal,
				acct_group,
				nat_seg_code, modify_flag, rollup_level)
	SELECT	1, account_code, account_type,
				2, account_description, 2,
				convert(int, substring(ltrim(str(account_type)),1,1)),
				account_code, 0, 0
	FROM		inserted
        WHERE           (@OnlyActive = 0 OR inactive_flag = 0)

	/* Update the nat_seg_code if natural segment is not 1 */
	IF (@NatSegNum = 2)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg2_code + seg1_code + seg3_code + seg4_code
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.account_code
	ELSE IF (@NatSegNum = 3)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg3_code + seg1_code + seg2_code + seg4_code
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.account_code
	ELSE IF (@NatSegNum = 4)
		UPDATE	frl_acct_code
		SET		nat_seg_code = seg4_code + seg1_code + seg2_code + seg3_code
		FROM		frl_acct_code, inserted
		WHERE		acct_code = inserted.account_code

	/* Reset acct_group and normal_bal flag */
	UPDATE	frl_acct_code
	SET		acct_group = 4
	FROM		inserted
	WHERE		acct_group = 6
	AND		acct_code = account_code

	UPDATE	frl_acct_code
	SET		normal_bal = 1
	FROM		inserted
	WHERE		acct_group in (1,5)
	AND		acct_code = account_code

	/* Build frl_acct_seg records */
	if @NatSegNum = 1
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg3_code + seg4_code, 2, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 2

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg2_code + seg4_code, 3, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg2_code + seg3_code, 4, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4
	end

	if @NatSegNum = 2
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg4_code, 3, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs >= 3

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg3_code, 4, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 3
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg4_code, 2, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg4_code + seg2_code, 4, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code
		AND		@MaxSegs = 4

	end

	if @NatSegNum = 4
	begin
		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg2_code + seg3_code, 2, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code

		INSERT	frl_acct_seg(
					seg_code, seg_num, entity_num,
					acct_id, acct_code, rollup_level)
		SELECT	seg3_code + seg2_code, 3, 1,
					acct_id, account_code, 0
		FROM		inserted, frl_acct_code
		WHERE		inserted.account_code = frl_acct_code.acct_code

	end

END                   
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

CREATE TRIGGER [dbo].[glchart_integ_del_trg]
	ON [dbo].[glchart]
	FOR DELETE AS
BEGIN



INSERT INTO epintegrationrecs 
SELECT Distinct DEL.account_code, '', 4, 'D', 0 
FROM Deleted DEL
	INNER JOIN glchart_proc CPROC ON DEL.account_code LIKE CPROC.account_code_mask

END

GO
DISABLE TRIGGER [dbo].[glchart_integ_del_trg] ON [dbo].[glchart]
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

CREATE TRIGGER [dbo].[glchart_integ_ins_trg]
	ON [dbo].[glchart]
	FOR INSERT AS
BEGIN



INSERT INTO epintegrationrecs 
SELECT Distinct INS.account_code, '', 4, 'I', 0 
FROM Inserted INS
	INNER JOIN glchart_proc CPROC ON INS.account_code LIKE CPROC.account_code_mask


END

GO
DISABLE TRIGGER [dbo].[glchart_integ_ins_trg] ON [dbo].[glchart]
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

CREATE TRIGGER [dbo].[glchart_integ_upd_trg]
	ON [dbo].[glchart]
	FOR UPDATE AS
BEGIN


DELETE epintegrationrecs WHERE action = 'U' AND type = 4 AND id_code IN ( SELECT account_code FROM Inserted )

INSERT INTO epintegrationrecs 
SELECT Distinct INS.account_code, '', 4, 'U', 0 
FROM Inserted INS
	INNER JOIN glchart_proc CPROC ON INS.account_code LIKE CPROC.account_code_mask

END

GO
DISABLE TRIGGER [dbo].[glchart_integ_upd_trg] ON [dbo].[glchart]
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

CREATE TRIGGER [dbo].[glchart_integration_del_trg]
	ON [dbo].[glchart]
	FOR DELETE AS
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
	status VARCHAR(1) NOT NULL
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code, reference_type)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)

/*--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------*/
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT DEL.account_code, DEL.account_description, TYP.reference_type, REF.reference_code, REF.description, DEL.active_date, DEL.inactive_date, 'D'
FROM Deleted DEL
	INNER JOIN glratyp TYP ON DEL.account_code LIKE TYP.account_mask
	INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
WHERE REF.status_flag = 0
	AND EXISTS (SELECT 1 FROM glref_proc RPROC WHERE REF.reference_code LIKE RPROC.ref_code_mask)
	AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE DEL.account_code LIKE CPROC.account_code_mask)
	AND ACT.reference_flag IN (2,3)

/*--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------*/
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT DEL.account_code, DEL.account_description, NULL, 'NOREF', 'NOREF', DEL.active_date, DEL.inactive_date, 'D'
FROM Deleted DEL
WHERE EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE DEL.account_code LIKE CPROC.account_code_mask)


/*--------------------------------------------------------------INSERT ACCOUNTS------*/
UPDATE HIST
SET HIST.account_description = COAS.account_description, 
	HIST.status = COAS.status 
FROM glchart_history HIST, #TEMPCoas COAS
WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')


DROP TABLE #TEMPCoas

END

GO
DISABLE TRIGGER [dbo].[glchart_integration_del_trg] ON [dbo].[glchart]
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

CREATE TRIGGER [dbo].[glchart_integration_ins_trg]
	ON [dbo].[glchart]
	FOR INSERT AS
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
	status VARCHAR(1) NOT NULL
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
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoasDeleted (account_code, reference_code)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoasDeleted (guid)

DECLARE @DATETIME DATETIME
SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------
/*---Is DISTINCT because the two reference types can has the same reference code, and the mask asosiated to the reference types can match with the same account---*/
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT INS.account_code, INS.account_description, TYP.reference_type, REF.reference_code, REF.description, INS.active_date, INS.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glref REF ON TYP.reference_type = REF.reference_type
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON CHRT.account_code = INS.account_code
WHERE INS.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE INS.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, INS.active_date - 693596,'01/01/1900') END 
					AND 
					CASE INS.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, INS.inactive_date - 693596,'01/01/1900')  END
		AND EXISTS (SELECT 1 FROM glref_proc RPROC WHERE REF.reference_code LIKE RPROC.ref_code_mask)
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
		AND REF.status_flag = 0
		AND ACT.reference_flag IN (2,3)

--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCE CODE, BUT THAT HAS A REFERENCES CODES MARKED AS NOT REQUIRED------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT INS.account_code, INS.account_description, NULL, 'NOREF', 'NOREF', INS.active_date, INS.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON CHRT.account_code = INS.account_code
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
		AND ACT.reference_flag IN (1,2)
		

--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT INS.account_code, INS.account_description, NULL, 'NOREF', 'NOREF', INS.active_date, INS.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN Inserted INS ON CHRT.account_code = INS.account_code
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND NOT EXISTS (SELECT 1 FROM glratyp TYP WHERE CHRT.account_code LIKE TYP.account_mask)
		AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)

--------------------------------------------------------------GET ACCOUNTS PREVIOUSLY DELETED------
INSERT #TEMPCoasDeleted (account_code, account_description,	reference_code)
SELECT COAS.account_code, COAS.account_description, COAS.reference_code
FROM glchart_history HIST
	INNER JOIN #TEMPCoas COAS ON HIST.account_code = COAS.account_code AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

--------------------------------------------------------------CHNAGE STATUS FOR ALL ACCOUNT PREVIOUSLY DELETED------
UPDATE HIST
	SET HIST.status = 'I',
		HIST.account_description = COAS.account_description
FROM glchart_history HIST, #TEMPCoasDeleted COAS
WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

DELETE COAS
FROM #TEMPCoas COAS, #TEMPCoasDeleted DEL
WHERE COAS.account_code = DEL.account_code AND ISNULL(COAS.reference_code,'') = ISNULL(DEL.reference_code,'')

--------------------------------------------------------------INSERT ACCOUNTS------
INSERT glchart_history (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT 	account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status 
FROM #TEMPCoas

DROP TABLE #TEMPCoas
DROP TABLE #TEMPCoasDeleted



END

GO
DISABLE TRIGGER [dbo].[glchart_integration_ins_trg] ON [dbo].[glchart]
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

CREATE TRIGGER [dbo].[glchart_integration_upd_trg]
	ON [dbo].[glchart]
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
	status VARCHAR(1) NOT NULL,
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code, reference_type)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)

DECLARE @DATETIME DATETIME
SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

/*--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------*/
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT INS.account_code, INS.account_description, TYP.reference_type, REF.reference_code, REF.description, INS.active_date, INS.inactive_date,
		CASE INS.inactive_flag WHEN 0 THEN 
			CASE WHEN @DATETIME BETWEEN 
							CASE INS.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, INS.active_date - 693596,'01/01/1900') END 
								AND 
							CASE INS.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, INS.inactive_date - 693596,'01/01/1900') END
				THEN 'U'
			ELSE 'D' END
		ELSE 'D' END
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON CHRT.account_code = INS.account_code
WHERE REF.status_flag = 0
	AND EXISTS (SELECT 1 FROM glref_proc RPROC WHERE REF.reference_code LIKE RPROC.ref_code_mask)
	AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
	AND ACT.reference_flag IN (2,3)

/*--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------*/
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT INS.account_code, INS.account_description, NULL, 'NOREF', 'NOREF', INS.active_date, INS.inactive_date,
		CASE INS.inactive_flag WHEN 0 THEN 
			CASE WHEN @DATETIME BETWEEN 
							CASE INS.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, INS.active_date - 693596,'01/01/1900') END 
								AND 
							CASE INS.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, INS.inactive_date - 693596,'01/01/1900') END
				THEN 'U'
			ELSE 'D' END
		ELSE 'D' END
FROM glchart CHRT
	INNER JOIN Inserted INS ON CHRT.account_code = INS.account_code
WHERE EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)


/*--------------------------------------------------------------INSERT ACCOUNTS------*/
UPDATE HIST
SET HIST.account_description = COAS.account_description,
	HIST.status = (CASE WHEN INS.inactive_flag = 0 AND DEL.inactive_flag = 1 THEN 'I'
	   			   ELSE CASE WHEN HIST.status = 'I' AND COAS.status = 'U' THEN 'I'
					 ELSE CASE WHEN INS.inactive_flag = 0 AND COAS.status = 'U'  
						AND (INS.active_date <> DEL.active_date OR INS.inactive_date <> DEL.inactive_date)
						AND 0 = (CASE WHEN @DATETIME BETWEEN 
							CASE INS.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, INS.active_date - 693596,'01/01/1900') END 
								AND 
							CASE INS.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, INS.inactive_date - 693596,'01/01/1900') END
							THEN 0 ELSE 1 END) THEN 'I'
							ELSE COAS.status 
						END
					END
			   END),
	HIST.active_date = COAS.active_date, 
	HIST.inactive_date = COAS.inactive_date
FROM glchart_history HIST, #TEMPCoas COAS
	INNER JOIN Deleted DEL ON COAS.account_code = DEL.account_code
	INNER JOIN Inserted INS ON COAS.account_code = INS.account_code
WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

	
INSERT glchart_history (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT 	COAS.account_code, COAS.account_description, COAS.reference_type, COAS.reference_code, COAS.reference_description, COAS.active_date, COAS.inactive_date,
		CASE WHEN COAS.status = 'U' THEN  'I' ELSE COAS.status END
FROM #TEMPCoas COAS
	LEFT JOIN glchart_history HIST ON COAS.account_code = HIST.account_code AND ISNULL(COAS.reference_code,'') = ISNULL(HIST.reference_code,'') AND COAS.reference_code = HIST.reference_code
WHERE HIST.account_code IS NULL 

DROP TABLE #TEMPCoas


END

GO
DISABLE TRIGGER [dbo].[glchart_integration_upd_trg] ON [dbo].[glchart]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glchart_trigger_1] ON [dbo].[glchart] FOR DELETE
AS
BEGIN                                                   
	/* FRx glchart delete trigger code to keep the server-based GL Index */
	/* up to date when the chart of accounts changes. */                         

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	DELETE	glbal
	FROM		glbal b, deleted d
	WHERE		b.account_code = d.account_code
	AND		balance_type=1

	DELETE	frl_acct_seg
	FROM		frl_acct_seg s, frl_acct_code c, deleted d
	WHERE		c.acct_code = d.account_code
	AND		s.acct_id = c.acct_id
	AND		c.rollup_level = 0

	DELETE	frl_acct_code
	FROM		frl_acct_code c, deleted d
	WHERE		c.acct_code = d.account_code
	AND		rollup_level = 0

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glchart_upd_trg]
	ON [dbo].[glchart]
	FOR UPDATE AS
BEGIN

	--Return the process if there is no change in the following columns
	if ((	SELECT count(*) FROM inserted i, deleted d
		WHERE 	(d.account_code <> i.account_code or
			 d.account_description <> i.account_description or
			d.currency_code <> i.currency_code or
			d.account_type <> i.account_type or
			d.inactive_date <> i.inactive_date or
			d.active_date <> i.active_date or
			d.inactive_flag <> i.inactive_flag)) = 0)
		Return

	--UPDATE ep_temp_glchart if the records already exists
	UPDATE ep_temp_glchart 
	SET	account_code = i.account_code,
		account_description = i.account_description, 
		account_type = i.account_type ,
		currency_code = i.currency_code,
		modified_dt = GETDATE(),
		inactive_flag = i.inactive_flag, 
		inactive_dt = CASE WHEN i.inactive_date <> 0 THEN DATEADD(dd, i.inactive_date - 657072, '1/1/1800') ELSE NULL END, 
		active_dt = CASE WHEN i.active_date <> 0 THEN DATEADD(dd, i.active_date - 657072, '1/1/1800') ELSE NULL END,
		seg1_code = i.seg1_code,
		seg2_code = i.seg2_code,
		seg3_code = i.seg3_code,
		seg4_code = i.seg4_code
	FROM inserted i, deleted d
	WHERE 	(d.account_code <> i.account_code or
		 d.account_description <> i.account_description or
		 d.account_type <> i.account_type or
		 d.currency_code <> i.currency_code or
		 d.seg1_code <> i.seg1_code or
		 d.seg2_code <> i.seg2_code or
		 d.seg3_code <> i.seg3_code or
		 d.seg4_code <> i.seg4_code or
		 d.active_date <> i.active_date or
		 d.inactive_date <> i.inactive_date or
		d.inactive_flag <> i.inactive_flag) AND
		ep_temp_glchart.account_code = d.account_code
		


	--INSERT into epcoa with no reference code
	INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		 modified_dt)
	SELECT	NEWID(), g.account_code, g.account_description, g.active_dt, g.inactive_dt, 
		g.modified_dt
	FROM	ep_temp_glchart g (nolock), inserted i--, glchart_proc gc				       --ggr	
	WHERE 	i.account_code = g.account_code
	AND	i.account_code not in (SELECT account_code FROM epcoa)
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr   

	--populate epcoa with the account_code-reference_code permutations
	INSERT INTO epcoa (guid, account_code, account_description, reference_code, reference_description, 
		modified_dt, inactive_dt, active_dt)
	SELECT NEWID(), i.account_code, i.account_description, r.reference_code, r.description, GETDATE(),
		CASE WHEN i.inactive_date <> 0 then dateadd(dd, i.inactive_date - 657072, '1/1/1800') ELSE NULL END, 
		CASE WHEN i.active_date <> 0 then dateadd(dd, i.active_date - 657072, '1/1/1800') ELSE NULL END
	FROM inserted i, ep_temp_glref r, ep_temp_glref_acct_type v --, glchart_proc gc, glref_proc gr                --ggr
	WHERE i.account_code LIKE v.account_mask
	AND v.reference_type = r.reference_type
	--AND i.account_code  LIKE gc.account_code_mask						        --ggr
       -- AND r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND i.account_code NOT IN (SELECT DISTINCT e.account_code 
				  FROM epcoa e
				  WHERE e.account_code = i.account_code 
				  AND	e.reference_code = r.reference_code)
	GROUP BY i.account_code, r.reference_code, i.account_description, r.description, i.inactive_date, i.active_date
	ORDER BY i.account_code


	--UPDATE if glchart.inactive_date = 0, UPDATE ep_temp_glchart.inactive_dt = NULL 
	UPDATE ep_temp_glchart
	SET inactive_dt = NULL
	FROM ep_temp_glchart e, inserted i
	WHERE 	i.account_code = e.account_code 
	AND	i.inactive_date = 0 
	AND	e.inactive_dt is not NULL

	
	--UPDATE if glchart.active_date = 0, UPDATE ep_temp_glchart.active_dt = NULL 
	UPDATE ep_temp_glchart
	SET active_dt = NULL
	FROM ep_temp_glchart e, inserted i
	WHERE 	i.account_code = e.account_code 
	AND	i.active_date = 0 
	AND	e.active_dt is not NULL

	--UPDATE inactive_dt when inactive flag is changed FROM inactive to active
	UPDATE ep_temp_glchart
	SET	inactive_dt = NULL
	FROM 	deleted d, inserted i
	WHERE 	ep_temp_glchart.account_code = i.account_code 
	AND	d.account_code = i.account_code 
	AND	d.inactive_flag <> i.inactive_flag 
	AND	i.inactive_flag = 0 
	AND	(ep_temp_glchart.inactive_dt is not NULL AND
		 i.inactive_date = 0)

	--UPDATE inactive_dt when inactive flag is changed FROM active to inactive
	UPDATE ep_temp_glchart
	SET	inactive_dt = GETDATE()
	FROM 	deleted d, inserted i
	WHERE 	ep_temp_glchart.account_code = i.account_code 
	AND	d.account_code = i.account_code 
	AND	d.inactive_flag <> i.inactive_flag 
	AND	i.inactive_flag = 1 
	AND	(ep_temp_glchart.inactive_dt is NULL or
		 ep_temp_glchart.inactive_dt > GETDATE())

	--Case the account code is changed. 
	if ((SELECT count(*) FROM inserted i, deleted d 
		WHERE 	i.account_code <> d.account_code) > 0)
	Begin
		--SET all deleted account to deleted
		UPDATE epcoa
		SET 	inactive_dt = GETDATE(),
			modified_dt = GETDATE(),
			deleted_dt = GETDATE()
		FROM deleted d, inserted i
		WHERE 	i.account_code <> d.account_code 
		AND	d.account_code = epcoa.account_code
	End -- account change

	--Case the account description is changed. 
	if ((SELECT count(*) FROM inserted i, deleted d 
		WHERE 	i.account_code = d.account_code 
		AND 	i.account_description <> d.account_description) > 0)
	Begin
		--SET account description AND modified date
		UPDATE epcoa
		SET 	account_description = i.account_description,
			modified_dt = GETDATE()
		FROM deleted d, inserted i
		WHERE 	i.account_description <> d.account_description 
		AND	d.account_code = i.account_code 
		AND	d.account_code = epcoa.account_code
	End -- account description change

	--Case the inactive_flag is changed. 
	if ((SELECT count(*) FROM inserted i, deleted d 
		WHERE 	d.inactive_flag <> i.inactive_flag 
		AND	d.account_code = i.account_code) > 0)
	Begin
		--SET account to inactive
		UPDATE 	epcoa
		SET 	inactive_dt = GETDATE()
		FROM deleted d, inserted i, epcoa e
		WHERE 	d.inactive_flag <> i.inactive_flag 
		AND 	i.inactive_flag = 1 
		AND	d.account_code = i.account_code 
		AND	d.account_code = e.account_code
			
		--SET account to active
		UPDATE 	epcoa
		SET 	inactive_dt = g.inactive_dt
		FROM deleted d, inserted i, ep_temp_glchart g, epcoa e
		WHERE 	d.inactive_flag <> i.inactive_flag 
		AND 	i.inactive_flag = 0 
		AND	d.account_code = i.account_code 
		AND	d.account_code = e.account_code 
		AND 	g.account_code = e.account_code

	End 

	--Case the active_date is changed
	if ((SELECT count(*) FROM inserted i, deleted d 
		WHERE 	i.account_code = d.account_code 
		AND 	i.active_date <> d.active_date) > 0)
	Begin
		--SET active date AND modified date
		UPDATE epcoa
		SET 	active_dt = CASE WHEN i.active_date <> 0 then dateadd(dd, i.active_date - 657072, '1/1/1800') ELSE NULL END,
			modified_dt = GETDATE()
		FROM deleted d, inserted i
		WHERE 	i.active_date <> d.active_date 
		AND	d.account_code = i.account_code 
		AND	d.account_code = epcoa.account_code
	End 

	--Case the inactive_date is changed
	if ((SELECT count(*) FROM inserted i, deleted d 
		WHERE 	i.account_code = d.account_code 
		AND 	i.inactive_date <> d.inactive_date) > 0)
	Begin
		--SET inactive date AND modified date
		UPDATE epcoa
		SET 	inactive_dt = CASE WHEN i.inactive_date <> 0 then dateadd(dd, i.inactive_date - 657072, '1/1/1800') ELSE NULL END,
			modified_dt = GETDATE()
		FROM deleted d, inserted i
		WHERE 	i.inactive_date <> d.inactive_date 
		AND	d.account_code = i.account_code 
		AND	d.account_code = epcoa.account_code
	End 

/*****/
	--Set account to inactive if inactive flag is on
	UPDATE epcoa
	SET inactive_dt = CASE WHEN epcoa.inactive_dt IS NULL THEN GETDATE() ELSE epcoa.inactive_dt END
	FROM ep_temp_glref r (nolock), inserted i
	WHERE 	epcoa.account_code = i.account_code 
	AND	epcoa.reference_code = r.reference_code 
	AND	(i.inactive_flag = 1 or r.status_flag = 1)	
	
	--Case of Required
	-- set all the account that have reference code as null to inactive
	UPDATE 	epcoa
	SET 	inactive_dt = CASE WHEN epcoa.inactive_dt IS NULL THEN GETDATE() ELSE epcoa.inactive_dt END,
		modified_dt = GETDATE()
	FROM 	inserted i, ep_temp_glref_acct_type v
	WHERE 	epcoa.account_code = i.account_code 
	AND	epcoa.reference_code IS NULL
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 3
	AND	(inactive_dt IS NOT NULL OR inactive_dt > GETDATE())

	--Case of Exclusive
	-- set all the account that have reference code to inactive
	UPDATE	epcoa
	SET 	inactive_dt = CASE WHEN epcoa.inactive_dt IS NULL THEN GETDATE() ELSE epcoa.inactive_dt END,
		modified_dt = GETDATE()
	FROM	inserted i, ep_temp_glref_acct_type v
	WHERE 	epcoa.account_code = i.account_code
	AND	epcoa.reference_code IS NOT NULL
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 1
	AND	(inactive_dt IS NOT NULL OR inactive_dt > GETDATE())

END
GO
DISABLE TRIGGER [dbo].[glchart_upd_trg] ON [dbo].[glchart]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glchart_update] ON [dbo].[glchart] FOR UPDATE
AS
BEGIN                                                   
	/* FRx glchart update trigger code to keep the server-based GL Index up */
	/* to date when the chart of accounts changes. */                         

	/* Halt processing if no records were affected */
	IF (@@ROWCOUNT = 0)
		RETURN

	/* Don't report back to client the number of rows affected */
	/* This may speed up processing */
	SET NOCOUNT ON

	DECLARE	@OnlyActive	smallint

	/* Are we processing only active accounts? */
	SELECT	@OnlyActive = only_active_accts
	FROM		frl_entity
	WHERE		entity_num = 1

	/* Update frl_acct_code record with newly changed values */
	UPDATE	frl_acct_code
	SET		acct_desc = account_description,
				acct_type = account_type,
				acct_group = convert(int, substring(ltrim(str(account_type)),1,1)),
				normal_bal = 2
	FROM		inserted
	WHERE		entity_num = 1
	AND		acct_code = account_code
        AND             (@OnlyActive = 0 OR inactive_flag = 0)

	/* Reset acct_group and normal_bal flag */
	UPDATE	frl_acct_code
	SET		acct_group = 3
	FROM		inserted
	WHERE		acct_group = 6
	AND		acct_code = account_code

	UPDATE	frl_acct_code
	SET		normal_bal = 1
	FROM		inserted
	WHERE		acct_group in (1,5)
	AND		acct_code = account_code

END
GO
CREATE UNIQUE CLUSTERED INDEX [glchart_ind_0] ON [dbo].[glchart] ([account_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glchart_ind_1] ON [dbo].[glchart] ([account_type], [account_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glchart_ind_seg_1] ON [dbo].[glchart] ([seg1_code], [account_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glchart_ind_2] ON [dbo].[glchart] ([seg2_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glchart_ind_3] ON [dbo].[glchart] ([seg3_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glchart_ind_4] ON [dbo].[glchart] ([seg4_code]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[glchart] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart] TO [public]
GO
GRANT REFERENCES ON  [dbo].[glchart] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart] TO [public]
GO
