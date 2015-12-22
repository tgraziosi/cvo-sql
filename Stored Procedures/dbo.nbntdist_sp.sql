SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[nbntdist_sp]
			@net_ctrl_num	varchar(16)
AS
	Declare 
		@return		int,
		@payment_flag	smallint,
		@module_id	int,
		@amt_payment	float,
		@debit_amount	float,
		@credit_amount	float,
		@amt_net	float,
		@apply_amount	float,
		@total_amount	float,
		@sequence_id	int
BEGIN

	Select @return = 0

	Select @apply_amount = 0

	


	Update #nbnetdeb_work 
	Set
		amt_payment	= 0,
		amt_committed	= 0
	Where
		apply_trx	= 1
	and	net_ctrl_num = @net_ctrl_num

	Update #nbnetcre_work	
	Set
		amt_payment	= 0,
		amt_committed	= 0
	Where
		apply_trx	= 1
	and	net_ctrl_num = @net_ctrl_num

	


	Select
		@payment_flag	= payment_flag,
		@module_id	= module_id,
		@amt_payment	= amt_payment
	From
		nbnethdr
	Where
		net_ctrl_num	= @net_ctrl_num

	


	Select 
		@debit_amount = sum(amt_net)	
	From
		#nbnetdeb_work			
	Where
		apply_trx	= 1
	and	net_ctrl_num = @net_ctrl_num



	Select 
		@credit_amount = sum(amt_net)	
	From
		#nbnetcre_work		
	Where
		apply_trx	= 1
	and	net_ctrl_num = @net_ctrl_num


	


	if (@debit_amount <= @credit_amount) 
	Begin

		
		Update #nbnetdeb_work			
		Set
			amt_payment	= 0,
			amt_committed	= amt_net
		Where
			apply_trx	= 1
		and	net_ctrl_num = @net_ctrl_num

		
		Select @total_amount = @debit_amount

		Declare credit_cursor CURSOR FOR 
		Select sequence_id, amt_net
		From #nbnetcre_work			
		Where
			apply_trx	= 1
		and	net_ctrl_num = @net_ctrl_num			
		Order By
			date_applied	asc
  		Open credit_cursor
		Fetch Next From credit_cursor Into @sequence_id, @amt_net
  
		While @@FETCH_STATUS = 0
		Begin

			if ( @total_amount > 0)
			Begin
				
				if ( @total_amount >= @amt_net )
				Begin
					Select @apply_amount = @amt_net
				End
				Else
				Begin
					Select @apply_amount = @total_amount
				End

				Update #nbnetcre_work			
				Set
					amt_payment	= 0,
					amt_committed	= @apply_amount
				Where
					sequence_id	= @sequence_id
				and	net_ctrl_num = @net_ctrl_num

			End
			Select 
				@total_amount = @total_amount - @apply_amount

		
			Fetch Next From credit_cursor Into @sequence_id, @amt_net
		End
  
		Close credit_cursor
		Deallocate credit_cursor
		
		if (( @payment_flag = 1 ) and ( @module_id = 4000 ) )	
		Begin
			Update #nbnetcre_work			
			Set 
				amt_payment	= amt_net - amt_committed
			Where
				apply_trx	= 1
			and	net_ctrl_num = @net_ctrl_num
			
		End
		Else
		Begin
			Update #nbnetcre_work		
			Set 
				apply_trx	= 0
			Where
					apply_trx	= 1			
				And	amt_committed	= 0
				and	net_ctrl_num = @net_ctrl_num

		End

	End
	Else
	Begin

		
		Update #nbnetcre_work			
		Set
			amt_payment	= 0,
			amt_committed	= amt_net
		Where
			apply_trx	= 1
		and	net_ctrl_num = @net_ctrl_num

		
		Select @total_amount = @credit_amount

		Declare debit_cursor CURSOR FOR 
		Select sequence_id, amt_net
		From #nbnetdeb_work		
		Where
			apply_trx	= 1
		and	net_ctrl_num = @net_ctrl_num			
		Order By
			date_applied	asc
  		Open debit_cursor
		Fetch Next From debit_cursor Into @sequence_id, @amt_net
  
		While @@FETCH_STATUS = 0
		Begin

			if ( @total_amount > 0)
			Begin
				
				if ( @total_amount >= @amt_net )
				Begin
					Select @apply_amount = @amt_net
				End
				Else
				Begin
					Select @apply_amount = @total_amount
				End

				Update #nbnetdeb_work			
				Set
					amt_payment	= 0,
					amt_committed	= @apply_amount
				Where
					sequence_id	= @sequence_id
				and	net_ctrl_num = @net_ctrl_num

			End

			Select 
				@total_amount = @total_amount - @apply_amount

		
			Fetch Next From debit_cursor Into @sequence_id, @amt_net
		End
  
		Close debit_cursor
		Deallocate debit_cursor
		
		if (( @payment_flag = 1 ) and ( @module_id = 2000 ) ) 
		Begin

			Update #nbnetdeb_work 			
			Set 
				amt_payment	= amt_net - amt_committed
			Where
				apply_trx	= 1
			and	net_ctrl_num = @net_ctrl_num			

		End
		Else
		Begin
			Update #nbnetdeb_work 			
			Set 
				apply_trx	= 0
			Where
				apply_trx	= 1			
			And	amt_committed	= 0
			and	net_ctrl_num = @net_ctrl_num

		End


	End



END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbntdist_sp] TO [public]
GO
