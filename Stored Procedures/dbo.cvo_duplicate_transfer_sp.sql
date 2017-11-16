SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.cvo_duplicate_transfer_sp 1653,2,'sa'

CREATE PROC [dbo].[cvo_duplicate_transfer_sp]	@tran_no	int,
											@userid		varchar(50)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@count		int,
			@new_tran	int,
			@msg		varchar(255),
			@copies		int, -- v1.1
			@location	varchar(10), -- v1.1
			@first		int, -- v1.1
			@addr1		varchar(40), -- v1.2
			@addr2		varchar(40), -- v1.2
			@addr3		varchar(40), -- v1.2
			@addr4		varchar(40), -- v1.2
			@addr5		varchar(40), -- v1.2
			@addr_name	varchar(40) -- v1.2
	-- WORKING TABLES
	-- v1.1 Start
	CREATE TABLE #xfer_locations (
		location	varchar(10),
		copies		int)
	-- v1.1 End

	-- PROCESSING
	-- v1.1 Start
	INSERT	#xfer_locations
	SELECT	location, qty
	FROM	#dup_locs
	WHERE	qty > 0

	SET @location = ''
	SET @first = 1

	WHILE (1 = 1)
	BEGIN

		SELECT	TOP 1 @location = location,
				@copies = copies
		FROM	#xfer_locations
		WHERE	location > @location
		ORDER BY location ASC

		IF (@@ROWCOUNT = 0)
			BREAK
		-- v1.1 End

		SET @count = 0

		WHILE (@count < @copies)
		BEGIN

			SET @count = @count + 1

			UPDATE	dbo.next_xfer_no 
			SET		last_no =last_no + 1 

			SELECT	@new_tran = last_no 
			FROM	dbo.next_xfer_no 		

			-- v1.2 Start
			SET @addr_name = NULL
			SELECT	@addr_name = salesperson_name,
					@addr1 = addr1,
					@addr2 = addr2,
					@addr3 = addr3,
					@addr4 = addr4,
					@addr5 = addr5
			FROM	arsalesp (NOLOCK)
			WHERE	addr_sort1 = @location

			IF (@addr_name IS NULL)
			BEGIN
				SELECT	@addr_name = name,
						@addr1 = addr1,
						@addr2 = addr2,
						@addr3 = addr3,
						@addr4 = addr4,
						@addr5 = addr5
				FROM	locations_all (NOLOCK)
				WHERE	location = @location
			END
			-- v1.2 End

			INSERT xfers_all (xfer_no, from_loc, to_loc, req_ship_date, sch_ship_date, date_shipped, date_entered, req_no, who_entered, 
				status, attention, phone, routing, special_instr, fob, freight, printed, label_no, no_cartons, who_shipped, date_printed, 
				who_picked, to_loc_name, to_loc_addr1, to_loc_addr2, note, rec_no, freight_type, no_pallets, to_loc_addr3, to_loc_addr4, 
				to_loc_addr5, who_recvd, date_recvd, from_organization_id, to_organization_id, back_ord_flag, autopack, autoship)
			SELECT	@new_tran, from_loc, @location, GETDATE(), GETDATE(), NULL, GETDATE(), NULL, @userid, 'N', attention, phone, routing, -- v1.1
					special_instr, fob, freight, 'N', label_no, no_cartons, NULL, NULL, NULL, @addr_name, @addr1, @addr2, -- v1.2 
					note, 0, freight_type, no_pallets, @addr3, @addr4, @addr5, NULL, NULL, from_organization_id, -- v1.2
					to_organization_id, back_ord_flag, autopack, autoship
			FROM	xfers_all 
			WHERE	xfer_no = @tran_no

			INSERT	xfer_list (xfer_no, line_no, from_loc, to_loc, part_no, description, time_entered, ordered, shipped, comment, status, 
				cost, com_flag, who_entered, temp_cost, uom, conv_factor, std_cost, from_bin, to_bin, lot_ser, date_expires, lb_tracking, 
				labor, direct_dolrs, ovhd_dolrs, util_dolrs, display_line, back_ord_flag)
			SELECT	@new_tran, line_no, from_loc, @location, part_no, description, GETDATE(), ordered, 0, comment, 'N', cost, com_flag, @userid, -- v1.1
					temp_cost, uom, conv_factor, std_cost, NULL, 'IN TRANSIT', lot_ser, GETDATE(), lb_tracking, labor, direct_dolrs, ovhd_dolrs, 
					util_dolrs, display_line, back_ord_flag
			FROM	xfer_list
			WHERE	xfer_no = @tran_no
	  
			EXEC cvo_xfer_after_save_sp @xfer_no = @new_tran  

			IF (@first = 1)
			BEGIN
				SET @msg = 'Duplicates created - From ' + CAST(@new_tran as varchar(20)) + ' to '
				SET @first = 0
			END
		END

	END -- v1.1

	SET @msg = @msg + CAST(@new_tran as varchar(20))

	SELECT @new_tran, @msg

END
GO
GRANT EXECUTE ON  [dbo].[cvo_duplicate_transfer_sp] TO [public]
GO
