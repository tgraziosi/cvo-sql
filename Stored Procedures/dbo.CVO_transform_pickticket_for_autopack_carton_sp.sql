SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			CVO_transform_pickticket_for_autopack_carton_sp		
Project ID:		Issue 690
Type:			Stored Proc
Description:	Splits pick ticket data across cartons
Developer:		Chris Tyler

History
-------
v1.0	27/07/12	CT	Original version
v1.1	20/08/12	CT	Fix for consolidated cases split across cartons
v1.2	29/08/12	CB	Fix for cases being duplicated
*/

CREATE PROC [dbo].[CVO_transform_pickticket_for_autopack_carton_sp] (	@order_no INT,
																	@order_ext INT,
																	@max_carton_id INT)
AS
BEGIN

	DECLARE @rec_key					INT,
			@pick_qty					DECIMAL(20,8),
			@qty_to_apply				DECIMAL(20,8),
			@qty_reqd					DECIMAL(20,8),
			@qty_remaining				DECIMAL(20,8),
			@line_no					INT,
			@part_no					VARCHAR(30),
			@autopack_id				INT,
			@carton_id					INT,
			@tran_id_link	INT -- v1.1

	-- Create working table
	CREATE TABLE #process(
		[rec_key] [INT] IDENTITY(1,1),
		[order_no] [int] NULL,
		[order_ext] [int] NULL,
		[location] [varchar] (10) NULL,
		[line_no] [int] NULL,
		[part_type] [char](1) NULL,
		[uom] [char](2) NULL,
		[description] [varchar](255) NULL,
		[ord_qty] [decimal](20, 8) NOT NULL,
		[dest_bin] [varchar](12) NULL,
		[pick_qty] [decimal](20, 8) NOT NULL,
		[part_no] [varchar](30) NOT NULL,
		[lot_ser] [varchar](25) NULL,
		[bin_no] [varchar](12) NULL,
		[item_note] [varchar](255) NULL,
		[tran_id] [varchar](10) NULL,
		[carton_id] [int] NULL)
	
	-- Copy data into working table
	INSERT INTO #process(
		order_no,
		order_ext,
		location,
		line_no,
		part_type,
		uom,
		[description],
		ord_qty,
		dest_bin,
		pick_qty,
		part_no,
		lot_ser,
		bin_no,
		item_note,
		tran_id,
		carton_id)
	SELECT  
		order_no,
		order_ext,
		location,
		line_no,
		part_type,
		uom,
		[description],
		ord_qty,
		dest_bin,
		pick_qty,
		part_no,
		lot_ser,
		bin_no,
		item_note,
		tran_id,
		carton_id
	FROM
		#pick_ticket

	-- Build table to hold carton details
	SELECT
		autopack_id,
		carton_id,
		line_no,
		part_no,
		qty - picked as qty_to_pick,
		qty - picked as qty_remaining
	INTO 
		#carton
	FROM
		dbo.CVO_autopack_carton (NOLOCK)
	WHERE
		order_no = @order_no
		AND order_ext = @order_ext
		AND qty - picked > 0
	
	IF NOT EXISTS (SELECT 1 FROM #carton)
	BEGIN
		RETURN
	END

	-- Clear pick ticket table
	DELETE FROM #pick_ticket

	-- Increase max carton - this will be the carton_id for no carton lines
	SET @max_carton_id = @max_carton_id + 1
	
	-- Loop through process table and assign to cartons
	SET @rec_key = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_key = rec_key,
			@line_no = line_no,
			@part_no = part_no,
			@pick_qty = pick_qty
		FROM
			#process
		WHERE
			rec_key > @rec_key
		ORDER BY 
			rec_key

		IF @@ROWCOUNT = 0
			BREAK

		-- Loop through record in the carton table for this line/part
		SET @autopack_id = 0
		SET @qty_remaining = @pick_qty 
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@autopack_id = autopack_id,
				@qty_reqd = qty_remaining,
				@carton_id = carton_id
			FROM
				#carton
			WHERE
				line_no = @line_no
				AND part_no = @part_no
				AND qty_remaining > 0
				AND autopack_id > @autopack_id

			IF @@ROWCOUNT = 0
				BREAK

			IF @qty_reqd >= @qty_remaining
			BEGIN
				SET @qty_to_apply = @qty_remaining
				SET @qty_remaining = 0
			END
			ELSE
			BEGIN
				SET @qty_to_apply = @qty_reqd
				SET @qty_remaining = @qty_remaining - @qty_reqd
			END

			-- Update carton table 
			UPDATE
				#carton
			SET
				qty_remaining = qty_remaining - @qty_to_apply
			WHERE
				autopack_id = @autopack_id

			-- Insert record into pick ticket table
			INSERT INTO #pick_ticket(
				order_no,
				order_ext,
				location,
				line_no,
				part_type,
				uom,
				[description],
				ord_qty,
				dest_bin,
				pick_qty,
				part_no,
				lot_ser,
				bin_no,
				item_note,
				tran_id,
				carton_id)
			SELECT 
				order_no,
				order_ext,
				location, 
				line_no,
				part_type,
				uom,
				[description],
				ord_qty,
				dest_bin,
				@qty_to_apply,
				part_no,
				lot_ser,
				bin_no,
				item_note,
				tran_id,
				@carton_id
			FROM
				#process
			WHERE
				rec_key = @rec_key

			IF @qty_remaining = 0
				BREAK

		END
		
		-- If there are no more rows add the remaining qty to the max carton
		IF @qty_remaining > 0 
		BEGIN
			INSERT INTO #pick_ticket(
				order_no,
				order_ext,
				location,
				line_no,
				part_type,
				uom,
				[description],
				ord_qty,
				dest_bin,
				pick_qty,
				part_no,
				lot_ser,
				bin_no,
				item_note,
				tran_id,
				carton_id)
			SELECT
				order_no,
				order_ext,
				location, 
				line_no,
				part_type,
				uom,
				[description],
				ord_qty,
				dest_bin,
				@qty_remaining,
				part_no,
				lot_ser,
				bin_no,
				item_note,
				tran_id,
				@max_carton_id
			FROM
				#process
			WHERE
				rec_key = @rec_key
		END
	END

	-- START v1.1
	-- Look for consolidated cases in cartons where the visible transacttion doesn't exist
	SET @carton_id = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@carton_id = carton_id
		FROM
			#pick_ticket 
		WHERE
			carton_id > @carton_id
		ORDER BY 
			carton_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @tran_id_link = 0
		WHILE 1=1
		BEGIN
			-- Loop through all the consolidated cases in carton
			SELECT TOP 1
				@tran_id_link = b.tran_id_link
			FROM
				#pick_ticket a
			INNER JOIN
				dbo.tdc_pick_queue b (NOLOCK)
			ON
				CAST(a.tran_id AS INT) = b.tran_id
			WHERE
				a.carton_id = @carton_id
				AND b.tran_id_link > @tran_id_link
				AND CAST(a.tran_id AS INT) <> b.tran_id_link
			ORDER BY
				b.tran_id_link


			IF @@ROWCOUNT = 0
				BREAK

			-- If there is no record for the tran_id_link in the table, update one of the hidden records
			IF NOT EXISTS (SELECT 1 FROM #pick_ticket WHERE carton_id = @carton_id AND CAST(tran_id AS INT) = @tran_id_link)
			BEGIN

				SET ROWCOUNT 1
				UPDATE 
					a
				SET
					tran_id = CAST(@tran_id_link AS VARCHAR)
				FROM
					#pick_ticket a
				INNER JOIN
					dbo.tdc_pick_queue b (NOLOCK)
				ON
					CAST(a.tran_id AS INT) = b.tran_id
				WHERE
					b.tran_id_link = @tran_id_link
					AND CAST(a.tran_id AS INT) <> @tran_id_link
					AND a.carton_id = @carton_id -- v1.2 

				SET ROWCOUNT 0
			END 
		END

	END
	-- END v1.1
END

GO
GRANT EXECUTE ON  [dbo].[CVO_transform_pickticket_for_autopack_carton_sp] TO [public]
GO
