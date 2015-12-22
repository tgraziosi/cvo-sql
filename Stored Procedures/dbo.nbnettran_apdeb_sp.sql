SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[nbnettran_apdeb_sp]
			@net_ctrl_num	varchar(16),	@vendor_code	varchar(12),
			@customer_code	varchar(8),	@currency_code 	varchar(8)
AS
	Declare 
		@return			int,
		@trx_ctrl_num		varchar(16), 
		@doc_ctrl_num		varchar(16),
		@tmp_cust_code		varchar(8),
		@tmp_cur_code		varchar(8),
		@tmp_vend_code		varchar(12),
		@tmp_doc_ctrl_num	varchar(16),
		@amt_applied 		float, 
		@amt_disc_taken 	float, 
		@amt_max_wr_off		float,
		@valid_payer_flag	int,
		@sequence_id		int

BEGIN
		Select @return = 0
		


		


		Exec apldoa_sp @vendor_code, @currency_code, '',1

		
		Insert into ##nbnetdeb(
			net_ctrl_num, 			apply_trx,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			date_applied,
			customer_code)
		Select 
			@net_ctrl_num,			0,
			a.trx_ctrl_num,			a.doc_ctrl_num,			4092,
			b.trx_type_desc,		a.amt_on_acct,			0,
			0,				a.nat_cur_code,			a.date_applied,
			""
		From 
			#onacct		a,
			aptrxtyp	b
		Where 
				payment_code  	= "DBMEMO"
			AND	b.trx_type 	= 4092 
		Order By
			a.date_applied	asc
		Select @return = @@ERROR
		IF @return <> 0
			return @return



		
		Insert into ##nbnetdeb(
			net_ctrl_num, 			apply_trx,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			a.date_applied,
			customer_code)
		Select 
			@net_ctrl_num,			0,
			a.trx_ctrl_num,			a.doc_ctrl_num,			4091,
			b.trx_type_desc,		abs(a.amt_net-a.amt_paid_to_date),0,
			0,				a.currency_code,		a.date_applied,
			""
		From 
			apvohdr		a,
			aptrxtyp	b
		Where 
				a.vendor_code 	= @vendor_code
			AND 	a.currency_code	= @currency_code
			AND	a.paid_flag	= 0
			AND	b.trx_type 	= 4091 
			And	(a.amt_net-a.amt_paid_to_date) < 0
		Order by
			date_applied	asc
		Select @return = @@ERROR
		IF @return <> 0
			return @return



		Declare debit_cursor CURSOR FOR 
		Select sequence_id, trx_ctrl_num, customer_code
		From ##nbnetdeb
		Order By
			sequence_id	asc
  		Open debit_cursor
		Fetch Next From debit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_cust_code
  
		While @@FETCH_STATUS = 0
		Begin

			Select 	
				@amt_applied 	= isnull( sum(vo_amt_applied) ,0), 
				@amt_disc_taken = isnull( sum(vo_amt_disc_taken) ,0) 
			From    apinppdt 
			Where  
					apply_to_num 	= @tmp_doc_ctrl_num
				AND   	vendor_code 	= @tmp_vend_code
				And	trx_type	in ( 4111 ) 


			Update 	##nbnetdeb
			Set	amt_net 	= amt_net + ( @amt_applied + @amt_disc_taken )
			Where	sequence_id	= @sequence_id
			Select @return = @@ERROR
			IF @return <> 0
				return @return

				
			Fetch Next From debit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_cust_code
		End
  
		Close debit_cursor
		Deallocate debit_cursor



		
		Insert into ##nbnetdeb(
			net_ctrl_num, 			apply_trx,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			a.date_applied,
			customer_code)
		Select 
			@net_ctrl_num,			0,
			a.trx_ctrl_num,			a.doc_ctrl_num,			4111,
			b.trx_type_desc,		a.amt_on_acct,			0,
			0,				a.nat_cur_code,			a.date_applied,
			""
		From 
			#onacct		a,
			aptrxtyp	b
		Where 
				payment_code not in ("VDSPCHK" , "DBMEMO" )
			AND	b.trx_type 	= 4111 
		Order By	
			date_applied	asc
		Select @return = @@ERROR
		IF @return <> 0
			return @return


	return @return

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbnettran_apdeb_sp] TO [public]
GO
