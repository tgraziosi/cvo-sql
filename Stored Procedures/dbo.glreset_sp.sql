SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[glreset_sp] 
		@isit_intercomp int,
		@debug tinyint = 0
AS

DECLARE @result int,
	@tran_started tinyint,
	@client_id varchar(20),
	@E_RECOVERY_FAILED int,
	@E_INTERCOMP_FAILED int
	
IF ( @debug > 0 )
BEGIN
	SELECT "-------------------- Entering glreset_sp -------------------"
END

SELECT @client_id = "POSTTRX"

SELECT @tran_started = 0

SELECT @E_RECOVERY_FAILED = e_code
FROM glerrdef
WHERE e_sdesc = "E_RECOVERY_FAILED"

SELECT @E_INTERCOMP_FAILED = e_code
FROM glerrdef
WHERE e_sdesc = "E_INTERCOMP_FAILED"

IF ( @debug > 0 )
BEGIN
	SELECT "Begining Transaction"
	SELECT "Updating posted flag  "
END

IF (@isit_intercomp = 1)
BEGIN
 INSERT gltrxdet 
		(journal_ctrl_num,
		 sequence_id,
		 account_code, 
		 posted_flag,
		 date_posted,
		 balance, 
		 document_1,
		 description,
		 rec_company_code, 
		 company_id,
		 document_2,
		 reference_code, 
		 nat_balance,
		 nat_cur_code,
		 rate,
		 trx_type, 
		 offset_flag,
		 seg1_code,
		 seg2_code,
		 seg3_code, 
		 seg4_code,
		 seq_ref_id) 
 SELECT a.journal_ctrl_num,
		 a.sequence_id, 
		 a.account_code,
		 a.posted_flag,
		 a.date_posted, 
		 a.balance,
		 "",
		 a.description, 
		 a.rec_company_code,
		 a.company_id,
		 a.document_2, 
		 a.reference_code,
		 a.nat_balance,
		 a.nat_cur_code, 
		 a.rate,
		 a.trx_type,
		 a.offset_flag,
		 a.seg1_code, 
		 a.seg2_code,
		 a.seg3_code,
		 a.seg4_code,
		 a.seq_ref_id 
 FROM glictrxd a, #jnum b
 WHERE a.journal_ctrl_num = b.journal_num
	 

 IF (@@error > 0)
 BEGIN
	 SELECT @result =@E_INTERCOMP_FAILED
	 RETURN @result
 END

 DELETE glictrxd 
 FROM glictrxd a, #jnum b
 WHERE a.journal_ctrl_num= b.journal_num

 IF (@@error > 0)
 BEGIN
	 SELECT @result =@E_INTERCOMP_FAILED
	 RETURN @result
 END

END
ELSE
BEGIN



 IF ( @@trancount = 0 )
 BEGIN
	BEGIN TRAN
	SELECT @tran_started = 1
 END


 
 UPDATE a
 SET a.posted_flag=0
 FROM gltrxdet a,glpost b
 WHERE a.posted_flag=b.posted_flag
 AND b.checked_flag=1
 AND b.batch_proc_flag=0

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END

 UPDATE a
 SET a.posted_flag=0
 FROM gltrx a,glpost b
 WHERE a.posted_flag=b.posted_flag
 AND b.checked_flag=1
 AND b.batch_proc_flag=0

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END

 
 UPDATE a
 SET a.posted_flag=0
 FROM gltrxdet a,gltrx b, batchctl c, glpost d
 WHERE a.journal_ctrl_num=b.journal_ctrl_num
 AND b.batch_code=c.batch_ctrl_num
 AND c.posted_flag=d.posted_flag
 AND d.checked_flag = 1
 AND d.batch_proc_flag=1

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END

 UPDATE a
 SET a.posted_flag=0
 FROM gltrx a, batchctl b, glpost c
 WHERE a.batch_code=b.batch_ctrl_num
 AND b.posted_flag=c.posted_flag
 AND c.checked_flag = 1
 AND c.batch_proc_flag=1

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END

 UPDATE a
 SET a.posted_flag=0,
		a.hold_flag=0,
		a.void_flag=0,
		a.selected_flag=0
 FROM batchctl a, glpost b
 WHERE a.posted_flag=b.posted_flag
 AND b.checked_flag = 1
 AND b.batch_proc_flag=1

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END


 
 UPDATE glpost
 SET checked_flag = 0,
		completed_flag = 1
 WHERE checked_flag = 1

 IF (@@error > 0)
 BEGIN
 SELECT @result=@E_RECOVERY_FAILED
 GOTO process_err
 END

 IF ( @tran_started = 1 )
 BEGIN
	COMMIT TRAN
	SELECT @tran_started = 0
 
 END
END

IF ( @debug > 0 )
BEGIN
	SELECT "---------------- Exiting glreset_sp --------------------"
END

RETURN 0

process_err: 

IF ( @tran_started = 1 )
BEGIN
 ROLLBACK TRAN
 SELECT @tran_started = 0
END

UPDATE glpost
SET checked_flag=0
WHERE checked_flag=1 

RETURN @result

GO
GRANT EXECUTE ON  [dbo].[glreset_sp] TO [public]
GO
