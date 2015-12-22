SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[nbnettran_inv_sp]
			@net_ctrl_num	varchar(16),	@vendor_code	varchar(12),
			@customer_code	varchar(8),	@currency_code 	varchar(8)
AS
	Declare 
		@return			int,
		@trx_ctrl_num		varchar(16), 
		@doc_ctrl_num		varchar(16),
		@tmp_cust_code		varchar(8),
		@tmp_cur_code		varchar(8),
		@tmp_doc_ctrl_num	varchar(16),
		@amt_applied 		float, 
		@amt_disc_taken 	float, 
		@amt_max_wr_off		float,
		@sequence_id		int


BEGIN
		Select @return = 0

		
		Select 
			net_ctrl_num =@net_ctrl_num,	apply_trx = 0,				sequence_id = IDENTITY(int, 1, 1),
			trx_ctrl_num = a.trx_ctrl_num,	doc_ctrl_num = a.doc_ctrl_num,		trx_type = a.trx_type,
			trx_type_desc = b.trx_type_desc,amt_net = a.amt_tot_chg - a.amt_paid_to_date,	amt_payment = 0,
			amt_committed = 0,		nat_cur_code = a.nat_cur_code,		date_applied = a.date_applied,
			customer_code = customer_code
		into ##nbnetdeb
		From 
			artrx 		a,
			artrxtyp	b
		Where 
				a.customer_code in ( Select customer_code From #arvpay )
			AND 	a.trx_type 	in (2031 , 2021)
			AND	a.trx_type 	= b.trx_type
			AND 	a.nat_cur_code	= @currency_code
			AND	a.paid_flag	= 0
			AND (a.amt_tot_chg - a.amt_paid_to_date) > 0
			AND a.doc_ctrl_num = a.apply_to_num
			
		Order by
			date_applied	asc
		Select @return = @@ERROR
		IF @return <> 0
			return @return

		Declare debit_cursor CURSOR FOR 
		Select sequence_id, doc_ctrl_num, customer_code
		From ##nbnetdeb
		Order By
			sequence_id	asc
  		Open debit_cursor
		Fetch Next From debit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_cust_code
  
		While @@FETCH_STATUS = 0
		Begin

			Select 	
				@amt_applied 	= isnull( sum(inv_amt_applied) ,0), 
				@amt_disc_taken = isnull( sum(inv_amt_disc_taken) ,0), 
				@amt_max_wr_off	= isnull( sum(inv_amt_max_wr_off) ,0) 
			From    arinppdt 
			Where  
					apply_to_num 	= @tmp_doc_ctrl_num
				AND   	customer_code 	= @tmp_cust_code
				And	trx_type	in ( 2111 ) 

			Select 	
				@amt_applied 	= @amt_applied + isnull( sum( amt_net ) ,0)
			From    arinpchg 
			Where  
					apply_to_num 	= @tmp_doc_ctrl_num
				AND	trx_type	= 2032
				AND   	customer_code 	= @tmp_cust_code 

	
			Update 	##nbnetdeb
			Set	amt_net 	= amt_net - ( @amt_applied + @amt_disc_taken + @amt_max_wr_off)
			Where	sequence_id	= @sequence_id
			Select @return = @@ERROR
			IF @return <> 0
				return @return

			Fetch Next From debit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_cust_code
		End
  
		Close debit_cursor
		Deallocate debit_cursor

	return @return

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbnettran_inv_sp] TO [public]
GO
