SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[nbnettran_sp]
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

BEGIN TRANSACTION

	Create Table #arvpay (customer_code	varchar(8) )
	Create Table #onacct (
		trx_ctrl_num 	varchar(16), 	doc_ctrl_num 	varchar(16), 	date_doc 	int, 
		date_applied 	int, 		payment_code 	varchar(8), 	cash_acct_code 	varchar(32), 
		amt_on_acct 	float, 		nat_cur_code 	varchar(8), 	rate_home 	float, 
		rate_oper 	float, 		rate_type_home 	varchar(8), 	rate_type_oper 	varchar(8))
	Create Table #avail_onacct ( 
		customer_code 	varchar(8), 	doc_ctrl_num 	varchar(16), 	trx_type_desc 	varchar(30),
		amt_on_acct 	float,		in_use 		smallint )


	
	Truncate Table #nbnetdeb
	Truncate Table #nbnetcre

	Select @return = 0











































	Insert into #arvpay(customer_code) Values( @customer_code )

	If NOT EXISTS(	Select 	1 
			From 	nbnethdr a, #arvpay b
			Where 		a.vendor_code 	= @vendor_code 
				And  	a.customer_code	= b.customer_code
				And	a.currency_code	= @currency_code )
	Begin

		


		
		
		exec @return = nbnettran_inv_sp @net_ctrl_num, @vendor_code, @customer_code, @currency_code
		IF @return <> 0
			goto rollback_tran

		
		exec @return = nbnettran_apdeb_sp @net_ctrl_num, @vendor_code, @customer_code, @currency_code
		IF @return <> 0
			goto rollback_tran


		



		
		exec @return = nbnettran_vou_sp @net_ctrl_num, @vendor_code, @customer_code, @currency_code
		IF @return <> 0
			goto rollback_tran


		

		exec @return = nbnettran_arcre_sp @net_ctrl_num, @vendor_code, @customer_code, @currency_code 
		IF @return <> 0
			goto rollback_tran


		



		
		Insert into #nbnetdeb(
			net_ctrl_num, 			apply_trx,			sequence_id,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			date_applied)
		Select 
			net_ctrl_num, 			apply_trx,			sequence_id,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_net,			nat_cur_code,			date_applied
		From
			##nbnetdeb
		Where 
			amt_net		> 0
		Order by
			sequence_id
		Select @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		
		Insert into #nbnetcre(
			net_ctrl_num, 			apply_trx,			sequence_id,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			date_applied)
		Select 
			net_ctrl_num, 			apply_trx,			sequence_id,
			trx_ctrl_num,			doc_ctrl_num,       		trx_type,
			trx_type_desc,			amt_net,	        	amt_payment,
	        	amt_committed,			nat_cur_code,			date_applied
		From
			##nbnetcre
		Where 
			amt_net		> 0

		Order by
			sequence_id
		Select @return = @@ERROR
		IF @return <> 0
			goto rollback_tran


		
		If Not Exists( Select * From #nbnetcre )
		Begin
			If Not Exists( Select * From #nbnetdeb )
			Begin
				Select @return = -2 --NB_ZERO_TRANS
				goto rollback_tran
			End
		End

		

		If Exists(	Select 1 
				From 	arinppdt	a,
					arinppyt	b,
					#arvpay		c
				Where
						a.trx_ctrl_num 	=	b.trx_ctrl_num	
					And	b.customer_code	=	c.customer_code
					And	b.nat_cur_code	=  	@currency_code )
			Select @return = -3
		Else
		Begin
			If Exists(	Select 1 
					From 	apinppdt	a,
						apinppyt	b
					Where
							a.trx_ctrl_num 	=	b.trx_ctrl_num	
						And	b.vendor_code	=	@vendor_code
						And	b.nat_cur_code	=  	@currency_code )
				Select @return = -3
			Else
			Begin

				If Exists(	Select 1 
						From 	arinpchg	a,
							#arvpay		b
						Where
								a.apply_to_num 	<>	""
							And	a.customer_code	=	b.customer_code
							And	a.nat_cur_code	=  	@currency_code )
					Select @return = -3
				Else
				Begin
		
					If Exists(	Select 1 
							From 	apinpchg	
							Where
									apply_to_num 	<>	""
								And	 vendor_code	=	@vendor_code
								And	nat_cur_code	=  	@currency_code )
						Select @return = -3
				End


			End

		End


		Drop Table #onacct
		Drop Table ##nbnetdeb
		Drop Table ##nbnetcre
		Drop table #arvpay
		Commit Tran
		RETURN @return

	End
	Else
	Begin
		Select @return = -1
	End

	rollback_tran:
		ROLLBACK TRANSACTION
		RETURN	@return

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbnettran_sp] TO [public]
GO
