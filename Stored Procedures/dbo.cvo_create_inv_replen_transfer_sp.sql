SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 12/07/2012 - Create a transfer order for TBB order processing
-- v1.1	CT 19/07/2012 - Create a note on originating order holding transfer number
-- v1.2	CT 25/07/2012 - Default carrier to SAL
-- v1.3	CT 08/11/2012 - New transfer fields autopack and autoship
-- v1.4 CT 15/11/2012 - Auto-allocate transfer

CREATE PROC [dbo].[cvo_create_inv_replen_transfer_sp] (@order_no INT, @ext INT)
AS
BEGIN
	DECLARE @xfer_no	INT,
			@CreateXfer	SMALLINT,
			@line_no	INT,
			@xfer_line_no INT,
			@location VARCHAR(10),
			@who_entered VARCHAR(20),
			@from_loc_name VARCHAR(30),
			@from_loc_addr1 VARCHAR(40),
			@from_loc_addr2 VARCHAR(40),
			@from_loc_addr3 VARCHAR(40),
			@from_loc_addr4 VARCHAR(40),
			@from_loc_addr5 VARCHAR(40),
			@to_loc_name VARCHAR(30),
			@to_loc_addr1 VARCHAR(40),
			@to_loc_addr2 VARCHAR(40),
			@to_loc_addr3 VARCHAR(40),
			@to_loc_addr4 VARCHAR(40),
			@to_loc_addr5 VARCHAR(40),
			@part_no VARCHAR(30),
			@description VARCHAR(255),
			@ordered DECIMAL(20,8),
			@cost DECIMAL(20,8),
			@uom CHAR(2),
			@lb_tracking CHAR(1),
			@cubic_feet DECIMAL(20,8),
			@weight_ea DECIMAL(20,8),
			@serial_flag SMALLINT,
			@allow_fractions SMALLINT,
			@date DATETIME


	
	-- If this is a SO, is marked to replenish inventory and doesn't have a transfer already created then continue
	IF NOT EXISTS (SELECT 1 FROM dbo.cvo_orders_all a INNER JOIN dbo.orders_all b ON a.order_no = b.order_no WHERE a.replen_inv = 1 AND a.xfer_no IS NULL AND b.type = 'I' AND a.order_no = @order_no AND a.ext = @ext)
	BEGIN
		RETURN
	END

	SET @CreateXfer = 0 -- False
	SEt @date = GETDATE()	

	CREATE TABLE #lines(
		order_no INT,
		order_ext INT,
		line_no INT,
		part_no VARCHAR(30),
		valid SMALLINT)

	INSERT INTO #lines(
		order_no,
		order_ext,
		line_no,
		part_no,
		valid)
	SELECT 
		order_no,
		order_ext,
		line_no,
		part_no,
		0
	FROM
		dbo.ord_list
	WHERE
		order_no = @order_no
		AND order_ext = @ext

	-- Mark valid lines
	UPDATE
		a
	SET
		valid = 1
	FROM
		#lines a
	INNER JOIN
		inv_master_add b (NOLOCK)
	ON 
		a.part_no = b.part_no
	WHERE
		ISNULL(b.field_28,GETDATE()) >= GETDATE()
		
	
	-- If there are no valid lines then don't create transfer
	IF EXISTS (SELECT 1 FROM #lines WHERE valid = 1)
	BEGIN
		SET @CreateXfer = 1
	END

	IF @CreateXfer = 1
	BEGIN

		-- Get next transfer no
		BEGIN TRAN
		UPDATE dbo.next_xfer_no SET last_no =last_no + 1 
		SELECT @xfer_no = last_no FROM dbo.next_xfer_no (NOLOCK)
		COMMIT TRAN

		-- Get details from order header
		SELECT
			@location = location,
			@who_entered = who_entered
		FROM
			dbo.orders_all (NOLOCK)
		WHERE 
			order_no = @order_no
			AND ext = @ext

		-- Get from location info
		SELECT 
			@from_loc_name = name,
			@from_loc_addr1 = addr1,
			@from_loc_addr2 = addr2,
			@from_loc_addr3 = addr3,
			@from_loc_addr4 = addr4,
			@from_loc_addr5 = addr5
		FROM
			dbo.locations (NOLOCK)
		WHERE
			location = '001'
	
		-- Get to location info (use salesperson address if it exists)
		IF EXISTS (SELECT 1 FROM dbo.arsalesp ( NOLOCK ) WHERE addr_sort1 = @location)
		BEGIN
			SELECT 
				@to_loc_name = salesperson_name, 
				@to_loc_addr1 = addr1, 
				@to_loc_addr2 = addr2, 
				@to_loc_addr3 = addr3, 
				@to_loc_addr4 = addr4, 
				@to_loc_addr5 = addr5 
			FROM 
				dbo.arsalesp ( NOLOCK ) 
			WHERE 
				addr_sort1 = @location 
		END
		ELSE
		BEGIN
			SELECT 
				@to_loc_name = name,
				@to_loc_addr1 = addr1,
				@to_loc_addr2 = addr2,
				@to_loc_addr3 = addr3,
				@to_loc_addr4 = addr4,
				@to_loc_addr5 = addr5
			FROM
				dbo.locations (NOLOCK)
			WHERE
				location = @location
		END
			
		-- Create transfer
		BEGIN TRAN
		
		-- Create header
		EXEC dbo.scm_pb_set_dw_transfer_sp	'I',@xfer_no,'001',@location,@date,@date,NULL,@date,NULL,@who_entered,
											'N',NULL,NULL,'SAL',NULL,NULL,0.00000000,'N',0,0,NULL,NULL,NULL,		-- v1.2
											@to_loc_name,@to_loc_addr1,@to_loc_addr2,@from_loc_name,@from_loc_addr1,@from_loc_addr2,
											NULL,0,NULL,0,NULL,NULL,
											@from_loc_addr3,@from_loc_addr4,@from_loc_addr5,@to_loc_addr3,@to_loc_addr4,@to_loc_addr5,
											NULL,NULL,NULL,NULL,'CVO','CVO',NULL,0,0,NULL,NULL,NULL,0,0  -- v1.3
										


		-- Loop through valid order lines and add them
		SET @line_no = 0
		SET @xfer_line_no = 0
		WHILE 1=1
		BEGIN

			SELECT TOP 1
				@line_no = line_no
			FROM
				#lines
			WHERE
				line_no > @line_no
				AND valid = 1
			ORDER BY
				line_no

			IF @@ROWCOUNT = 0
				BREAK

			-- Get details from order line
			SELECT 
				@part_no = part_no,
				@description = [description],
				@ordered = ordered
			FROM
				dbo.ord_list (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @ext
				AND line_no = @line_no

			-- Get part details
			SELECT 
				@uom = uom, 
				@lb_tracking = lb_tracking, 
				@allow_fractions = allow_fractions,
				@cubic_feet = cubic_feet,
				@weight_ea = weight_ea,
				@serial_flag = serial_flag
			FROM 
				dbo.inv_master (NOLOCK) 
			WHERE 
				part_no = @part_no

			-- Get part/location details
			SELECT 
				@cost = avg_cost 
			FROM 
				dbo.inventory (NOLOCK) 
			WHERE 
				part_no = @part_no 
				AND location ='001' 

			-- Create line
			SET @xfer_line_no = @xfer_line_no + 1
			EXEC dbo.scm_pb_set_dw_xfer_list_sp		'I',@xfer_no,@xfer_line_no,'001',@location,@part_no,@description,
													@date,@ordered,0.00000000,NULL,'N',@cost,NULL,@who_entered,
													0.00000000,@uom,1.00000000,0.00000000,NULL,'IN TRANSIT','N/A',
													@date,@lb_tracking,0.00000000,0.00000000,0.00000000,0.00000000,
													@allow_fractions,@xfer_line_no,@cubic_feet,@weight_ea,@serial_flag,NULL,0,NULL


	
		END

		-- START v1.4
		EXEC cvo_xfer_after_save_sp @xfer_no
		-- END v1.4

		-- Commit tran
		COMMIT TRAN
	END
	
	-- Update cvo_orders_all (if no valid lines set xfer_no = 0)
	IF @CreateXfer = 0
	BEGIN
		SET @xfer_no = 0
	END	

	UPDATE
		dbo.cvo_orders_all
	SET
		xfer_no = @xfer_no
	WHERE
		order_no = @order_no
		AND ext = @ext

	-- v1.1 - Write note to originating order
	UPDATE
		dbo.orders_all
	SET
		note = (CASE ISNULL(note,'') WHEN '' THEN '' ELSE note + CHAR(13) + CHAR(10) END) + (CASE @xfer_no WHEN 0 THEN 'No Transfer Order created, no valid lines exist' ELSE 'Transfer Order ' + CAST (@xfer_no AS VARCHAR(10)) END)
	WHERE
		order_no = @order_no
		AND ext = @ext

END
GO
GRANT EXECUTE ON  [dbo].[cvo_create_inv_replen_transfer_sp] TO [public]
GO
