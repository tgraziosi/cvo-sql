CREATE TABLE [dbo].[inv_sales]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_alloc] [decimal] (20, 8) NOT NULL,
[commit_ed] [decimal] (20, 8) NOT NULL,
[sales_qty_mtd] [decimal] (20, 8) NOT NULL,
[sales_qty_ytd] [decimal] (20, 8) NOT NULL,
[last_order_qty] [decimal] (20, 8) NOT NULL,
[oe_on_order] [decimal] (20, 8) NOT NULL,
[oe_order_date] [datetime] NULL,
[sales_amt_mtd] [decimal] (20, 8) NOT NULL,
[sales_amt_ytd] [decimal] (20, 8) NOT NULL,
[hold_ord] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delinvs] ON [dbo].[inv_sales]   FOR DELETE AS 
begin

if NOT exists (select * from inv_list l, inserted i where i.part_no=l.part_no
	and i.location=l.location) return
if exists (select * from config where flag='TRIG_DEL_INV' and value_str='DISABLE')
	begin
		return
	end
else
	begin
	if exists (select * from deleted d,inventory i where 
	d.part_no=i.part_no and d.location=i.location and ( i.in_stock <> 0
	OR i.oe_on_order <> 0 OR i.po_on_order <> 0 ) and i.status != 'R') begin
	rollback tran
	exec adm_raiserror 73199, 'You Can Not Delete Inventory With In Stock Quantities!'
	return
		end
	end 
end

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 19/10/2011 Performance
-- v1.1 CT 06/08/2012 When calculating available stock, include bins that are marked as non-allocating but are not in the config
-- v1.2 CB 21/04/2015 - Performance Changes

CREATE TRIGGER [dbo].[t602updinvs] ON [dbo].[inv_sales]
FOR UPDATE
AS
BEGIN
	IF UPDATE(sales_qty_mtd)
	BEGIN
		IF EXISTS (SELECT * FROM config (NOLOCK) WHERE flag = 'INV_EOM_UPD' AND value_str = 'YES') RETURN

		DECLARE @i_part_no varchar(30), @i_location varchar(10), @i_qty_alloc decimal(20,8),
				@i_commit_ed decimal(20,8), @i_sales_qty_mtd decimal(20,8), @i_sales_qty_ytd decimal(20,8),
				@i_last_order_qty decimal(20,8), @i_oe_on_order decimal(20,8), @i_oe_order_date datetime,
				@i_sales_amt_mtd decimal(20,8), @i_sales_amt_ytd decimal(20,8), @i_hold_ord decimal(20,8),
				@d_part_no varchar(30), @d_location varchar(10), @d_qty_alloc decimal(20,8),
				@d_commit_ed decimal(20,8), @d_sales_qty_mtd decimal(20,8), @d_sales_qty_ytd decimal(20,8),
				@d_last_order_qty decimal(20,8), @d_oe_on_order decimal(20,8), @d_oe_order_date datetime,
				@d_sales_amt_mtd decimal(20,8), @d_sales_amt_ytd decimal(20,8), @d_hold_ord decimal(20,8)

		-- v1.2 Start
		DECLARE	@row_id			int,
				@last_row_id	int

		CREATE TABLE #t700updinv (
			row_id				int IDENTITY(1,1),
			i_part_no			varchar(30) NULL,
			i_location			varchar(10) NULL,
			i_qty_alloc			decimal(20,8) NULL,
			i_commit_ed			decimal(20,8) NULL,
			i_sales_qty_mtd		decimal(20,8) NULL,
			i_sales_qty_ytd		decimal(20,8) NULL,
			i_last_order_qty	decimal(20,8) NULL,
			i_oe_on_order		decimal(20,8) NULL,
			i_oe_order_date		datetime NULL,
			i_sales_amt_mtd		decimal(20,8) NULL,
			i_sales_amt_ytd		decimal(20,8) NULL,
			i_hold_ord			decimal(20,8) NULL,
			d_part_no			varchar(30) NULL,
			d_location			varchar(10) NULL,
			d_qty_alloc			decimal(20,8) NULL,
			d_commit_ed			decimal(20,8) NULL,
			d_sales_qty_mtd		decimal(20,8) NULL,
			d_sales_qty_ytd		decimal(20,8) NULL,
			d_last_order_qty	decimal(20,8) NULL,
			d_oe_on_order		decimal(20,8) NULL,
			d_oe_order_date		datetime NULL,
			d_sales_amt_mtd		decimal(20,8) NULL,
			d_sales_amt_ytd		decimal(20,8) NULL,
			d_hold_ord			decimal(20,8) NULL)

		INSERT	#t700updinv (i_part_no, i_location, i_qty_alloc, i_commit_ed, i_sales_qty_mtd, i_sales_qty_ytd, i_last_order_qty, i_oe_on_order, 
					i_oe_order_date, i_sales_amt_mtd, i_sales_amt_ytd, i_hold_ord, d_part_no, d_location, d_qty_alloc, d_commit_ed, d_sales_qty_mtd, 
					d_sales_qty_ytd, d_last_order_qty, d_oe_on_order, d_oe_order_date, d_sales_amt_mtd, d_sales_amt_ytd, d_hold_ord)
		-- v1.2 DECLARE t700updinv__cursor CURSOR LOCAL STATIC FOR
		SELECT	i.part_no, i.location, i.qty_alloc, i.commit_ed, i.sales_qty_mtd, i.sales_qty_ytd,
				i.last_order_qty, i.oe_on_order, i.oe_order_date, i.sales_amt_mtd, i.sales_amt_ytd, i.hold_ord,
				d.part_no, d.location, d.qty_alloc, d.commit_ed, d.sales_qty_mtd, d.sales_qty_ytd,
				d.last_order_qty, d.oe_on_order, d.oe_order_date, d.sales_amt_mtd, d.sales_amt_ytd, d.hold_ord
		FROM	inserted i, deleted d
		WHERE	i.part_no = d.part_no 
		AND		i.location = d.location

		-- v1.2
		/*
		OPEN t700updinv__cursor
		FETCH NEXT FROM t700updinv__cursor into
		@i_part_no, @i_location, @i_qty_alloc, @i_commit_ed, @i_sales_qty_mtd, @i_sales_qty_ytd,
		@i_last_order_qty, @i_oe_on_order, @i_oe_order_date, @i_sales_amt_mtd, @i_sales_amt_ytd,
		@i_hold_ord,
		@d_part_no, @d_location, @d_qty_alloc, @d_commit_ed, @d_sales_qty_mtd, @d_sales_qty_ytd,
		@d_last_order_qty, @d_oe_on_order, @d_oe_order_date, @d_sales_amt_mtd, @d_sales_amt_ytd,
		@d_hold_ord
		*/

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@i_part_no = i_part_no, 
				@i_location = i_location, 
				@i_qty_alloc = i_qty_alloc, 
				@i_commit_ed = i_commit_ed, 
				@i_sales_qty_mtd = i_sales_qty_mtd, 
				@i_sales_qty_ytd = i_sales_qty_ytd, 
				@i_last_order_qty = i_last_order_qty, 
				@i_oe_on_order = i_oe_on_order, 
				@i_oe_order_date = i_oe_order_date, 
				@i_sales_amt_mtd = i_sales_amt_mtd, 
				@i_sales_amt_ytd = i_sales_amt_ytd, 
				@i_hold_ord = i_hold_ord, 
				@d_part_no = d_part_no, 
				@d_location = d_location, 
				@d_qty_alloc = d_qty_alloc, 
				@d_commit_ed = d_commit_ed, 
				@d_sales_qty_mtd = d_sales_qty_mtd, 
				@d_sales_qty_ytd = d_sales_qty_ytd, 
				@d_last_order_qty = d_last_order_qty, 
				@d_oe_on_order = d_oe_on_order, 
				@d_oe_order_date = d_oe_order_date, 
				@d_sales_amt_mtd = d_sales_amt_mtd, 
				@d_sales_amt_ytd = d_sales_amt_ytd, 
				@d_hold_ord = d_hold_ord
		FROM	#t700updinv
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
		
		-- v1.0 While @@FETCH_STATUS = 0
		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			IF (SELECT MIN(i.in_stock) FROM inv_list i (NOLOCK) -- v1.0 changed from inventory 
				WHERE @i_part_no = i.part_no AND @i_location = i.location AND i.status='K') < 0
			BEGIN
				INSERT prod_batch (prod_no, prod_ext, status, part_no, location, prod_date,
					qty, lot_ser, bin_no, project_key, batch_type, qc_flag, who_entered)
				SELECT	0, 0, 'S', @i_part_no, @i_location, getdate(),
						(i.in_stock * -1), 'N/A', 'N/A', 'N/A', 'A', 'N', 'AUTO-KIT'
				FROM	inventory i 
				WHERE	@i_part_no = i.part_no 
				AND		@i_location = i.location 
				AND		i.status = 'K' 
				AND		i.in_stock < 0
			END

			-- v1.0 Use tables instead of inventory view
			IF EXISTS (SELECT 1 FROM inv_master m (NOLOCK) JOIN	inv_list l (NOLOCK) ON m.part_no = l.part_no
						JOIN inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no
						JOIN inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no
						JOIN inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no
						JOIN inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no
						LEFT JOIN dbo.f_get_excluded_bins(4) z on l.location = z.location AND l.part_no = z.part_no
						WHERE	@i_part_no = l.part_no 
						AND		@i_location = l.location 
						AND		m.lb_tracking = 'Y' 
						AND		(case when (m.status='C' or m.status='V') then 0 else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd - isnull(z.qty,0))end) < 0)

			BEGIN
				ROLLBACK TRAN
				EXEC adm_raiserror 99888, 'You cannot ship more than is available for lot bin tracked items'
				RETURN
			END											-- mls 7/30/99 SCR 70 20175 end

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@i_part_no = i_part_no, 
					@i_location = i_location, 
					@i_qty_alloc = i_qty_alloc, 
					@i_commit_ed = i_commit_ed, 
					@i_sales_qty_mtd = i_sales_qty_mtd, 
					@i_sales_qty_ytd = i_sales_qty_ytd, 
					@i_last_order_qty = i_last_order_qty, 
					@i_oe_on_order = i_oe_on_order, 
					@i_oe_order_date = i_oe_order_date, 
					@i_sales_amt_mtd = i_sales_amt_mtd, 
					@i_sales_amt_ytd = i_sales_amt_ytd, 
					@i_hold_ord = i_hold_ord, 
					@d_part_no = d_part_no, 
					@d_location = d_location, 
					@d_qty_alloc = d_qty_alloc, 
					@d_commit_ed = d_commit_ed, 
					@d_sales_qty_mtd = d_sales_qty_mtd, 
					@d_sales_qty_ytd = d_sales_qty_ytd, 
					@d_last_order_qty = d_last_order_qty, 
					@d_oe_on_order = d_oe_on_order, 
					@d_oe_order_date = d_oe_order_date, 
					@d_sales_amt_mtd = d_sales_amt_mtd, 
					@d_sales_amt_ytd = d_sales_amt_ytd, 
					@d_hold_ord = d_hold_ord
			FROM	#t700updinv
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			-- v1.2 
			/*
			FETCH NEXT FROM t700updinv__cursor into
			@i_part_no, @i_location, @i_qty_alloc, @i_commit_ed, @i_sales_qty_mtd, @i_sales_qty_ytd,
			@i_last_order_qty, @i_oe_on_order, @i_oe_order_date, @i_sales_amt_mtd, @i_sales_amt_ytd,
			@i_hold_ord, @d_part_no, @d_location, @d_qty_alloc, @d_commit_ed, @d_sales_qty_mtd, @d_sales_qty_ytd,
			@d_last_order_qty, @d_oe_on_order, @d_oe_order_date, @d_sales_amt_mtd, @d_sales_amt_ytd, @d_hold_ord
			*/
		END -- while

		-- v1.2 CLOSE t700updinv__cursor
		-- v1.2 DEALLOCATE t700updinv__cursor

	END
END
GO
CREATE UNIQUE CLUSTERED INDEX [invl_ord1] ON [dbo].[inv_sales] ([part_no], [location]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_sales] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_sales] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_sales] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_sales] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_sales] TO [public]
GO
