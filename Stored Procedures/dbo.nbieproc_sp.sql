SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[nbieproc_sp]
			@process_ctrl_num 	varchar(16),	@status			smallint, 	@module_id		int,
			@user_id		smallint,	@net_ctrl_num_from 	varchar(16), 	@net_ctrl_num_to	varchar(16),
			@vendor_code_from 	varchar(16), 	@vendor_code_to 	varchar(16), 	@customer_code_from 	varchar(16),
			@customer_code_to 	varchar(16)
AS
	Declare 
		@return			int,
		@MIN_ASCII 		int,	
		@MAX_ASCII 		int,		
		@MAX_DASCII		int,
		@batch_usr_flag		smallint,
		@posted_flag		smallint,
		@date_posted		int,
		@today			smalldatetime,
		@year			int, 
		@month			int, 
		@day			int,
		@net_ctrl_num		varchar(16)

BEGIN


Select @return = 0


if ( @status = 0 )
Begin

Select  @MIN_ASCII = 32,
	@MAX_ASCII = 255,
	@MAX_DASCII = 1200





















IF ( upper( @net_ctrl_num_from ) = "<FIRST>" )
	Select @net_ctrl_num_from = MIN(net_ctrl_num)
	From nbnethdr
IF ( upper( @net_ctrl_num_to ) = "<LAST>" )
	Select @net_ctrl_num_to = MAX(net_ctrl_num)
	From nbnethdr
IF ( upper( @vendor_code_from ) = "<FIRST>" )
	Select @vendor_code_from = MIN(vendor_code)
	From nbnethdr
IF ( upper( @vendor_code_to ) = "<LAST>" )
	Select @vendor_code_to = MAX(vendor_code)
	From nbnethdr
IF ( upper( @customer_code_from ) = "<FIRST>" )
	Select @customer_code_from = MIN(customer_code)
	From nbnethdr
IF ( upper( @customer_code_to ) = "<LAST>" )
	Select @customer_code_to = MAX(customer_code)
	From nbnethdr


	Select
		@posted_flag = 	min(posted_flag) - 1
	From 
		nbnethdr


	Update 	nbnethdr
	Set	posted_flag = @posted_flag
	From	nbnethdr
	Where
			net_ctrl_num 	BETWEEN @net_ctrl_num_from 	And @net_ctrl_num_to
		And	vendor_code	BETWEEN @vendor_code_from 	And @vendor_code_to
		And	customer_code	BETWEEN @customer_code_from 	And @customer_code_to
		And	posted_flag	= 0
		And	user_id		= @user_id
		And	module_id	= @module_id

	Select @return = @@ERROR

	If @return <> 0
		return @return

	
	If not exists ( Select 	1 
			From 	nbnethdr 
			Where 	posted_flag = @posted_flag )
		return -1


	
	Insert into #nbnethdr_work(
		net_ctrl_num,		vendor_code,		customer_code,		currency_code,
		payment_flag,		amt_payment,		module_id,		date_entered,	
		user_id,		posted_flag,		process_ctrl_num)
	Select 
		net_ctrl_num,		vendor_code,		customer_code,		currency_code,
		payment_flag,		amt_payment,		module_id,		date_entered,	
		user_id,		posted_flag,		@process_ctrl_num
	From
		nbnethdr
	Where
			posted_flag	= @posted_flag
	Order by
		net_ctrl_num
	Select @return = @@ERROR
	If @return <> 0
		return @return


	Insert into #nbnetdeb_work (
		net_ctrl_num,		sequence_id,		trx_ctrl_num,		doc_ctrl_num,
		trx_type,		amt_net,        	amt_payment,        	amt_committed,
		date_applied,		apply_trx )
	Select
		b.net_ctrl_num,		b.sequence_id,		b.trx_ctrl_num,		b.doc_ctrl_num,
	        b.trx_type,		b.amt_net,	        b.amt_payment,	        b.amt_committed,
		b.date_applied,		1
	From
		#nbnethdr_work	a,
		nbnetdeb	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	a.process_ctrl_num	= @process_ctrl_num
	Order by
		b.net_ctrl_num	asc,
		b.sequence_id	asc	
	Select @return = @@ERROR
	If @return <> 0
		return @return

	update	 #nbnetdeb_work
	set amt_committed = amt_net
	Where amt_committed = 0


	Insert into #nbnetcre_work (
		net_ctrl_num,		sequence_id,		trx_ctrl_num,		doc_ctrl_num,
		trx_type,		amt_net,        	amt_payment,        	amt_committed,
		date_applied,		apply_trx )
	Select
		b.net_ctrl_num,		b.sequence_id,		b.trx_ctrl_num,		b.doc_ctrl_num,
	        b.trx_type,		b.amt_net,	        b.amt_payment,	        b.amt_committed,
		b.date_applied,		1
	From
		#nbnethdr_work	a,
		nbnetcre	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	a.process_ctrl_num	= @process_ctrl_num
	Order by
		b.net_ctrl_num	asc,
		b.sequence_id	asc	
	Select @return = @@ERROR
	If @return <> 0
		return @return



	DECLARE nb_cursor CURSOR FOR SELECT net_ctrl_num FROM #nbnethdr_work
	OPEN nb_cursor

	FETCH NEXT FROM nb_cursor INTO @net_ctrl_num

	WHILE @@FETCH_STATUS = 0
	BEGIN
		exec nbntdist_sp @net_ctrl_num

		FETCH NEXT FROM nb_cursor INTO @net_ctrl_num
	END

	Update nbnetcre			
		Set	amt_payment	= 0,
			amt_committed	= a.amt_committed
	FROM #nbnetcre_work a
	where 	nbnetcre.sequence_id	= a.sequence_id
	and 	nbnetcre.net_ctrl_num = a.net_ctrl_num			

	Update nbnetdeb			
		Set	amt_payment	= 0,
			amt_committed	= a.amt_committed
	FROM #nbnetdeb_work a
	where 	nbnetdeb.sequence_id	= a.sequence_id
	and 	nbnetdeb.net_ctrl_num = a.net_ctrl_num			

	delete #nbnetcre_work
	where apply_trx = 0 

	delete #nbnetdeb_work
	where apply_trx = 0 
	
	CLOSE nb_cursor
	DEALLOCATE nb_cursor

End
Else
Begin

	Select @today = getdate()

	Select	@year 	= DATEPART(yy, @today), 
		@month	= DATEPART(mm, @today), 
		@day	= DATEPART(dd, @today)

	exec appjuldt_sp @year, @month, @day, @date_posted OUTPUT

	
	Insert into nbtrx(
		net_ctrl_num,		vendor_code,		customer_code,		currency_code,
	    	payment_flag,    	amt_payment,		module_id,		date_entered,
		date_posted,		user_id,		process_ctrl_num,	posted_flag )
	Select
		net_ctrl_num,		vendor_code,		customer_code,		currency_code,
		payment_flag,		amt_payment,		module_id,		date_entered,
		@date_posted,		user_id,		process_ctrl_num,	1
	From
		#nbnethdr_work
	Where
		process_ctrl_num	=	@process_ctrl_num
	Select @return = @@ERROR
	If @return <> 0
		return @return

	
	Insert into nbtrxdeb(
		net_ctrl_num,		sequence_id,		trx_ctrl_num,		doc_ctrl_num,
		trx_type,		amt_net,		amt_payment,		amt_committed,
		date_applied,		date_posted )
	Select
		b.net_ctrl_num,		b.sequence_id,		b.trx_ctrl_num,		b.doc_ctrl_num,
	        b.trx_type,		b.amt_net,	        b.amt_payment,	        b.amt_committed,
		b.date_applied,		@date_posted
	From
		#nbnethdr_work	a,
		nbnetdeb	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	a.process_ctrl_num	= @process_ctrl_num
	Order by
		b.net_ctrl_num	asc,
		b.sequence_id	asc	
	Select @return = @@ERROR
	If @return <> 0
		return @return

	
	Insert into nbtrxcre(
		net_ctrl_num,		sequence_id,		trx_ctrl_num,		doc_ctrl_num,
		trx_type,		amt_net,		amt_payment,		amt_committed,
		date_applied,		date_posted )
	Select
		b.net_ctrl_num,		b.sequence_id,		b.trx_ctrl_num,		b.doc_ctrl_num,
	        b.trx_type,		b.amt_net,	        b.amt_payment,	        b.amt_committed,
		b.date_applied,		@date_posted
	From
		#nbnethdr_work	a,
		nbnetcre 	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	a.process_ctrl_num	= @process_ctrl_num
	Order by
		b.net_ctrl_num	asc,
		b.sequence_id	asc	
	Select @return = @@ERROR
	If @return <> 0
		return @return


	
	Insert into nbtrxrel(	process_ctrl_num,	net_ctrl_num,		trx_ctrl_num,		trx_type )
	Select 			@process_ctrl_num,	net_ctrl_num,		trx_ctrl_num,		trx_type
	From	#nbtrxrel

	
	Insert into nbprcrel(	process_ctrl_parent,	process_ctrl_child )
	Select 			process_ctrl_parent,	process_ctrl_child
	From #nbprcrel


	
	Delete 
		nbnethdr
	From
		nbnethdr	a,
		#nbnethdr_work	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	b.process_ctrl_num	= @process_ctrl_num
	Select @return = @@ERROR
	If @return <> 0
		return @return

	
	Delete 
		nbnetdeb
	From
		nbnetdeb	a,
		#nbnethdr_work	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	b.process_ctrl_num	= @process_ctrl_num
	Select @return = @@ERROR
	If @return <> 0
		return @return

	
	Delete 
		nbnetcre
	From
		nbnetcre	a,
		#nbnethdr_work	b
	Where
			a.net_ctrl_num		= b.net_ctrl_num
		And	b.process_ctrl_num	= @process_ctrl_num
	Select @return = @@ERROR
	If @return <> 0
		return @return


End

End

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'1',0,''

return @return

GO
GRANT EXECUTE ON  [dbo].[nbieproc_sp] TO [public]
GO
