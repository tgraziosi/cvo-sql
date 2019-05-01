CREATE TABLE [dbo].[ord_list]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[price] [decimal] (20, 8) NOT NULL,
[price_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_comm] [decimal] (20, 8) NOT NULL,
[temp_price] [decimal] (20, 8) NULL,
[temp_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_ordered] [decimal] (20, 8) NOT NULL,
[cr_shipped] [decimal] (20, 8) NOT NULL,
[discount] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__ord_list__void__3C2A3641] DEFAULT ('N'),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[cubic_feet] [decimal] (20, 8) NOT NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__ord_list__lb_tra__3D1E5A7A] DEFAULT ('N'),
[labor] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[taxable] [int] NULL,
[weight_ea] [decimal] (20, 8) NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__ord_list__qc_fla__3E127EB3] DEFAULT ('N'),
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[qc_no] [int] NULL CONSTRAINT [DF__ord_list__qc_no__3F06A2EC] DEFAULT ((0)),
[rejected] [decimal] (20, 8) NULL CONSTRAINT [DF__ord_list__reject__3FFAC725] DEFAULT ((0)),
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__ord_list__part_t__40EEEB5E] DEFAULT ('P'),
[orig_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gl_rev_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NOT NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_price] [decimal] (20, 8) NOT NULL,
[oper_price] [decimal] (20, 8) NOT NULL,
[display_line] [int] NOT NULL,
[std_direct_dolrs] [decimal] (20, 8) NULL,
[std_ovhd_dolrs] [decimal] (20, 8) NULL,
[std_util_dolrs] [decimal] (20, 8) NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[agreement_id] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[service_agreement_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_ord_list_service_agreement_flag] DEFAULT ('N'),
[inv_available_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ord_list_inv_available_flag] DEFAULT ('Y'),
[create_po_flag] [smallint] NULL,
[load_group_no] [int] NULL,
[return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_count] [int] NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[picked_dt] [datetime] NULL,
[who_picked_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed_dt] [datetime] NULL,
[who_unpicked_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unpicked_dt] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ord_list_insupddel] ON [dbo].[ord_list]	FOR INSERT, UPDATE, DELETE  AS 
BEGIN
	DECLARE @ord_no int, @ord_ext int
	DECLARE @data varchar(30)
	Declare @credit_return_flag char(1), @type char(1)	-- rev 3

	select @credit_return_flag = 'N'	-- assume it's not a credit return
	select @type = orders.type from orders_all orders, inserted 
		where orders.order_no = inserted.order_no and orders.ext = inserted.order_ext
	if @type = 'C' select @credit_return_flag = 'Y'
	   
	select @type = orders.type from orders_all orders, deleted 
		where orders.order_no = deleted.order_no and orders.ext = deleted.order_ext
	if @type = 'C' select @credit_return_flag = 'Y'

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%')
	BEGIN	--EAI enable

	   if (@credit_return_flag = 'N') begin		-- rev 3--can't be a credit return

		IF ((Exists( select *
			from inserted i, deleted d
			where (i.order_no <> d.order_no) or 
				(i.order_ext <> d.order_ext) or
				(i.line_no <> d.line_no) or 
				(i.part_no <> d.part_no) or 
				(i.description <> d.description) or 
				(i.part_type <> d.part_type) or 
				(i.ordered <> d.ordered) or 
				(i.uom <> d.uom) or 
				(i.conv_factor <> d.conv_factor) or 
				(i.weight_ea <> d.weight_ea) or 
				(i.cubic_feet <> d.cubic_feet) or 
				(i.back_ord_flag <> d.back_ord_flag) or 
				(i.status <> d.status) or 
				(i.price <> d.price) or 
				(i.discount <> d.discount) or 
				(i.cost <> d.cost) or 
				(i.tax_code <> d.tax_code) or 
				(i.taxable <> d.taxable) or 
				(i.location <> d.location) or 
				(i.gl_rev_acct <> d.gl_rev_acct) or 
				(i.note <> d.note) or 
				(i.time_entered <> d.time_entered) or 
				(i.who_entered <> d.who_entered))) 
			or (Not Exists(select 'X' from deleted))
			or (Not Exists(select 'X' from inserted)))
		BEGIN	--orders has been changed or new orders, send data to Front Office
			if (exists(select 'X' from inserted)) begin	-- insert or update
				select distinct @ord_no = order_no, @ord_ext = order_ext from inserted
				if exists(select @ord_no) and exists(select @ord_ext)
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)
				else
					select @data = '|'	-- rev 4
			end
			else begin	-- deleted 
				select distinct @ord_no = order_no, @ord_ext = order_ext from deleted
				if exists(select @ord_no) and exists(select @ord_ext)
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)
				else
					select @data = '|'	-- rev 4
			end

			if (@data <> '') and (@data <> '|') begin -- orders
				IF (Exists( SELECT 'X' FROM config  
	   				WHERE flag = 'EAI_SEND_SO_IMAGE' and value_str like 'Y%'))
				BEGIN	--Send SO Image that create from BO to FO
					-- Customized to avoid sending SOI for any with Misc Parts
					IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
					BEGIN
						exec EAI_process_insert 'SalesOrderImage', @data, 'BO'
					END
					-- End
				END
				ELSE --Check to see if the orders number is in EAI_ord_xref cross reference table 
				BEGIN
					IF (Exists (SELECT 'X' from EAI_ord_xref 
						WHERE	BO_order_no = @ord_no and
							BO_order_ext = @ord_ext))
					BEGIN
						-- Customized to avoid sending SOI for any with Misc Parts
						IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
						BEGIN
							exec EAI_process_insert 'SalesOrderImage', @data, 'BO'
						END
						-- End
					END
				END 	--End config for EAI_SEND_SO_IMAGE
			end	-- end while
		END	--End columns check
	   end	-- check for credit return
	END  --End EAI enable
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			ord_list_del_trg		
Type:			Trigger
Description:	When an ord_list record is deleted, delete the corresponding record from cvo_pattern_tracking if it exists
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	01/04/2011	Original Version
v1.1	CT	12/05/2011	If a Credit Return, also delete record from cvo_ord_list
v1.2	CT	05/11/2013	Issue #864 - If deleting an order line, remove it from drawdown promo tracking
*/

CREATE TRIGGER [dbo].[ord_list_del_trg] ON [dbo].[ord_list]
FOR DELETE
AS
BEGIN
	DECLARE	@order_no	int,
			@order_ext	int,
			@line_no	int

	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = order_no
		FROM 
			deleted 
		WHERE
			order_no > @order_no
		ORDER BY 
			order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @order_ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@order_ext = order_ext
			FROM 
				deleted 
			WHERE
				order_no = @order_no
				AND order_ext > @order_ext
			ORDER BY 
				order_ext

			IF @@RowCount = 0
				Break
		
			-- Loop through lines
			SET @line_no = 0
			WHILE 1=1
			BEGIN
			
				SELECT TOP 1 
					@line_no = line_no
				FROM 
					deleted 
				WHERE
					order_no = @order_no
					AND order_ext = @order_ext
					AND line_no > @line_no
				ORDER BY 
					line_no

				IF @@RowCount = 0
					Break

				-- Delete record from cvo_pattern_tracking
				DELETE FROM 
					cvo_pattern_tracking 
				WHERE 
					order_no = @order_no 
					AND order_ext = @order_ext 
					AND line_no = @line_no

				-- START v1.1
				IF EXISTS (SELECT 1 FROM dbo.orders_all WHERE order_no = @order_no and ext = @order_ext and type = 'C')
				BEGIN
					DELETE FROM 
						cvo_ord_list
					WHERE 
						order_no = @order_no 
						AND order_ext = @order_ext 
						AND line_no = @line_no
				END
				-- END v1.1

				-- START v1.2
				EXEC CVO_remove_debit_promo_line_sp @order_no, @order_ext, @line_no
				-- END v1.2
			END
		END

	END		
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			ord_list_ins_trg		
Type:			Trigger
Description:	When an ord_list record is inserted for a Credit Return, create a cvo_ord_list record
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	12/05/2011	Original Version
*/

CREATE TRIGGER [dbo].[ord_list_ins_trg] ON [dbo].[ord_list]
FOR INSERT
AS
BEGIN
	DECLARE	@order_no		int,
			@order_ext		int,
			@line_no		int,
			@orig_part_no	varchar(30),
			@part_no		varchar(30),
			@list_price		decimal (20,8),
			@orig_no		int,
			@orig_ext		int	

	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = order_no
		FROM 
			inserted 
		WHERE
			order_no > @order_no
		ORDER BY 
			order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @order_ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@order_ext = order_ext
			FROM 
				inserted 
			WHERE
				order_no = @order_no
				AND order_ext > @order_ext
			ORDER BY 
				order_ext

			IF @@RowCount = 0
				Break
		
			-- Only continue if this is a credit return
			IF EXISTS (SELECT 1 FROM dbo.orders_all (NOLOCK) WHERE order_no = @order_no and ext = @order_ext and type = 'C')
			BEGIN

				-- Loop through lines
				SET @line_no = 0
				WHILE 1=1
				BEGIN
				
					SELECT TOP 1 
						@line_no = line_no,
						@orig_part_no = orig_part_no,
						@part_no = part_no
					FROM 
						inserted 
					WHERE
						order_no = @order_no
						AND order_ext = @order_ext
						AND line_no > @line_no
					ORDER BY 
						line_no

					IF @@RowCount = 0
						Break

					-- If it's based on a SO (orig_part_no <> NULL), copy record, if not create it
					IF @orig_part_no IS NULL
					BEGIN
						-- Get list price
						SELECT 
							@list_price = b.price
						FROM
							dbo.adm_inv_price a (NOLOCK)
						INNER JOIN
							dbo.adm_inv_price_det b (NOLOCK)
						ON
							a.inv_price_id = b.inv_price_id
						WHERE
							a.part_no = @part_no
							AND b.p_level = 1
							AND a.active_ind = 1

						INSERT INTO cvo_ord_list (
							order_no,
							order_ext,
							line_no,
							list_price)
						SELECT
							@order_no,
							@order_ext,
							@line_no,
							ISNULL(@list_price,0)

					END
					ELSE
					BEGIN
						-- Get original order_no, ext
						SELECT 
							@orig_no = orig_no,
							@orig_ext = orig_ext
						FROM
							dbo.orders_all (NOLOCK)
						WHERE
							order_no = @order_no
							AND ext = @order_ext
						
						INSERT INTO cvo_ord_list (
							order_no,
							order_ext,
							line_no,
							add_case,
							add_pattern,
							from_line_no,
							is_case,
							is_pattern,
							add_polarized,
							is_polarized,
							is_pop_gif,
							is_amt_disc,
							amt_disc,
							is_customized,
							promo_item,
							list_price)
						SELECT
							@order_no,
							@order_ext,
							@line_no,
							add_case,
							add_pattern,
							from_line_no,
							is_case,
							is_pattern,
							add_polarized,
							is_polarized,
							is_pop_gif,
							is_amt_disc,
							amt_disc,
							is_customized,
							promo_item,
							list_price
						FROM
							cvo_ord_list (NOLOCK)
						WHERE
							order_no = @orig_no
							AND order_ext = @orig_ext
							AND line_no = @line_no
					END
				END
			END
		END

	END		
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t700delordl] ON [dbo].[ord_list] FOR DELETE AS 
BEGIN
declare @retval int
declare 
  @qty decimal(20,8), @account varchar(10), 
  @tran_date datetime, @tran_age datetime, @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),
  @labor decimal(20,8), @utility decimal(20,8),
  @multi_flag char(1), -- RLT 5/20/00
  @order_qty decimal(20,8),
  @new_qty decimal(20,8), -- RLT 5/20/00
  @orig_order_no int, @orig_order_ext int,
  @orders_load_no int, @load_master_status char(1), @msg varchar(255)  ,
  @rc int, @mtd_qty decimal(20,8), @mtd_amt decimal(20,8)

DECLARE @d_order_no int, @d_order_ext int, @d_line_no int, @d_location varchar(10),
@d_part_no varchar(30), @d_description varchar(255), @d_time_entered datetime,
@d_ordered decimal(20,8), @d_shipped decimal(20,8), @d_price decimal(20,8),
@d_price_type char(1), @d_note varchar(255), @d_status char(1), @d_cost decimal(20,8),
@d_who_entered varchar(20), @d_sales_comm decimal(20,8), @d_temp_price decimal(20,8),
@d_temp_type char(1), @d_cr_ordered decimal(20,8), @d_cr_shipped decimal(20,8),
@d_discount decimal(20,8), @d_uom char(2), @d_conv_factor decimal(20,8), @d_void char(1),
@d_void_who varchar(20), @d_void_date datetime, @d_std_cost decimal(20,8),
@d_cubic_feet decimal(20,8), @d_printed char(1), @d_lb_tracking char(1), @d_labor decimal(20,8),
@d_direct_dolrs decimal(20,8), @d_ovhd_dolrs decimal(20,8), @d_util_dolrs decimal(20,8),
@d_taxable int, @d_weight_ea decimal(20,8), @d_qc_flag char(1), @d_reason_code varchar(10),
@d_row_id int, @d_qc_no int, @d_rejected decimal(20,8), @d_part_type char(1),
@d_orig_part_no varchar(30), @d_back_ord_flag char(1), @d_gl_rev_acct varchar(32),
@d_total_tax decimal(20,8), @d_tax_code varchar(10), @d_curr_price decimal(20,8),
@d_oper_price decimal(20,8), @d_display_line int, @d_std_direct_dolrs decimal(20,8),
@d_std_ovhd_dolrs decimal(20,8), @d_std_util_dolrs decimal(20,8), @d_reference_code varchar(32),
@d_contract varchar(16), @d_agreement_id varchar(32), @d_ship_to varchar(10),
@d_service_agreement_flag char(1), @d_inv_available_flag char(1), @d_create_po_flag smallint,
@d_load_group_no int, @d_return_code varchar(10), @d_user_count int

if exists (select * from config where flag='TRIG_DEL_ORDL' and value_str='DISABLE')
  return

DECLARE t700delord__cursor CURSOR LOCAL STATIC FOR
SELECT d.order_no, d.order_ext, d.line_no, d.location, d.part_no, d.description, d.time_entered,
d.ordered, d.shipped, d.price, d.price_type, d.note, d.status, d.cost, d.who_entered,
d.sales_comm, d.temp_price, d.temp_type, d.cr_ordered, d.cr_shipped, d.discount, d.uom,
d.conv_factor, d.void, d.void_who, d.void_date, d.std_cost, d.cubic_feet, d.printed,
d.lb_tracking, d.labor, d.direct_dolrs, d.ovhd_dolrs, d.util_dolrs, d.taxable, d.weight_ea,
d.qc_flag, d.reason_code, d.row_id, d.qc_no, d.rejected, d.part_type, d.orig_part_no,
d.back_ord_flag, d.gl_rev_acct, d.total_tax, d.tax_code, d.curr_price, d.oper_price,
d.display_line, d.std_direct_dolrs, d.std_ovhd_dolrs, d.std_util_dolrs, d.reference_code,
d.contract, d.agreement_id, d.ship_to, d.service_agreement_flag, d.inv_available_flag,
d.create_po_flag, d.load_group_no, d.return_code, d.user_count
from deleted d

OPEN t700delord__cursor

IF @@CURSOR_ROWS = 0 
begin
  CLOSE t700delord__cursor
  DEALLOCATE t700delord__cursor
  return
end

FETCH NEXT FROM t700delord__cursor into
@d_order_no, @d_order_ext, @d_line_no, @d_location, @d_part_no, @d_description, @d_time_entered,
@d_ordered, @d_shipped, @d_price, @d_price_type, @d_note, @d_status, @d_cost, @d_who_entered,
@d_sales_comm, @d_temp_price, @d_temp_type, @d_cr_ordered, @d_cr_shipped, @d_discount, @d_uom,
@d_conv_factor, @d_void, @d_void_who, @d_void_date, @d_std_cost, @d_cubic_feet, @d_printed,
@d_lb_tracking, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs, @d_taxable,
@d_weight_ea, @d_qc_flag, @d_reason_code, @d_row_id, @d_qc_no, @d_rejected, @d_part_type,
@d_orig_part_no, @d_back_ord_flag, @d_gl_rev_acct, @d_total_tax, @d_tax_code, @d_curr_price,
@d_oper_price, @d_display_line, @d_std_direct_dolrs, @d_std_ovhd_dolrs, @d_std_util_dolrs,
@d_reference_code, @d_contract, @d_agreement_id, @d_ship_to, @d_service_agreement_flag,
@d_inv_available_flag, @d_create_po_flag, @d_load_group_no, @d_return_code, @d_user_count

While @@FETCH_STATUS = 0
begin
  if @d_status >= 'S'
  begin
		rollback tran
		exec adm_raiserror 74131 ,'You Can NOT Delete An Order Item That Is Picked, Shipped Or Voided!'
		return
  end
  if @d_shipped > 0
  begin
		rollback tran
		exec adm_raiserror 74133, 'You Can NOT Delete An Order Item That Is Picked, Shipped Or Voided!'
		return
  end

  if @d_status >= 'R' and @d_status < 'V' and @d_qc_flag = 'Y'
  BEGIN
	rollback tran
	exec adm_raiserror 74134 ,'You Can NOT DELETE An Order Item That Is In QC Check!'
	return
  END

  select @orders_load_no = isnull((select load_no
  from orders (nolock)
  where order_no = @d_order_no and ext = @d_order_ext),0)

  if @orders_load_no != 0
  begin
    select @load_master_status = isnull((select status from load_master_all (nolock)
      where load_no = @orders_load_no),'N')
    if @load_master_status = 'H'
    begin
      select @msg = 'This order is on a Shipment that is in User Hold.  No changes are allowed until the '
      select @msg = @msg + 'shipment is removed from User Hold.'
      rollback tran
      exec adm_raiserror 74112, @msg
      RETURN
    end
    if @load_master_status = 'C'
    begin
      select @msg = 'This order is on a Shipment that is in Credit Hold.  No changes are allowed until the '
      select @msg = @msg + 'shipment is removed from Credit Hold.'
      rollback tran
      exec adm_raiserror 74113, @msg
      RETURN
    end
  end												-- #34 end

  
  if @d_location like 'DROP%' or @d_create_po_flag = 1
  begin
    delete orders_auto_po 
    where order_no= @d_order_no and line_no= @d_line_no and status='N'
	
    if exists (select 1 from orders_auto_po o (nolock)
    where o.order_no= @d_order_no and o.line_no= @d_line_no and o.status > 'N')
    begin
      rollback tran
      exec adm_raiserror 74135 ,'You Can NOT Delete An Order Item That Is In Auto Purchased - Contact Purchasing!'
      return
    end 
  end 

  if (@d_status='N' or @d_status='P' or @d_status='Q' or @d_status='R') and
    ((@d_ordered - @d_shipped) > 0) and 					-- mls 7/21/99 SCR 70 19992
    @d_part_type='P' 
  begin
    update inv_sales 
    set commit_ed=(commit_ed - ((@d_ordered - @d_shipped) * @d_conv_factor))
    where @d_part_no=inv_sales.part_no and @d_location=inv_sales.location
  end

  if (@d_status='Q' or @d_status='P' or (@d_status='R' and @d_cr_shipped = 0)) and @d_part_type='P'
  begin
    update inv_sales 
    set hold_ord=(hold_ord - ((@d_shipped + @d_cr_shipped) * @d_conv_factor))
    where (@d_part_no=inv_sales.part_no) and (@d_location=inv_sales.location) 
  end

  if ((@d_shipped != 0 and (@d_status = 'R' or @d_status = 'Q' or @d_status='P')) 
    OR (@d_cr_shipped != 0 and @d_status='R')) and @d_qc_flag != 'Y' and
    (@d_part_type='P' or @d_part_type='C')
  begin
    update inv_sales 
    set sales_qty_mtd=sales_qty_mtd - ((@d_shipped - @d_cr_shipped) * @d_conv_factor),
	sales_qty_ytd=sales_qty_ytd - ((@d_shipped - @d_cr_shipped) * @d_conv_factor),
	sales_amt_mtd=sales_amt_mtd - ((@d_shipped - @d_cr_shipped) * @d_price),
	sales_amt_ytd=sales_amt_ytd - ((@d_shipped - @d_cr_shipped) * @d_price)
    where (@d_part_no=inv_sales.part_no) and (@d_location=inv_sales.location)

      -- mls 1/18/05 SCR 34050
      select @mtd_qty = -((@d_shipped - @d_cr_shipped) * @d_conv_factor),
        @mtd_amt = -((@d_shipped - @d_cr_shipped) * @d_price)
      exec @rc = adm_inv_mtd_upd @d_part_no, @d_location, 'S', @mtd_qty, @mtd_amt
      if @rc < 1
      begin
        select @msg = 'Error (' + convert(varchar,@rc) + ') returned from adm_inv_mtd_upd'
        rollback tran
        exec adm_raiserror 9910141, @msg
        return
      end

  end

  delete lot_bin_ship 
  where lot_bin_ship.tran_no=@d_order_no and 
    lot_bin_ship.tran_ext=@d_order_ext and	
    lot_bin_ship.line_no=@d_line_no and
    lot_bin_ship.part_no=@d_part_no and
    lot_bin_ship.location=@d_location

  delete ord_list_kit
  where order_no = @d_order_no and order_ext = @d_order_ext and line_no = @d_line_no

  /*START: AMENDEZ, 06/10/2010, 68668-FOC-001 Custom Frame Build*/
  delete cvo_ord_list_kit
  where order_no = @d_order_no and order_ext = @d_order_ext and line_no = @d_line_no
  /*END: AMENDEZ, 06/10/2010, 68668-FOC-001 Custom Frame Build*/

  if ((@d_status = 'Q' OR @d_status = 'P') and @d_cr_shipped > 0 and @d_lb_tracking='N' and @d_qc_flag='Y')
  begin
    update qc_results 
    set status='V', qc_qty=0 
    where qc_no=@d_qc_no 
  end

  -- this logic is for multi ship to's.  What this does is delete the amout from the original order, if that order is a
  -- back order it will keep deleting until it finds the orginal order. --RLT 5/23/00
  IF (@d_order_ext > 0)
  BEGIN
    SELECT @multi_flag = multiple_flag from orders (nolock) where order_no = @d_order_no and ext = 0 -- skk 05/25/00
    IF (@multi_flag = 'Y') -- skk 05/25/00
    BEGIN
      SELECT @orig_order_no = orig_no, @orig_order_ext = orig_ext 
      from orders (nolock) where order_no = @d_order_no and ext = @d_order_ext
      IF (@orig_order_no <> 0)
      BEGIN
        SELECT @order_qty = ordered 
        from ord_list (nolock)
        where order_no = @orig_order_no and order_ext = @orig_order_ext
	and part_no = @d_part_no and ship_to = @d_ship_to and location = @d_location
        SELECT @new_qty = @order_qty - @d_ordered
	UPDATE ord_list 
        set ordered = @new_qty 
        where order_no = @orig_order_no and order_ext = @orig_order_ext and part_no = @d_part_no 
          and ship_to = @d_ship_to and location = @d_location
	if @new_qty = 0
	delete ord_list
        where order_no = @orig_order_no and order_ext = @orig_order_ext and part_no = @d_part_no 
          and ship_to = @d_ship_to and location = @d_location and ordered = 0 and shipped = 0
      END
    END 
  END 

  declare @tdc_rtn int, @stat varchar(10)

  SELECT @qty=( (@d_shipped - @d_cr_shipped) * @d_conv_factor) ,
    @stat = 'ORDL_DEL'

  exec @tdc_rtn = tdc_order_list_change @d_order_no, @d_order_ext, @d_line_no, @d_part_no, @qty, @stat

  if (@tdc_rtn< 0 )
  begin
   exec adm_raiserror 74900 ,'Invalid Inventory Update From TDC.'
  end

FETCH NEXT FROM t700delord__cursor into
@d_order_no, @d_order_ext, @d_line_no, @d_location, @d_part_no, @d_description, @d_time_entered,
@d_ordered, @d_shipped, @d_price, @d_price_type, @d_note, @d_status, @d_cost, @d_who_entered,
@d_sales_comm, @d_temp_price, @d_temp_type, @d_cr_ordered, @d_cr_shipped, @d_discount, @d_uom,
@d_conv_factor, @d_void, @d_void_who, @d_void_date, @d_std_cost, @d_cubic_feet, @d_printed,
@d_lb_tracking, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs, @d_taxable,
@d_weight_ea, @d_qc_flag, @d_reason_code, @d_row_id, @d_qc_no, @d_rejected, @d_part_type,
@d_orig_part_no, @d_back_ord_flag, @d_gl_rev_acct, @d_total_tax, @d_tax_code, @d_curr_price,
@d_oper_price, @d_display_line, @d_std_direct_dolrs, @d_std_ovhd_dolrs, @d_std_util_dolrs,
@d_reference_code, @d_contract, @d_agreement_id, @d_ship_to, @d_service_agreement_flag,
@d_inv_available_flag, @d_create_po_flag, @d_load_group_no, @d_return_code, @d_user_count
end -- while

CLOSE t700delord__cursor
DEALLOCATE t700delord__cursor

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE TRIGGER [dbo].[t700insordl] 
ON [dbo].[ord_list] 
FOR INSERT   
AS
BEGIN    
   
	DECLARE	@i_order_no				int,  
			@i_order_ext			int,  
			@i_line_no				int,  
			@i_location				varchar(10),  
			@i_part_no				varchar(30),  
			@i_ordered				decimal(20,8),  
			@i_shipped				decimal(20,8),  
			@i_price				decimal(20,8),  
			@i_status				char(1),  
			@i_cost					decimal(20,8),  
			@i_who_entered			varchar(50),  
			@i_cr_ordered			decimal(20,8),  
			@i_cr_shipped			decimal(20,8),  
			@i_uom					char(2),  
			@i_conv_factor			decimal(20,8),  
			@i_lb_tracking			char(1),  
			@i_labor				decimal(20,8),  
			@i_direct_dolrs			decimal(20,8),  
			@i_ovhd_dolrs			decimal(20,8),  
			@i_util_dolrs			decimal(20,8),  
			@i_qc_flag				char(1),  
			@i_reason_code			varchar(10),  
			@i_row_id				int ,  
			@i_part_type			char(1),  
			@i_gl_rev_acct			varchar(32),  
			@i_tax_code				varchar(10),  
			@i_ship_to				varchar(10),  
			@i_create_po_flag		int,   
			@i_load_group_no		int,  
			@i_return_code			varchar(10),  
			@i_user_count			int,  
			@i_organization_id		varchar(30),  
			@company_id				int,  
			@line_no				int,
			@stock_account			varchar(10), 
			@qc_account				varchar(10),  
			@org_id					varchar(30),  
			@retval					int, 
			@vend					varchar(10),
			@qty					decimal(20,8),
			@account				varchar(10),  
			@tran_date				datetime, 
			@tran_age				datetime, 
			@unitcost				decimal(20,8), 
			@direct					decimal(20,8), 
			@overhead				decimal(20,8),  
			@labor					decimal(20,8), 
			@utility				decimal(20,8),  
			@jobno					int, 
			@jrow					int, 
			@jqty					decimal(20,8), 
			@prodqty				decimal(20,8),  
			@i_is_sales_qty			decimal(20,8), 
			@d_is_hold_ord			decimal(20,8),  
			@a_tran_qty				decimal(20,8),		
			@a_unitcost				decimal(20,8), 
			@a_direct				decimal(20,8), 
			@a_overhead				decimal(20,8),  
			@a_utility				decimal(20,8), 
			@date_shipped			datetime, 
			@a_tran_data			varchar(255), 
			@a_labor				decimal(20,8),  
			@a_tran_id				int, 
			@COGS					int, 
			@in_stock				decimal(20,8),  
			@orders_eprocurement_ind int,  
			@orders_load_no			int, 
			@load_master_status		char(1), 
			@msg					varchar(255),
			@orders_type			char(1), 
			@orders_module			varchar(10),  
			@last_tax_code			varchar(10),  
			@rc						int, 
			@mtd_qty				decimal(20,8), 
			@mtd_amt				decimal(20,8),  
			@inv_org_id				varchar(30), 
			@orders_org_id			varchar(30),
			@tdc_rtn				int, 
			@stat					varchar(10)  

	DECLARE	@row_id					int,
			@last_row_id			int

	IF EXISTS (SELECT 1 FROM config (NOLOCK) WHERE flag = 'TRIG_INS_ORDL' AND value_str = 'DISABLE') RETURN  
  
	SELECT	@company_id = NULL,  
			@last_tax_code = '!@#$'  
  
	-- v1.0 Start
	CREATE TABLE #t700insordl (
		row_id					int IDENTITY(1,1),
		i_order_no				int NULL,  
		i_order_ext				int NULL,  
		i_line_no				int NULL,  
		i_location				varchar(10) NULL,  
		i_part_no				varchar(30) NULL,  
		i_ordered				decimal(20,8) NULL,  
		i_shipped				decimal(20,8) NULL,  
		i_price					decimal(20,8) NULL,  
		i_status				char(1) NULL,  
		i_cost					decimal(20,8) NULL,  
		i_who_entered			varchar(50) NULL,  
		i_cr_ordered			decimal(20,8) NULL,  
		i_cr_shipped			decimal(20,8) NULL,  
		i_uom					char(2) NULL,  
		i_conv_factor			decimal(20,8) NULL,  
		i_lb_tracking			char(1) NULL,  
		i_labor					decimal(20,8) NULL,  
		i_direct_dolrs			decimal(20,8) NULL,  
		i_ovhd_dolrs			decimal(20,8) NULL,  
		i_util_dolrs			decimal(20,8) NULL,  
		i_qc_flag				char(1) NULL,  
		i_reason_code			varchar(10) NULL,  
		i_row_id				int  NULL,  
		i_part_type				char(1) NULL,  
		i_gl_rev_acct			varchar(32) NULL,  
		i_tax_code				varchar(10) NULL,  
		i_ship_to				varchar(10) NULL,  
		i_create_po_flag		int NULL,   
		i_load_group_no			int NULL,  
		i_return_code			varchar(10) NULL,  
		i_user_count			int NULL,  
		i_organization_id		varchar(30) NULL) 

	INSERT #t700insordl (i_order_no, i_order_ext, i_line_no, i_location, i_part_no, i_ordered, i_shipped, i_price, i_status, i_cost, i_who_entered,
						i_cr_ordered, i_cr_shipped, i_uom, i_conv_factor, i_lb_tracking, i_labor, i_direct_dolrs, i_ovhd_dolrs, i_util_dolrs, i_qc_flag, 
						i_reason_code, i_row_id, i_part_type, i_gl_rev_acct, i_tax_code, i_ship_to, i_create_po_flag, i_load_group_no, i_return_code, 
						i_user_count, i_organization_id)
	SELECT	order_no, order_ext, line_no, location, part_no, ordered, shipped, price, status, cost, who_entered, cr_ordered, cr_shipped, uom, conv_factor, 
			lb_tracking, labor, direct_dolrs, ovhd_dolrs, util_dolrs, qc_flag, reason_code, row_id, part_type, gl_rev_acct, tax_code, ship_to, create_po_flag,    
			load_group_no, return_code, user_count, ISNULL(organization_id,'')  
	FROM	inserted  
	ORDER BY order_no, order_ext, line_no

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@i_order_no = i_order_no, 
			@i_order_ext = i_order_ext, 
			@i_line_no = i_line_no, 
			@i_location = i_location, 
			@i_part_no = i_part_no, 
			@i_ordered = i_ordered, 
			@i_shipped = i_shipped, 
			@i_price = i_price, 
			@i_status = i_status, 
			@i_cost = i_cost, 
			@i_who_entered = i_who_entered,
			@i_cr_ordered = i_cr_ordered, 
			@i_cr_shipped = i_cr_shipped, 
			@i_uom = i_uom, 
			@i_conv_factor = i_conv_factor, 
			@i_lb_tracking = i_lb_tracking, 
			@i_labor = i_labor, 
			@i_direct_dolrs = i_direct_dolrs, 
			@i_ovhd_dolrs = i_ovhd_dolrs, 
			@i_util_dolrs = i_util_dolrs, 
			@i_qc_flag = i_qc_flag, 
			@i_reason_code = i_reason_code, 
			@i_row_id = i_row_id, 
			@i_part_type = i_part_type, 
			@i_gl_rev_acct = i_gl_rev_acct, 
			@i_tax_code = i_tax_code, 
			@i_ship_to = i_ship_to, 
			@i_create_po_flag = i_create_po_flag, 
			@i_load_group_no = i_load_group_no, 
			@i_return_code = i_return_code, 
			@i_user_count = i_user_count, 
			@i_organization_id = i_organization_id
	FROM	#t700insordl
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE(@@ROWCOUNT <> 0)
	BEGIN			

		SELECT	@orders_load_no = load_no,   
				@orders_type = type,  
				@orders_org_id = organization_id,  
				@orders_module = CASE WHEN TYPE = 'I' THEN 'soe' ELSE 'cm' END,  
				@orders_eprocurement_ind = ISNULL(eprocurement_ind,0)  
		FROM	orders_all (NOLOCK)  
		WHERE	order_no = @i_order_no 
		AND		ext = @i_order_ext  
  
		IF (@@ROWCOUNT = 0)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84101 ,'Primary key values not found in table dbo.orders.  The transaction is being rolled back.'  
			RETURN  
		END  
  
		IF (@i_organization_id = '')
		BEGIN  
			UPDATE	ord_list  
			SET		organization_id = 'CVO',  
					gl_rev_acct = CASE WHEN @orders_eprocurement_ind = 0 THEN dbo.adm_mask_acct_fn (gl_rev_acct, 'CVO') ELSE gl_rev_acct END  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no 
		END  
   
		IF (@company_id is NULL)  
		BEGIN  
			SELECT	@company_id = company_id FROM glco (NOLOCK)  
			SELECT	@stock_account = ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag = 'INV_STOCK_ACCOUNT'),'STOCK')  
			SELECT	@qc_account = ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag = 'QC_STOCK_ACCOUNT'),'QC')  
		END  
  
		IF (ISNULL(@i_tax_code,'') != @last_tax_code)
		BEGIN  
			IF (ISNULL(@i_tax_code,'') != '')  
			BEGIN  
				IF NOT EXISTS (SELECT 1 FROM artax (NOLOCK) WHERE tax_code = @i_tax_code and module_flag != 1)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 941333 ,'Tax code not defined for use with Accounts Receivable'  
					RETURN  
				END  
			END  
			ELSE  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 941334, 'Tax code not defined'  
				RETURN  
			END  
			SELECT @last_tax_code = ISNULL(@i_tax_code,'')  
		END  
  
		IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @i_order_no AND ext = @i_order_ext)   
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84101, 'Order Header Missing.  The transaction is being rolled back.'  
			RETURN  
		END  
  
		IF (@i_part_type = 'M' AND ISNULL(@i_lb_tracking,'') = '')  
		BEGIN  
			UPDATE	ord_list  
			SET		lb_tracking = 'N'  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no  
			AND		ISNULL(lb_tracking,'') = ''  
    
			SET @i_lb_tracking = 'N'  
		END  
  
		IF (@i_status != 'E' and @i_part_type = 'P')   
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM inv_sales (NOLOCK) WHERE part_no = @i_part_no AND location = @i_location)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 84103 ,'Inventory Part Missing.  The transaction is being rolled back.'  
				RETURN  
			END  
		END  
  
		IF NOT EXISTS (SELECT 1 FROM adm_glchart_all (NOLOCK) WHERE account_code = @i_gl_rev_acct)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94105, 'The revenue account code for one of the lines on this order is invalid for the user. The transaction cannot be completed.'  
			RETURN  
		END  
  
		IF EXISTS (SELECT 1 FROM adm_glchart_all (NOLOCK) WHERE inactive_flag = 1 AND account_code = @i_gl_rev_acct)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94105, 'The revenue account code for one of the lines on this order is inactive. The transaction cannot be completed.'  
			RETURN  
		END  
		  
		IF (@i_status >= 'S')
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84131, 'You Can NOT ADD To An Order Item That Is Shipped Or Voided!'  
			RETURN  
		END  
  
		IF (@i_status >= 'R' and @i_qc_flag = 'Y')  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84132, 'You Can NOT Ship/Close An Order Item That Is In QC Check!'  
			RETURN  
		END  
  
		IF (@i_order_ext > 0)  
		BEGIN  
			IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE ext = 0 AND order_no = @i_order_no AND status ='M')   
			BEGIN  
				IF NOT EXISTS(SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @i_order_no AND part_no = @i_part_no 
							AND status = 'M' AND order_ext = 0 AND line_no = @i_line_no)
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 84133 ,'You Can NOT Insert A New Part On Blanket Release That Does NOT Exist In Blanket Master!'  
					RETURN  
				END  
			END  
		END  
  
		IF (@i_part_type = 'C')  
		BEGIN  
			UPDATE	ord_list_kit  
			SET		location = @i_location  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no 
			AND		location != @i_location  
		END  
   
		IF (@i_status >= 'P' AND @i_part_type = 'E')  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84135 ,'You Can NOT Pick/Ship An Order Item That Is An Estimate - Create A Job First.'  
			RETURN  
		END  
  
		IF (@i_location LIKE 'DROP%' OR @i_create_po_flag = 1)  
		BEGIN  
			IF (@i_part_type NOT IN ('M','P','V') OR EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @i_part_no AND status = 'C'))  
            BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 84136, 'You Can NOT Dropship A Kit Item!'  
				RETURN  
			END  
		END  
  
		IF (@i_part_type = 'J' AND @i_shipped > 0)  
		BEGIN  
			SELECT @jobno = CONVERT(int, @i_part_no)  
			SELECT @prodqty = ISNULL((SELECT qty FROM produce_all (NOLOCK) WHERE prod_no = @jobno),0)  
  
			IF (@prodqty = 0)   
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 193081 ,'You Can NOT ship a job that has no completed quantity.'  
				RETURN  
			END  
  
			IF (@prodqty != @i_shipped)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 193082 ,'You Can NOT ship a quantity different than what was produced for the job.'  
				RETURN  
			END  
		END  
  
		IF (@i_line_no = 0)  
		BEGIN  
			UPDATE	ord_list   
			SET		line_no = 1 + (SELECT (MAX(line_no)) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no)  
			WHERE	order_no = @i_order_no 
			AND		row_id = @i_row_id 
			AND		order_ext = @i_order_ext 
			AND		line_no = 0  
  
			SELECT	@i_line_no = line_no  
			FROM	ord_list (NOLOCK)  
			WHERE	order_no = @i_order_no 
			AND		row_id = @i_row_id 
			AND		order_ext = @i_order_ext   
		END  
   
		IF ((@i_location LIKE 'DROP%' OR @i_create_po_flag = 1) AND (@i_status BETWEEN 'N' AND 'R') AND @i_ordered != 0)  
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM orders_auto_po (NOLOCK) WHERE order_no = @i_order_no AND part_no = @i_part_no
							AND line_no = @i_line_no)
			BEGIN  
				INSERT	orders_auto_po (location, part_no, order_no, line_no, qty, status, req_ship_date, part_type)  
				SELECT	@i_location, @i_part_no, @i_order_no, @i_line_no, (@i_ordered * @i_conv_factor), 'N', req_ship_date, @i_part_type  
				FROM	orders_all (NOLOCK)  
				WHERE	order_no = @i_order_no 
				AND		ext = @i_order_ext  
			END  
		END   
   
		IF (@i_part_type = 'P')  
		BEGIN  
			SELECT @i_is_sales_qty = ISNULL((SELECT CASE WHEN ((@i_shipped != 0 AND @i_status IN ('P','Q','R','S')) OR (@i_cr_shipped != 0 AND @i_status = 'S')) AND @i_qc_flag != 'Y'
												THEN ((@i_shipped - @i_cr_shipped)) ELSE 0 END),0)  
  
			SELECT @d_is_hold_ord = 0  
  
			SELECT @a_tran_qty = - @i_is_sales_qty  
  
			IF (@a_tran_qty != 0)  
			BEGIN  
				SELECT	@a_unitcost= @i_cost / @i_conv_factor,         
						@a_direct= @i_direct_dolrs / @i_conv_factor,   
						@a_overhead= @i_ovhd_dolrs / @i_conv_factor,   
						@a_utility= @i_util_dolrs / @i_conv_factor,  
						@a_labor = @i_labor / @i_conv_factor,  
						@date_shipped = getdate()  
  
				SELECT	@a_tran_data = @i_part_type + CONVERT(varchar(30),@d_is_hold_ord) + REPLICATE(' ',30 - DATALENGTH(CONVERT(varchar(30),@d_is_hold_ord)))  
  
				EXEC @retval = adm_inv_tran 'S', @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @date_shipped, @i_uom,   
									@i_conv_factor, @i_status, @a_tran_data, DEFAULT, @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,  
									@COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT  
				IF (@retval <> 1)  
				BEGIN  
					ROLLBACK TRAN  
					SELECT @msg = 'Error ([' + CONVERT(varchar(10), @retval) + ']) returned from adm_inv_tran.'  
					EXEC adm_raiserror 83202, @msg  
					RETURN  
				END  
			END  
  
			IF (@i_status IN ('N','P','Q','R') AND ((@i_ordered - @i_shipped) > 0))
			BEGIN  
				UPDATE	inv_sales WITH (ROWLOCK) -- v1.1
				SET		commit_ed=commit_ed + ((@i_ordered - @i_shipped) * @i_conv_factor)  
				WHERE	part_no = @i_part_no 
				AND		location = @i_location  
			END  
  
			IF (@i_status in ('P','Q','R') and @i_shipped != 0)
			BEGIN  
				UPDATE	inv_sales WITH (ROWLOCK) -- v1.1
				SET		hold_ord=(hold_ord + (@i_shipped * @i_conv_factor)) 
				WHERE	part_no = @i_part_no and location = @i_location  
			END  
  
			IF (@i_status in ('P','Q','R') and @i_cr_shipped != 0) 
			BEGIN  
				UPDATE	inv_sales WITH (ROWLOCK) -- v1.1
				SET		qty_alloc = (qty_alloc + (@i_cr_shipped * @i_conv_factor))
				WHERE	part_no = @i_part_no 
				AND		location = @i_location  
			END  
  
			IF (@i_is_sales_qty != 0)  
			BEGIN  
				UPDATE	inv_sales WITH (ROWLOCK) -- v1.1
				SET		sales_qty_mtd = sales_qty_mtd + (@i_is_sales_qty * @i_conv_factor),  
						sales_qty_ytd = sales_qty_ytd + (@i_is_sales_qty * @i_conv_factor),  
						sales_amt_mtd = sales_amt_mtd + (@i_is_sales_qty * @i_price),  
						sales_amt_ytd = sales_amt_ytd + (@i_is_sales_qty * @i_price)  
				WHERE	part_no = @i_part_no 
				AND		location = @i_location  
  
				SELECT	@mtd_qty = (@i_is_sales_qty * @i_conv_factor),  
						@mtd_amt = (@i_is_sales_qty * @i_price)  
				
				EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @mtd_qty, @mtd_amt  
				IF (@rc < 1)  
				BEGIN  
					SELECT @msg = 'Error ([' + CONVERT(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 84137, @msg  
					RETURN  
				END  
			END  
		END 
   
		SELECT	@account = @stock_account  

		IF (@i_status IN ('Q','P') AND @i_cr_shipped > 0 AND @i_lb_tracking = 'N' AND @i_qc_flag = 'Y')  
		BEGIN  
			SELECT	@account = @qc_account,  
					@qty = (@i_cr_shipped * @i_conv_factor),  
					@tran_date = GETDATE(), 
					@tran_age = GETDATE()  
  
			SELECT	@unitcost = avg_cost, 
					@direct = avg_direct_dolrs, 
					@overhead = avg_ovhd_dolrs,  
					@labor = labor, 
					@utility = avg_util_dolrs  
			FROM	inv_list (NOLOCK)  
			WHERE	part_no = @i_part_no 
			AND		location = @i_location  
  
			SELECT	@vend = vendor 
			FROM	inv_master (NOLOCK) 
			WHERE	part_no = @i_part_no  
  
			EXEC fs_enter_qc 'C', @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @i_location, null, null, @qty, @vend, @i_who_entered, @i_reason_code, null  
  
			EXEC @retval = fs_cost_insert @i_part_no, @i_location, @qty, 'S', @i_order_no, @i_order_ext, @i_line_no,  
									@account, @tran_date, @tran_age, @unitcost , @direct , @overhead , @labor , @utility   
  
			IF (@retval = 0)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 84123 ,'Costing Error... Try Re-Saving!'  
				RETURN  
			END   
		END   

		IF (@i_order_ext > 0)  
		BEGIN  
			IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @i_order_no AND ext = @i_order_ext AND multiple_flag = 'Y')  
			BEGIN  
				SELECT	@line_no = line_no   
				FROM	ord_list (NOLOCK)  
				WHERE	order_no = @i_order_no  
				AND		order_ext = 0 
				AND		part_no = @i_part_no    
				AND		ship_to = @i_ship_to  
				AND		location = @i_location   
	   
				INSERT	ord_list_kit (order_no , order_ext , line_no ,  location , part_no , part_type , ordered , shipped , status , lb_tracking , cr_ordered , cr_shipped ,   
							uom , conv_factor , cost , labor , direct_dolrs , ovhd_dolrs , util_dolrs , note , qty_per , qc_flag , qc_no , description )  
				SELECT	@i_order_no , @i_order_ext , @i_line_no , @i_location , k.part_no , k.part_type , @i_ordered , @i_shipped , @i_status , k.lb_tracking , @i_cr_ordered , @i_cr_shipped ,   
							k.uom , @i_conv_factor , k.cost , k.labor , k.direct_dolrs , k.ovhd_dolrs , k.util_dolrs , k.note , k.qty_per , k.qc_flag , k.qc_no , k.description   
				FROM	ord_list_kit k (NOLOCK)  
				WHERE	k.order_no = @i_order_no 
				AND		k.order_ext = 0 
				AND		k.line_no = @i_line_no  
			END		
		END
  
		SELECT @qty = ((@i_shipped - @i_cr_shipped) * @i_conv_factor)  
    
		SELECT @stat = 'ORDL_INS'  
  
		EXEC @tdc_rtn = tdc_order_list_change @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @qty, @stat  
  
		IF (@tdc_rtn < 0 )  
		BEGIN  
			EXEC adm_raiserror 84900 ,'Invalid Inventory Update From TDC'  
		END  
  
		IF (@orders_type = 'C')  
		BEGIN  
			IF (ISNULL(@i_load_group_no,0) != 0 OR ISNULL(@i_user_count,0) != 0)  
			BEGIN  
				UPDATE	ord_list  
				SET		load_group_no = 0,  
						user_count = 0   
				WHERE	order_no = @i_order_no 
				AND		order_ext = @i_order_ext 
				AND		line_no = @i_line_no  
			END  
		END  
  
		IF (@orders_type = 'I')  
		BEGIN  
			IF (ISNULL(@i_return_code,'') != '')  
			BEGIN  
				UPDATE	ord_list  
				SET		return_code = ''  
				WHERE	order_no = @i_order_no 
				AND		order_ext = @i_order_ext 
				AND		line_no = @i_line_no  
			END  
		END  
  
  		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_order_no = i_order_no, 
				@i_order_ext = i_order_ext, 
				@i_line_no = i_line_no, 
				@i_location = i_location, 
				@i_part_no = i_part_no, 
				@i_ordered = i_ordered, 
				@i_shipped = i_shipped, 
				@i_price = i_price, 
				@i_status = i_status, 
				@i_cost = i_cost, 
				@i_who_entered = i_who_entered,
				@i_cr_ordered = i_cr_ordered, 
				@i_cr_shipped = i_cr_shipped, 
				@i_uom = i_uom, 
				@i_conv_factor = i_conv_factor, 
				@i_lb_tracking = i_lb_tracking, 
				@i_labor = i_labor, 
				@i_direct_dolrs = i_direct_dolrs, 
				@i_ovhd_dolrs = i_ovhd_dolrs, 
				@i_util_dolrs = i_util_dolrs, 
				@i_qc_flag = i_qc_flag, 
				@i_reason_code = i_reason_code, 
				@i_row_id = i_row_id, 
				@i_part_type = i_part_type, 
				@i_gl_rev_acct = i_gl_rev_acct, 
				@i_tax_code = i_tax_code, 
				@i_ship_to = i_ship_to, 
				@i_create_po_flag = i_create_po_flag, 
				@i_load_group_no = i_load_group_no, 
				@i_return_code = i_return_code, 
				@i_user_count = i_user_count, 
				@i_organization_id = i_organization_id
		FROM	#t700insordl
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DROP TABLE #t700insordl     
  
END  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
     
CREATE TRIGGER [dbo].[t700updordl] 
ON [dbo].[ord_list]   
FOR UPDATE  AS  
BEGIN  
  
	IF (NOT UPDATE(part_type) AND NOT UPDATE(order_no) AND NOT UPDATE(conv_factor) AND NOT UPDATE(order_ext) AND NOT UPDATE(lb_tracking) 
		AND NOT UPDATE(shipped) AND NOT UPDATE(cr_shipped) AND NOT UPDATE(price) AND NOT UPDATE(qc_flag) AND NOT UPDATE(conv_factor) 
		AND NOT UPDATE(ordered) AND NOT UPDATE(cr_ordered) AND NOT UPDATE(part_no) AND NOT UPDATE(location) AND NOT UPDATE(status)  
		AND NOT UPDATE(create_po_flag) AND NOT UPDATE(tax_code) AND NOT UPDATE(curr_price) AND NOT UPDATE(discount))  
	BEGIN  
		RETURN  
	END   
  
	IF EXISTS (SELECT 1 FROM config (NOLOCK) WHERE flag = 'TRIG_UPD_ORDL' AND value_str='DISABLE') RETURN  
  
	DECLARE	@i_order_no			int,  
			@i_order_ext		int,  
			@i_line_no			int,  
			@i_location			varchar(10),  
			@i_part_no			varchar(30),  
			@i_ordered			decimal(20,8),  
			@i_shipped			decimal(20,8),  
			@i_price			decimal(20,8),  
			@i_price_type		char(1),  
			@i_status			char(1),  
			@i_cost				decimal(20,8),  
			@i_who_entered		varchar(20),  
			@i_cr_shipped		decimal(20,8),  
			@i_discount			decimal(20,8),  
			@i_uom				char(2),  
			@i_conv_factor		decimal(20,8),  
			@i_lb_tracking		char(1),  
			@i_labor			decimal(20,8),  
			@i_direct_dolrs		decimal(20,8),  
			@i_ovhd_dolrs		decimal(20,8),  
			@i_util_dolrs		decimal(20,8),  
			@i_qc_flag			char(1),  
			@i_reason_code		varchar(10),  
			@i_row_id			int,  
			@i_qc_no			int,  
			@i_part_type		char(1),  
			@i_back_ord_flag	char(1),  
			@i_gl_rev_acct		varchar(32),  
			@i_tax_code			varchar(10),  
			@i_curr_price		decimal(20,8),  
			@i_oper_price		decimal(20,8),  
			@i_reference_code	varchar(32),  
			@i_ship_to			varchar(10),  
			@i_create_po_flag	int,   
			@i_organization_id	varchar(30),  
			@d_order_no			int,  
			@d_order_ext		int,  
			@d_line_no			int,  
			@d_location			varchar(10),  
			@d_part_no			varchar(30),  
			@d_ordered			decimal(20,8),  
			@d_shipped			decimal(20,8),  
			@d_price			decimal(20,8),  
			@d_status			char(1),  
			@d_cr_shipped		decimal(20,8),  
			@d_discount			decimal(20,8),  
			@d_conv_factor		decimal(20,8),  
			@d_lb_tracking		char(1),  
			@d_qc_flag			char(1),  
			@d_part_type		char(1),  
			@d_gl_rev_acct		varchar(32),  
			@d_tax_code			varchar(10),  
			@d_curr_price		decimal(20,8),  
			@d_oper_price		decimal(20,8),  
			@d_create_po_flag	int,   
			@i_RETURN_code		varchar(10), 
			@d_RETURN_code		varchar(10),  
			@i_amt				decimal(20,8), 
			@d_amt				decimal(20,8),  
			@xlp				int, 
			@retval				int,
			@vEND				varchar(10), 
			@cost				decimal(20,8),  
			@homecode			varchar(8), 
			@posting_code		varchar(8), 
			@company_id			int, 
			@rev_flag			int,  
			@iloop				int,	
			@inv_acct			varchar(32), 
			@inv_direct			varchar(32), 
			@inv_ovhd			varchar(32), 
			@inv_util			varchar(32),  
			@cog_acct			varchar(32), 
			@cog_direct			varchar(32), 
			@cog_ovhd			varchar(32), 
			@cog_util			varchar(32),  
			@var_acct			varchar(32), 
			@var_direct			varchar(32), 
			@var_ovhd			varchar(32), 
			@var_util			varchar(32),  
			@acct_code			varchar(32), 
			@mask				varchar(32),  
			@shipped_qty		decimal(20,8), 
			@barcoded			varchar(10), 
			@multi_ship_to_status varchar(10),  
			@already_shipped	decimal(20,8), 
			@backorder_jobs		char(1), 
			@jobext				int,  
			@ar_cgs_mask1		varchar(32), 
			@j					int, 
			@i					int, 
			@i1					int,  
			@jobno				int, 
			@jrow				int, 
			@prodqty			decimal(20,8),  
			@qty				decimal(20,8),
			@account			varchar(10),  
			@tran_date			datetime, 
			@tran_age			datetime,   
			@unitcost			decimal(20,8), 
			@direct				decimal(20,8), 
			@overhead			decimal(20,8), 
			@labor				decimal(20,8),   
			@utility			decimal(20,8),   
			@stkacct			varchar(10), 
			@qcacct				varchar(10), 
			@miscacct			varchar(10),  
			@typ				char(1), 
			@o_avg_cost			decimal(20,8),
			@o_direct_dolrs		decimal(20,8), 
			@o_ovhd_dolrs		decimal(20,8),
			@o_util_dolrs		decimal(20,8), 
			@o_std_cost			decimal(20,8), 
			@o_std_direct_dolrs decimal(20,8),   
			@o_std_ovhd_dolrs	decimal(20,8),
			@o_std_util_dolrs	decimal(20,8),  
			@o_in_stock			decimal(20,8), 
			@r_avg_cost			decimal(20,8),
			@r_direct_dolrs		decimal(20,8), 
			@r_ovhd_dolrs		decimal(20,8),
			@r_util_dolrs		decimal(20,8), 
			@use_ac				char(1), 
			@in_stock			decimal(20,8),
			@dummycost			decimal(20,8), 
			@COGS				int, 
			@temp_qty			decimal(20,8), 
			@prior_shipments	decimal(20,8),  
			@control_org_id		varchar(30), 
			@eproc_org_id		varchar(30),  
			@orders_req_ship_date datetime, 
			@orders_date_shipped datetime,  
			@orders_back_ord_flag char(1),  
			@rc					int,  
			@po_so_upd			int,  
			@mtd_qty			decimal(20,8), 
			@mtd_amt			decimal(20,8),  
			@org_id				varchar(30), 
			@orders_org_id		varchar(30), 
			@line_org_id		varchar(30),
			@orders_eprocurement_ind int,
			@prev_order_no		int, 
			@prev_order_ext		int,  
			@orders_posting_code varchar(10), 
			@freight_acct		varchar(32),  
			@orders_freight		decimal(20,8), 
			@tot_qty			decimal(20,8), 
			@freight_per		decimal(20,8),  
			@rem_freight		decimal(20,8), 
			@first_line			int, 
			@line_freight		decimal(20,8),         
			@f_shipped			decimal(20,8), 
			@f_cr_shipped		decimal(20,8), 
			@PRODUCTID			int, 
			@LOCATIONID			int, 
			@TIMEID				int, 
			@CROSS_REF_PRODUCTID int,   
			@CROSS_REF_PART_NO	varchar(3), 
			@kit_row_id			int, 
			@kit_part_no		varchar(30),   
			@kit_location		varchar(30),   
			@kit_shipped		decimal(20,8), 
			@kit_cr_shipped		decimal(20,8), 
			@kit_PRODUCTID		int,   
			@kit_LOCATIONID		int, 
			@kit_CROSS_REF_PART_NO varchar(30), 
			@kit_CROSS_REF_PRODUCTID int,
			@line_descr			varchar(50), 
			@tempqty			decimal(20,8),  
			@orders_type		char(1), 
			@orders_module		varchar(10),  
			@orders_blanket_amt float, 
			@orders_blanket		char(1),
			@prev_acct			varchar(32), 
			@prev_ref_cd		varchar(32), 
			@ord_ref_cd			varchar(32),
			@curr_precision		int, 
			@orders_curr_key	varchar(10),
			@glcurr_curr_key	varchar(10), 
			@rel_amt			decimal(20,8), 
			@msg				varchar(255),  
			@ord_amt			decimal(20,8),  
			@a_tran_id			int, 
			@a_tran_qty			decimal(20,8), 
			@a_tran_data		varchar(255),  
			@d_is_commit_ed		decimal(20,8), 
			@d_is_hold_ord		decimal(20,8), 
			@d_is_qty_alloc		decimal(20,8),  
			@d_is_sales_qty		decimal(20,8), 
			@d_is_sales_amt		decimal(20,8),  
			@i_is_commit_ed		decimal(20,8), 
			@i_is_hold_ord		decimal(20,8), 
			@i_is_qty_alloc		decimal(20,8),  
			@i_is_sales_qty		decimal(20,8), 
			@i_is_sales_amt		decimal(20,8),  
			@a_unitcost			decimal(20,8), 
			@a_direct			decimal(20,8), 
			@a_overhead			decimal(20,8), 
			@a_utility			decimal(20,8),  
			@a_labor			decimal(20,8),  
			@tempcost			decimal(20,8),  
			@im_status			char(1), 
			@lost_sale_no		int, 
			@orders_cust_code	varchar(10), 
			@who				varchar(20),  
			@inv_lot_bin		int,  
			@last_tax_code		varchar(10),
			@m_lb_tracking		char(1), 
			@lb_sum				decimal(20,8), 
			@part_cnt			int,  
			@lb_part			varchar(30), 
			@lb_loc				varchar(10), 
			@uom_sum			decimal(20,8),  
			@i_qty				decimal(20,8),
			@tdc_rtn			int, 
			@diff				int, 
			@stat				varchar(10)    

	-- v1.0 Start
	DECLARE @row_id			int,
			@last_row_id	int,
			@kit_row		int,
			@last_kit_row	int
	-- v1.0 END

	SELECT	@rev_flag = NULL, 
			@company_id = NULL, 
			@homecode = NULL
  
	SELECT	@use_ac = NULL, 
			@stkacct = NULL, 
			@miscacct = NULL, 
			@qcacct = NULL,  
			@company_id = NULL,  
			@prev_order_no = -1, 
			@prev_order_ext = -1, 
			@first_line = 0,  
			@last_tax_code = '!@#$' 
  
	SELECT	@inv_lot_bin = ISNULL((SELECT 1 FROM config (NOLOCK) WHERE flag = 'INV_LOT_BIN' AND UPPER(value_str) = 'YES' ),0)  
  
	CREATE TABLE #lots (
		part_no		varchar(30), 
		location	varchar(10), 
		qty			decimal(20,8), 
		uom_qty		decimal(20,8),   
		conv_qty	decimal(20,8),
		typ			int)  
  
	-- v1.0 Start
	CREATE TABLE #t700updordl (
		row_id				int IDENTITY(1,1),
		i_order_no			int NULL,  
		i_order_ext			int NULL,  
		i_line_no			int NULL,  
		i_location			varchar(10) NULL,  
		i_part_no			varchar(30) NULL,  
		i_ordered			decimal(20,8) NULL,  
		i_shipped			decimal(20,8) NULL,  
		i_price				decimal(20,8) NULL,  
		i_price_type		char(1) NULL,  
		i_status			char(1) NULL,  
		i_cost				decimal(20,8) NULL,  
		i_who_entered		varchar(20) NULL,  
		i_cr_shipped		decimal(20,8) NULL,  
		i_discount			decimal(20,8) NULL,  
		i_uom				char(2) NULL,  
		i_conv_factor		decimal(20,8) NULL,  
		i_lb_tracking		char(1) NULL,  
		i_labor				decimal(20,8) NULL,  
		i_direct_dolrs		decimal(20,8) NULL,  
		i_ovhd_dolrs		decimal(20,8) NULL,  
		i_util_dolrs		decimal(20,8) NULL,  
		i_qc_flag			char(1) NULL,  
		i_reason_code		varchar(10) NULL,  
		i_row_id			int NULL,  
		i_qc_no				int NULL,  
		i_part_type			char(1) NULL,  
		i_back_ord_flag		char(1) NULL,  
		i_gl_rev_acct		varchar(32) NULL,  
		i_tax_code			varchar(10) NULL,  
		i_curr_price		decimal(20,8) NULL,  
		i_oper_price		decimal(20,8) NULL,  
		i_reference_code	varchar(32) NULL,  
		i_ship_to			varchar(10) NULL,  
		i_create_po_flag	int NULL,   
		i_organization_id	varchar(30) NULL,  
		d_order_no			int NULL,  
		d_order_ext			int NULL,  
		d_line_no			int NULL,  
		d_location			varchar(10) NULL,  
		d_part_no			varchar(30) NULL,  
		d_ordered			decimal(20,8) NULL,  
		d_shipped			decimal(20,8) NULL,  
		d_price				decimal(20,8) NULL,  
		d_status			char(1) NULL,  
		d_cr_shipped		decimal(20,8) NULL,  
		d_discount			decimal(20,8) NULL,  
		d_conv_factor		decimal(20,8) NULL,  
		d_lb_tracking		char(1) NULL,  
		d_qc_flag			char(1) NULL,  
		d_part_type			char(1) NULL,  
		d_gl_rev_acct		varchar(32) NULL,  
		d_tax_code			varchar(10) NULL,  
		d_curr_price		decimal(20,8) NULL,  
		d_oper_price		decimal(20,8) NULL,  
		d_create_po_flag	int NULL,   
		i_RETURN_code		varchar(10) NULL, 
		d_RETURN_code		varchar(10) NULL) 

	CREATE TABLE #t700updordl_kit (
		kit_row			int IDENTITY(1,1),
		kit_part_no		varchar(30),
		kit_location	varchar(10), 
		kit_shipped		decimal(20,8), 
		kit_cr_shipped	decimal(20,8), 
		kit_row_id		int)

	INSERT #t700updordl (i_order_no, i_order_ext, i_line_no, i_location, i_part_no, i_ordered, i_shipped, i_price, i_price_type, i_status, i_cost, i_who_entered, 
					i_cr_shipped, i_discount, i_uom, i_conv_factor, i_lb_tracking, i_labor, i_direct_dolrs, i_ovhd_dolrs, i_util_dolrs, i_qc_flag, i_reason_code, 
					i_row_id, i_qc_no, i_part_type, i_back_ord_flag, i_gl_rev_acct, i_tax_code, i_curr_price, i_oper_price, i_reference_code, i_ship_to, i_create_po_flag,
					i_organization_id, d_order_no, d_order_ext, d_line_no, d_location, d_part_no, d_ordered, d_shipped, d_price, d_status, d_cr_shipped, d_discount, 
					d_conv_factor, d_lb_tracking, d_qc_flag, d_part_type, d_gl_rev_acct, d_tax_code, d_curr_price, d_oper_price, d_create_po_flag, i_return_code, 
					d_return_code)
	SELECT	i.order_no, i.order_ext, i.line_no, i.location, i.part_no, i.ordered, i.shipped, i.price, i.price_type, i.status, i.cost, i.who_entered, 
			i.cr_shipped, i.discount, i.uom, i.conv_factor, i.lb_tracking, i.labor, i.direct_dolrs, i.ovhd_dolrs, i.util_dolrs, i.qc_flag, i.reason_code, 
			i.row_id, i.qc_no, i.part_type, i.back_ord_flag, i.gl_rev_acct, i.tax_code, i.curr_price, i.oper_price, i.reference_code, i.ship_to, i.create_po_flag,
			ISNULL(i.organization_id,''), d.order_no, d.order_ext, d.line_no, d.location, d.part_no, d.ordered, d.shipped, d.price, d.status, d.cr_shipped, d.discount, 
			d.conv_factor, d.lb_tracking, d.qc_flag, d.part_type, d.gl_rev_acct, d.tax_code, d.curr_price, d.oper_price, d.create_po_flag, i.return_code, 
			d.return_code
	FROM	inserted i
	JOIN	deleted d  
	ON		i.row_id = d.row_id  
	ORDER BY i.order_no, i.order_ext, i.line_no  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,	
			@i_order_no = i_order_no,
			@i_order_ext = i_order_ext,
			@i_line_no = i_line_no,
			@i_location = i_location,
			@i_part_no = i_part_no,
			@i_ordered = i_ordered,
			@i_shipped = i_shipped,
			@i_price = i_price,
			@i_price_type = i_price_type,
			@i_status = i_status,
			@i_cost = i_cost,
			@i_who_entered = i_who_entered,
			@i_cr_shipped = i_cr_shipped,  
			@i_discount = i_discount,
			@i_uom = i_uom,
			@i_conv_factor = i_conv_factor,
			@i_lb_tracking = i_lb_tracking,
			@i_labor = i_labor,
			@i_direct_dolrs = i_direct_dolrs,
			@i_ovhd_dolrs = i_ovhd_dolrs,
			@i_util_dolrs = i_util_dolrs,
			@i_qc_flag = i_qc_flag,
			@i_reason_code = i_reason_code,
			@i_row_id = i_row_id,
			@i_qc_no = i_qc_no,
			@i_part_type = i_part_type,
			@i_back_ord_flag = i_back_ord_flag,
			@i_gl_rev_acct = i_gl_rev_acct,
			@i_tax_code = i_tax_code,
			@i_curr_price = i_curr_price,
			@i_oper_price = i_oper_price,
			@i_reference_code = i_reference_code,
			@i_ship_to = i_ship_to,
			@i_create_po_flag = i_create_po_flag,
			@i_organization_id = i_organization_id,
			@d_order_no = d_order_no,
			@d_order_ext = d_order_ext,
			@d_line_no = d_line_no,
			@d_location = d_location,
			@d_part_no = d_part_no,
			@d_ordered = d_ordered,
			@d_shipped = d_shipped,
			@d_price = d_price,
			@d_status = d_status,
			@d_cr_shipped = d_cr_shipped,
			@d_discount = d_discount,
			@d_conv_factor = d_conv_factor,
			@d_lb_tracking = d_lb_tracking,
			@d_qc_flag = d_qc_flag,
			@d_part_type = d_part_type,
			@d_gl_rev_acct = d_gl_rev_acct,
			@d_tax_code = d_tax_code,
			@d_curr_price = d_curr_price,
			@d_oper_price = d_oper_price,
			@d_create_po_flag = d_create_po_flag,
			@i_return_code = i_return_code,
			@d_return_code = i_return_code
	FROM	#t700updordl
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@tran_date is NULL)  
			SELECT @tran_date = GETDATE()  
  
		IF (@d_status IN ('S','T') AND @i_status < @d_status)
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94130, 'You Can Unpost an Order that has posted!'  
			RETURN  
		END
  
		IF (@i_status BETWEEN 'R' AND 'V' AND @i_qc_flag = 'Y')  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94131 ,'You Can NOT Ship/Close An Order Item That Is In QC Check!'  
			RETURN  
		END  
  
		IF (@i_status >= 'P' AND @i_part_type = 'E')  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94133, 'You Can NOT Pick/Ship An Order Item That Is An Estimate - Create A Job First.'  
			RETURN  
		END  
  
		IF (@i_location like 'DROP%' OR @i_create_po_flag = 1)
		BEGIN  
			IF (@i_part_type NOT IN ('M','P','V','A','N') OR EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @i_part_no AND status = 'C'))
            BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94136, 'You Can NOT Auto Ship A Kit Item!'  
				RETURN  
			END   
		END  
  
		IF (@i_status NOT IN ('E','V') AND @i_part_type = 'P' AND (@i_part_no != @d_part_no OR @i_location != @d_location))
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM inv_sales (NOLOCK) WHERE  part_no =  @i_part_no AND location =  @i_location)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94103, 'Inventory Part Missing.  The transaction is being rolled back.'  
				RETURN  
			END  
		END  
  
		IF (@i_status = 'V' AND @i_location LIKE 'DROP%')  
		BEGIN  
			IF EXISTS (SELECT 1 FROM orders_auto_po o (NOLOCK), ord_list l (NOLOCK) WHERE o.order_no = @i_order_no AND o.status != 'N' 
						AND o.order_no = l.order_no AND o.part_no = l.part_no AND o.line_no = l.line_no AND l.order_ext = @i_order_ext AND l.shipped != 0)                     
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94132, 'You Can NOT VOID a DROP SHIP Order Item - This Must Be Performed In Purchasing System!'  
				RETURN  
			END  
		END  
  
		IF (ISNULL(@i_tax_code,'') != ISNULL(@d_tax_code,'') and ISNULL(@i_tax_code,'') != @last_tax_code)  
		BEGIN  
			IF (ISNULL(@i_tax_code,'') != '')  
			BEGIN  
				IF NOT EXISTS (SELECT 1 FROM artax (NOLOCK) WHERE tax_code = @i_tax_code AND module_flag != 1)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 941333, 'Tax code not defined for use with Accounts Receivable'  
					RETURN  
				END  
			END  
			ELSE  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 941334 ,'Tax code not defined'  
				RETURN  
			END  
			SELECT @last_tax_code = ISNULL(@i_tax_code,'')  
		END  
  
		IF (@prev_order_no != @i_order_no or @prev_order_ext != @i_order_ext)
		BEGIN  
			SELECT	@orders_req_ship_date = req_ship_date,  
					@orders_date_shipped = date_shipped,  
					@orders_back_ord_flag = ISNULL(back_ord_flag,1),
					@orders_type = type, 
					@orders_blanket = blanket, 
					@orders_blanket_amt = blanket_amt,  
					@orders_eprocurement_ind = ISNULL(eprocurement_ind,0),  
					@orders_freight = freight,  
					@orders_posting_code = posting_code,  
					@orders_cust_code = cust_code, 
					@orders_org_id = dbo.adm_get_locations_org_fn(location),  
					@orders_module = CASE WHEN TYPE = 'I' THEN 'soe' ELSE 'cm' END  
			FROM	orders_all (NOLOCK)  
			WHERE	order_no = @i_order_no 
			AND		ext = @i_order_ext  
  
			IF (@@ROWCOUNT = 0)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94101, 'Primary key values not found in table dbo.orders.  The transaction is being rolled back.'  
				RETURN  
			END  
  
			SELECT	@prev_order_no = @i_order_no, 
					@prev_order_ext = @i_order_ext,  
					@tot_qty = 0, 
					@freight_per = 0, 
					@rem_freight = 0, 
					@first_line = 0, 
					@freight_acct = ''  
  
			IF (@orders_eprocurement_ind = 1 and @orders_freight != 0 and @i_status = 'T' and @orders_type = 'I')  
			BEGIN  
				SELECT	@first_line = CASE WHEN MIN(line_no) = @i_line_no THEN 1 ELSE 0 END,  
						@tot_qty = SUM(shipped)   
				FROM	ord_list (NOLOCK)  
				WHERE	order_no = @i_order_no 
				AND		order_ext = @i_order_ext 
				AND		status BETWEEN 'S' AND 'T' 
				AND		shipped != 0  
  
				SELECT	@tot_qty = ISNULL(@tot_qty,1)  
  
				SELECT	@freight_acct = freight_acct_code  
				FROM	araccts (NOLOCK) 
				WHERE	posting_code = @orders_posting_code  
  
				SELECT	@freight_per = @orders_freight / @tot_qty        
  
				SELECT	@rem_freight = ISNULL((SELECT SUM(shipped * @freight_per)  
											FROM	ord_list (NOLOCK)  
											WHERE	order_no = @i_order_no 
											AND		order_ext = @i_order_ext 
											AND		status BETWEEN 'S' AND 'T'),1)  
  
				SELECT	@rem_freight = @rem_freight - @orders_freight  
			END  
		END  
  
		IF (@i_organization_id = '')
		BEGIN  
			SET	@i_gl_rev_acct = CASE WHEN @orders_eprocurement_ind = 0 THEN dbo.adm_mask_acct_fn( @i_gl_rev_acct, 'CVO') ELSE @i_gl_rev_acct END  
			
			UPDATE	ord_list  
			SET		organization_id = 'CVO',  
					gl_rev_acct = @i_gl_rev_acct  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no 			
		END  
  
		IF (@i_status >= 'R' OR @i_gl_rev_acct != @d_gl_rev_acct)  
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM adm_glchart_all (NOLOCK) WHERE inactive_flag = 0 AND account_code = @i_gl_rev_acct)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94105 ,'The revenue account code for one of the lines on this order is either inactive or invalid. The transaction cannot be completed.'  
				RETURN  
			END  
		END  
  
		IF (@i_status = 'S')  
		BEGIN  
			SELECT @m_lb_tracking = 'N'  

			IF (@i_part_type = 'P')  
				SELECT @m_lb_tracking = ISNULL((SELECT lb_tracking FROM inv_master (NOLOCK) WHERE part_no = @i_part_no),NULL)  
  
			IF (@m_lb_tracking IS NULL)  
			BEGIN  
				SELECT @msg = 'Part ([' + @i_part_no + ']) does not exist in inventory.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832111, @msg  
				RETURN  
			END  
  
			IF (ISNULL(@m_lb_tracking,'N') != @i_lb_tracking AND @i_part_type NOT IN ( 'N','A'))
			BEGIN  
				SELECT @msg = 'Lot bin tracking flag mismatch with inventory for part [' + @i_part_no + '].'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832112, @msg  
				RETURN  
			END  
  
			DELETE FROM #lots  
    
			IF (@i_lb_tracking = 'Y')  
			BEGIN
				INSERT	#lots   
				VALUES (@i_part_no, @i_location, (@i_shipped - @i_cr_shipped) * @i_conv_factor, (@i_shipped - @i_cr_shipped), (@i_shipped - @i_cr_shipped), -1)  
			END
   
			IF (@i_part_type = 'C')  
			BEGIN
				INSERT	#lots   
				SELECT	part_no, location, (shipped - cr_shipped) * qty_per * conv_factor, (shipped - cr_shipped) * qty_per, (shipped - cr_shipped) * qty_per, -2  
				FROM	ord_list_kit (NOLOCK) 
				WHERE	order_no = @i_order_no 
				AND		order_ext = @i_order_ext 
				AND		line_no = @i_line_no  
				AND		lb_tracking = 'Y'  
			END	  
			
			INSERT	#lots  
			SELECT	part_no, location, SUM(qty * direction), SUM(uom_qty * direction), SUM(qty / conv_factor * direction), -3  
			FROM	lot_bin_ship (NOLOCK) 
			WHERE	tran_no = @i_order_no 
			AND		tran_ext = @i_order_ext 
			AND		line_no = @i_line_no  
			GROUP BY part_no, location  
  
			INSERT	#lots  
			SELECT	part_no, location, SUM(qty), SUM(uom_qty), SUM(conv_qty), 0  
			FROM	#lots  
			GROUP BY part_no, location  
  
			SELECT	@lb_sum = ISNULL(SUM(qty),0), 
					@uom_sum = ISNULL(SUM(uom_qty),0),  
					@part_cnt = COUNT(DISTINCT (part_no + '!@#' + location)) ,  
					@lb_part = ISNULL(MIN(part_no),''),  
					@lb_loc = ISNULL(MIN(location),'')  
			FROM	#lots  
			WHERE	typ = -3  
  
			IF (@orders_type = 'C' AND @inv_lot_bin = 0 AND @part_cnt > 0)  
			BEGIN  
				SELECT @msg = 'You cannot have lot bin records on an inbound transaction when you are not lb tracking.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832114, @msg  
				RETURN  
			END  
  
			IF (@m_lb_tracking = 'Y')   
			BEGIN  
				IF (@part_cnt = 0 AND (@i_shipped - @i_cr_shipped) <> 0 AND @inv_lot_bin = 1)  
				BEGIN  
					SELECT @msg = 'No lot bin records found on lot_bin_ship for this item ([' + @i_part_no + ']).'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832113, @msg  
					RETURN  
				END  
  
				IF (@part_cnt > 1)  
				BEGIN  
					SELECT @msg = 'More than one parts lot bin records found on lot_bin_ship for this part ([' + @i_part_no + ']).'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832113 ,@msg  
					RETURN  
				END  
  
				SELECT @i_qty = -(@i_shipped - @i_cr_shipped)  
  
				SELECT @i_qty = @i_qty * @i_conv_factor  
      
				IF (@lb_sum != @i_qty and @inv_lot_bin = 1)  
				BEGIN  
					SELECT @msg = 'Item qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) +   
							'] for part ([' + @i_part_no + ']).'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832113, @msg  
					RETURN  
				END  
  
				IF (@part_cnt > 0)  
				BEGIN  
					IF (@lb_part != @i_part_no OR @lb_loc != @i_location)  
					BEGIN  
						SELECT @msg = 'Part/Location on lot_bin_ship is not the same as on ord_list table.'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 832115, @msg  
						RETURN  
					END  
				END  
			END  
			ELSE  
			BEGIN  
				IF (@part_cnt > 0 AND @i_part_type != 'C')  
				BEGIN  
					SELECT @msg = 'Lot bin records found on lot_bin_ship for this not lot/bin tracked part ([' + @i_part_no + ']).'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832114, @msg  
					RETURN  
				END  
		
				IF (@i_part_type = 'C')  
				BEGIN  
					IF EXISTS (SELECT 1 FROM #lots WHERE typ = 0 AND ( qty != 0))  
					BEGIN  
						SELECT @msg = 'Lot bin records on lot_bin_ship do not match shipped/RETURNed qtys on ord_list_kit for kit ([' + @i_part_no + ']).'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 832114, @msg  
						RETURN  
					END  
				END  
			END  
		END  

    
		IF (@i_part_type = 'J' AND @i_shipped > 0 AND @i_status > 'Q')       
		BEGIN  
			IF (@backorder_jobs is NULL)
			BEGIN  
				SELECT @backorder_jobs = SUBSTRING(LOWER(ISNULL((SELECT value_str FROM config WHERE flag = 'BACKORDER_JOBS'),'N')),1,1)  
			END  
  
			SELECT @jobno = CONVERT(int, @i_part_no)  
			SELECT @jobext = ISNULL((SELECT MAX(prod_ext) FROM produce_all (NOLOCK) WHERE prod_no = @jobno),0)
  
			SELECT	@prior_shipments = ISNULL((SELECT SUM(shipped)  
											FROM shippers (NOLOCK) 
											WHERE order_no = @i_order_no AND part_no = @i_part_no),0)
  
			IF (@backorder_jobs != 'y')
			BEGIN  
				SELECT @prodqty = ISNULL((SELECT SUM(qty) FROM produce_all (NOLOCK) WHERE prod_no = @jobno),0)
				IF (@prodqty = 0)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 193081 , 'You Can NOT ship a job that has no completed quantity.'  
					RETURN  
				END  
				IF (@prodqty  < @i_shipped + @prior_shipments)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 193082 , 'You Can NOT ship a higher quantity than what was produced for the job.'  
					RETURN  
				END  
			END  
			ELSE  
			BEGIN  
				SELECT @prodqty = ISNULL((SELECT SUM(qty) FROM produce_all (NOLOCK) WHERE prod_no = @jobno AND prod_ext = @jobext),0)
				IF (@prodqty = 0)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 193081 , 'You Can NOT ship a job that has no completed quantity.'  
					RETURN  
				END  
				IF (@prodqty  <> @i_shipped)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 193082 , 'You Can NOT ship a quantity different than what was produced for the job.'  
					RETURN  
				END  
			END  
  
			IF (@i_status = 'S' AND (ISNULL(@i_back_ord_flag,1) != 0 OR @orders_back_ord_flag != 0))    
			BEGIN  
				UPDATE	prod_list 
				SET		status = 'S' 
				WHERE	prod_no = @jobno 
				AND		status != 'S' 
				AND		direction=-1   

				UPDATE	prod_list 
				SET		status = 'S' 
				WHERE	prod_no = @jobno 
				AND		status != 'S' 
				AND		direction=1   
      
				UPDATE	produce_all 
				SET		status = 'S' 
				WHERE	prod_no = @jobno 
				AND		status != 'S'  
			END
		END  
    
		IF (@i_create_po_flag != @d_create_po_flag AND @i_create_po_flag = 0) AND @i_location NOT LIKE 'DROP%' AND @i_status NOT IN ('L','M')
		BEGIN  
			-- v1.0
			IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @i_order_no AND status = 'N' AND create_po_flag = 1 AND order_ext > 0)
			BEGIN
				DELETE	orders_auto_po   
				WHERE	order_no = @i_order_no 
				AND		part_no = @i_part_no 
				AND		line_no = @i_line_no  
			END
		END
  
		IF ((@i_location LIKE 'DROP%' OR @i_create_po_flag = 1) OR (@d_location LIKE 'DROP%' OR @d_create_po_flag = 1))  
				AND (@i_order_no != @d_order_no  OR @i_ordered != @d_ordered OR @i_location != @d_location OR @i_shipped != @d_shipped   
				OR @i_part_no != @d_part_no OR @i_line_no != @d_line_no OR @i_create_po_flag != @d_create_po_flag  
				OR @i_status != @d_status) AND @i_status NOT IN ('L','M')            
		BEGIN  
			-- v1.0  
			IF NOT EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @i_order_no AND status = 'N' AND create_po_flag = 1 AND order_ext > 0)
			BEGIN
				DELETE	orders_auto_po   
				WHERE	order_no = @d_order_no 
				AND		part_no = @d_part_no 
				AND		status = 'N'  
				AND		line_no = @d_line_no
			END
 
			IF (@po_so_upd IS NULL)  
			BEGIN  
				SELECT	@po_so_upd = ISNULL((SELECT 1 FROM config (NOLOCK) WHERE UPPER(flag) = 'PUR_SO_UPD' AND UPPER(LEFT(value_str,1)) = 'Y'),0)  
			END  
        
			IF (@i_ordered != @d_ordered OR @i_location != @d_location OR @i_shipped != @d_shipped OR @i_line_no != @d_line_no OR @i_part_no != @d_part_no
					OR @i_create_po_flag != @d_create_po_flag) AND ((@i_location LIKE 'DROP%' or @d_location LIKE 'DROP%') OR @po_so_upd = 1)  
			BEGIN  
				IF EXISTS (SELECT 1 FROM orders_auto_po (NOLOCK) WHERE order_no = @d_order_no AND part_no = @d_part_no AND line_no = @d_line_no AND status > 'N') 
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94135, 'You Can NOT Change An Order Item That Is Auto Purchased - Contact Purchasing!'  
					RETURN  
				END   
			END  
         
			IF (@i_status BETWEEN 'N' AND 'R' AND (@i_location LIKE 'DROP%' OR @i_create_po_flag = 1))
			BEGIN  
				IF NOT EXISTS (SELECT 1 FROM orders_auto_po (NOLOCK) WHERE order_no = @i_order_no AND part_no = @i_part_no AND line_no = @i_line_no)  
				BEGIN  
					INSERT	orders_auto_po (location, part_no, order_no, line_no, qty, status, req_ship_date, part_type)  
					SELECT	@i_location, @i_part_no, @i_order_no, @i_line_no, (@i_ordered * @i_conv_factor), 'N', @orders_req_ship_date, @i_part_type  
				END  
				ELSE  
				BEGIN  
					IF (@i_create_po_flag = 1 and @po_so_upd = 0)  
					BEGIN  
						EXEC @rc = adm_po_sales_order_update '',@i_part_no, NULL, @i_line_no, 0,0,NULL,@msg OUT, @i_order_no  
						IF (@rc < 1)  
						BEGIN  
							ROLLBACK TRAN  
							EXEC adm_raiserror 94135, @msg  
							RETURN  
						END  
					END  
				END        
			END  
		END    
  
		IF (@i_order_ext > 0)   
		BEGIN  
			SELECT @multi_ship_to_status = ISNULL((SELECT multiple_flag FROM orders_all o (NOLOCK) WHERE o.order_no = @i_order_no and o.ext = 0),'N')
	  
			IF (@i_shipped != @d_shipped AND (@multi_ship_to_status = 'Y' ))   
			BEGIN  
				SELECT @already_shipped = ISNULL((SELECT SUM(shipped) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no AND order_ext > 0 
												AND location = @i_location AND ship_to = @i_ship_to AND part_no = @i_part_no AND order_ext != @i_order_ext),0)  
     
				UPDATE	ord_list   
				SET		shipped = @i_shipped + @already_shipped  
				WHERE	order_no = @i_order_no 
				AND		order_ext = 0 
				AND		part_no = @i_part_no 
				AND		location = @i_location 
				AND		ship_to = @i_ship_to  
			END  
  
			IF (@i_ordered != @d_ordered AND (@multi_ship_to_status = 'Y'))   
			BEGIN  
				UPDATE	ord_list 
				SET		ordered = ordered + (@i_ordered - @d_ordered)  
				WHERE	order_no = @i_order_no 
				AND		order_ext = 0 
				AND		part_no =  @i_part_no   
				AND		ship_to = @i_ship_to 
				AND location = @i_location  
			END   
		END   
  
		SELECT	@a_unitcost= @i_cost,         
				@a_direct= @i_direct_dolrs,   
				@a_overhead= @i_ovhd_dolrs,   
				@a_utility= @i_util_dolrs,  
				@a_labor = @i_labor  
  
		IF (@d_part_type IN ('P','C','V','J') OR @i_part_type IN ('P','C','V','J'))  
		BEGIN  
			SELECT	@i_is_commit_ed = 0, 
					@d_is_commit_ed = 0, 
					@i_is_hold_ord = 0, 
					@d_is_hold_ord = 0,  
					@i_is_qty_alloc = 0, 
					@d_is_qty_alloc = 0,  
					@i_is_sales_qty = 0, 
					@i_is_sales_amt = 0, 
					@d_is_sales_qty = 0, 
					@d_is_sales_amt = 0  
  
			SELECT	@i_is_commit_ed = ISNULL((SELECT CASE WHEN @i_status IN ('N','P','Q','R') AND (@i_ordered - @i_shipped) > 0 AND @i_part_type = 'P'  
											THEN ((@i_ordered - @i_shipped) * @i_conv_factor) ELSE 0 END),0),  
					@d_is_commit_ed = ISNULL((SELECT CASE WHEN @d_status IN ('N','P','Q','R') AND (@d_ordered - @d_shipped) > 0 AND @d_part_type = 'P'  
											THEN ((@d_ordered - @d_shipped) * @d_conv_factor) ELSE 0 END),0)  
    
			SELECT	@i_is_hold_ord = ISNULL((SELECT CASE WHEN (@i_status IN ('R','Q','P') AND @i_shipped != 0) AND @i_part_type = 'P'
											THEN (@i_shipped * @i_conv_factor) ELSE 0 END),0),  
					@d_is_hold_ord = ISNULL((SELECT CASE WHEN (@d_status IN ('R','Q','P') AND @d_shipped != 0) AND @d_part_type = 'P'
											THEN (@d_shipped * @d_conv_factor) ELSE 0 END),0)  
    
			SELECT	@i_is_qty_alloc = ISNULL((SELECT CASE WHEN (@i_status IN ('R','Q','P') AND @i_cr_shipped != 0) AND @i_part_type = 'P'  
											THEN (@i_cr_shipped * @i_conv_factor) ELSE 0 END),0),  
					@d_is_qty_alloc = ISNULL((SELECT CASE WHEN (@d_status IN ('R','Q','P') AND @d_cr_shipped != 0) AND @d_part_type = 'P'  
											THEN (@d_cr_shipped * @d_conv_factor) ELSE 0 END),0)  
				
			SELECT	@i_is_sales_qty = ISNULL((SELECT CASE WHEN ((@i_shipped != 0 AND @i_status IN ('P','Q','R','S')) OR (@i_cr_shipped != 0 AND @i_status = 'S')) AND @i_qc_flag != 'Y'
											THEN ((@i_shipped - @i_cr_shipped)) ELSE 0 END),0),  
					@d_is_sales_qty = ISNULL((SELECT CASE WHEN ((@d_shipped != 0 AND @d_status IN ('P','Q','R','S')) OR (@d_cr_shipped != 0 AND @d_status = 'S'))
													AND (@i_status <= 'S' OR @i_status = 'V') AND @d_qc_flag != 'Y'  
											THEN ((@d_shipped - @d_cr_shipped)) ELSE 0 END),0)  
		
			SELECT	@i_is_sales_amt = ISNULL((SELECT CASE WHEN ((@i_shipped != 0 AND @i_status IN ('P','Q','R','S')) OR (@i_cr_shipped != 0 AND @i_status = 'S')) AND @i_qc_flag != 'Y'
											THEN ((@i_shipped - @i_cr_shipped) * @i_price) ELSE 0 END),0),  
					@d_is_sales_amt = ISNULL((SELECT CASE WHEN ((@d_shipped != 0 AND @d_status IN ('P','Q','R','S')) OR (@d_cr_shipped != 0 AND @d_status = 'S')) 
													AND (@i_status <= 'S' OR @i_status = 'V') AND @d_qc_flag != 'Y'  
											THEN ((@d_shipped - @d_cr_shipped) * @d_price) ELSE 0 END),0)  
  
			SELECT	@d_amt = 0, 
					@i_amt = 0, 
					@a_tran_qty = 0  

			IF (@i_part_no != @d_part_no OR @i_location != @d_location OR @i_is_sales_qty != @d_is_sales_qty OR (@i_status = 'S' AND @d_status < 'S'))  
			BEGIN  
				IF (@i_status = @d_status AND @i_status = 'S') AND (@i_is_sales_qty != @d_is_sales_qty OR @i_part_no != @d_part_no OR @i_location != @d_location)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94136, 'You cannot update inventory on an order that is shipped/posted'  
					RETURN  
				END   
  
				SELECT	@d_amt = @d_is_sales_qty * @d_conv_factor, 
						@i_amt = @i_is_sales_qty * @i_conv_factor,  
						@a_tran_qty = 0  
  
				IF @i_part_no = @d_part_no AND @i_location = @d_location 
					SELECT @a_tran_qty = CASE WHEN @i_status = 'S' THEN - @i_is_sales_qty ELSE (@d_amt - @i_amt) / @i_conv_factor END  
				ELSE  
					SELECT @a_tran_qty = - @i_is_sales_qty 
  
				IF @a_tran_qty != 0 OR (@i_status = 'S' AND (@d_amt != @i_amt))  
				BEGIN  
					SELECT	@a_unitcost = @a_unitcost * @a_tran_qty, 
							@a_direct = @a_direct * @a_tran_qty,  
							@a_overhead = @a_overhead * @a_tran_qty, 
							@a_utility = @a_utility * @a_tran_qty,  
							@a_labor = @a_labor * @a_tran_qty  
  
					SELECT  @a_tran_data = @i_part_type +   
								CONVERT(varchar(30),@d_is_hold_ord) + REPLICATE(' ',30 - DATALENGTH(CONVERT(varchar(30),@d_is_hold_ord)))  
  
					EXEC @retval = adm_inv_tran 'S', @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @orders_date_shipped, @i_uom,   
											@i_conv_factor, @i_status, @a_tran_data, DEFAULT, @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,  
											@COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT  
  
					IF (@retval <> 1)  
					BEGIN  
						ROLLBACK TRAN  
						SELECT @msg = 'Error ([' + convert(varchar(10), @retval) + ']) RETURNed from adm_inv_tran.'  
						EXEC adm_raiserror 83202, @msg  
						RETURN  
					END  
				END  
			END  
    
			IF (@i_part_no != @d_part_no OR @i_location != @d_location OR @i_is_commit_ed != @d_is_commit_ed OR @i_is_hold_ord != @d_is_hold_ord OR @i_is_qty_alloc != @d_is_qty_alloc  
				OR @i_is_sales_qty != @d_is_sales_qty OR @i_is_sales_amt != @d_is_sales_amt) AND @i_part_type != 'J'  
			BEGIN  
				IF @i_part_no = @d_part_no AND @i_location = @d_location  
				BEGIN  
					UPDATE	inv_sales WITH (ROWLOCK) -- v1.2  
					SET		commit_ed = commit_ed - @d_is_commit_ed + @i_is_commit_ed,  
							hold_ord = hold_ord - @d_is_hold_ord + @i_is_hold_ord,  
							qty_alloc = qty_alloc - @d_is_qty_alloc + @i_is_qty_alloc,  
							sales_qty_mtd = sales_qty_mtd - @d_amt + @i_amt,  
							sales_qty_ytd = sales_qty_ytd - @d_amt + @i_amt,  
							sales_amt_mtd = sales_amt_mtd - @d_is_sales_amt + @i_is_sales_amt,  
							sales_amt_ytd = sales_amt_ytd - @d_is_sales_amt + @i_is_sales_amt  
					WHERE	part_no = @i_part_no 
					AND		location = @i_location  
  
					SELECT	@mtd_qty = (@i_amt - @d_amt),  
							@mtd_amt = @i_is_sales_amt - @d_is_sales_amt  
        
					EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @mtd_qty, @mtd_amt  
					IF (@rc < 1)  
					BEGIN  
						SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) RETURNed from adm_inv_mtd_upd'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 84137, @msg  
						RETURN  
					END  
				END  
				ELSE  
				BEGIN  
					UPDATE	inv_sales WITH (ROWLOCK) -- v1.2   
					SET		commit_ed = commit_ed - @d_is_commit_ed,  
							hold_ord = hold_ord - @d_is_hold_ord,  
							qty_alloc = qty_alloc - @d_is_qty_alloc,  
							sales_qty_mtd = sales_qty_mtd - @d_amt,  
							sales_qty_ytd = sales_qty_ytd - @d_amt,  
							sales_amt_mtd = sales_amt_mtd - @d_is_sales_amt,  
							sales_amt_ytd = sales_amt_ytd - @d_is_sales_amt   
					WHERE	part_no = @d_part_no 
					AND		location = @d_location 
					AND		@d_part_type IN ('P','C','V')  
  
					IF (@d_part_type IN ('P','C','V'))  
					BEGIN  
						SELECT	@mtd_qty = - @d_amt,  
								@mtd_amt = - @d_is_sales_amt  
				
						EXEC @rc = adm_inv_mtd_upd @d_part_no, @d_location, 'S', @mtd_qty, @mtd_amt  
						IF (@rc < 1)  
						BEGIN  
							SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) RETURNed from adm_inv_mtd_upd'  
							ROLLBACK TRAN  
							EXEC adm_raiserror 84137, @msg  
							RETURN  
						END  
					END  
  
					UPDATE	inv_sales WITH (ROWLOCK) -- v1.2   
					SET		commit_ed = commit_ed + @i_is_commit_ed,  
							hold_ord = hold_ord + @i_is_hold_ord,  
							qty_alloc = qty_alloc + @i_is_qty_alloc,  
							sales_qty_mtd = sales_qty_mtd + @i_amt,  
							sales_qty_ytd = sales_qty_ytd + @i_amt,  
							sales_amt_mtd = sales_amt_mtd + @i_is_sales_amt,  
							sales_amt_ytd = sales_amt_ytd + @i_is_sales_amt   
					WHERE	part_no = @i_part_no 
					AND		location = @i_location 
					AND		@i_part_type IN ('P','C','V')  
  
					IF (@i_part_type in ('P','C','V'))  
					BEGIN  
						EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @i_amt, @i_is_sales_amt  
						IF (@rc < 1)  
						BEGIN  
							SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) RETURNed from adm_inv_mtd_upd'  
							ROLLBACK TRAN  
							EXEC adm_raiserror 84137,@msg  
							RETURN  
						END  
					END  
				END -- part/loc changed  
			END -- part/loc or amt changed  
		END -- part type C or P  
  
		IF (@i_part_type = 'P' AND (@i_status = 'V' OR @i_status = 'N') AND @d_status > 'N')	          
		BEGIN              
			DELETE	lot_bin_ship  
			WHERE	tran_no = @i_order_no 
			AND		tran_ext = @i_order_ext 
			AND		line_no = @i_line_no  
			AND		part_no = @i_part_no 
			AND		location = @i_location  
		END              
  
		IF (@i_status = 'S' AND @i_order_ext > 0 AND @i_shipped != 0)
		BEGIN 
			IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @i_order_no AND ext = 0 AND status = 'M')  
			BEGIN  
				UPDATE	ord_list   
				SET		shipped = shipped + @i_shipped  
				WHERE	order_no = @i_order_no 
				AND		order_ext = 0 
				AND		status = 'M' 
				AND		line_no = @i_line_no  
			END  
		END
    
		IF (@i_part_type = 'C')
		BEGIN  
			IF (@barcoded IS NULL)
				SELECT @barcoded = ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag='SHIP_BARCODE'),'NO')
     
			UPDATE	ord_list_kit   
			SET		status = @i_status,  
					location = @i_location,  
					shipped = case when @barcoded IN ('YES','Y') THEN shipped ELSE @i_shipped END, 
					cr_shipped = @i_cr_shipped  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no 
			AND		(status != @i_status OR cr_shipped != @i_cr_shipped  
			OR		location != @i_location  
			OR		shipped != CASE WHEN @barcoded IN ('YES','Y') THEN shipped ELSE @i_shipped END)
		END  
  
		IF @i_status = 'T' AND @d_status < 'T' AND @i_part_type IN ('P', 'C', 'V', 'X') AND @i_ordered - @i_shipped > 0 
				AND EXISTS (SELECT 1 FROM config (NOLOCK) WHERE flag = 'INV_LOSTSALES_TRIG' AND value_str = 'YES')  
				AND (@orders_back_ord_flag <> '0' OR @i_back_ord_flag <> '0') 
		BEGIN  
			UPDATE	next_lost_sale_no  
			SET		@lost_sale_no = last_no = last_no + 1  
      
			--Record the Lost Sale  
			INSERT INTO lost_sales (lost_sale_no, cust_code, ship_to, location, part_no, part_type, uom, conv_factor, qty, so_no, so_ext,  
						date_entered, who_entered, date_modified, who_modified)  
			VALUES (@lost_sale_no, @orders_cust_code, @i_ship_to, @i_location, @i_part_no, @i_part_type, @i_uom, @i_conv_factor, @i_ordered - @i_shipped,  
					@i_order_no, @i_order_ext, GETDATE(), left(HOST_NAME(),20), GETDATE(), left(HOST_NAME(),20))  
		END  
  
		IF @i_status = 'T' AND @d_status < 'T' AND @i_part_type IN ('P','C')
			AND @orders_cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST)  
		BEGIN    
			SELECT  @f_shipped = ISNULL(@i_shipped, 0) * @i_conv_factor,  
					@f_cr_shipped = ISNULL(@i_cr_shipped, 0) * @i_conv_factor  
     
			EXEC fs_eforecast_record_sale @i_part_no, @i_location, @orders_date_shipped, @f_shipped, @f_cr_shipped, 0  
   
			IF @i_part_type = 'C' 
			BEGIN      
				DELETE	#t700updordl_kit
		
				INSERT	#t700updordl_kit (kit_part_no, kit_location, kit_shipped, kit_cr_shipped, kit_row_id)
				SELECT	part_no, 
						location, 
						shipped * qty_per * conv_factor,  
						cr_shipped * qty_per * conv_factor, 
						row_id  
				FROM	ord_list_kit (NOLOCK) 
				WHERE	order_no = @i_order_no   
				AND		order_ext = @i_order_ext   
				AND		line_no = @i_line_no   
				AND		part_type != 'M'  

				SET @last_kit_row = 0

				SELECT	TOP 1 @kit_row = kit_row,
						@kit_part_no = kit_part_no, 
						@kit_location = kit_location, 
						@kit_shipped = kit_shipped, 
						@kit_cr_shipped = kit_cr_shipped, 
						@kit_row_id = kit_row_id
				FROM	#t700updordl_kit
				WHERE	kit_row > @last_kit_row
				ORDER BY kit_row ASC

				WHILE (@@ROWCOUNT <> 0)
				BEGIN
					EXEC fs_eforecast_record_sale @kit_part_no, @kit_location, @orders_date_shipped, @kit_shipped, @kit_cr_shipped, 0  

					SET @last_kit_row = @kit_row

					SELECT	TOP 1 @kit_row = kit_row,
							@kit_part_no = kit_part_no, 
							@kit_location = kit_location, 
							@kit_shipped = kit_shipped, 
							@kit_cr_shipped = kit_cr_shipped, 
							@kit_row_id = kit_row_id
					FROM	#t700updordl_kit
					WHERE	kit_row > @last_kit_row
					ORDER BY kit_row ASC

				END
			END -- part_type = 'C'  
		END 
   
		SELECT  @shipped_qty = ( @i_shipped - @i_cr_shipped )  
  
		IF @i_status = 'S' AND @d_status < 'S' AND @i_part_type NOT IN ('A','C','M','N') AND @shipped_qty <> 0  
		BEGIN  
			SELECT	@line_org_id = @org_id      
			IF @i_part_type = 'J' 
			BEGIN  
				SELECT	@posting_code = posting_code 
				FROM	produce_all (NOLOCK) 
				WHERE	prod_no = CONVERT(int,@i_part_no)  
				AND		prod_ext = @jobext  
  
				IF @posting_code = NULL OR @posting_code = ''  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94124 ,'Posting Code not defined on Production Header. Please Fix Re-save!'  
					RETURN	
		        END			
			END  
			ELSE  
			BEGIN  
				SELECT	@posting_code = acct_code 
				FROM	inv_list (NOLOCK) 
				WHERE	part_no = @i_part_no 
				AND		location = @i_location  
  
				IF @posting_code = NULL OR @posting_code = ''  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94126 ,'Posting Code not defined on Inv Item. Please Fix Inventory and Re-save!'  
					RETURN  
				END  
			END  
  
			SELECT	@inv_acct = inv_acct_code,  
					@inv_direct = inv_direct_acct_code,  
					@inv_ovhd = inv_ovhd_acct_code,  
					@inv_util = inv_util_acct_code,  
					@cog_acct = ar_cgs_code,  
					@cog_direct = ar_cgs_direct_code,  
					@cog_ovhd = ar_cgs_ovhd_code,  
					@cog_util = ar_cgs_util_code,  
					@var_acct = cost_var_code,  
					@var_direct = cost_var_direct_code,  
					@var_ovhd = cost_var_ovhd_code,  
					@var_util = cost_var_util_code,  
					@mask = ar_cgs_mask  
			FROM	in_account (NOLOCK)  
			WHERE	acct_code = @posting_code  
  
			SELECT @control_org_id = dbo.adm_get_locations_org_fn(@i_location)  
  
			IF @orders_eprocurement_ind = 1 
			BEGIN  
				SELECT  @cog_acct = @i_gl_rev_acct  
				SELECT  @cog_direct = @i_gl_rev_acct       
				SELECT  @cog_ovhd = @i_gl_rev_acct       
				SELECT  @cog_util = @i_gl_rev_acct       
  
				SELECT @eproc_org_id = dbo.IBOrgbyAcct_fn(@i_gl_rev_acct)  
			END  
			ELSE  
			BEGIN  
				IF @rev_flag IS NULL 
					SELECT @rev_flag = ISNULL((SELECT default_rev_flag FROM arco (NOLOCK)),0)  
  
				IF @rev_flag = 0 AND RTRIM(ISNULL(@mask,'')) <> ''      
				BEGIN  
					IF (ISNULL(@i_gl_rev_acct,'') != '' ) AND ( @i_gl_rev_acct != SPACE(32) ) 
					BEGIN  
						SELECT @ar_cgs_mask1 = '--------------------------------'  
						SELECT  @j = DATALENGTH( RTRIM( @i_gl_rev_acct ) )  
						select @i1 = DATALENGTH(rtrim(@mask))  
						select @i = 1  
						SELECT @ar_cgs_mask1 = STUFF(@ar_cgs_mask1, 1, 1, SUBSTRING(@mask, 1, @i1))  
  
						SELECT @mask = @ar_cgs_mask1  
  
						WHILE ( @i <= @j )  
						BEGIN  
							IF (SUBSTRING( @mask, @i, 1 ) = '_') OR (SUBSTRING( @mask, @i, 1 ) = '-') OR  
									(SUBSTRING( @mask, @i, 1 ) = ' ')  
							SELECT  @mask = STUFF( @mask, @i, 1, SUBSTRING( @i_gl_rev_acct, @i, 1 ))  
						
							SELECT @i = @i + 1  
						END  
						SELECT  @j = DATALENGTH( RTRIM(@mask) )  
						SELECT @i = 1  
  
						WHILE (@i <= @j)  
						BEGIN  
							IF (SUBSTRING(@mask, @i, 1) = '-')  
								SELECT @mask = STUFF(@mask, @i, 1, SPACE(1))  
							SELECT @i = @i + 1  
						END  
  
						IF EXISTS (SELECT 1 FROM adm_glchart_all (NOLOCK) WHERE inactive_flag = 0 AND account_code = @mask)  
						BEGIN
							SELECT  @cog_acct = @mask  
							SELECT  @cog_direct = @mask
							SELECT  @cog_ovhd = @mask  
							SELECT  @cog_util = @mask 
						END   
					END  
				END -- masking  
			END -- eprocurement_ind = 0  
  
			SELECT @iloop = 1  
			SELECT @prev_acct = '', 
				@prev_ref_cd = ''    
  
			WHILE @iloop <= 12  
			BEGIN  
  
				SELECT @cost = CASE @iloop  
								WHEN 1 THEN @unitcost    --Inventory Adjustments (CR Inv on Invoice / DB on a RETURN)  
								WHEN 2 THEN @direct     
								WHEN 3 THEN @overhead   
								WHEN 4 THEN @utility    
								WHEN 5 THEN -@a_unitcost --COGS Adjustments  
								WHEN 6 THEN -@a_direct   
								WHEN 7 THEN -@a_overhead   
								WHEN 8 THEN -@a_utility   
								WHEN 9 THEN @a_unitcost - @unitcost -- cost variance for WAVG  
								WHEN 10 THEN @a_direct - @direct  
								WHEN 11 THEN @a_overhead - @overhead  
								WHEN 12 THEN @a_utility - @utility  
								END  
	  
				IF @company_id IS NULL  
				BEGIN  
					SELECT	@company_id = company_id, 
							@homecode   = home_currency 
					FROM	glco (NOLOCK)  
				END  
	  
				SELECT @acct_code = CASE @iloop  
									WHEN 1 THEN @inv_acct     --Inventory Adjustments  
									WHEN 2 THEN @inv_direct  
									WHEN 3 THEN @inv_ovhd  
									WHEN 4 THEN @inv_util  
									WHEN 5 THEN @cog_acct       --COGS Adjustments  
									WHEN 6 THEN @cog_direct  
									WHEN 7 THEN @cog_ovhd  
									WHEN 8 THEN @cog_util  
									WHEN 9 THEN @var_acct -- cost variance for WAVG  
									WHEN 10 THEN @var_direct  
									WHEN 11 THEN @var_ovhd  
									WHEN 12 THEN @var_util  
									END,  
						@line_descr = CASE @iloop  
									WHEN 1 THEN 'inv_acct'  --Inventory Adjustments  
									WHEN 2 THEN 'inv_direct_acct'  
									WHEN 3 THEN 'inv_ovhd_acct'  
									WHEN 4 THEN 'inv_util_acct'  
									WHEN 5 THEN 'ar_cgs_acct' --COGS Adjustments  
									WHEN 6 THEN 'ar_cgs_direct_acct'  
									WHEN 7 THEN 'ar_cgs_ovhd_acct'  
									WHEN 8 THEN 'ar_cgs_util_acct'  
									WHEN 9 THEN 'cost_var_acct' -- cost variance for WAVG  
									WHEN 10 THEN 'cost_var_direct_acct'  
									WHEN 11 THEN 'cost_var_ovhd_acct'  
									WHEN 12 THEN 'cost_var_util_acct'  
									END  
	  
	  
				IF @orders_eprocurement_ind = 1 AND @iloop BETWEEN 4 AND 8   
					SELECT	@line_descr = 'expense account',  
							@org_id = @eproc_org_id  
				ELSE  
					SET @org_id = ''  
	    
				SELECT @tempqty = CASE WHEN @iloop BETWEEN 1 AND 4 THEN @shipped_qty * -1 ELSE @shipped_qty END  
	  
				IF isnull( @cost, 0 ) != 0
				BEGIN  
					SELECT @ord_ref_cd = ''
					IF @acct_code = @prev_acct  
						SELECT @ord_ref_cd = @prev_ref_cd  
					ELSE  
					BEGIN  
						IF EXISTS (SELECT 1 FROM glrefact (NOLOCK) WHERE @acct_code LIKE account_mask AND reference_flag > 1)  
						BEGIN  
							IF EXISTS (SELECT 1 FROM glratyp t (NOLOCK), glref r (NOLOCK)  
											WHERE t.reference_type = r.reference_type AND @acct_code LIKE t.account_mask AND r.status_flag = 0 AND r.reference_code = @i_reference_code)  
							BEGIN  
								SELECT @ord_ref_cd = @i_reference_code  
							END  
						END  
					END  
					SELECT	@prev_acct = @acct_code, 
							@prev_ref_cd = @ord_ref_cd
	  
					SELECT @tempcost = @cost / @tempqty  
	        
					EXEC @retval = adm_gl_insert  @i_part_no,@i_location,'S',@i_order_no,@i_order_ext,@i_line_no, @orders_date_shipped,@tempqty,@tempcost,@acct_code,@homecode,DEFAULT,DEFAULT,   
											@company_id, DEFAULT,@ord_ref_cd, @a_tran_id, @line_descr, @cost, @iloop, @org_id, @control_org_id  
	  
					IF (@retval <= 0)  
					BEGIN  
						SET @msg = 'Error Inserting GL Costing Record ([' + convert(varchar,@retval) + '])!'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 94123 ,@msg  
						RETURN  
					END  
				END  
	  
				SELECT @iloop = @iloop + 1  
			END --While @iloop < 8  
		END -- @i_status = 'S' and @i_part_type NOT IN ('A','C','M','N')  
		  
		IF @i_status = 'T' AND @d_status < 'T'  
		BEGIN   
			IF @orders_eprocurement_ind = 1 AND @freight_per != 0 
			BEGIN  
				IF @company_id IS NULL  
				BEGIN  
					SELECT	@company_id = company_id, 
							@homecode = home_currency 
					FROM	glco (NOLOCK)  
				END  
  
				SELECT @line_freight = @freight_per * @shipped_qty  
				SELECT @control_org_id = dbo.adm_get_locations_org_fn(@i_location)  
	  
				IF @first_line = 1   
				BEGIN  
					SELECT @ord_ref_cd = ''        
					IF EXISTS (SELECT 1 FROM glrefact (NOLOCK) WHERE @freight_acct LIKE account_mask AND reference_flag > 1)  
					BEGIN  
						IF EXISTS (SELECT 1 FROM glratyp t (NOLOCK), glref r (NOLOCK)  
								WHERE t.reference_type = r.reference_type AND @freight_acct LIKE t.account_mask AND r.status_flag = 0 AND r.reference_code  = @i_reference_code)  
							SELECT @ord_ref_cd = @i_reference_code  
					END  
	  
					SELECT @orders_freight = -@orders_freight  
					EXEC @retval = adm_gl_insert  'FREIGHT',@i_location,'S',@i_order_no,@i_order_ext,0, @orders_date_shipped,1,@orders_freight,@freight_acct,@homecode,DEFAULT,DEFAULT,   
										@company_id, DEFAULT,'',0,'AR Freight Acct', @orders_freight, 0  
					IF (@retval <= 0)  
					BEGIN  
						SET @msg = 'Error Inserting Freight GL Costing Record ([' + convert(varchar,@retval) + '])!'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 94123, @msg  
						RETURN  
					END  
	  
					SELECT @line_freight = @line_freight - @rem_freight  
				END  
	  
				SELECT @org_id = dbo.IBOrgbyAcct_fn(@i_gl_rev_acct)  
	  
				EXEC @retval = adm_gl_insert  'FREIGHT',@i_location,'S',@i_order_no,@i_order_ext,0, @orders_date_shipped,@i_shipped,@freight_per,@i_gl_rev_acct,@homecode,DEFAULT,DEFAULT,  
										@company_id, DEFAULT,@i_reference_code,0,'expense acct - FRT', @line_freight, 0 , @org_id, @control_org_id  
				IF (@retval <= 0)  
				BEGIN  
					SET @msg = 'Error Inserting Frt Exp GL Costing Record ([' + convert(varchar,@retval) + '])!'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94123, @msg  
					RETURN  
				END  
			END
		END  
      
		IF (@d_qc_flag = 'Y' AND @d_lb_tracking = 'N') OR (@i_qc_flag = 'Y' AND @i_lb_tracking = 'N')  
		BEGIN  
			SELECT @tran_age = ISNULL(@orders_date_shipped,GETDATE())   
  
			IF @d_status IN ('P','Q') AND @d_cr_shipped > 0 AND @d_lb_tracking = 'N' AND @d_qc_flag = 'Y'  
			BEGIN  
				SELECT @qty=(@d_cr_shipped * @d_conv_factor)  
				IF @qcacct IS NULL   
					SELECT @qcacct=ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag='QC_STOCK_ACCOUNT'),'QC')  
  
				SELECT @im_status = ISNULL(( SELECT status FROM inv_master (NOLOCK) WHERE part_no = @i_part_no),'P')  
  
				EXEC @retval=fs_cost_delete @d_part_no, @d_location, @qty,'S', @d_order_no, @d_order_ext, @d_line_no,  
								@qcacct, @tran_date, @tran_age, @unitcost OUT, @direct OUT, @overhead OUT, @labor OUT, @utility OUT, 0,0,0,0,0, 0,0,0,0,0, @im_status, 'A', 'N'  
  
				IF (@retval=0)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94127, 'Costing Error... Try Re-Saving!'  
					RETURN  
				END   
			END   
  
			IF @i_status IN ('Q','P') AND @i_cr_shipped > 0 AND (@i_lb_tracking = 'N' OR @inv_lot_bin = 0) AND @i_qc_flag = 'Y'  
			BEGIN  
				SELECT @qty=(@i_cr_shipped * @i_conv_factor)  
  
				SELECT	@vend = vendor, 
						@im_status = status 
				FROM	inv_master (NOLOCK) 
				WHERE	part_no=@i_part_no  
      
				SELECT @im_status = ISNULL(@im_status,'P')  
  
				SELECT	@unitcost = avg_cost, 
						@direct = avg_direct_dolrs, 
						@overhead = avg_ovhd_dolrs,  
						@labor = labor, 
						@utility = avg_util_dolrs  
				FROM	inv_list (NOLOCK)  
				WHERE	part_no = @i_part_no 
				AND		location = @i_location  
  
				IF NOT EXISTS (SELECT * FROM qc_results (NOLOCK) WHERE qc_no=@i_qc_no)  
				BEGIN  
					EXEC fs_enter_qc 'C', @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @i_location, NULL, NULL, @qty, @vend, @i_who_entered, @i_reason_code, null  
				END  
				ELSE  
				BEGIN  
					UPDATE	qc_results  
					SET		qc_qty = @i_cr_shipped  
					WHERE	qc_no = @i_qc_no  
				END  
  
				IF @qcacct IS NULL   
					SELECT @qcacct = ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag='QC_STOCK_ACCOUNT'),'QC')  
  
				EXEC @retval=fs_cost_insert @i_part_no, @i_location, @qty, 'S', @i_order_no, @i_order_ext, @i_line_no,  
									@qcacct, @tran_date, @tran_age, @unitcost , @direct , @overhead , @labor , @utility, 0,0,0,0,0, 0,0,0,0,0, @im_status, 'A', 'N'  
  
				IF (@retval=0)   
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94129, 'Costing Error... Try Re-Saving!'  
					RETURN  
				END   
			END  
		END -- qc flagged  
      
		SELECT @qty = ((@i_shipped - @i_cr_shipped) * @i_conv_factor)  
  
		SELECT @stat = 'ORDL_UPD'  
  
		EXEC @tdc_rtn = tdc_order_list_change @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @qty, @stat  
  
		IF (@tdc_rtn < 0 )  
		BEGIN  
			EXEC adm_raiserror 74900 ,'Invalid Inventory Update From TDC.'  
		END  
  
		SELECT @first_line = 0  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,	
				@i_order_no = i_order_no,
				@i_order_ext = i_order_ext,
				@i_line_no = i_line_no,
				@i_location = i_location,
				@i_part_no = i_part_no,
				@i_ordered = i_ordered,
				@i_shipped = i_shipped,
				@i_price = i_price,
				@i_price_type = i_price_type,
				@i_status = i_status,
				@i_cost = i_cost,
				@i_who_entered = i_who_entered,
				@i_cr_shipped = i_cr_shipped,  
				@i_discount = i_discount,
				@i_uom = i_uom,
				@i_conv_factor = i_conv_factor,
				@i_lb_tracking = i_lb_tracking,
				@i_labor = i_labor,
				@i_direct_dolrs = i_direct_dolrs,
				@i_ovhd_dolrs = i_ovhd_dolrs,
				@i_util_dolrs = i_util_dolrs,
				@i_qc_flag = i_qc_flag,
				@i_reason_code = i_reason_code,
				@i_row_id = i_row_id,
				@i_qc_no = i_qc_no,
				@i_part_type = i_part_type,
				@i_back_ord_flag = i_back_ord_flag,
				@i_gl_rev_acct = i_gl_rev_acct,
				@i_tax_code = i_tax_code,
				@i_curr_price = i_curr_price,
				@i_oper_price = i_oper_price,
				@i_reference_code = i_reference_code,
				@i_ship_to = i_ship_to,
				@i_create_po_flag = i_create_po_flag,
				@i_organization_id = i_organization_id,
				@d_order_no = d_order_no,
				@d_order_ext = d_order_ext,
				@d_line_no = d_line_no,
				@d_location = d_location,
				@d_part_no = d_part_no,
				@d_ordered = d_ordered,
				@d_shipped = d_shipped,
				@d_price = d_price,
				@d_status = d_status,
				@d_cr_shipped = d_cr_shipped,
				@d_discount = d_discount,
				@d_conv_factor = d_conv_factor,
				@d_lb_tracking = d_lb_tracking,
				@d_qc_flag = d_qc_flag,
				@d_part_type = d_part_type,
				@d_gl_rev_acct = d_gl_rev_acct,
				@d_tax_code = d_tax_code,
				@d_curr_price = d_curr_price,
				@d_oper_price = d_oper_price,
				@d_create_po_flag = d_create_po_flag,
				@i_return_code = i_return_code,
				@d_return_code = i_return_code
		FROM	#t700updordl
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

END  
GO
ALTER TABLE [dbo].[ord_list] ADD CONSTRAINT [CK_ord_list_inv_available_flag] CHECK (([inv_available_flag]='N' OR [inv_available_flag]='Y'))
GO
CREATE NONCLUSTERED INDEX [ord_list5_121613] ON [dbo].[ord_list] ([cust_po]) INCLUDE ([order_ext], [order_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordlst4] ON [dbo].[ord_list] ([location], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ordlst1] ON [dbo].[ord_list] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordlst3] ON [dbo].[ord_list] ([order_no], [order_ext], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ol_orig_part] ON [dbo].[ord_list] ([orig_part_no]) INCLUDE ([line_no], [order_ext], [order_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_ordlst_partno_usage] ON [dbo].[ord_list] ([part_no]) INCLUDE ([cr_ordered], [cr_shipped], [location], [order_ext], [order_no], [ordered], [shipped]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordlst3m] ON [dbo].[ord_list] ([part_no], [location], [status], [part_type], [shipped], [conv_factor]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord_cr_shipped_ol] ON [dbo].[ord_list] ([part_no], [return_code]) INCLUDE ([cr_shipped], [order_ext], [order_no]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ordlst2] ON [dbo].[ord_list] ([row_id]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[ord_list] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_list] TO [public]
GO
GRANT REFERENCES ON  [dbo].[ord_list] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_list] TO [public]
GO
