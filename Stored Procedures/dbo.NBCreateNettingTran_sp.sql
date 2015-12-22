SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[NBCreateNettingTran_sp] @process_ctrl_num varchar(16), @module_id smallint, @debug_level smallint 
AS


	DECLARE	@customer_code	 varchar(8),
		@net_ctrl_num    varchar(16),
		@vendor_code	 varchar(12),
		@vend_susp_acct	 varchar(32),
		@cust_susp_acct	 varchar(32),
		@result		 int

	
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2',0,''

	





	Update apco set batch_proc_flag = batch_proc_flag
	where batch_proc_flag = 5


	SELECT @net_ctrl_num = '', @vend_susp_acct = '' , @cust_susp_acct = ''

	



	SELECT	@net_ctrl_num	= MIN(net_ctrl_num)
	FROM	#nbnethdr_work
	WHERE   process_ctrl_num = @process_ctrl_num
	AND	net_ctrl_num	> @net_ctrl_num

	IF @module_id != 2000 and @module_id!= 4000		
		RETURN 1

	IF @net_ctrl_num IS NULL			
		RETURN 1

	WHILE 	@net_ctrl_num IS NOT NULL
	BEGIN


		SELECT	@customer_code 	= customer_code,@vendor_code 	= vendor_code
		FROM 	#nbnethdr_work
		WHERE	net_ctrl_num = @net_ctrl_num

		IF @module_id = 2000  				  
		BEGIN 
			
			SELECT 	@cust_susp_acct = suspense_acct_code
			FROM	araccts, arcust
			WHERE	arcust.posting_code 	= araccts.posting_code
			AND	arcust.customer_code 	= @customer_code
		
			SELECT @vend_susp_acct = @cust_susp_acct
		END		
		ELSE            
		BEGIN

			SELECT 	@vend_susp_acct = suspense_acct_code
			FROM	apaccts, apvend
			WHERE	apvend.posting_code	= apaccts.posting_code
			AND	apvend.vendor_code	= @vendor_code
	
			SELECT @cust_susp_acct = @vend_susp_acct
			
		END

		IF  (@customer_code IS NULL OR @vendor_code IS NULL OR @vend_susp_acct IS NULL OR @cust_susp_acct IS NULL)
			RETURN 1

		


		EXEC	@result = NBNetInvoicesVsCMemoCReceipt_sp @net_ctrl_num, @process_ctrl_num, @debug_level 
		IF (@result !=  0 )
			RETURN @result

		


		EXEC	@result = NBNetVoucherVsPaymentDebitMemo_sp @net_ctrl_num, @process_ctrl_num,  @debug_level 
		IF (@result !=  0 )
			RETURN @result

		


		EXEC	@result = NBNetVoucherVsNegativeVoucher_sp @net_ctrl_num, @vend_susp_acct, @process_ctrl_num,  @debug_level 
		IF (@result !=  0 )
			RETURN @result

		


		EXEC	@result = NBNetInvoiceVsVoucher_sp @net_ctrl_num, @vend_susp_acct, @cust_susp_acct, @process_ctrl_num, @debug_level 
		IF (@result !=  0 )
			RETURN @result


		


		EXEC	@result = NBNetPaymentVsCashReceipt_sp @net_ctrl_num, @vend_susp_acct, @cust_susp_acct, @process_ctrl_num, @debug_level 
		IF (@result !=  0 )
			RETURN @result

		


		EXEC	@result = NBNettingPaymentNonAr_sp @net_ctrl_num, @vend_susp_acct, @cust_susp_acct, @process_ctrl_num, @module_id,	@debug_level 
		IF (@result !=  0 )
			RETURN @result

		
		exec nbbatch_sp @process_ctrl_num, @result output

		IF (@result !=  0 )
			RETURN @result

		SELECT	@net_ctrl_num	= MIN(net_ctrl_num)
		FROM	#nbnethdr_work
		WHERE   process_ctrl_num = @process_ctrl_num
		AND	net_ctrl_num	> @net_ctrl_num

	END	-- End of while @net_ctrl_num IS NOT NULL

	delete from apinpstl where settlement_ctrl_num not in (select settlement_ctrl_num from apinppyt)
	delete from arinpstlhdr where settlement_ctrl_num not in (select settlement_ctrl_num from arinppyt)
	

	-- SCR  32444 01/21/2004 Cyanez  This part of the code was added because  the stores procedures
	-- inserts user_id = 1 in the tables arinpchg, arinpstlhdr, arinppyt, apinpchg, apinpstl
	-- apinppyt when the correct situation is insert the user_id of the user who starts the process.
	
	-- At this point change all the stores procedures that prevents the combination where a Netting 
	-- transaction is possible, is most complex than just update the tables after 
	-- the stores finalize their work.

	UPDATE arinpchg
	SET arinpchg.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= arinpchg.process_group_num
	AND arinpchg.process_group_num= @process_ctrl_num

	UPDATE arinpstlhdr
	SET arinpstlhdr.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= arinpstlhdr.process_group_num
	AND arinpstlhdr.process_group_num= @process_ctrl_num
	
	UPDATE arinppyt
	SET arinppyt.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= arinppyt.process_group_num
	AND arinppyt.process_group_num= @process_ctrl_num
	
	UPDATE apinpchg
	SET apinpchg.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= apinpchg.process_group_num
	AND apinpchg.process_group_num= @process_ctrl_num

	UPDATE apinpstl
	SET apinpstl.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= apinpstl.process_group_num
	AND apinpstl.process_group_num= @process_ctrl_num

	UPDATE apinppyt
	SET apinppyt.user_id=p.process_user_id
	FROM pcontrol_vw p
	WHERE p.process_ctrl_num= apinppyt.process_group_num
	AND apinppyt.process_group_num= @process_ctrl_num

	-- SCR 32444

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2',-1,''

RETURN   0  
GO
GRANT EXECUTE ON  [dbo].[NBCreateNettingTran_sp] TO [public]
GO
