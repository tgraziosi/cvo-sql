SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                
/*
**  Name of Stored Procedure : ibpost_sp
**
**  Purpose : This SP mark ibifc records for in posting journals
**
**  AUTHOR:     Cyanez
**	DATE:		10-28-200	
**
**
**
**
**                    Confidential Information
**         Limited Distribution of Authorized Persons Only
**         Created 1992 and Protected as Unpublished Work
**               Under the U.S. Copyright Act of 1976
**      Copyright (c) 1992-1993  Platinum Software Corporation.
**                       All Rights Reserved
**
**
**
**	Rev	When		Who		Why
**	----	--------	---------	--------------------------------------
**	1.0	02/07/05	JGallegos	SCR 34203, Update the root organzation when the org is null. this will apply mostly for imported transactions.
**	1.1	03/06/05	Cyanez		Hold Flag.
**	2.0	JGallegos	03/10/2005	Change outline_num = 1 for the ROOT ORG Dev 7.3.6
**	3.0	JGallegos	08/15/2005	Change the defaults values when the org_id is null.
*/


























CREATE PROC [dbo].[ibpost_sp]
 
	@process_ctrl_num	nvarchar(16),
	@trial_flag	integer=1,
	@debug_flag	integer=0,
	@post_ib_external integer =0

AS




DECLARE @num_rows	int,
	@ret		int,
	@debug_level	int

SELECT @num_rows =0, @debug_level = @debug_flag

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 47, 5 ) + " -- ENTRY: "

CREATE TABLE #temp_journal (journal_ctrl_num varchar(16), sequence_id int, account_code varchar(32), org_id nvarchar(30))









IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 59, 5 ) + " -- MSG: " + 'Get the Detail transactions without org.'

INSERT INTO #temp_journal 
SELECT 	det.journal_ctrl_num, det.sequence_id, det.account_code, NULL
FROM	gltrx hdr, gltrxdet det
WHERE	hdr.process_group_num = @process_ctrl_num
AND	hdr.journal_ctrl_num = det.journal_ctrl_num
AND 	(det.org_id IS NULL OR det.org_id = '')

IF @@rowcount != 0
BEGIN
	


	UPDATE  #temp_journal
	SET	org_id = gl.organization_id
	FROM glchart gl, #temp_journal t WHERE gl.account_code =  t.account_code
	
	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + 'Update the org_id in gltrxdet'
	
	UPDATE 	det
	SET	det.org_id = t.org_id
	FROM	gltrxdet det, #temp_journal t
	WHERE	det.journal_ctrl_num 	= t.journal_ctrl_num
	AND	det.sequence_id		= t.sequence_id
	
	TRUNCATE TABLE #temp_journal

END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 93, 5 ) + " -- MSG: " + 'Get the HEADER transactions with at least one details without org.'

INSERT INTO #temp_journal
SELECT 	journal_ctrl_num,NULL,NULL,NULL
FROM	gltrx
WHERE	process_group_num = @process_ctrl_num
AND	(org_id IS NULL OR org_id = '')

IF @@ROWCOUNT != 0
BEGIN

	
	


	UPDATE  hdr
	SET	hdr.org_id = CASE 
			WHEN (SELECT COUNT(DISTINCT org_id) FROM gltrxdet det WHERE det.journal_ctrl_num = j.journal_ctrl_num) > 1 THEN
				ISNULL((SELECT organization_id FROM Organization_all WHERE outline_num = '1'),'')
			ELSE
				(SELECT MIN(det.org_id) FROM gltrxdet det WHERE det.journal_ctrl_num = j.journal_ctrl_num)
					
			END,
		hdr.interbranch_flag = 0									 	
	FROM	gltrx hdr, #temp_journal j
	WHERE	hdr.journal_ctrl_num = j.journal_ctrl_num

	
END

DROP TABLE #temp_journal





--
-- Make sure inter-branch processing is turned on
-- 
IF NOT EXISTS (SELECT 1 FROM glco WHERE ib_flag = 1) 
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 134, 5 ) + " -- EXIT: "
	RETURN 0
END



-- Mark transactions to be automatically posted. The where clause purposely excludes all
-- transactions since all that we want is the process_ctrl_num. We will do the actual marking
-- ourselves based on the data that is already in #gldtrx.
--
IF (@post_ib_external=1) 
BEGIN
	UPDATE 	ibifc 
	SET 	process_ctrl_num = @process_ctrl_num
	WHERE  	state_flag IN ( -1, -5)
	AND 	ISNULL(hold_flag,0) = 0
	
	SELECT @num_rows = @@rowcount
END
ELSE
BEGIN
	
	UPDATE	ibifc
	SET	ibifc.process_ctrl_num 	= @process_ctrl_num
	FROM	ibifc, gltrx
	WHERE	ibifc.link1	 	= gltrx.journal_ctrl_num
	AND	gltrx.process_group_num = @process_ctrl_num
	AND	gltrx.posted_flag = -1
	AND	interbranch_flag = 1
	AND	intercompany_flag = 0
	AND	ibifc.state_flag IN ( 0 , -4)
	AND	ISNULL(ibifc.hold_flag,0) = 0

	SELECT @num_rows = @@rowcount

END

--
-- Continue only if transactions have been marked in the interface table (ibifc) to
-- be posted.
--

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 176, 5 ) + " -- MSG: " + 'Check for transactions to post'


IF NOT EXISTS (SELECT 1 FROM ibifc WHERE process_ctrl_num = @process_ctrl_num AND state_flag IN ( 0,-1, -4, -5))
BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 181, 5 ) + " -- EXIT: "
	RETURN 0
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 186, 5 ) + " -- MSG: " + 'Update process status - running'

EXEC @ret = pctrlupd_sp @process_ctrl_num, 4

IF @ret <> 0 
BEGIN

	RETURN -110
END






IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 201, 5 ) + " -- MSG: " + 'EXEC ibpost_gl_sp'

EXEC @ret = ibpost_gl_sp @process_ctrl_num, @trial_flag, @debug_level


	IF @ret IN (0, -1, -120)
	BEGIN
		SELECT 	@ret =0
	END

	IF  @post_ib_external = 1
	BEGIN
		SELECT @ret=@num_rows
	END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost.cpp" + ", line " + STR( 216, 5 ) + " -- EXIT: "

RETURN @ret


GO
GRANT EXECUTE ON  [dbo].[ibpost_sp] TO [public]
GO
