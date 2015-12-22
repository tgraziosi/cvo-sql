SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 11/10/2012 - Gets price for a part on a credit return based on customer settings
-- v1.1 CT 08/11/2012 - Remove hardcoded values in f_create_tdc_log_data_string call
-- v1.2	CT 05/12/2012 - Corrected bug when getting saleable bin's group code
-- v1.3 CT 08/03/2013 - Load ord_list records into temp table to improve performance
-- v1.4 CT 27/06/2013 - Issue #1327 - Process N lines
-- v1.5 CB 15/08/2014 - Performance
-- v1.6 CB 08/09/2014 - If credit has inv return lines after non inv return lines the lot_ser does not get reset
-- v1.7 CB 28/07/2015 - Move writing log to when the stock is actually received

-- EXEC CVO_auto_receive_credit_return_sp 1420466, 0

CREATE PROC [dbo].[CVO_auto_receive_credit_return_sp] (@order_no	INT,
												   @ext			INT)
AS
BEGIN
	DECLARE @line_no		INT,
			@part_no		VARCHAR(30),
			@qty			DECIMAL(20,8),
			@location		VARCHAR(10),
			@return_code	VARCHAR(32),
			@bin_no			VARCHAR(12),
			@saleable		SMALLINT,
			@saleable_bin	VARCHAR(12),
			@lot_ser		VARCHAR(25),
			@group_code		VARCHAR(10),
			@saleable_gc	VARCHAR(10),
			@uom			CHAR(2),
			@primary_bin	VARCHAR(12),
			@data			VARCHAR(7500),
			@part_type		CHAR(1),
			@default_lot_ser varchar(25), -- v1.6
			@iret			int -- v1.7


	-- Get bin from config for saleable condition
	SELECT @saleable_bin = LEFT(value_str,12) FROM dbo.config (NOLOCK) WHERE flag = 'AUTOREC_CREDIT_BIN'

	-- START v1.2 - code moved down in proc
	/*
	-- Get bin info
	SELECT 
		@saleable_gc = group_code
	FROM 
		dbo.tdc_bin_master (NOLOCK) 
	WHERE 
		bin_no = @bin_no
		AND location = @location
	*/
	-- END v1. 2

	-- Get auto lot from tdc_config
	SELECT @lot_ser = LEFT(value_str,25) FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'AUTO_LOT'
	SET @default_lot_ser = @lot_ser -- v1.6

	-- Create temporary tables
	CREATE TABLE #adm_credit_order (
		order_no int NOT NULL,
		ext int NOT NULL,
		part_no varchar(30) NOT NULL,
		line_no int NOT NULL,
		location varchar(10) NOT NULL,
		ordered decimal(20,8) NOT NULL,
		bin_no varchar(12) NULL,
		lot_ser varchar(25) NULL,
		date_expires datetime NULL,
		who_entered varchar(50) NULL,
		err_msg varchar(255) NULL,
		row_id int identity NOT NULL)

	CREATE TABLE #temp_tbl_for_kit (
		part_no varchar(30) NOT NULL, 
		line_no int NOT NULL, 
		location varchar(10) NOT NULL, 
		lot_ser varchar(25) NULL, 
		bin_no varchar(12) NULL, 
		date_expires datetime NULL, 
		qty_per decimal(20,8) NULL, 
		qty decimal(20,8) NOT NULL)

	CREATE TABLE #temp_who (
		who		VARCHAR(50),
		login_id	VARCHAR(50))
	
	INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')

	-- START v1.3
	CREATE TABLE #ord_list(
		line_no INT NOT NULL,
		part_no VARCHAR(30) NOT NULL,
		qty DECIMAL(20,8) NOT NULL,
		location VARCHAR(10) NOT NULL,
		return_code VARCHAR(10) NOT NULL,
		part_type CHAR(1) NOT NULL)

	INSERT INTO #ord_list(
		line_no,
		part_no,
		qty,
		location,
		return_code,
		part_type)
	SELECT 
		line_no,
		part_no,
		cr_ordered - cr_shipped,
		location,
		return_code,
		part_type
	FROM
		dbo.ord_list (NOLOCK)
	WHERE
		order_no = @order_no
		AND order_ext = @ext
		-- START v1.4
		AND part_type IN ('P','M', 'N')
		--AND part_type IN ('P','M')
		-- END v1.4
		AND cr_ordered > 0
		AND cr_shipped < cr_ordered
	ORDER BY 
		line_no 
	-- END v1.3

	-- Loop through order lines
	SET @line_no = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@line_no = line_no,
			@part_no = part_no,
			@qty = qty, -- cr_ordered - cr_shipped, -- v1.3
			@location = location,
			@return_code = return_code,
			@part_type = part_type
		FROM
		-- START v1.3
			#ord_list 
			--dbo.ord_list (NOLOCK)
		WHERE
			line_no > @line_no
			/*
			order_no = @order_no
			AND order_ext = @ext
			AND line_no > @line_no
			AND part_type IN ('P','M')
			AND cr_ordered > 0
			AND cr_shipped < cr_ordered
			*/
		-- END v1.3
		ORDER BY 
			line_no 

		IF @@ROWCOUNT = 0
			BREAK

		-- START v1.4
		IF @part_type IN ('P','M')
		BEGIN
			SET @lot_ser = @default_lot_ser -- v1.6

			-- Get return code details
			SELECT
				@bin_no = ISNULL(return_bin,''),
				@saleable = ISNULL(saleable_condition,0)
			FROM
				dbo.po_retcode (NOLOCK)
			WHERE
				return_code = @return_code

			-- Get bin details
			IF @saleable = 0
			BEGIN
				SELECT 
					@group_code = group_code
				FROM 
					dbo.tdc_bin_master (NOLOCK) 
				WHERE 
					bin_no = @bin_no
					AND location = @location
			END
			-- START v1.2
			ELSE
			BEGIN
				-- Get bin info
				SELECT 
					@saleable_gc = group_code
				FROM 
					dbo.tdc_bin_master (NOLOCK) 
				WHERE 
					bin_no = @saleable_bin
					AND location = @location
			END
			-- END v1.2
		END
		ELSE
		BEGIN
			SET @saleable = 0
			SET @bin_no = ''
			SET @lot_ser = ''
			SET @group_code = ''
		END
		-- END v1.4

		-- Get part details
		SELECT
			@uom = uom
		FROM
			dbo.inv_master
		WHERE 
			part_no = @part_no
		

		DELETE FROM #adm_credit_order

		-- Load details into temporary table
		INSERT INTO #adm_credit_order(
			order_no, 
			ext, 
			part_no, 
			line_no, 
			location, 
			ordered, 
			bin_no, 
			lot_ser, 
			who_entered) 							
		SELECT 
			@order_no, 
			@ext, 
			@part_no, 
			@line_no, 
			@location,
			@qty,
			CASE @saleable WHEN 1 THEN @saleable_bin ELSE @bin_no END, 
			@lot_ser, 
			SUSER_SNAME()

		-- v1.7 Start
		EXEC @iret = tdc_credit_order 

		IF (@iret = 0)
		BEGIN

			EXEC tdc_queue_cred_ret_sp 

			IF @part_type <> 'M'
			BEGIN
				INSERT INTO dbo.tdc_3pl_receipts_log  WITH (ROWLOCK)(
					trans, 
					tran_no, 
					tran_ext, 
					location, 
					part_no, 
					bin_no, 
					bin_group, 
					uom, 
					qty, 
					userid, 
					expert) 															
				SELECT DISTINCT 
					'CRRETN', 
					order_no, 
					0, 
					location, 
					part_no, 
					bin_no, 
					CASE @saleable WHEN 1 THEN @saleable_gc ELSE @group_code END, 
					@uom, 
					ordered, 
					who_entered, 
					'N' 															  
				FROM 
					#adm_credit_order  															 
				WHERE 
					lot_ser IS NOT NULL 	
			
				INSERT INTO dbo.tdc_ei_bin_log  WITH (ROWLOCK) (
					module, 
					trans, 
					tran_no, 
					tran_ext, 
					location, 
					part_no, 
					to_bin, 
					userid, 
					direction, 
					quantity) 															
				SELECT 
					'ADH', 
					'CRRETN', 
					order_no,   
					0,	  
					location, 
					part_no, 
					bin_no, 
					who_entered,    
					1,         
					ordered 															  
				FROM 
					#adm_credit_order 															 
				WHERE 
					lot_ser IS NOT NULL 															   
					AND bin_no IS NOT NULL
			END
-- v1.7 Start
--			SELECT @data = dbo.f_create_tdc_log_data_string (@order_no,@ext,@line_no) -- v1.1
--
--			INSERT INTO dbo.tdc_log  WITH (ROWLOCK) (
--				tran_date,
--				UserID,
--				trans_source,
--				module,
--				trans,
--				tran_no,
--				tran_ext,
--				part_no,
--				lot_ser,
--				bin_no,
--				location,
--				quantity,
--				data) 										
--			SELECT 
--				GETDATE(), 
--				who_entered, 
--				'CO', 
--				'ADH', 
--				'CRRETN', 
--				CAST(order_no AS VARCHAR(20)),
--				CAST(ext AS VARCHAR(5)),
--				part_no, 
--				CASE @part_type WHEN 'P' THEN lot_ser ELSE '' END, 
--				CASE @part_type WHEN 'P' THEN bin_no ELSE '' END, 
--				location, 
--				CAST(CAST(ordered AS INT) AS VARCHAR(20)), 
--				@data
--			FROM 
--				#adm_credit_order 															 
-- v1.7 End

			-- If return code is for saleable item, then update putaway record to part's primary bin
			IF @saleable = 1
			BEGIN
				SELECT
					@primary_bin = bin_no 
				FROM 
					dbo.tdc_bin_part_qty (nolock)   
				WHERE 
					location = @location   
					AND part_no = @part_no   
					AND [primary] = 'Y'  

				/*
				INSERT tdc_put_queue (
					trans_source,
					trans,
					priority,
					location,
					trans_type_no,
					trans_type_ext,
					line_no,
					part_no,
					lot,
					bin_no,
					qty_to_process,
					qty_processed,
					qty_short,
					next_op,
					date_time,
					assign_group,
					[user_id],
					tx_control,
					tx_lock)
				SELECT
					'CO',
					'CRPTWY',
					5,
					location,
					CAST(order_no AS VARCHAR(16)),
					trans_type_ext,
					line_no,
					part_no,
					lot_ser,
					bin_no,
					ordered,
					0,
					0,
					next_op,
					GETDATE(),
					'PUTAWAY',
					who_entered
					'M',
					'Q'
				FROM 
					#adm_credit_order 
				*/

				IF ISNULL(@primary_bin,'') <> ''
				BEGIN
			
					UPDATE
						tdc_put_queue  WITH (ROWLOCK)
					SET
						next_op = @primary_bin
					WHERE
						trans_type_no = CAST(@order_no AS VARCHAR(16))
						AND trans_type_ext = @ext
						AND line_no = @line_no
						AND trans_source = 'CO'
						AND trans = 'CRPTWY'
				END
			END 
		END -- v1.7 End
	END

	DROP TABLE #adm_credit_order
	DROP TABLE #temp_who
	DROP TABLE #ord_list -- v1.3

END
GO
GRANT EXECUTE ON  [dbo].[CVO_auto_receive_credit_return_sp] TO [public]
GO
