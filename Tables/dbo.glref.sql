CREATE TABLE [dbo].[glref]
(
[timestamp] [timestamp] NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glref_del_trg]
	ON [dbo].[glref]
	FOR DELETE AS
BEGIN
	--Return if ep_temp_glref_acct_type has not have any records in it
	If ((select count(*) from ep_temp_glref_acct_type ) = 0)
		Return

	--Return if chart of account has not set up yet.
	If ((select count(*) from ep_temp_glchart ) = 0)
		Return

	update 	epcoa
	set 	deleted_dt = getdate(),
		inactive_dt = case when (epcoa.inactive_dt is null or epcoa.inactive_dt > getdate()) then getdate() end,
		modified_dt = case when (epcoa.inactive_dt is null or epcoa.inactive_dt > getdate()) then getdate() end
	from 	deleted d
	where 	d.reference_code = epcoa.reference_code


	update 	ep_temp_glref					/*ggr*/
	set 	ep_temp_glref.status_flag = d.status_flag
	from 	deleted d
	where 	d.reference_code = ep_temp_glref.reference_code

	insert epcoa (guid, account_code, account_description, reference_code, reference_description, 
			modified_dt, inactive_dt, active_dt, deleted_dt, send_inactive_flg, deleted_flg)
	select 	newid(), ch.account_code, ch.account_description, 
		ref.reference_code, ref.description,
		ch.modified_dt, ch.inactive_dt, ch.active_dt,
		deleted_dt = getdate(), send_inactive_flg = 0, deleted_flg = 0
	from 	deleted ref,
		ep_temp_glchart ch (nolock), 
		ep_temp_glref_acct_type rat (nolock)--,
		--glchart_proc gc, glref_proc gr  						--ggr	
				
	where	ch.account_code like rat.account_mask
	AND 	ref.reference_type = rat.reference_type
	--AND     ch.account_code  LIKE gc.account_code_mask						--ggr
        --AND     ref.reference_code LIKE gr.ref_code_mask						--ggr
        AND	ch.account_code 
	NOT IN	(select distinct e.account_code
		 from epcoa e
		 where e.account_code = ch.account_code
		 and e.reference_code = ref.reference_code)
END

GO
DISABLE TRIGGER [dbo].[glref_del_trg] ON [dbo].[glref]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glref_ins_trg]
	ON [dbo].[glref]
	FOR INSERT AS
BEGIN

   INSERT INTO ep_temp_glref (reference_code,description,reference_type,status_flag )      --ggr
   SELECT DISTINCT r.reference_code,r.description,r.reference_type,r.status_flag      --ggr
   FROM glref r, glref_proc gr						  --ggr
   WHERE r.reference_code LIKE gr.ref_code_mask			  --ggr 
   AND r.reference_code NOT IN (SELECT DISTINCT reference_code FROM ep_temp_glref) --ggr	
 		
   If ((select count(*) 
		from ep_temp_glref_acct_type t, inserted i
		where i.reference_type = t.reference_type ) = 0)
		Return

	update 	ep_temp_glchart 
	set 	modified_dt = getdate()
	from 	ep_temp_glref_acct_type e (nolock),
		inserted i
	where 	i.reference_type = e.reference_type and
		account_code like e.account_mask
	
	select 	guid = newid(), ch.account_code, ch.account_description, 
		ref.reference_code, reference_description = ref.description,
		ch.modified_dt, 
		inactive_dt = case 
			when (ch.inactive_flag = 1 or ref.status_flag = 1) then getdate()
			else NULL 
		end,
		ch.active_dt,
		deleted_dt = NULL, 
		send_inactive_flg = 0, 
		deleted_flg = 0
	INTO	#epcoa_tmp
	from 	inserted ref, /*inserted*/
		ep_temp_glchart ch (nolock), 
		ep_temp_glref_acct_type rat (nolock)
	where	ch.account_code like rat.account_mask
	AND 	ref.reference_type = rat.reference_type	

	update 	#epcoa_tmp
	set 	inactive_dt = getdate(),
		modified_dt = getdate()
	from	ep_temp_glref_acct_type rat (nolock)
	where 	rat.reference_flag = 3 --Required
	and	#epcoa_tmp.account_code like rat.account_mask 
	and	#epcoa_tmp.reference_code is null

	update 	#epcoa_tmp
	set 	inactive_dt = getdate(),
		modified_dt = getdate()
	from	ep_temp_glref_acct_type rat (nolock)
	where 	rat.reference_flag = 1 --Exclusive
	and	#epcoa_tmp.account_code like rat.account_mask 
	and	#epcoa_tmp.reference_code is not null
	
	--UPDATE IF RECORDS EXIST
	update	epcoa
	set	epcoa.account_description = tmp.account_description,
		epcoa.reference_description = tmp.reference_description,
		epcoa.modified_dt = tmp.modified_dt,
		epcoa.inactive_dt = tmp.inactive_dt,
		epcoa.active_dt = tmp.active_dt,
		epcoa.deleted_dt = tmp.deleted_dt,
		epcoa.send_inactive_flg = tmp.send_inactive_flg,
		epcoa.deleted_flg = tmp.deleted_flg
	from	#epcoa_tmp tmp--, glchart_proc gc, glref_proc gr  		--ggr
	WHERE	epcoa.account_code = tmp.account_code
	AND	epcoa.reference_code = tmp.reference_code
       -- AND     tmp.account_code  LIKE gc.account_code_mask						--ggr
       -- AND     tmp.reference_code LIKE gr.ref_code_mask 							--ggr
	
	--INSERT IF RECORDS DON'T EXIST	
	insert 	epcoa(guid, account_code, account_description, reference_code, reference_description, 
		 	modified_dt, inactive_dt, active_dt, deleted_dt, send_inactive_flg, deleted_flg)
	select 	guid, account_code, account_description, reference_code, reference_description, 
		 	modified_dt, inactive_dt, active_dt, deleted_dt, send_inactive_flg, deleted_flg
	from	#epcoa_tmp tmp-- , glchart_proc gc, glref_proc gr  		--ggr
	WHERE	tmp.account_code 
	NOT IN	(select distinct e.account_code
		 from epcoa e
		 where e.account_code = tmp.account_code
		 and e.reference_code = tmp.reference_code)
	--AND     tmp.account_code  LIKE gc.account_code_mask						--ggr
        --AND     tmp.reference_code LIKE gr.ref_code_mask 							--ggr

	drop table #epcoa_tmp	

END

GO
DISABLE TRIGGER [dbo].[glref_ins_trg] ON [dbo].[glref]
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


CREATE TRIGGER [dbo].[glref_integ_ins_trg]
	ON [dbo].[glref]
	FOR INSERT AS
BEGIN

INSERT INTO epintegrationrecs 
SELECT Distinct INS.reference_code, INS.reference_type, 6, 'I', 0 
FROM Inserted INS
	INNER JOIN glref_proc RPROC ON INS.reference_code LIKE RPROC.ref_code_mask

END

GO
DISABLE TRIGGER [dbo].[glref_integ_ins_trg] ON [dbo].[glref]
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

CREATE TRIGGER [dbo].[glref_integ_upd_trg]
	ON [dbo].[glref]
	FOR UPDATE AS
BEGIN


DELETE epintegrationrecs 
WHERE action = 'U' AND type = 6 
	AND id_code IN ( SELECT reference_code FROM Inserted, epintegrationrecs WHERE id_code = reference_code )
	AND mask IN ( SELECT reference_type FROM Inserted, epintegrationrecs WHERE mask = reference_type )

INSERT INTO epintegrationrecs 
SELECT Distinct INS.reference_code, INS.reference_type, 6, 'U', 0 
FROM Inserted INS
	INNER JOIN glref_proc RPROC ON INS.reference_code LIKE RPROC.ref_code_mask
END

GO
DISABLE TRIGGER [dbo].[glref_integ_upd_trg] ON [dbo].[glref]
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

CREATE TRIGGER [dbo].[glref_integration_del_trg]
	ON [dbo].[glref]
	FOR DELETE AS
BEGIN
	INSERT INTO epintegrationrecs 
	SELECT Distinct  DEL.reference_code, DEL.reference_type, 6, 'D', 0 
	FROM Deleted DEL
		INNER JOIN glref_proc RPROC ON DEL.reference_code LIKE RPROC.ref_code_mask
END

GO
DISABLE TRIGGER [dbo].[glref_integration_del_trg] ON [dbo].[glref]
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


CREATE TRIGGER [dbo].[glref_integration_ins_trg]
	ON [dbo].[glref]
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
	status VARCHAR(1) NOT NULL
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code, reference_type)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)


CREATE TABLE #TEMPCoasDeleted
	(
	guid VARCHAR(50) NOT NULL DEFAULT (NEWID()),
	account_code VARCHAR(30) NOT NULL,
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
SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type, INS.reference_code, INS.description, CHRT.active_date, CHRT.inactive_date, 'I'
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN glref REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON REF.reference_code = INS.reference_code AND REF.reference_type = INS.reference_type
	INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
	INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
		AND INS.status_flag = 0
--ACT.reference_flag IN (2,3)

--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCE CODE, BUT THAT HAS A REFERENCES CODES MARKED AS NOT REQUIRED------
/*INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date, 'I'
FROM GLCHART CHRT
	INNER JOIN GLRATYP TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN GLREF REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN GLREFACT ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON REF.reference_code = INS.reference_code AND REF.reference_type = INS.reference_type
	INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
WHERE CHRT.inactive_flag = 0 
		AND GETDATE() BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN GETDATE() ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,GETDATE()) ELSE DATEADD(day,-1,DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900')) END
		AND ACT.reference_flag = 1
		AND INS.status_flag = 0
--ACT.reference_flag IN (2,3)
*/
--------------------------------------------------------------GET ACCOUNTS PREVIOUSLY DELETED------
INSERT #TEMPCoasDeleted (account_code, account_description,	reference_code)
SELECT COAS.account_code, COAS.account_description, COAS.reference_code
FROM glchart_history HIST
	INNER JOIN #TEMPCoas COAS ON HIST.account_code = COAS.account_code AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')

--------------------------------------------------------------CHANGE STATUS FOR ALL ACCOUNT PREVIOUSLY DELETED------
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
DISABLE TRIGGER [dbo].[glref_integration_ins_trg] ON [dbo].[glref]
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

CREATE TRIGGER [dbo].[glref_integration_upd_trg]
	ON [dbo].[glref]
	FOR UPDATE AS
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
	status VARCHAR(1) DEFAULT('N'),
	)

CREATE UNIQUE INDEX hist_index1
ON #TEMPCoas (account_code, reference_code, reference_type)

CREATE UNIQUE INDEX hist_index2
ON #TEMPCoas (guid)

DECLARE @DATETIME DATETIME
SELECT @DATETIME = CAST(CONVERT( VARCHAR(10), GETDATE(), 101) AS DATETIME)

--------------------------------------------------------------INSERT ACCOUNTS WITH REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type, INS.reference_code, INS.description, CHRT.active_date, CHRT.inactive_date,
		CASE WHEN DEL.status_flag = 0 AND INS.status_flag = 1 THEN 'D' ELSE 
			CASE WHEN (DEL.status_flag = 1 ) AND INS.status_flag = 0 THEN 'I' ELSE 
				CASE WHEN (DEL.status_flag  = 0 ) AND INS.status_flag = 0 THEN 'U' ELSE 
				  CASE WHEN DEL.status_flag = 1 AND INS.status_flag = 1 THEN 'N' END	
				END
			END
		END
FROM glchart CHRT
	INNER JOIN glratyp TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN deleted DEL ON TYP.reference_type = DEL.reference_type 
	INNER JOIN glrefact ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON DEL.reference_code = INS.reference_code AND DEL.reference_type = INS.reference_type
WHERE CHRT.inactive_flag = 0 
		AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900') END
	  AND EXISTS (SELECT 1 FROM glref_proc RPROC WHERE DEL.reference_code LIKE RPROC.ref_code_mask)
	  AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
	  --AND INS.status_flag = 0


--------------------------------------------------------------UPDATE ACCOUNTS WITH REFERENCES CODES DISABLED------
/*INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, TYP.reference_type, INS.reference_code, INS.description, CHRT.active_date, CHRT.inactive_date,'D'
FROM GLCHART CHRT
	INNER JOIN GLRATYP TYP ON CHRT.account_code LIKE TYP.account_mask
	INNER JOIN GLREF REF ON TYP.reference_type = REF.reference_type 
	INNER JOIN GLREFACT ACT ON  TYP.account_mask = ACT.account_mask
	INNER JOIN Inserted INS ON REF.reference_code = INS.reference_code AND REF.reference_type = INS.reference_type
WHERE EXISTS (SELECT 1 FROM glref_proc RPROC WHERE REF.reference_code LIKE RPROC.ref_code_mask)
	  AND EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
	  AND INS.status_flag = 1
--WHERE ACT.reference_flag IN (2,3)
*/
/*
--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------
INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', INS.active_date, INS.inactive_date,
		CASE CHRT.inactive_flag WHEN 0 THEN 
			CASE WHEN GETDATE() BETWEEN 
							CASE CHRT.active_date WHEN 0 THEN GETDATE() ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
								AND 
							CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,GETDATE()) ELSE DATEADD(day,-1,DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900')) END
				THEN 'U'
			ELSE 'D' END
		ELSE 'D' END
FROM GLCHART CHRT
	INNER JOIN Inserted INS ON REF.reference_code = INS.reference_code AND REF.reference_type = INS.reference_type
WHERE EXISTS (SELECT 1 FROM glchart_proc CPROC WHERE CHRT.account_code LIKE CPROC.account_code_mask)
--WHERE ACT.reference_flag IN (2,3)
*/
--------------------------------------------------------------INSERT ACCOUNTS------
UPDATE HIST
SET HIST.reference_description = COAS.reference_description, 
	HIST.status = (	CASE WHEN HIST.status = 'I' AND COAS.status ='U' THEN 'I' ELSE
						COAS.status END )
FROM glchart_history HIST, #TEMPCoas COAS
WHERE HIST.account_code = COAS.account_code
	AND ISNULL(HIST.reference_code,'') = ISNULL(COAS.reference_code,'')
	AND NOT COAS.status = 'N'


DROP TABLE #TEMPCoas

END

GO
DISABLE TRIGGER [dbo].[glref_integration_upd_trg] ON [dbo].[glref]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glref_upd_trg]
	ON [dbo].[glref]
	FOR UPDATE AS
BEGIN

	--Return the process if there is no change in the following columns
	if ((	select count(*) from inserted i, deleted d
		where 	(d.reference_code <> i.reference_code or
			 d.description <> i.description or
			d.reference_type <> i.reference_type or
			d.status_flag <> i.status_flag)) = 0)
		Return
			
	--If there is no records in ep_temp_glref_acct_type, it indicates that the
	--account mask in glratyp table need to be populate before calling this process
	If ((select count(*) 
		from ep_temp_glref_acct_type t, inserted i, deleted d
		where 	i.reference_type = t.reference_type or
			d.reference_type = t.reference_type) = 0)
		Return

	insert epcoa (guid, account_code, account_description, reference_code, reference_description, 
			modified_dt, inactive_dt, active_dt, deleted_dt, send_inactive_flg, deleted_flg)
	select 	newid(), ch.account_code, ch.account_description, 
		ref.reference_code, ref.description,
		ch.modified_dt, ch.inactive_dt, ch.active_dt,
		deleted_dt = NULL, send_inactive_flg = 0, deleted_flg = 0
	from 	deleted ref,
		ep_temp_glchart ch (nolock), 
		ep_temp_glref_acct_type rat (nolock)
		--, glchart_proc gc, glref_proc gr 							 --ggr
	where	ch.account_code like rat.account_mask
	AND 	ref.reference_type = rat.reference_type
	--AND     ch.account_code  LIKE gc.account_code_mask						--ggr
        --AND     ref.reference_code LIKE gr.ref_code_mask 						--ggr
	AND	ch.account_code 
	NOT IN	(select distinct e.account_code
		 from epcoa e
		 where e.account_code = ch.account_code
		 and e.reference_code = ref.reference_code)

	--Case the reference code is changed.  This case should never happen
	if ((select count(*) from inserted i, deleted d 
		where 	i.reference_code <> d.reference_code) > 0)
	Begin
		
		--Set all deleted account to deleted
		update 	epcoa
		set 	deleted_dt = getdate()
		from 	deleted d, 
			inserted i
		where 	d.reference_code = epcoa.reference_code and
			d.reference_code <> i.reference_code 
			
		--Set all deleted account to inactive
		update 	epcoa
		set 	inactive_dt = getdate(),
			modified_dt = getdate()
		from 	deleted d, 
			inserted i
		where 	d.reference_code = epcoa.reference_code and
			(epcoa.inactive_dt is null or
			 epcoa.inactive_dt > getdate()) and
			d.reference_code <> i.reference_code 

	END	--End the case of reference code is changed. 

	--Case the reference description is changed. 
	if ((select count(*) from inserted i, deleted d 
		where 	i.description <> d.description and
			d.reference_code = i.reference_code) > 0)
	Begin

		--update the modified date and reference description
		update epcoa
		set 	reference_description = i.description,
			modified_dt = getdate()
		from deleted d, inserted i
		where 	d.reference_code = epcoa.reference_code and
			d.reference_code = i.reference_code and
			i.description <> d.description
		
		update 	ep_temp_glref						/*ggr*/
		set 	ep_temp_glref.description = i.description
		from 	deleted d , inserted i
		where 	d.reference_code = ep_temp_glref.reference_code and
			d.reference_code = i.reference_code and
			i.description <> d.description

	END	--End the case of reference description is changed. 
		
	--Case the status_flag is changed. 
	if ((select count(*) from inserted i, deleted d 
		where 	d.status_flag <> i.status_flag and
			d.reference_code = i.reference_code) > 0)
	Begin
		--set reference code to inactive
		update 	epcoa
		set 	inactive_dt = getdate()
		from 	deleted d, inserted i
		where 	d.status_flag <> i.status_flag and
		 	i.status_flag = 1 and
			d.reference_code = i.reference_code and
			d.reference_code = epcoa.reference_code
			
		--set reference code to active
		update 	epcoa
		set 	inactive_dt = g.inactive_dt
		from deleted d, inserted i, ep_temp_glchart g
		where 	d.status_flag <> i.status_flag and
		 	i.status_flag = 0 and
			d.reference_code = i.reference_code and
			d.reference_code = epcoa.reference_code and 
			g.account_code = epcoa.account_code

		update 	ep_temp_glref						/*ggr*/
		set 	ep_temp_glref.status_flag = i.status_flag
		from 	deleted d , inserted i
		where 	d.status_flag <> i.status_flag and
		 	d.reference_code = i.reference_code and
			d.reference_code = ep_temp_glref.reference_code

	End -- status_flag is changed
	
	update 	ep_temp_glchart 
	set 	modified_dt = getdate()
	from ep_temp_glref_acct_type e, inserted i, deleted d
	where 	i.reference_type = e.reference_type and
		i.reference_type = d.reference_type and
		i.reference_code = d.reference_code and
		(i.status_flag <> d.status_flag or 
		 i.description <> d.description)
	and	account_code like e.account_mask

END
GO
DISABLE TRIGGER [dbo].[glref_upd_trg] ON [dbo].[glref]
GO
CREATE UNIQUE CLUSTERED INDEX [glref_ind_0] ON [dbo].[glref] ([reference_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glref_ind_1] ON [dbo].[glref] ([reference_type], [reference_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glref] TO [public]
GO
GRANT SELECT ON  [dbo].[glref] TO [public]
GO
GRANT INSERT ON  [dbo].[glref] TO [public]
GO
GRANT DELETE ON  [dbo].[glref] TO [public]
GO
GRANT UPDATE ON  [dbo].[glref] TO [public]
GO
