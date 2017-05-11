CREATE TABLE [dbo].[tdc_pick_queue]
(
[trans_source] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_id] [int] NOT NULL IDENTITY(1, 2),
[priority] [int] NOT NULL,
[seq_no] [int] NOT NULL,
[company_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[warehouse_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trans_type_no] [int] NULL,
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
[tx_lock] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mp_consolidation_no] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			tdc_pick_queue_d_trg		
Type:			Trigger
Description:	Updates replenishment qtys for replenishment moves
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	02/07/2012	Original Version
*/

CREATE TRIGGER [dbo].[tdc_pick_queue_d_trg] ON [dbo].[tdc_pick_queue]
FOR DELETE
AS
BEGIN
	DECLARE @tran_id	INT,
			@location	VARCHAR(10),
			@part_no	VARCHAR(30),
			@qty		DECIMAL (20,8)

	SET @tran_id = 0
	WHILE 1=1
	BEGIN

		-- Get next record to action
		SELECT TOP 1
			@tran_id = tran_id,
			@location = location,
			@part_no = part_no,
			@qty = qty_to_process
		FROM
			deleted
		WHERE
			tran_id > @tran_id
			AND trans = 'MGTB2B' 
			AND eco_no IS NOT NULL
		ORDER BY 
			tran_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Update record
		UPDATE
			dbo.cvo_replenishment_qty 
		SET
			qty = qty - @qty
		WHERE 
			location = @location 
			AND part_no = @part_no
	END
END
	
		

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			tdc_pick_queue_i_trg		
Type:			Trigger
Description:	Updates replenishment qtys for replenishment moves
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	02/07/2012	Original Version
*/

CREATE TRIGGER [dbo].[tdc_pick_queue_i_trg] ON [dbo].[tdc_pick_queue]
FOR INSERT
AS
BEGIN
	DECLARE @tran_id	INT,
			@location	VARCHAR(10),
			@part_no	VARCHAR(30),
			@qty		DECIMAL (20,8)

	SET @tran_id = 0
	WHILE 1=1
	BEGIN

		-- Get next record to action
		SELECT TOP 1
			@tran_id = tran_id,
			@location = location,
			@part_no = part_no,
			@qty = qty_to_process
		FROM
			inserted
		WHERE
			tran_id > @tran_id
			AND trans = 'MGTB2B' 
			AND eco_no IS NOT NULL
		ORDER BY 
			tran_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Update cvo_replenishment_qty
		IF EXISTS (SELECT 1 FROM dbo.cvo_replenishment_qty (NOLOCK) WHERE location = @location AND part_no = @part_no)
		BEGIN
			-- Update record
			UPDATE
				dbo.cvo_replenishment_qty 
			SET
				qty = qty + @qty
			WHERE 
				location = @location 
				AND part_no = @part_no
		END
		ELSE
		BEGIN
			INSERT dbo.cvo_replenishment_qty(
				location,
				part_no,
				qty)
			SELECT
				@location,
				@part_no,
				@qty
		END
	END
END
	
		

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			tdc_pick_queue_u_trg		
Type:			Trigger
Description:	Updates replenishment qtys for replenishment moves
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	02/07/2012	Original Version
*/

CREATE TRIGGER [dbo].[tdc_pick_queue_u_trg] ON [dbo].[tdc_pick_queue]
FOR UPDATE
AS
BEGIN
	DECLARE @tran_id	INT,
			@location	VARCHAR(10),
			@part_no	VARCHAR(30),
			@qty		DECIMAL (20,8)

	SET @tran_id = 0
	WHILE 1=1
	BEGIN

		-- Get next record to action
		SELECT TOP 1
			@tran_id = i.tran_id,
			@location = i.location,
			@part_no = i.part_no,
			@qty = d.qty_to_process - i.qty_to_process
		FROM
			inserted i
		INNER JOIN
			deleted d
		ON 
			i.tran_id = d.tran_id
		WHERE
			i.tran_id > @tran_id
			AND i.trans = 'MGTB2B' 
			AND i.eco_no IS NOT NULL
			AND d.qty_to_process <> i.qty_to_process
		ORDER BY 
			i.tran_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Update record
		UPDATE
			dbo.cvo_replenishment_qty 
		SET
			qty = qty - @qty
		WHERE 
			location = @location 
			AND part_no = @part_no
	END
END
	
		

GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx03] ON [dbo].[tdc_pick_queue] ([assign_group], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx04] ON [dbo].[tdc_pick_queue] ([assign_user_id], [assign_group], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx02] ON [dbo].[tdc_pick_queue] ([assign_user_id], [tx_lock], [tran_id], [location], [bin_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx06] ON [dbo].[tdc_pick_queue] ([location], [part_no], [lot], [bin_no], [trans]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_ind_prio_seq] ON [dbo].[tdc_pick_queue] ([priority], [seq_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx07] ON [dbo].[tdc_pick_queue] ([tran_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_tdc_pick_queue_tranid_cons] ON [dbo].[tdc_pick_queue] ([tran_id]) INCLUDE ([mp_consolidation_no], [trans_type_ext], [trans_type_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx05] ON [dbo].[tdc_pick_queue] ([trans], [trans_type_no], [trans_type_ext], [location], [part_no], [lot], [bin_no], [line_no], [trans_source]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_tdc_pick_queue_ind1] ON [dbo].[tdc_pick_queue] ([trans], [trans_type_no], [trans_type_ext], [mfg_batch]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_tdc_pick_queue_ind2] ON [dbo].[tdc_pick_queue] ([trans], [trans_type_no], [trans_type_ext], [mfg_batch], [mfg_lot], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_ind_type_no_ext_line_trans] ON [dbo].[tdc_pick_queue] ([trans_type_no], [trans_type_ext], [line_no], [trans]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_ind_type_no_ext_lock] ON [dbo].[tdc_pick_queue] ([trans_type_no], [trans_type_ext], [tx_lock]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_pick_queue_idx01] ON [dbo].[tdc_pick_queue] ([user_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pick_queue] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pick_queue] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pick_queue] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pick_queue] TO [public]
GO
