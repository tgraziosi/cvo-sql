SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[nbnetsync_sp]
			@net_ctrl_num	varchar(16)
			
AS
	Declare 
		@return		int
BEGIN

	Select @return = 0



		
		Select
			net_ctrl_num	= net_ctrl_num,
			sequence_id	= IDENTITY(int, 1, 1),
			trx_ctrl_num	= trx_ctrl_num,
			doc_ctrl_num	= doc_ctrl_num,
		        trx_type	= trx_type,
			amt_net		= amt_net,
		        amt_payment	= amt_payment,
        		amt_committed	= amt_committed,
			date_applied	= date_applied
		into ##nbnetdeb
		From
			#nbnetdeb
		Where
			apply_trx	=	1
		Order by
			sequence_id
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		
		Select
			net_ctrl_num	= net_ctrl_num,
			sequence_id	= IDENTITY(int, 1, 1),
			trx_ctrl_num	= trx_ctrl_num,
			doc_ctrl_num	= doc_ctrl_num,
		        trx_type	= trx_type,
			amt_net		= amt_net,
		        amt_payment	= amt_payment,
        		amt_committed	= amt_committed,
			date_applied	= date_applied
		into ##nbnetcre
		From
			#nbnetcre
		Where
			apply_trx	=	1
		Order by
			sequence_id

		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		


		
		DELETE nbnetdeb WHERE net_ctrl_num = @net_ctrl_num
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		
		Insert into nbnetdeb(
			net_ctrl_num,			sequence_id,			trx_ctrl_num,
			doc_ctrl_num,		        trx_type,			amt_net,
		        amt_payment,        		amt_committed,			date_applied)
		Select
			net_ctrl_num,			sequence_id,			trx_ctrl_num,
			doc_ctrl_num,		        trx_type,			amt_net,
		        amt_payment,        		amt_committed,			date_applied
		From
			##nbnetdeb
		Order by
			sequence_id
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran


		
		DELETE nbnetcre WHERE net_ctrl_num = @net_ctrl_num
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		
		Insert into nbnetcre(
			net_ctrl_num,			sequence_id,			trx_ctrl_num,
			doc_ctrl_num,		        trx_type,			amt_net,
		        amt_payment,        		amt_committed,			date_applied)
		Select
			net_ctrl_num,			sequence_id,			trx_ctrl_num,
			doc_ctrl_num,		        trx_type,			amt_net,
		        amt_payment,        		amt_committed,			date_applied
		From	
			##nbnetcre
		Order by
			sequence_id
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran


		Drop Table ##nbnetcre
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran

		Drop Table ##nbnetdeb
		SELECT @return = @@ERROR
		IF @return <> 0
			goto rollback_tran


		RETURN @return


	rollback_tran:
		RETURN	1
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[nbnetsync_sp] TO [public]
GO
