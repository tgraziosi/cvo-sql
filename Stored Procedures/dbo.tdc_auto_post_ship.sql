SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_auto_post_ship] 
	@tran int, 
	@ext int, 
	@batch varchar(16),
	@post2gl varchar(1),
	@post2ar varchar(1),
	@who varchar(50),
	@err int output AS
BEGIN
/* Explanation of parameters

	@tran		- the order number
	@ext		- the ext of the order
	@batch		- the batch or process control number (optional). If you are not going to pass one in,
			  then you pass in null and it creates it for you
	@post2GL	- if you want to post to GL or not - usually yes. Values are 'Y' or 'N'.
	@post2AR	- if you want to post to AR or not - usually yes. Values are 'Y' or 'N'.
	@who		- who is calling this (optional). If you don't send anything in, it will stamp it 'Auto ship post.'
	@err (out)	- outputs the error nunber
*/

/* ---- Create temp tables here -- these are the tables created during user login ---------------------------------*/
/* ---- In SQL Server 7.0+, cannot be in a separate stored procedure		  ---------------------------------*/
	
	DECLARE @obj varchar(40), @language varchar(10), @login_id	varchar(50)
	
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')
	-- SCR #35149: get login id without domain
	SELECT @who = login_id FROM #temp_who

	IF OBJECT_ID('tempdb..##employee') IS NULL
	BEGIN	
		CREATE TABLE ##employee( emp_id	integer CONSTRAINT p1_constraint PRIMARY KEY NONCLUSTERED,
			fname CHAR(20) NOT NULL,
			minitial CHAR(1) NULL,
			lname VARCHAR(30) NOT NULL,
			job_id SMALLINT NOT NULL DEFAULT 1
		)
	END
/*------------------------------------------- end creation of temp tables -----------------------------------------*/


/* Declare Variables */
DECLARE @msg		varchar(200),	
	@trx_type 	varchar(1),
	@gl_method	smallint

/*
	Order must be a minimum status of 'R'
	if @post2gl = 'Y' then will attempt to post to GL
	if @post2AR = 'Y' then will attempt to post to AR
*/

/* Initial Validation */

IF NOT EXISTS (SELECT * FROM orders WHERE order_no = @tran AND ext = @ext AND status = 'R')
BEGIN
	-- Order: %d-%d must be at status of R!
--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -101 AND language = @language
--	RAISERROR (@msg, 16, 1, @tran, @ext)
	RETURN -101
END

SELECT @who = ISNULL(@who,'AUTO SHIP POST')
SELECT @post2gl = ISNULL(@post2gl,'N')
SELECT @post2ar = ISNULL(@post2ar,'N')


/* Create Temp Tables */
CREATE TABLE #t_batch (
		result int,
		process_ctrl_num varchar(16)
)

--BEGIN TRAN

/* Get Next AR Batch */
IF ISNULL(@batch,'') = '' AND @post2ar = 'Y'
BEGIN
	INSERT INTO #t_batch (result, process_ctrl_num)
	EXECUTE fs_next_batch 'ADM AR Transactions', @who, 18000

	SELECT @batch = Case WHEN result = 0 THEN process_ctrl_num ELSE '' END
	FROM #t_batch
END

IF ((ISNULL(@batch,'') != '') AND @post2ar = 'Y')
BEGIN
	UPDATE orders 
		SET process_ctrl_num = @batch, status = 'S', printed = 'S'
			WHERE order_no = @tran AND ext = @ext
END
ELSE
IF (@post2ar = 'Y')
BEGIN 
	-- Unable to retrieve next AR batch number!
--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -102 AND language = @language
--	RAISERROR (@msg, 16, 1)
	--ROLLBACK TRAN
	RETURN -102
END

/* Post to AR */
IF ISNULL(@batch,'') != '' and @post2ar = 'Y'
BEGIN
	--SCR 38422
	EXEC fs_post_ar_wrap @who, @batch -- @err OUT

	IF @@error != 0 AND @@error != 100	
	BEGIN
		UPDATE orders SET process_ctrl_num = '' WHERE order_no = @tran and ext = @ext

		/* Close AR Batch */
		EXEC fs_close_batch @batch

		-- Processing Of AR Transaction Failed.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -103 AND language = @language
	--	RAISERROR (@msg, 16, 1)
		--ROLLBACK TRAN
		RETURN -103
	END

	IF ISNULL( @err, 0 )= 0 OR @err <> 1 
	BEGIN
		UPDATE orders SET process_ctrl_num = '' WHERE order_no = @tran AND ext = @ext
	
		/* Close AR Batch */
		EXEC fs_close_batch @batch

		-- Error with Post AR Procedure : %d.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -104 AND language = @language
	--	RAISERROR (@msg, 16, 1, @err)
		--ROLLBACK TRAN 
		RETURN -104
	END

	/* Close AR Batch */
	EXEC fs_close_batch @batch

END


/* Post GL Here */
IF @post2gl = 'Y' AND exists(SELECT * FROM config WHERE flag = 'PSQL_GLPOST_MTH' AND value_str != 'I')
BEGIN
	SELECT @gl_method = indirect_flag FROM glco
	SELECT @trx_type = 'S' -- 'S'  for Shipping, 'R' for Receipts & Matching, 'P' for productions.

	EXEC adm_process_gl @who, @gl_method, @trx_type, @tran, @ext, @err out

	IF @@error <> 0 AND @@error <> 100
	BEGIN
		-- Process GL Transaction - Error with Post GL Procedure for Order No: %d-%d.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -105 AND language = @language
	--	RAISERROR (@msg, 16, 1, @tran, @ext)
		--ROLLBACK TRAN
		RETURN -105
	END

	IF ISNULL( @err,0 )=0 OR @err != 1 
	BEGIN
		-- Process GL Transaction - Error with Post GL Procedure: %d occurred for Order No: %d-%d.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -106 AND language = @language
	--	RAISERROR (@msg, 16, 1, @err, @tran, @ext)
		--ROLLBACK TRAN
		RETURN -106
	END

	EXEC adm_glpost_oejobs @batch, @who, @err out

	IF @@error <> 0 OR @@error <> 100
	BEGIN
		-- Process GL Transaction - Error with Job Posting  Procedure for Order No: %d-%d.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -107 AND language = @language
	--	RAISERROR (@msg, 16, 1, @tran, @ext)
		--ROLLBACK TRAN
		RETURN -107
	END

	IF ISNULL( @err,0 ) = 0 OR @err != 1 
	BEGIN
		-- Process GL Transaction - Error with Job Posting Procedure: %d occurred for Order No: %d-%d.
	--	SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_auto_post_ship' AND err_no = -108 AND language = @language
	--	RAISERROR (@msg, 16, 1, @err, @tran, @ext)
		--ROLLBACK TRAN
		RETURN -108
	END
END

--COMMIT TRAN
RETURN 1

END
GO
GRANT EXECUTE ON  [dbo].[tdc_auto_post_ship] TO [public]
GO
