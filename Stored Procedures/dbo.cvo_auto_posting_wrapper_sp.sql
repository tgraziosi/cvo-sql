SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 20/05/2014 - Tine added
-- v1.2 CB 20/06/2014 - Add validation for bins on credit returns
-- v1.3 CB 09/07/2014 - Add validtion for lots on credit returns
-- v1.4 CB 23/07/2014 - Add validation for NNB and inactive customer records
-- v1.5 CB 14/08/2014 - Check and correct curr_price / oper_price
-- v1.6 CB 17/04/2015 - Add #temp_who table for dealing WMS errors 
-- v1.7 CB 17/04/2015 - Add validation for lot_bin_ship error
-- tag - 042115 - add info for # errors for ending email
-- v1.8 CB 29/04/2015 - Fix for v1.7 - Could be multiple bins in lot bin ship
-- v1.9 TG 11/11/2015 - add check for null value for discount in cvo_ord_list
-- v2.0 TG 12/20/2016 - add check on lb_tracking and kit_flag for DCF
/* 
BEGIN TRAN
select status, * from orders_all where order_no = 1420450
EXEC cvo_auto_posting_wrapper_sp
select * from cvo_auto_posting_errors order by error_date desc
select status, * from orders_all where order_no = 1420450
ROLLBACK TRAN
*/
CREATE PROC [dbo].[cvo_auto_posting_wrapper_sp]
AS
BEGIN
	-- Directives
	SET NOCOUNT ON

	-- Declarations
	DECLARE	@row_id			int,
			@last_row_id	int,
			@order_no		int,
			@order_ext		int,
			@error_exists	int,
			@order_count	int,
			@cr_order_count	int,
			@start_time		datetime, -- tag
			@type			char(1), -- v1.2
			@cust_code		varchar(10), -- v1.4
			@ship_to		varchar(10), -- v1.4
			@ord_shipped	decimal(20,8), -- v1.8
			@ship_shipped	decimal(20,8) -- v1.8	

	select @start_time = getdate()

	BEGIN TRY

		-- v1.6 Start
		IF (object_id('tempdb..#temp_who') IS NULL) 
		BEGIN
			CREATE TABLE #temp_who (
				who        varchar(50), 
				login_id   varchar(50))
		END
		-- v1.6 End

		-- Create working table for process orders/credits
		CREATE TABLE #cvo_posting (
			row_id		int IDENTITY(1,1),
			order_no	int,
			order_ext	int,
			type		char(1),
			cust_code	varchar(10), -- v1.4
			ship_to		varchar(10)) -- v1.4
			

		INSERT	#cvo_posting (order_no, order_ext, type, cust_code, ship_to) -- v1.2 -- v1.4
		SELECT	order_no,    
				ext,
				type, -- v1.2
				cust_code, -- v1.4
				ship_to -- v1.4
		FROM	orders_all (NOLOCK)
		WHERE	status in ('R','S','W')
		-- AND		order_no = 1420450  
		ORDER BY order_no, ext

		IF (@@ROWCOUNT = 0)
		BEGIN
			DROP TABLE  #cvo_posting
			RETURN
		END	

		SELECT	@order_count = (SELECT  count(a.order_no)  
		FROM	orders_all a (NOLOCK)
		JOIN	#cvo_posting b
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	a.status = 'R'  
		AND		a.type = 'I' 
		AND		load_no = 0   
		AND		process_ctrl_num = '')  

		SELECT	@cr_order_count = (SELECT  count(a.order_no)  
		FROM	orders_all a (NOLOCK) 
		JOIN	#cvo_posting b
		ON		a.order_no = b.order_no
		AND		a.ext = b.order_ext
		WHERE	a.status = 'R'  
		AND		a.type = 'C' 
		AND		load_no = 0   
		AND		process_ctrl_num = '')  
		
		-- Post
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext,
				@type = type, -- v1.2
				@cust_code = cust_code, -- v1.4
				@ship_to = ship_to -- v1.4
		FROM	#cvo_posting
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			-- Validations to be added as required
			SET @error_exists = 0

			IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK)
						ON a.part_no = b.part_no WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND a.lb_tracking <> b.lb_tracking AND a.part_type = 'P')  -- v1.1
			BEGIN
				SET @error_exists = 1
				INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
				SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Lot Bin Tracking Flag MisMatch'
			END

			-- v1.2 Start
			IF (@type = 'C')
			BEGIN
				IF EXISTS (	SELECT	1 FROM ord_list a (NOLOCK) 
							JOIN	lot_bin_ship b (NOLOCK)
							ON		a.order_no = b.tran_no
							AND		a.order_ext = b.tran_ext
							AND		a.line_no = b.line_no
							LEFT JOIN tdc_bin_master c (NOLOCK)
							ON		b.location = c.location
							AND		b.bin_no = c.bin_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		b.tran_code = 'R'
							AND		c.bin_no IS NULL)
				BEGIN
					SET @error_exists = 1
					INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
					SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Invalid Return Bin On Credit Return'
				END

				-- v1.3 Start
				IF EXISTS (	SELECT	1 FROM ord_list a (NOLOCK) 
							JOIN	lot_bin_ship b (NOLOCK)
							ON		a.order_no = b.tran_no
							AND		a.order_ext = b.tran_ext
							AND		a.line_no = b.line_no
							WHERE	a.order_no = @order_no
							AND		a.order_ext = @order_ext
							AND		b.tran_code = 'R'
							AND		ISNULL(b.lot_ser,'') = '')
				BEGIN
					SET @error_exists = 1
					INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
					SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Invalid Lot Number On Credit Return'
				END
				-- v1.3 End

				-- v1.4 Start
				IF EXISTS (	SELECT	1 
							FROM	armaster_all (NOLOCK) 
							WHERE	customer_code = @cust_code
							AND		ship_to_code = @ship_to
							AND		status_type IN (2,3))
				BEGIN
					SET @error_exists = 1
					INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
					SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Customer is Inactive or set to No New Business'
				END
				-- v1.4 End

				-- v1.5 Start
				IF EXISTS (SELECT 1 FROM orders_all a (NOLOCK) JOIN ord_list b(NOLOCK) ON a.order_no = b.order_no AND a.ext = b.order_ext 
							WHERE a.curr_factor = 1 AND b.curr_price <> b.oper_price AND a.order_no = @order_no AND a.ext = @order_ext)
				BEGIN
					UPDATE	ord_list
					SET		curr_price = oper_price
					WHERE	order_no = @order_no
					AND		order_ext = @order_ext
					AND		curr_price <> oper_price
				END
				-- v1.5 End			
			END
			-- v1.2 End

			-- v1.7 Start
			IF (@type != 'C')
			BEGIN
				-- v1.8 Start
				SELECT	@ord_shipped = SUM(shipped)
				FROM	ord_list (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @order_ext
				-- 12/20/2016 - DCF - v2.0
				AND		part_type = 'P'
				AND		lb_tracking = 'Y' 

				SELECT	@ship_shipped = SUM(a.qty)
				FROM	lot_bin_ship a (NOLOCK)
				JOIN	inv_master b (NOLOCK)
				ON		a.part_no = b.part_no
				WHERE	a.tran_no = @order_no
				AND		a.tran_ext = @order_ext
				-- 12/20/2016 - DCF - v2.0
				AND		b.lb_tracking = 'Y' 
				AND		a.kit_flag = 'N'

				IF (@ord_shipped <> @ship_shipped) -- v1.8 End
				BEGIN
					SET @error_exists = 1
					INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
					SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Lot Bin Ship Quantity Mismatch'
				END
			END
			-- v1.7 End

			-- v1.9 Start
			IF EXISTS (	SELECT	1 FROM cvo_ord_list a (NOLOCK) 
						WHERE	a.order_no = @order_no
						AND		a.order_ext = @order_ext
						AND		a.amt_disc IS NULL )
			BEGIN
				SET @error_exists = 1
				INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
				SELECT	GETDATE(), NULL, @order_no, @order_ext, 'Amt Disc in cvo_ord_list is null'
			END
			-- v1.9 End

			
			IF (@error_exists = 0)
			BEGIN
				EXEC dbo.cvo_auto_posting_routine_new_sp @order_no, @order_ext
			END

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no,
					@order_ext = order_ext,
					@type = type, -- v1.2
					@cust_code = cust_code, -- v1.4
					@ship_to = ship_to -- v1.4
			FROM	#cvo_posting
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

		END


	END TRY
	BEGIN CATCH

		INSERT	dbo.cvo_auto_posting_errors (error_date, batch_no, order_no, order_ext, error_desc)
		SELECT	GETDATE(), NULL, @order_no, @order_ext, ERROR_MESSAGE()
	
	END CATCH

	-- Code for Tine
	DECLARE @body varchar (500)  , @subject varchar (100)
	DECLARE @orders_recovery int  
	DECLARE @shipped_count int  
	DECLARE @cr_orders_recovery int  
	DECLARE @cr_shipped_count int  
	declare @err_cnt int

	SELECT	@orders_recovery = (SELECT  count(order_no)  
    FROM	orders_all  
    WHERE	status = 'R'  
    AND		type = 'I' and load_no = 0   
    AND		process_ctrl_num <> '')  
  
	SELECT	@cr_orders_recovery = (SELECT  count(order_no)  
    FROM	orders_all  
    WHERE	status = 'R'  
    AND		type = 'C' and load_no = 0   
    AND		process_ctrl_num <> '')  
  
	SELECT @shipped_count = (SELECT count(order_no) FROM orders_all WHERE status = 'S' AND type = 'I')  
	SELECT @cr_shipped_count = (SELECT count(order_no) FROM orders_all WHERE status = 'S' AND type = 'C')  
  
	select @err_cnt = (select count(order_no) from cvo_auto_posting_errors where error_date >= @start_time)

	-- assemble body  
  
	select @body = 'Prior to posting orders to be posted = '  + cast (@order_count as varchar (12)) + char(13) +  
	'Prior to posting credit returns to be posted = '  + cast (@cr_order_count as varchar (12)) + char(13) +  
	'After Posting total orders in Shipped status (S) = ' + cast (@shipped_count as varchar (12)) + char(13) +  
	'After Posting total credit returns in Shipped status (S) = ' + cast (@cr_shipped_count as varchar (12)) + char(13) +  
	'After Posting total orders in recovery = ' + cast (@orders_recovery as varchar (12)) + char(13) +  
	'After Posting total credit returns in recovery = ' + cast (@cr_orders_recovery as varchar (12))  
	+ char(13) + 'After Posting total Errors recorded = ' + cast (@err_cnt as varchar(12))  
	+ char(13) + 'Starting Time: ' + cast (@start_time as varchar(20)) 
	+ char(13) + 'Ending Time: ' + cast (getdate() as varchar(20))

	select @subject = @@servername + ' - The Shipment Posting Job Has Completed'

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'WMS_1'  
   , @recipients = 'tgraziosi@cvoptical.com'  
--   , @copy_recipients = 'JBERMAN@CVOPTICAL.COM'
--   , @recipients = 'dmoon@epicor.com'  
----   , @blind_copy_recipients = 'customer_service@XXXXX'  
   , @subject = @subject
   , @body = @body  

END

GO
