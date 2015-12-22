SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






CREATE  PROCEDURE [dbo].[cminpcr_sp]
	@module_id			smallint,
	@val_mode			smallint,
	@trx_type			smallint,
	@trx_ctrl_num		varchar(16),      
	@doc_ctrl_num		varchar(16),
	@date_document		int,
	@description		varchar(30),
	@document1			varchar(30),
	@document2			varchar(30),
	@cash_acct_code		varchar(32),
	@amount_book		float,
	@void_flag			smallint,
	@date_applied		int,
	@apply_to_trx_num	varchar(16)	= NULL,
	@apply_to_trx_type	smallint = NULL,
	@apply_to_doc_num	varchar(16)	= NULL,
	@auto_reconcile     smallint = 0,
	@cleared_type 		smallint = NULL,
	@org_id			varchar(30) = ''
	
		
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE @result	int,
		@amount_bank float,
		@date_cleared int,
		@reconciled_flag smallint, 
		@debug_level int 

select @debug_level = 10


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cminpcr.cpp' + ', line ' + STR( 75, 5 ) + ' -- ENTRY: '




IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'		
END




IF @description IS NULL OR @description = ' '
	SELECT @description = @trx_ctrl_num + ':' + @doc_ctrl_num


IF (@cleared_type IS NULL)
   BEGIN
	  SELECT @cleared_type = ABS(SIGN(@trx_type/1000 -2))
   END

IF (@auto_reconcile = 1)
   BEGIN
      SELECT @amount_bank = @amount_book,
			 @date_cleared = @date_document,
			 @reconciled_flag = 1

   END
ELSE
   BEGIN
      SELECT @amount_bank = 0.0,
			 @date_cleared = 0,
			 @reconciled_flag = 0
   END



INSERT  #cminpdtl(
	trx_type,		
	trx_ctrl_num,		
	doc_ctrl_num,		
	date_document,		
	description,
	document1,
	document2,		
	cash_acct_code,		
	amount_book,		
	reconciled_flag,	
	closed_flag,	
	void_flag,		
	date_applied,		
	cleared_type,
	apply_to_trx_num,
	apply_to_trx_type,
	apply_to_doc_num,
	trx_state,
	mark_flag,
	org_id	)
VALUES (
	@trx_type,		
	@trx_ctrl_num,		
	@doc_ctrl_num,		
	@date_document,		
	@description,
	@document1,
	@document2,		
	@cash_acct_code,		
	@amount_book,		
	@reconciled_flag,	
	0,	
	@void_flag,		
	@date_applied,		
	@cleared_type,
	@apply_to_trx_num,
	@apply_to_trx_type,
	@apply_to_doc_num,
	0,
	0,
	@org_id
	)



IF ( @@error != 0 )
	RETURN  -1
	

RETURN  0


GO
GRANT EXECUTE ON  [dbo].[cminpcr_sp] TO [public]
GO
