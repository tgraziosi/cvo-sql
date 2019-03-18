SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 12/07/2012 - Create a transfer return
-- v1.1 CT 24/06/2013 - Issue #1034 - Add to inventory functionality
-- v1.2 CT 24/06/2013 - Fix bug with from/to location on xfer lines
-- v1.3 CB 11/03/2019 - #1692 Transfer Return Update


CREATE PROC [dbo].[cvo_create_transfer_return_sp] (@from_loc VARCHAR(10), @to_loc VARCHAR(10), @spid INT, @who_entered VARCHAR(20))
AS
BEGIN
	DECLARE @xfer_no			INT,
			@CreateXfer			SMALLINT,
			@rec_id				INT,
			@xfer_line_no		INT,
			@from_loc_name		VARCHAR(30),
			@from_loc_addr1		VARCHAR(40),
			@from_loc_addr2		VARCHAR(40),
			@from_loc_addr3		VARCHAR(40),
			@from_loc_addr4		VARCHAR(40),
			@from_loc_addr5		VARCHAR(40),
			@to_loc_name		VARCHAR(30),
			@to_loc_addr1		VARCHAR(40),
			@to_loc_addr2		VARCHAR(40),
			@to_loc_addr3		VARCHAR(40),
			@to_loc_addr4		VARCHAR(40),
			@to_loc_addr5		VARCHAR(40),
			@part_no			VARCHAR(30),
			@description		VARCHAR(255),
			@ordered			DECIMAL(20,8),
			@cost				DECIMAL(20,8),
			@uom				CHAR(2),
			@lb_tracking		CHAR(1),
			@cubic_feet			DECIMAL(20,8),
			@weight_ea			DECIMAL(20,8),
			@serial_flag		SMALLINT,
			@allow_fractions	SMALLINT,
			@freight_type		VARCHAR(10),
			@date				DATETIME,
			@add_to_inv			SMALLINT, -- v1.1
			@bin_no				VARCHAR(12), -- v1.1
			@qty_in_bin			decimal(20,8), -- v1.3
			@exp_date			varchar(12) -- v1.3


	-- If nothing in table return 0
	IF NOT EXISTS (SELECT 1 FROM dbo.CVO_transfer_return (NOLOCK) WHERE spid = @spid AND process = 1)
	BEGIN
		SELECT 0
		RETURN 0
	END	

	-- v1.3 Start
	-- If only adjust out exists then skip the creation of the transfer
	IF NOT EXISTS ( SELECT 1 FROM dbo.CVO_transfer_return (NOLOCK) WHERE spid = @spid AND process = 1 AND adjust_out = 0)
	BEGIN
		GOTO AdjustOut
	END
	-- v1.3 End


	SET @date = GETDATE()

	-- Get zero freight freight type
	SELECT @freight_type = value_str FROM dbo.config WHERE flag = 'FRTHTYPE'	

	-- START v1.1
	-- Get bin for stock adjustment
	SELECT TOP 1
		@bin_no = bin_no 
	FROM 
		dbo.tdc_bin_master (NOLOCK)
	WHERE	
		location = @from_loc 
		AND usage_type_code in ('OPEN','REPLENISH') 
		AND [status] = 'A'
	-- END v1.1

	SET @CreateXfer = 1 -- True
	
	IF @CreateXfer = 1
	BEGIN

		-- Get next transfer no
		BEGIN TRAN
		UPDATE dbo.next_xfer_no SET last_no =last_no + 1 
		SELECT @xfer_no = last_no FROM dbo.next_xfer_no (NOLOCK)
		COMMIT TRAN

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
			location = @from_loc
	

		-- Get from location info (use salesperson address if it exists)
		IF EXISTS (SELECT 1 FROM dbo.arsalesp ( NOLOCK ) WHERE addr_sort1 = @from_loc)
		BEGIN
			SELECT 
				@from_loc_name = salesperson_name, 
				@from_loc_addr1 = addr1,
				@from_loc_addr2 = addr2,
				@from_loc_addr3 = addr3,
				@from_loc_addr4 = addr4,
				@from_loc_addr5 = addr5
			FROM 
				dbo.arsalesp ( NOLOCK ) 
			WHERE 
				addr_sort1 = @from_loc 
		END
		ELSE
		BEGIN
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
				location = @from_loc
		END

		-- Get to location info (use salesperson address if it exists)
		IF EXISTS (SELECT 1 FROM dbo.arsalesp ( NOLOCK ) WHERE addr_sort1 = @to_loc)
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
				addr_sort1 = @to_loc 
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
				location = @to_loc
		END
			
		-- Create transfer
		BEGIN TRAN
		
		-- Create header
		EXEC dbo.scm_pb_set_dw_transfer_sp	'I',@xfer_no,@from_loc,@to_loc,@date,@date,NULL,@date,NULL,@who_entered,
											'N',NULL,NULL,'SAL',NULL,NULL,0.00000000,'N',0,0,NULL,NULL,NULL,		
											@to_loc_name,@to_loc_addr1,@to_loc_addr2,@from_loc_name,@from_loc_addr1,@from_loc_addr2,
											NULL,0,@freight_type,0,NULL,NULL,
											@from_loc_addr3,@from_loc_addr4,@from_loc_addr5,@to_loc_addr3,@to_loc_addr4,@to_loc_addr5,
											NULL,NULL,NULL,NULL,'CVO','CVO',NULL,0,0,NULL,NULL,NULL,0,1  
										

		-- START v1.1
		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRAN
			RETURN
		END 
		-- END v1.1

		-- Loop through lines and add them
		SET @rec_id = 0
		SET @xfer_line_no = 0
		WHILE 1=1
		BEGIN

			SELECT TOP 1
				@rec_id = rec_id,
				@part_no = part_no,
				@ordered = qty,
				@add_to_inv = add_to_inv -- v1.1
			FROM
				dbo.CVO_transfer_return (NOLOCK)
			WHERE
				rec_id > @rec_id
				AND process = 1
				AND	adjust_out = 0 -- v1.3
				AND spid = @spid
			ORDER BY
				rec_id

			IF @@ROWCOUNT = 0
				BREAK


			-- Get part details
			SELECT 
				@uom = uom, 
				@description = [description],
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
				AND location = @from_loc


			-- START v1.1 - create stock adjustment
			IF @add_to_inv = 1 AND ISNULL(@bin_no,'') <> ''
			BEGIN
				EXEC dbo.cvo_transfer_return_adhoc_adjust_sp @from_loc, @part_no, @ordered, @bin_no, @who_entered, @xfer_no
				
				IF @@ERROR <> 0
				BEGIN
					ROLLBACK TRAN
					RETURN
				END 
			END
			-- END v1.1

			-- Create line
			SET @xfer_line_no = @xfer_line_no + 1
			-- START v1.2
			--EXEC dbo.scm_pb_set_dw_xfer_list_sp		'I',@xfer_no,@xfer_line_no,'001',@from_loc,@part_no,@description,
			EXEC dbo.scm_pb_set_dw_xfer_list_sp		'I',@xfer_no,@xfer_line_no,@from_loc,@to_loc,@part_no,@description,
													@date,@ordered,0.00000000,NULL,'N',@cost,NULL,@who_entered,
													0.00000000,@uom,1.00000000,0.00000000,NULL,'IN TRANSIT','N/A',
													@date,@lb_tracking,0.00000000,0.00000000,0.00000000,0.00000000,
													@allow_fractions,@xfer_line_no,@cubic_feet,@weight_ea,@serial_flag,NULL,0,NULL
			-- END v1.2

			-- START v1.1
			IF @@ERROR <> 0
			BEGIN
				ROLLBACK TRAN
				RETURN
			END 
			-- END v1.1


	
		END

		IF NOT EXISTS (SELECT 1 FROM CVO_transfer_return_autoship WHERE xfer_no = @xfer_no)
		BEGIN
			INSERT INTO CVO_transfer_return_autoship (xfer_no) SELECT @xfer_no
		END

		-- Commit tran
		COMMIT TRAN

		-- v1.3 Start
		IF NOT EXISTS ( SELECT 1 FROM dbo.CVO_transfer_return (NOLOCK) WHERE spid = @spid AND process = 1 AND adjust_out = 1)
		BEGIN
			GOTO Finish
		END

AdjustOut:	

		IF OBJECT_ID('tempdb..#temp_who') IS NOT NULL 
		BEGIN   
			DROP TABLE #temp_who  
		END

		CREATE TABLE #temp_who (
			who			varchar(50) not NULL, 
			login_id	varchar(50) not NULL)

		INSERT	#temp_who (who, login_id) 
		VALUES	(@who_entered, @who_entered)

		IF OBJECT_ID('tempdb..#adm_inv_adj') IS NOT NULL 
		BEGIN   
			DROP TABLE #adm_inv_adj  
		END

		CREATE TABLE #adm_inv_adj (
			adj_no			int null,
			loc				varchar(10) not null,
			part_no			varchar(30) not null,
			bin_no			varchar(12) null,
			lot_ser			varchar(25) null,
			date_exp		datetime null,
			qty				decimal(20,8) not null,
			direction		int not null,
			who_entered		varchar(50) not null,
			reason_code		varchar(10) null,
			code 			varchar(8) not null,
			cost_flag		char(1) null,
			avg_cost		decimal(20,8) null,
			direct_dolrs	decimal(20,8) null,
			ovhd_dolrs		decimal(20,8) null,
			util_dolrs		decimal(20,8) null,
			err_msg			varchar(255) null,
			row_id			int identity not null)

		SELECT	TOP 1 @bin_no = bin_no 
		FROM	dbo.tdc_bin_master (NOLOCK)
		WHERE	location = @from_loc 
		AND		usage_type_code in ('OPEN','REPLENISH') 
		AND		[status] = 'A'

		SET @rec_id = 0
		WHILE 1=1
		BEGIN

			SELECT TOP 1 @rec_id = rec_id,
					@part_no = part_no,
					@ordered = qty
			FROM	dbo.CVO_transfer_return (NOLOCK)
			WHERE	rec_id > @rec_id
			AND		process = 1
			AND		adjust_out = 1
			AND		spid = @spid
			ORDER BY rec_id

			IF @@ROWCOUNT = 0
				BREAK	

			SELECT	@qty_in_bin = qty
			FROM	lot_bin_stock (NOLOCK)
			WHERE	location = @from_loc
			AND		bin_no = @bin_no
			AND		part_no = @part_no

			IF (@qty_in_bin >= @ordered)
			BEGIN
				TRUNCATE TABLE #adm_inv_adj

				SELECT	@exp_date = CONVERT(varchar(12), date_expires, 101)
				FROM	lot_bin_stock (NOLOCK)
				WHERE	location = @from_loc 
				AND		part_no = @part_no 
				AND		bin_no = @bin_no 
				AND		lot_ser = '1'

				INSERT	#adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 
				SELECT	@from_loc, @part_no, @bin_no, '1', @exp_date, @ordered, -1, @who_entered, '', 'ADHOC'

				BEGIN TRAN

				EXEC tdc_adm_inv_adj 
				
				IF (@@ERROR <> 0)
				BEGIN 
					IF (@@TRANCOUNT > 0)
						ROLLBACK TRAN
				END
				ELSE
				BEGIN

					INSERT	tdc_log (tran_date,UserID,trans_source,module,trans,tran_no,tran_ext,part_no,lot_ser,bin_no,location,quantity,data)
					SELECT	GETDATE(), @who_entered, 'BO','TRANRET', 'ADHOC', '', '', @part_no, '1', @bin_no, @from_loc, CAST(@ordered as varchar(20)),
							'TRANSFER RETURN - ADJUST OUT'

					COMMIT TRAN
				END

			END 

		END
		-- v1.3 End

Finish:
		-- Return xfer no
		SELECT @xfer_no

	END
END
GO
GRANT EXECUTE ON  [dbo].[cvo_create_transfer_return_sp] TO [public]
GO
