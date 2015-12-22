CREATE TABLE [dbo].[glratyp]
(
[timestamp] [timestamp] NOT NULL,
[account_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[glratyp_del_trg]
	ON [dbo].[glratyp]
	FOR DELETE AS
BEGIN

	--Return if ep_temp_glref_acct_type has not have any records in it
	If ((SELECT count(*) FROM deleted i, ep_temp_glref_acct_type t 
		WHERE i.account_mask = t.account_mask) = 0)
		Return

	--Return if chart of account has not SET up yet.
	If ((SELECT count(*) FROM ep_temp_glchart ) = 0)
		Return
	
	--Updating ep_temp_glchart with new modified_dt
	UPDATE ep_temp_glchart
	SET modified_dt = GETDATE()
	FROM deleted d
	WHERE account_code LIKE d.account_mask

	--SET records in epcoa to deleted
	/*UPDATE epcoa
	SET deleted_flg = 1
	FROM ep_temp_glref r, deleted d--,  glref_proc gr      --ggr
	WHERE 	epcoa.reference_code = r.reference_code
	AND	epcoa.deleted_dt is NULL 
	AND	r.reference_type = d.reference_type 
	AND	epcoa.account_code LIKE d.account_mask
	--AND     r.reference_code LIKE gr.ref_code_mask     --ggr*/

	SELECT epcoa.account_code, epcoa.reference_code
        INTO  #epcoa_tmp
        FROM ep_temp_glref r, deleted d, epcoa epcoa
	WHERE 	epcoa.reference_code = r.reference_code
	AND	epcoa.deleted_dt is NULL 
	AND	r.reference_type = d.reference_type 
	AND	epcoa.account_code LIKE d.account_mask
       
        UPDATE epcoa
        SET deleted_flg = 1
        FROM #epcoa_tmp
        WHERE epcoa.account_code = #epcoa_tmp.account_code
        AND epcoa.reference_code = #epcoa_tmp.reference_code
        
        drop table #epcoa_tmp
        
  	
	--Deleted record off ep_temp_glref_acct_type  
	DELETE ep_temp_glref_acct_type  
	FROM deleted d
	WHERE ep_temp_glref_acct_type.account_mask = d.account_mask AND
		ep_temp_glref_acct_type.reference_type = d.reference_type

	--Reverse the deleted flag
	/*UPDATE	epcoa
	SET	deleted_flg = 0
	FROM	ep_temp_glref r, ep_temp_glref_acct_type e-- , glref_proc gr --ggr
	WHERE 	epcoa.reference_code = r.reference_code 
	AND	epcoa.deleted_dt is NULL 
	AND	epcoa.deleted_flg = 1 
	AND	r.reference_type = e.reference_type
	AND	epcoa.account_code LIKE e.account_mask
	--AND     r.reference_code LIKE gr.ref_code_mask     --ggr*/
   
    /*    SELECT epcoa.account_code,epcoa.reference_code
        INTO   #epcoa_tmp1
        FROM   ep_temp_glref r, ep_temp_glref_acct_type e,epcoa epcoa   
        WHERE 	epcoa.reference_code = r.reference_code 
	AND	epcoa.deleted_dt is NULL 
	AND	epcoa.deleted_flg = 1 
	AND	r.reference_type = e.reference_type
	AND	epcoa.account_code LIKE e.account_mask
     
        UPDATE	epcoa
        SET	deleted_flg = 0
        FROM    #epcoa_tmp1
        WHERE   epcoa.account_code = #epcoa_tmp1.account_code
        AND     epcoa.reference_code=  #epcoa_tmp1.reference_code
	
	drop table #epcoa_tmp1*/
	
       
	--SET records in epcoa to deleted
	/*UPDATE epcoa
	SET 	deleted_dt = GETDATE(),
		inactive_dt = GETDATE(),
		modified_dt = GETDATE(),
		deleted_flg = 0
	FROM ep_temp_glref r --, glref_proc gr						--ggr
	WHERE 	epcoa.reference_code = r.reference_code AND
		epcoa.deleted_dt is NULL AND
		epcoa.deleted_flg = 1 
               -- AND  r.reference_code LIKE gr.ref_code_mask 							--ggr*/

	
	SELECT epcoa.account_code,epcoa.reference_code
        INTO   #epcoa_tmp2
        FROM   ep_temp_glref r, epcoa epcoa 
        WHERE  epcoa.reference_code = r.reference_code AND
	       epcoa.deleted_dt is NULL AND
	       epcoa.deleted_flg = 1 

        UPDATE epcoa
        SET 	deleted_dt = GETDATE(),
		inactive_dt = GETDATE(),
		modified_dt = GETDATE(),
		deleted_flg = 0
        FROM    #epcoa_tmp2 
        WHERE	epcoa.account_code = #epcoa_tmp2.account_code
        AND     epcoa.reference_code = #epcoa_tmp2.reference_code

	drop table #epcoa_tmp2
	
	/*INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt, deleted_dt)
	SELECT newid(), g.account_code, g.account_description, g.active_dt, 
		GETDATE(), r.reference_code, r.description, GETDATE(), GETDATE()
	FROM ep_temp_glchart g (nolock), ep_temp_glref r (nolock), deleted d --, glchart_proc gc, glref_proc gr  --ggr
	WHERE  g.account_code LIKE d.account_mask
	AND r.reference_type = d.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND  g.account_code not In
	  ( SELECT DISTINCT e.account_code 
	    FROM epcoa e
	    WHERE e.account_code = g.account_code 
	    AND e.reference_code = r.reference_code)	*/

	SELECT guid = newid(), g.account_code, g.account_description, g.active_dt, 
		inactive_dt= GETDATE(), r.reference_code, r.description, modified_dt=GETDATE(),deleted_dt=GETDATE()
        INTO #epcoa_temp3
	FROM ep_temp_glchart g (nolock), ep_temp_glref  r (nolock), deleted d--, glchart_proc gc, glref_proc gr glref  --ggr 
	WHERE 	g.account_code LIKE d.account_mask
	AND	r.reference_type = d.reference_type
        --AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND 	g.account_code not In
		( SELECT DISTINCT e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)
  
   INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt,deleted_dt)
   SELECT guid , account_code, account_description, active_dt, 
		inactive_dt, reference_code, description, modified_dt, deleted_dt
    from #epcoa_temp3


   drop table #epcoa_temp3

END
GO
DISABLE TRIGGER [dbo].[glratyp_del_trg] ON [dbo].[glratyp]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glratyp_ins_trg]
	ON [dbo].[glratyp]
	FOR INSERT AS
BEGIN
	--Populate ep_temp_glref_acct_type

	

        
	INSERT ep_temp_glref_acct_type (account_mask, reference_flag, reference_type)      /*ggr*/
		Select DISTINCT glrefact.account_mask,glrefact.reference_flag,i.reference_type
		from glrefact glrefact, glratyp glratyp, ep_temp_glref r, inserted i 
        	where glrefact.account_mask=glratyp.account_mask
        	and r.reference_type=glratyp.reference_type
        	and i.account_mask = glrefact.account_mask 
        	--Order by i.account_mask

		/*SELECT t.account_mask, t.reference_flag, i.reference_type
		FROM inserted i, glrefact t 
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
	WHERE ep_temp_glchart.account_code LIKE i.account_mask

	--INSERT the account that not exist in epcoa
	/*INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
	SELECT newid(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
	FROM ep_temp_glchart g (nolock), ep_temp_glref  r (nolock), inserted i--, glchart_proc gc, glref_proc gr glref  --ggr 
	WHERE 	g.account_code LIKE i.account_mask
	AND	r.reference_type = i.reference_type
        --AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND 	g.account_code not In
		( SELECT DISTINCT e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)*/

      SELECT guid = newid(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
      INTO #epcoa_temp
      FROM ep_temp_glchart g (nolock), ep_temp_glref  r (nolock), inserted i
      WHERE 	g.account_code LIKE i.account_mask
	  AND	r.reference_type = i.reference_type
      AND 	g.account_code not In
		( SELECT DISTINCT e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)
      
      INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
      SELECT guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, description, modified_dt
      FROM #epcoa_temp
      
      DROP TABLE #epcoa_temp

/***/

	--SET account to active if already exists on epcoa as deleted
	/*UPDATE	epcoa
	SET	inactive_dt = NULL,
		deleted_dt = NULL,
		modified_dt = GETDATE()
	FROM	inserted i, ep_temp_glref r, ep_temp_glchart g--, glchart_proc gc, glref_proc gr --ggr   glref
	WHERE 	epcoa.account_code like i.account_mask
	AND	epcoa.account_code = g.account_code
	--AND     g.account_code  LIKE gc.account_code_mask				--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 					--ggr
	AND	epcoa.reference_code = r.reference_code
	AND	r.reference_type = i.reference_type*/

    SELECT epcoa.account_code, epcoa.reference_code
    INTO #epcoa_temp2
    FROM inserted i, ep_temp_glref r, ep_temp_glchart g, epcoa epcoa
    WHERE epcoa.account_code like i.account_mask
	AND	epcoa.account_code = g.account_code
	AND	epcoa.reference_code = r.reference_code
	AND	r.reference_type = i.reference_type
  
    UPDATE epcoa
    SET inactive_dt = NULL,
		deleted_dt = NULL,
		modified_dt = GETDATE()
    FROM #epcoa_temp2
    WHERE	epcoa.account_code = #epcoa_temp2.account_code
    AND     epcoa.reference_code = #epcoa_temp2.reference_code
 
    DROP TABLE #epcoa_temp2

/***/

	--SET account to inactive if inactive flag is on
	--Case of Required
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM inserted i, ep_temp_glref_acct_type r
	WHERE 	epcoa.account_code LIKE i.account_mask
	AND	i.account_mask = r.account_mask
	AND	i.reference_type = r.reference_type
	AND	epcoa.reference_code IS NULL
	AND	r.reference_flag = 3
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())*/

    SELECT epcoa.account_code, epcoa.reference_code
    INTO #epcoa_temp3
    FROM inserted i, ep_temp_glref_acct_type r, epcoa epcoa
    WHERE epcoa.account_code LIKE i.account_mask
	AND	i.account_mask = r.account_mask
	AND	i.reference_type = r.reference_type
	AND	epcoa.reference_code IS NULL
	AND	r.reference_flag = 3
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

	UPDATE epcoa
    SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
    FROM #epcoa_temp3
    WHERE	epcoa.account_code = #epcoa_temp3.account_code
    AND     epcoa.reference_code = #epcoa_temp3.reference_code

   DROP TABLE #epcoa_temp3
   
    

	-- SET all the account that have reference code to inactive
	--Case of excluded
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r, inserted i, glrefact f--, glref_proc gr				--ggr glref
	WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.account_code LIKE f.account_mask
	--AND     r.reference_code LIKE gr.ref_code_mask 					--ggr 
	AND	epcoa.reference_code = r.reference_code
	AND	r.reference_type = i.reference_type
	AND	reference_flag = 1
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())*/

    SELECT epcoa.account_code, epcoa.reference_code
    INTO #epcoa_temp4
    FROM ep_temp_glref r, inserted i, glrefact f, epcoa epcoa
    WHERE epcoa.account_code LIKE i.account_mask 
	AND	epcoa.account_code LIKE f.account_mask
	AND	epcoa.reference_code = r.reference_code
	AND	r.reference_type = i.reference_type
	AND	reference_flag = 1
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

    UPDATE epcoa
    SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE()  
    FROM #epcoa_temp4
    WHERE	epcoa.account_code = #epcoa_temp4.account_code
    AND     epcoa.reference_code = #epcoa_temp4.reference_code

   DROP TABLE #epcoa_temp4
   
     

	--SET account to inactive if inactive flag is on
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r (nolock), ep_temp_glchart g, inserted i--, glchart_proc gc , glref_proc gr  --ggr  glref
	WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE i.account_mask 
        --AND     g.account_code  LIKE gc.account_code_mask						--ggr
	--AND     r.reference_code LIKE gr.ref_code_mask 					       --ggr 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = i.reference_type 
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())*/

   SELECT epcoa.account_code, epcoa.reference_code
   INTO #epcoa_temp5
   FROM ep_temp_glref r (nolock), ep_temp_glchart g, inserted i, epcoa epcoa
   WHERE epcoa.account_code = g.account_code 
	AND	g.account_code LIKE i.account_mask 
   	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = i.reference_type 
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

   UPDATE epcoa
    SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE()  
    FROM #epcoa_temp5
    WHERE	epcoa.account_code = #epcoa_temp5.account_code
    AND     epcoa.reference_code = #epcoa_temp5.reference_code

   DROP TABLE #epcoa_temp5
   
    


END
GO
DISABLE TRIGGER [dbo].[glratyp_ins_trg] ON [dbo].[glratyp]
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

CREATE TRIGGER [dbo].[glratyp_integ_del_trg]
	ON [dbo].[glratyp]
	FOR DELETE AS
BEGIN

	INSERT INTO epintegrationrecs 
	SELECT Distinct DEL.reference_type, DEL.account_mask, 5, 'D', 0 
	FROM Deleted DEL
		INNER JOIN glref REF ON DEL.reference_type = REF.reference_type
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
END

GO
DISABLE TRIGGER [dbo].[glratyp_integ_del_trg] ON [dbo].[glratyp]
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

CREATE TRIGGER [dbo].[glratyp_integ_ins_trg]
	ON [dbo].[glratyp]
	FOR INSERT AS
BEGIN

	INSERT INTO epintegrationrecs 
	SELECT DISTINCT INS.reference_type, INS.account_mask, 5, 'I', 0 
	FROM Inserted INS
		INNER JOIN glref REF ON INS.reference_type = REF.reference_type
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
END

GO
DISABLE TRIGGER [dbo].[glratyp_integ_ins_trg] ON [dbo].[glratyp]
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

CREATE TRIGGER [dbo].[glratyp_integration_del_trg]
	ON [dbo].[glratyp]
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
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, DEL.reference_type,REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date, 
	CASE WHEN ACT.reference_flag = 1 THEN 'N' ELSE 
		CASE WHEN ACT.reference_flag = 2 OR ACT.reference_flag = 3 THEN 'D' 
		END			
	END
	FROM deleted DEL 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE DEL.account_mask
		INNER JOIN glref REF ON DEL.reference_type = REF.reference_type 
		INNER JOIN glrefact ACT ON  DEL.account_mask = ACT.account_mask
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
		WHERE REF.status_flag = 0 AND CHRT.inactive_flag = 0 
				AND @DATETIME BETWEEN 
					CASE CHRT.active_date WHEN 0 THEN @DATETIME ELSE DATEADD(day, CHRT.active_date - 693596,'01/01/1900') END 
					AND 
					CASE CHRT.inactive_date WHEN 0 THEN DATEADD(day,1,@DATETIME) ELSE DATEADD(day, CHRT.inactive_date - 693596,'01/01/1900')  END
	
	/*--------------------------------------------------------------INSERT ACCOUNTS WITHOUT REFERENCES CODES------*/
	INSERT INTO #TEMPCoas (account_code, account_description, reference_type, reference_code, reference_description, active_date, inactive_date, status)
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, NULL, 'NOREF', 'NOREF', CHRT.active_date, CHRT.inactive_date,
	CASE WHEN ACT.reference_flag = 1 OR ACT.reference_flag = 2 THEN 'I' ELSE 
		CASE WHEN ACT.reference_flag = 3 THEN 'N' 
		END			
	END
	FROM deleted DEL 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE DEL.account_mask
		INNER JOIN glrefact ACT ON  DEL.account_mask = ACT.account_mask
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
	AND NOT COAS.status = 'N'

	DROP TABLE #TEMPCoas

END

GO
DISABLE TRIGGER [dbo].[glratyp_integration_del_trg] ON [dbo].[glratyp]
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

CREATE TRIGGER [dbo].[glratyp_integration_ins_trg]
	ON [dbo].[glratyp]
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
	SELECT DISTINCT CHRT.account_code, CHRT.account_description, INS.reference_type,REF.reference_code, REF.description, CHRT.active_date, CHRT.inactive_date, 
	CASE WHEN ACT.reference_flag = 1 THEN 'N' ELSE 
		CASE WHEN ACT.reference_flag = 2 OR ACT.reference_flag = 3 THEN 'I' 
		END			
	END,
	ACT.reference_flag
	FROM Inserted INS 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE INS.account_mask
		INNER JOIN glref REF ON INS.reference_type = REF.reference_type 
		INNER JOIN glrefact ACT ON  INS.account_mask = ACT.account_mask
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
	CASE WHEN ACT.reference_flag = 1 OR ACT.reference_flag = 2 THEN 'I' ELSE 
		CASE WHEN ACT.reference_flag = 3 THEN 'N' 
		END			
	END,
	ACT.reference_flag
	FROM Inserted INS 
		INNER JOIN glchart CHRT ON CHRT.account_code LIKE INS.account_mask
		INNER JOIN glrefact ACT ON  INS.account_mask = ACT.account_mask
		INNER JOIN glchart_proc CPROC ON CHRT.account_code LIKE CPROC.account_code_mask
	WHERE CHRT.inactive_flag = 0 
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
DISABLE TRIGGER [dbo].[glratyp_integration_ins_trg] ON [dbo].[glratyp]
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

CREATE TRIGGER [dbo].[glratyp_integration_upd_trg]
	ON [dbo].[glratyp]
	FOR UPDATE AS
BEGIN	
	DELETE epintegrationrecs 
	WHERE action = 'U' AND type = 5 
		AND id_code IN ( SELECT reference_type FROM Inserted, epintegrationrecs WHERE id_code = reference_type )
		AND mask IN ( SELECT account_mask FROM Inserted, epintegrationrecs WHERE mask = account_mask )
	
	INSERT INTO epintegrationrecs 
	SELECT Distinct INS.reference_type, INS.account_mask, 5, 'U', 0 
	FROM Inserted INS
		INNER JOIN glref REF ON INS.reference_type = REF.reference_type
		INNER JOIN glref_proc RPROC ON REF.reference_code LIKE RPROC.ref_code_mask
END

GO
DISABLE TRIGGER [dbo].[glratyp_integration_upd_trg] ON [dbo].[glratyp]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[glratyp_upd_trg]
	ON [dbo].[glratyp]
	FOR UPDATE AS
BEGIN

	--Note: This trigger assumed the user would be able to change account_mask. 
	--Return the process if there is no change in the following columns
	if ((	SELECT count(*) FROM inserted i, deleted d WHERE d.reference_type <> i.reference_type AND d.account_mask = i.account_mask) = 0)
		Return
			
	--If there is no records in ep_temp_glref_acct_type, it indicates that the
	--account mask in glratyp table need to be populate before calling this process
	If ((SELECT count(*) 
		FROM ep_temp_glref_acct_type t, deleted d
		WHERE 	d.reference_type = t.reference_type) = 0)
		Return

	--Check to see if There is any COA to populate
	If ((SELECT count(*) FROM ep_temp_glchart) = 0)
		Return

	UPDATE ep_temp_glref_acct_type 
	SET reference_type = i.reference_type
	FROM deleted d, inserted i
	WHERE 	d.account_mask = i.account_mask 
	AND	d.account_mask = ep_temp_glref_acct_type.account_mask 
	AND	d.reference_type = ep_temp_glref_acct_type.reference_type 
	AND	d.reference_type <> i.reference_type

	--Updating ep_temp_glchart with new modified_dt
	UPDATE ep_temp_glchart
	SET modified_dt = GETDATE()
	FROM inserted i
	WHERE account_code LIKE i.account_mask

	--take care the deleted reference type first
	--SET account to inactive if inactive flag is on
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r (nolock), ep_temp_glchart g, deleted d --, glchart_proc gc, glref_proc gr  --ggr
	WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE d.account_mask 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = d.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
       -- AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())*/
   
        
        SELECT account_code,reference_code
        INTO #epcoa_tmp
        FROM  p_temp_glref r (nolock), ep_temp_glchart g, deleted d, epcoa epcoa
        WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE d.account_mask 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = d.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
       -- AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND	(epcoa.inactive_dt is NULL or 
		 epcoa.inactive_dt > GETDATE())

	UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM #epcoa_tmp
	WHERE 	epcoa.account_code = #epcoa_tmp.account_code 
	AND	epcoa.reference_code = #epcoa_tmp.reference_code 
	
       drop table #epcoa_temp
	        
	
	--INSERT the account that not exist in epcoa
	/*INSERT INTO epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
	SELECT NEWID(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
	FROM ep_temp_glchart g (nolock), ep_temp_glref r (nolock), inserted i --, glchart_proc gc, glref_proc gr  --ggr
	WHERE 	r.reference_type = i.reference_type 
	AND	g.account_code LIKE i.account_mask
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
       -- AND     r.reference_code LIKE gr.ref_code_mask 							--ggr 
	AND	g.account_code NOT IN
		( SELECT distinct e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)*/

	SELECT guid = newid(), g.account_code, g.account_description, g.active_dt, 
		g.inactive_dt, r.reference_code, r.description, g.modified_dt
    	INTO #epcoa_temp1
	FROM ep_temp_glchart g (nolock), ep_temp_glref  r (nolock), inserted i
	WHERE 	g.account_code LIKE i.account_mask
	AND	r.reference_type = i.reference_type
        AND 	g.account_code not In
		( SELECT DISTINCT e.account_code 
		  FROM epcoa e
		  WHERE e.account_code = g.account_code 
		  AND	e.reference_code = r.reference_code)
  
        INSERT into epcoa 
		(guid, account_code, account_description, active_dt, inactive_dt, 
		reference_code, reference_description, modified_dt)
        SELECT guid , account_code, account_description, active_dt, 
		inactive_dt, reference_code, description, modified_dt
        from #epcoa_temp1

        drop table #epcoa_temp1
	

        
	--SET account to inactive if inactive flag is on
	--Case of Required
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM	inserted i, ep_temp_glref_acct_type v
	WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.reference_code is NULL 
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 3
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())*/
       
        SELECT epcoa.account_code,epcoa.reference_code
        INTO #epcoa_temp2
        FROM inserted i, ep_temp_glref_acct_type v, epcoa epcoa
        WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.reference_code is NULL 
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 3
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())
   
        UPDATE epcoa
        SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
        FROM  #epcoa_temp2
        WHERE  epcoa.account_code =  #epcoa_temp2.account_code
  	AND epcoa.reference_code  = #epcoa_temp2.reference_code
       
        DROP TABLE #epcoa_temp2
        
	-- SET all the account that have reference code to inactive
	--Case of Required


	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM	inserted i, ep_temp_glref_acct_type v
	WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 1
	AND	epcoa.reference_code is not NULL 
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())*/

       SELECT epcoa.account_code, epcoa.reference_code
       INTO #epcoa_temp3
       FROM inserted i, ep_temp_glref_acct_type v, epcoa epcoa
       WHERE 	epcoa.account_code LIKE i.account_mask 
	AND	epcoa.account_code LIKE v.account_mask
	AND	v.reference_flag = 1
	AND	epcoa.reference_code is not NULL 
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())
	
	UPDATE epcoa
        SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
        FROM #epcoa_temp3
        WHERE  epcoa.account_code =  #epcoa_temp3.account_code
  	AND epcoa.reference_code  = #epcoa_temp3.reference_code
        
        drop table #epcoa_temp3  


	--SET account to inactive if inactive flag is on
	/*UPDATE epcoa
	SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
	FROM ep_temp_glref r (nolock), ep_temp_glchart g, inserted i --, glchart_proc gc, glref_proc gr
	WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE i.account_mask 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = i.reference_type
	--AND     g.account_code  LIKE gc.account_code_mask						--ggr
        --AND     r.reference_code LIKE gr.ref_code_mask 							--ggr
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())*/

       SELECT epcoa.account_code, epcoa.reference_code
       INTO #epcoa_temp4
       FROM  ep_temp_glref r (nolock), ep_temp_glchart g, inserted i, epcoa epcoa
       WHERE 	epcoa.account_code = g.account_code 
	AND	g.account_code LIKE i.account_mask 
	AND	epcoa.reference_code = r.reference_code 
	AND	r.reference_type = i.reference_type
	AND	(g.inactive_flag = 1 or r.status_flag = 1) 
	AND	(epcoa.inactive_dt is NULL or epcoa.inactive_dt > GETDATE())
	
	UPDATE epcoa
        SET inactive_dt = GETDATE(),
	    modified_dt = GETDATE() 
        FROM #epcoa_temp4
        WHERE  epcoa.account_code =  #epcoa_temp4.account_code
  	AND epcoa.reference_code  = #epcoa_temp4.reference_code
        
        drop table #epcoa_temp4  


END
GO
DISABLE TRIGGER [dbo].[glratyp_upd_trg] ON [dbo].[glratyp]
GO
CREATE UNIQUE CLUSTERED INDEX [glratyp_ind_0] ON [dbo].[glratyp] ([account_mask], [reference_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glratyp] TO [public]
GO
GRANT SELECT ON  [dbo].[glratyp] TO [public]
GO
GRANT INSERT ON  [dbo].[glratyp] TO [public]
GO
GRANT DELETE ON  [dbo].[glratyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[glratyp] TO [public]
GO
