SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_fs_auto_ship_post] @tran int, @ext int, 
				@batch varchar(16), @post2gl varchar(1), @post2ar varchar(1),
				@who varchar(50), @err int output AS


    /* TDC Soft Alloc table Clean Up    */
    --BEGIN
       -- DELETE FROM tdc_dsf_soft_alloc_tbl WHERE order_no = @tran AND order_ext = @ext
    --END

Begin

Declare @obj varchar(35)
Select @obj='##employee%'

If not exists (select * from tempdb.dbo.sysobjects where type = 'U' and [name] like @obj)
	Begin	
		CREATE TABLE ##employee( emp_id	integer
			CONSTRAINT p1_constraint PRIMARY KEY NONCLUSTERED,
			fname 		CHAR(20) NOT NULL,
			minitial	CHAR(1) NULL,
			lname		VARCHAR(30) NOT NULL,
			job_id 		SMALLINT NOT NULL DEFAULT 1)
	End

/* Declare Variables */
declare @msg		varchar(200),	
	@trx_type 	varchar(1),
	@gl_method	smallint

/*
	Order must be a minimum status of 'R'
	if @post2gl = 'Y' then will attempt to post to GL
	if @post2AR = 'Y' then will attempt to post to AR
*/

/* Initial Validation */

if not exists (select * from orders where order_no = @tran and ext = @ext and status = 'R')
		Begin
			Select @err = -10
			Select @msg = 'Order: ' + convert(varchar(10),@tran) + '-' + convert(varchar(4),@ext)
			Select @msg = @msg + ' must be at status of ''R''!'
			Raiserror 99999 @msg
			Return @err
		End

SELECT @who = login_id FROM #temp_who

Select @who = isnull(@who,'AUTO SHIP POST')
Select @post2gl = isnull(@post2gl,'N')
Select @post2ar = isnull(@post2ar,'N')


/* Create Temp Tables */
Create Table #t_batch
		(
		 result		int,
		 process_ctrl_num	varchar(16)
		)
Create Table #tdc_batch
		(
		 result		int,
		)


/* Get Next AR Batch */

if isnull(@batch,'') = '' and @post2ar != 'N'
	Begin
		Insert Into #t_batch (result,process_ctrl_num)
			execute fs_next_batch 'ADM AR Transactions', @who , 18000

		Select @batch = Case when result = 0 then process_ctrl_num else '' end
		 from #t_batch

		/* Close AR Batch
		 * 
		 * Modified by TDC. CAC, because fs_close_batch was returning a 
		 * resultset  err_code = 0.  11-11-1999.
		 */
		Insert into #tdc_batch (result)
			execute fs_close_batch @batch

		Select @err = result
		  from #tdc_batch

		If (@err <> 0)
		Begin
			Select @msg = 'Unable to close batch number!'
			Raiserror 99999 @msg
			Return -140
		End
	End

If isnull(@batch,'') != '' and @post2ar != 'N'
			Begin
				Update orders set
					process_ctrl_num = @batch,
					status = 'S'
				where 	order_no = @tran and ext = @ext
			End
		Else
			Begin 
				Select @msg = 'Unable to retrieve next AR batch number!'
				Raiserror 99999 @msg
				Return -20
			End

	
/* Post to AR */
if @post2AR = 'Y'
	begin
		exec fs_post_ar @who, @batch, @err OUT

		if @@error != 0 		
			Begin
				Select @msg = @msg + 'Processing Of AR Transaction Failed' 
				Update orders set
					process_ctrl_num = ''
				where 	order_no = @tran and ext = @ext
			End

		if IsNull( @err, 0 )= 0 or @err <> 1 
			Begin
				Select @msg = @msg +'Error with Post AR Procedure :' + convert(varchar(10),@err) 

				Update orders set
					process_ctrl_num = ''
				where 	order_no = @tran and ext = @ext
				Raiserror 99999  @msg
				Return -30
	
			End
	/* Post OE Jobs */

		Exec adm_glpost_oejobs @batch, @who, @err OUT

		if @@error != 0 		
			Begin
				Select @msg = 'Processing Of GL Transaction Failed' 
				Update orders set
					process_ctrl_num = ''
				where 	order_no = @tran and ext = @ext
				Raiserror 99999 @msg
				Return -40
			End

		if IsNull( @err, 0 ) = 0 or  @err <> 1 
			Begin
				Select @msg = 'Error with Post Jobs Procedure :' + convert(varchar(10),@err) 
				Update orders set
					process_ctrl_num = ''
				where 	order_no = @tran and ext = @ext
				Raiserror 99999 @msg
				Return -50
			End
	End
/* Post GL Here */
if @post2gl = 'Y' and exists(select * from config where flag = 'PSQL_GLPOST_MTH' and value_str != 'I')
	Begin
		Select @gl_method = indirect_flag from glco
		Select @trx_type = 'S' -- 'S'  for Shipping, 'R' for Receipts & Matching, 'P' for productions.

		Exec adm_process_gl @who, @gl_method, @trx_type, @tran, @ext, @err out

		if @@error <> 0 
			Begin
				Select @msg = 'Process GL Transaction - Error with Post GL Procedure'
				Select @msg = @msg + ' for Order No: ' + convert(varchar(10),@tran)+'-' +  convert(varchar(10),@ext)
				RAISERROR 99999 @msg
				Return -130
			End

		if IsNull( @err,0 )!= 1 
			Begin
				Select @msg = 'Process GL Transaction - Error with Post GL Procedure :' + convert(varchar(20),@err)
				Select @msg = @msg + ' occurred for Order No: ' + convert(varchar(10),@tran)+'-' +  convert(varchar(10),@ext)
				RAISERROR 99999 @msg
				Return -130
			End

		Exec adm_glpost_oejobs @batch, @who, @err out

		if @@error <> 0 
			Begin
				Select @msg = 'Process GL Transaction - Error with Post GL Procedure'
				Select @msg = @msg + ' for Order No: ' + convert(varchar(10),@tran)+'-' +  convert(varchar(10),@ext)
				RAISERROR 99999 @msg
				Return -130
			End

		if IsNull( @err,0 )!= 1 
			Begin
				select @err= -130
				Select @msg = 'Process GL Transaction - Error with Job Posting Procedure :' + convert(varchar(20),@err)
				Select @msg = @msg + ' occurred for Order No: ' + convert(varchar(10),@tran)+'-' +  convert(varchar(10),@ext)
				RAISERROR 99999 @msg
				Return @err
			End
	End

Return 0

END
GO
GRANT EXECUTE ON  [dbo].[tdc_fs_auto_ship_post] TO [public]
GO
