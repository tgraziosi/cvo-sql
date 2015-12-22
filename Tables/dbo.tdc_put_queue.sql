CREATE TABLE [dbo].[tdc_put_queue]
(
[trans_source] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_id] [int] NOT NULL IDENTITY(2, 2),
[priority] [int] NOT NULL,
[seq_no] [int] NOT NULL,
[company_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[warehouse_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_type_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_type_ext] [int] NULL,
[tran_receipt_no] [int] NULL,
[line_no] [int] NULL,
[pcsn] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eco_no] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mfg_lot] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mfg_batch] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[serial_no] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_to_process] [decimal] (20, 8) NULL,
[qty_processed] [decimal] (20, 8) NULL,
[qty_short] [decimal] (20, 8) NULL,
[next_op] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id_link] [int] NULL,
[date_time] [datetime] NULL,
[assign_group] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[assign_user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_id] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tx_status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tx_control] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tx_lock] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		tdc_put_queue_d_trg		
Type:		Trigger
Description:	When put queue records are processed, update backorder processing table
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	13/06/2013	Original Version

*/

CREATE TRIGGER [dbo].[tdc_put_queue_d_trg] ON [dbo].[tdc_put_queue]
FOR DELETE
AS
BEGIN
	DECLARE @tran_id		INT,
			@bin_no			VARCHAR(12)

	-- Loop through updated records
	SET @tran_id = 0
	WHILE 1=1
	BEGIN

		SELECT TOP 1
			@tran_id = tran_id,
			@bin_no = next_op
		FROM
			deleted
		WHERE
			tran_id > @tran_id
			AND trans = 'POPTWY'
		ORDER BY
			tran_id
			

		IF @@ROWCOUNT = 0
			BREAK
		
		-- Update record		
		UPDATE
			dbo.CVO_backorder_processing_orders_po_xref_trans
		SET
			processed = -1,
			bin_no = @bin_no
		WHERE
			tran_id = @tran_id

	END
END

GO
ALTER TABLE [dbo].[tdc_put_queue] ADD CONSTRAINT [PK_tdc_put_queue_1__17] PRIMARY KEY CLUSTERED  ([priority], [seq_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_put_queue_idx03] ON [dbo].[tdc_put_queue] ([assign_group], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_put_queue_idx04] ON [dbo].[tdc_put_queue] ([assign_user_id], [assign_group], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_put_queue_idx02] ON [dbo].[tdc_put_queue] ([assign_user_id], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_put_queue_idx01] ON [dbo].[tdc_put_queue] ([user_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_put_queue] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_put_queue] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_put_queue] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_put_queue] TO [public]
GO
