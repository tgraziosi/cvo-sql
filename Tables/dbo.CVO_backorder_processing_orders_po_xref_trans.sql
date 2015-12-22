CREATE TABLE [dbo].[CVO_backorder_processing_orders_po_xref_trans]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[parent_rec_id] [int] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [int] NULL,
[processed] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		CVO_backorder_processing_orders_po_xref_trans_i_trg		
Type:		Trigger
Description:	When stock is received directly to non receipt bins, move it to the ringfence bin to stop it being allocated
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/06/2013	Original Version

*/

CREATE TRIGGER [dbo].[CVO_backorder_processing_orders_po_xref_trans_i_trg] ON [dbo].[CVO_backorder_processing_orders_po_xref_trans]
FOR INSERT
AS
BEGIN
	DECLARE @bin_no			VARCHAR(12),
			@rec_id			INT,
			@parent_rec_id	INT,
			@location		VARCHAR(10),
			@part_no		VARCHAR(30),
			@qty			DECIMAL(20,8),
			@user			VARCHAR(20),
			@ringfence_bin	VARCHAR(12),
			@tran_id		INT

	SET @user = SUSER_SNAME()
	SELECT @ringfence_bin = value_str FROM dbo.tdc_config WHERE [function] = 'BACKORDER_PROCESSING_RINGFENCE_BIN' 

	-- Loop through new records
	SET @rec_id = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@rec_id = rec_id,
			@parent_rec_id = parent_rec_id,
			@qty = qty,
			@bin_no = orig_bin_no,
			@tran_id = tran_id,
			@location = location
		FROM
			inserted
		WHERE
			rec_id > @rec_id
			--AND tran_id = -1
			--AND orig_bin_no IS NOT NULL
			AND processed = 0
		ORDER BY
			rec_id
			

		IF @@ROWCOUNT = 0
			BREAK

		-- Stock received directly to non receipt bins
		IF @tran_id = -1 AND @bin_no IS NOT NULL
		BEGIN
			-- Get details from parent
			SELECT
				@part_no = a.part_no
			FROM
				dbo.CVO_backorder_processing_orders_po_xref a (NOLOCK)
			INNER JOIN
				dbo.CVO_backorder_processing_orders b (NOLOCK)
			ON
				a.template_code = b.template_code
				AND a.order_no = b.order_no
				AND a.ext = b.ext
				AND a.line_no = b.line_no
			WHERE
				a.rec_id = @parent_rec_id

			
			-- Bin to bin the stock
 			EXEC cvo_bin2bin_sp @part_no, @location, @bin_no, @ringfence_bin, @qty, @user
			
			-- Update record		
			UPDATE
				dbo.CVO_backorder_processing_orders_po_xref_trans
			SET
				processed = 1,
				bin_no = @ringfence_bin
			WHERE
				rec_id = @rec_id

			-- Update parent
			UPDATE
				dbo.CVO_backorder_processing_orders_po_xref
			SET
				qty_received = qty_received + @qty,
				qty_ready_to_process = qty_ready_to_process - @qty
			WHERE
				rec_id = @parent_rec_id
		
		END

		-- Update order line
		UPDATE
			a
		SET
			processed = -1 
		FROM
			dbo.CVO_backorder_processing_orders a
		INNER JOIN
			dbo.CVO_backorder_processing_orders_po_xref b (NOLOCK)
		ON
			a.template_code = b.template_code
			AND a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no
		AND
			b.rec_id = @parent_rec_id
			AND a.processed = 0		
	END
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		CVO_backorder_processing_orders_po_xref_trans_u_trg		
Type:		Trigger
Description:	When put queue records are processed, update parent
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/06/2013	Original Version

*/

CREATE TRIGGER [dbo].[CVO_backorder_processing_orders_po_xref_trans_u_trg] ON [dbo].[CVO_backorder_processing_orders_po_xref_trans]
FOR UPDATE
AS
BEGIN
	DECLARE @rec_id			INT,
			@parent_rec_id	INT,
			@location		VARCHAR(10),
			@part_no		VARCHAR(30),
			@qty			DECIMAL(20,8),
			@bin_no			VARCHAR(12),
			@user			VARCHAR(20),
			@ringfence_bin	VARCHAR(12),
			@ringfenced		SMALLINT

	SET @user = SUSER_SNAME()
	SELECT @ringfence_bin = value_str FROM dbo.tdc_config WHERE [function] = 'BACKORDER_PROCESSING_RINGFENCE_BIN' 

	-- Loop through updated records
	SET @rec_id = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@rec_id = rec_id,
			@parent_rec_id = parent_rec_id,
			@qty = qty,
			@bin_no = bin_no,
			@location = location
		FROM
			inserted
		WHERE
			rec_id > @rec_id
			AND tran_id <> -1
			AND processed = -1
		ORDER BY
			rec_id
			

		IF @@ROWCOUNT = 0
			BREAK


		SET @ringfenced = 0

		-- If the bin isn't a CROSSDOCK bin then move it to the RINGFENCE bin
		IF NOT EXISTS (SELECT 1 FROM dbo.tdc_bin_master (NOLOCK) WHERE bin_no = @bin_no AND location = @location AND group_code = 'CROSSDOCK')
		BEGIN
			-- Get details from parent
			SELECT
				@part_no = a.part_no
			FROM
				dbo.CVO_backorder_processing_orders_po_xref a (NOLOCK)
			INNER JOIN
				dbo.CVO_backorder_processing_orders b (NOLOCK)
			ON
				a.template_code = b.template_code
				AND a.order_no = b.order_no
				AND a.ext = b.ext
				AND a.line_no = b.line_no
			WHERE
				a.rec_id = @parent_rec_id
			
			-- Bin to bin the stock
 			EXEC cvo_bin2bin_sp @part_no, @location, @bin_no, @ringfence_bin, @qty, @user

			SET @ringfenced = 1
		END

		
		-- Update record		
		UPDATE
			dbo.CVO_backorder_processing_orders_po_xref_trans
		SET
			processed = 1,
			orig_bin_no = CASE @ringfenced WHEN 1 THEN @bin_no ELSE orig_bin_no END,
			bin_no = CASE @ringfenced WHEN 1 THEN @ringfence_bin ELSE bin_no END
		WHERE
			rec_id = @rec_id

		-- Update parent
		UPDATE
			dbo.CVO_backorder_processing_orders_po_xref
		SET
			qty_received = qty_received + @qty,
			qty_ready_to_process = qty_ready_to_process - @qty,
			bin_no = CASE ISNULL(bin_no,'') WHEN '' THEN @bin_no ELSE bin_no END
		WHERE
			rec_id = @parent_rec_id

		-- Update order line
		UPDATE
			a
		SET
			processed = -1 
		FROM
			dbo.CVO_backorder_processing_orders a
		INNER JOIN
			dbo.CVO_backorder_processing_orders_po_xref b (NOLOCK)
		ON
			a.template_code = b.template_code
			AND a.order_no = b.order_no
			AND a.ext = b.ext
			AND a.line_no = b.line_no
		AND
			b.rec_id = @parent_rec_id
			AND a.processed = 0		
	END
END

GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_po_xref_trans_inx01] ON [dbo].[CVO_backorder_processing_orders_po_xref_trans] ([parent_rec_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [CVO_backorder_processing_orders_po_xref_trans_pk] ON [dbo].[CVO_backorder_processing_orders_po_xref_trans] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_backorder_processing_orders_po_xref_trans_inx02] ON [dbo].[CVO_backorder_processing_orders_po_xref_trans] ([tran_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_backorder_processing_orders_po_xref_trans] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_backorder_processing_orders_po_xref_trans] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_backorder_processing_orders_po_xref_trans] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_backorder_processing_orders_po_xref_trans] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_backorder_processing_orders_po_xref_trans] TO [public]
GO
