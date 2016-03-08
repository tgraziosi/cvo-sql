CREATE TABLE [dbo].[ord_list_kit]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cr_ordered] [decimal] (20, 8) NOT NULL,
[cr_shipped] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_per] [decimal] (20, 8) NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_no] [int] NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ord_list_kit_insupddel] ON [dbo].[ord_list_kit]	FOR INSERT, UPDATE, DELETE  AS 
BEGIN
	DECLARE @ord_no int, @ord_ext int
	DECLARE @data varchar(30)
	Declare @credit_return_flag char(1), @type char(1)	-- rev 3

	select @credit_return_flag = 'N'	-- assume it's not a credit return
	select @type = orders.type from orders, inserted 
		where orders.order_no = inserted.order_no and orders.ext = inserted.order_ext
	if @type = 'C' select @credit_return_flag = 'Y'
	   
	select @type = orders.type from orders, deleted 
		where orders.order_no = deleted.order_no and orders.ext = deleted.order_ext
	if @type = 'C' select @credit_return_flag = 'Y'

	IF Exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%')
	BEGIN	--EAI enable

	   if (@credit_return_flag = 'N') begin		-- rev 3--can't be a credit return

		IF ((Exists( select 'X'
			from inserted i, deleted d
			where (i.order_no <> d.order_no) or 
				(i.order_ext <> d.order_ext) or
				(i.line_no <> d.line_no) or 
				(i.part_no <> d.part_no) or 
				(i.qty_per <> d.qty_per))) 
			or (Not Exists(select 'X' from deleted))
			or (Not Exists(select 'X' from inserted)))
		BEGIN	--orders has been changed or new orders, send data to Front Office
			--Assume there would be one sales order get insert, update or delete at a time
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

			if (@data <> '') begin	-- while loop for orders
				IF (Exists( SELECT 'X' FROM config WHERE flag = 'EAI_SEND_SO_IMAGE' and value_str like 'Y%'))
				BEGIN	--Send SO Image that create from BO to FO
					If (( @ord_no > '') AND (@ord_ext > ''))
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
						WHERE BO_order_no = @ord_no and BO_order_ext = @ord_ext))
					BEGIN
						-- Customized to avoid sending SOI for any with Misc Parts
						IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
						BEGIN
							exec EAI_process_insert 'SalesOrderImage', @data, 'BO'
						END
						-- End
					END
				END 	--End config for EAI_SEND_SO_IMAGE
			end	-- end while loop
		END	--End columns check
	   end	-- end rev 3--credit return check
	END  --End EAI enable
END
GO
DISABLE TRIGGER [dbo].[EAI_ord_list_kit_insupddel] ON [dbo].[ord_list_kit]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 26/03/2012 - Fix issue with committed figures being updated for kit items that are not real kits  
  
CREATE TRIGGER [dbo].[t700delordkit] ON [dbo].[ord_list_kit] FOR delete AS   
BEGIN  
  
if exists (select 1 from deleted where status >='S')  
begin  
 if exists (select 1 from config (nolock) where flag='TRIG_DEL_ORDL' and value_str='DISABLE')  
  return  
 else  
 begin  
  rollback tran  
  exec adm_raiserror 75731 ,'You Can NOT Delete An Order Item That Is Picked, Shipped Or Voided!'  
  return  
 end  
end  
if exists (select 1 from deleted where shipped > 0)  
begin  
 if exists (select 1 from config (nolock)  where flag='TRIG_DEL_ORDL' and value_str='DISABLE')  
  return  
 else  
 begin  
  rollback tran  
  exec adm_raiserror 75733, 'You Can NOT Delete An Order Item That Is Picked, Shipped Or Voided!'  
  return  
 end  
end  
  
DECLARE @d_order_no int, @d_order_ext int, @d_line_no int, @d_location varchar(10),  
@d_part_no varchar(30), @d_part_type char(1), @d_ordered decimal(20,8), @d_shipped decimal(20,8),  
@d_status char(1), @d_lb_tracking char(1), @d_cr_ordered decimal(20,8),  
@d_cr_shipped decimal(20,8), @d_uom char(2), @d_conv_factor decimal(20,8), @d_cost decimal(20,8),  
@d_labor decimal(20,8), @d_direct_dolrs decimal(20,8), @d_ovhd_dolrs decimal(20,8),  
@d_util_dolrs decimal(20,8), @d_note varchar(255), @d_qty_per decimal(20,8), @d_qc_flag char(1),  
@d_qc_no int, @d_description varchar(255), @d_row_id int  
  
declare @orders_load_no int, @load_master_status char(1),   
@msg varchar(255),  
@rc int, @mtd_qty decimal(20,8)  
  
DECLARE t700delord__cursor CURSOR LOCAL STATIC FOR  
SELECT d.order_no, d.order_ext, d.line_no, d.location, d.part_no, d.part_type, d.ordered,  
d.shipped, d.status, d.lb_tracking, d.cr_ordered, d.cr_shipped, d.uom, d.conv_factor, d.cost,  
d.labor, d.direct_dolrs, d.ovhd_dolrs, d.util_dolrs, d.note, d.qty_per, d.qc_flag, d.qc_no,  
d.description, d.row_id  
from deleted d  
  
OPEN t700delord__cursor  
  
if @@cursor_rows = 0  
begin  
CLOSE t700delord__cursor  
DEALLOCATE t700delord__cursor  
return  
end  
  
FETCH NEXT FROM t700delord__cursor into  
@d_order_no, @d_order_ext, @d_line_no, @d_location, @d_part_no, @d_part_type, @d_ordered,  
@d_shipped, @d_status, @d_lb_tracking, @d_cr_ordered, @d_cr_shipped, @d_uom, @d_conv_factor,  
@d_cost, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs, @d_note, @d_qty_per,  
@d_qc_flag, @d_qc_no, @d_description, @d_row_id  
  
  
  
While @@FETCH_STATUS = 0  
begin  
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
      exec adm_raiserror 75112,@msg  
      RETURN  
    end  
    if @load_master_status = 'C'  
    begin  
      select @msg = 'This order is on a Shipment that is in Credit Hold.  No changes are allowed until the '  
      select @msg = @msg + 'shipment is removed from Credit Hold.'  
      rollback tran  
      exec adm_raiserror 75113, @msg  
      RETURN  
    end  
  end            -- #34 end  

  -- v1.0 Start
  IF EXISTS (SELECT 1 FROM inv_master a (NOLOCK) JOIN what_part b (NOLOCK)
				ON a.part_no = b.asm_no WHERE b.part_no = @d_part_no AND a.status <> 'P')
  BEGIN

	  if ((@d_status = 'N' or @d_status='P' or @d_status='Q' or @d_status='R') and  
		((@d_ordered - @d_shipped) != 0) and @d_part_type='P')  
		update inv_sales   
		set commit_ed=(commit_ed - ((@d_ordered - @d_shipped) * @d_conv_factor * @d_qty_per))  
		where @d_part_no=inv_sales.part_no and @d_location=inv_sales.location   
	  
	  
	  if ( (@d_status = 'Q' or @d_status='P' or (@d_status='R' and @d_cr_shipped = 0)) and  
	 @d_part_type='P' )  
		update inv_sales   
		set hold_ord=(hold_ord - (@d_shipped * @d_conv_factor * @d_qty_per))  
		where (@d_part_no=inv_sales.part_no) and (@d_location=inv_sales.location)   
	  
	  if ( ((@d_shipped != 0 and (@d_status = 'R' or @d_status = 'Q' or @d_status='P'))   
	 OR (@d_cr_shipped != 0 and @d_status = 'R')) and  
	 @d_qc_flag != 'Y' and @d_part_type='P')  
	  begin  
		update inv_sales   
		set sales_qty_mtd=sales_qty_mtd - ((@d_shipped - @d_cr_shipped) * @d_conv_factor * @d_qty_per),  
	 sales_qty_ytd=sales_qty_ytd - ((@d_shipped - @d_cr_shipped) * @d_conv_factor * @d_qty_per)  
		where (@d_part_no=inv_sales.part_no) and (@d_location=inv_sales.location)  
	  
		-- mls 1/18/05 SCR 34050  
		select @mtd_qty = -((@d_shipped - @d_cr_shipped) * @d_conv_factor * @d_qty_per)  
		exec @rc = adm_inv_mtd_upd @d_part_no, @d_location, 'S', @mtd_qty  
		if @rc < 1  
		begin  
		  select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
		  rollback tran  
		  exec adm_raiserror 75114, @msg  
		  return  
		end  
	  end  
	  
	  delete lot_bin_ship  
	  where lot_bin_ship.tran_no=@d_order_no and lot_bin_ship.tran_ext=@d_order_ext and   
		lot_bin_ship.line_no=@d_line_no and lot_bin_ship.part_no=@d_part_no  
	  
	  declare @tdc_rtn int, @qty decimal(20,8)  
	  
	  select @qty=( (@d_shipped - @d_cr_shipped) * @d_conv_factor)  
	  exec @tdc_rtn = tdc_ord_list_kit_change @d_order_no, @d_order_ext, @d_line_no, @d_part_no,   
		@qty, 'ORDKIT_DEL'  
	  
	  if (@tdc_rtn< 0 )  
	  begin  
		exec adm_raiserror 74900 ,'Invalid Inventory Update From TDC.'  
	  end  

	END -- v1.0 End
  
FETCH NEXT FROM t700delord__cursor into  
@d_order_no, @d_order_ext, @d_line_no, @d_location, @d_part_no, @d_part_type, @d_ordered,  
@d_shipped, @d_status, @d_lb_tracking, @d_cr_ordered, @d_cr_shipped, @d_uom, @d_conv_factor,  
@d_cost, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs, @d_note, @d_qty_per,  
@d_qc_flag, @d_qc_no, @d_description, @d_row_id  
end -- while  
  
CLOSE t700delord__cursor  
DEALLOCATE t700delord__cursor  
  
END  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE TRIGGER [dbo].[t700insordkit] 
ON [dbo].[ord_list_kit] 
FOR insert 
AS   
BEGIN  
  
	IF EXISTS (SELECT 1 FROM config (nolock) WHERE flag = 'TRIG_INS_ORDK' AND value_str = 'DISABLE') RETURN  
  
	DECLARE	@cost				decimal(20,8),
			@type				char(1),  
			@homecode			varchar(8),
			@posting_code		varchar(8),  
			@rc					int, 
			@mtd_qty			decimal(20,8),  
			@iloop				int,
			@company_id			int,  
			@inv_acct			varchar(32), 
			@inv_direct			varchar(32), 
			@inv_ovhd			varchar(32), 
			@inv_util			varchar(32),  
			@cog_acct			varchar(32), 
			@cog_direct			varchar(32), 
			@cog_ovhd			varchar(32), 
			@cog_util			varchar(32),  
			@xlp				int, 
			@retval				int,
			@vend				varchar(10), 
			@who				varchar(20), 
			@rcode				varchar(10),  
			@part				varchar(30), 
			@loc				varchar(10), 
			@lot				varchar(25), 
			@bin				varchar(12),  
			@qty				decimal(20,8),
			@tran_code			char(1), 
			@tran_no			int, 
			@tran_ext			int, 
			@account			varchar(10),   
			@tran_date			datetime, 
			@unitcost			decimal(20,8), 
			@direct				decimal(20,8), 
			@overhead			decimal(20,8),  
			@labor				decimal(20,8), 
			@utility			decimal(20,8), 
			@tran_line			int, 
			@apply_date			datetime,  
			@orders_load_no		int, 
			@load_master_status char(1), 
			@msg				varchar(255),  
			@ol_status			char(1), 
			@tdc_rtn			int, 
			@stat				varchar(15),  
			@ol_part_no			varchar(30), 
			@ol_location		varchar(10),  
			@i_order_no			int, 
			@i_order_ext		int, 
			@i_line_no			int, 
			@i_location			varchar(10),  
			@i_part_no			varchar(30), 
			@i_part_type		char(1), 
			@i_ordered			decimal(20,8), 
			@i_shipped			decimal(20,8),  
			@i_status			char(1), 
			@i_lb_tracking		char(1), 
			@i_cr_ordered		decimal(20,8),  
			@i_cr_shipped		decimal(20,8), 
			@i_uom				char(2), 
			@i_conv_factor		decimal(20,8), 
			@i_qty_per			decimal(20,8), 
			@i_qc_flag			char(1),  
			@i_row_id			int 
  
	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.0 End

	SELECT  @company_id = company_id,  
			@homecode = home_currency  
	FROM	glco (NOLOCK)  

	CREATE TABLE #t700insordkit (
		row_id			int IDENTITY(1,1),
		i_order_no		int NULL, 
		i_order_ext		int NULL, 
		i_line_no		int NULL, 
		i_location		varchar(10) NULL,  
		i_part_no		varchar(30) NULL, 
		i_part_type		char(1) NULL, 
		i_ordered		decimal(20,8) NULL, 
		i_shipped		decimal(20,8) NULL,  
		i_status		char(1) NULL, 
		i_lb_tracking	char(1) NULL, 
		i_cr_ordered	decimal(20,8) NULL,  
		i_cr_shipped	decimal(20,8) NULL, 
		i_uom			char(2) NULL, 
		i_conv_factor	decimal(20,8) NULL, 
		i_qty_per		decimal(20,8) NULL, 
		i_qc_flag		char(1) NULL,  
		i_row_id		int NULL)

	INSERT #t700insordkit (i_order_no, i_order_ext, i_line_no, i_location, i_part_no, i_part_type, i_ordered, i_shipped, i_status, i_lb_tracking, i_cr_ordered, 
					i_cr_shipped, i_uom, i_conv_factor, i_qty_per, i_qc_flag, i_row_id)
	SELECT	i.order_no, i.order_ext, i.line_no, i.location, i.part_no, i.part_type, i.ordered, i.shipped, i.status, i.lb_tracking, i.cr_ordered, i.cr_shipped, 
			i.uom, i.conv_factor, i.qty_per, i.qc_flag, i.row_id  
	FROM	inserted i

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@i_order_no = i_order_no,
			@i_order_ext = i_order_ext,
			@i_line_no = i_line_no,
			@i_location = i_location,
			@i_part_no = i_part_no,
			@i_part_type = i_part_type,
			@i_ordered = i_ordered,
			@i_shipped = i_shipped,
			@i_status = i_status,
			@i_lb_tracking = i_lb_tracking,
			@i_cr_ordered = i_cr_ordered,
			@i_cr_shipped = i_cr_shipped,
			@i_uom = i_uom,
			@i_conv_factor = i_conv_factor,
			@i_qty_per = i_qty_per,
			@i_qc_flag = i_qc_flag,
			@i_row_id = i_row_id
	FROM	#t700insordkit
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		SELECT @ol_status = NULL  

		SELECT	@ol_status = status,  
				@ol_part_no = part_no,  
				@ol_location = location  
		FROM	ord_list (NOLOCK)  
		WHERE	order_no = @i_order_no 
		AND		order_ext = @i_order_ext 
		AND		line_no = @i_line_no 
		AND		(part_type = 'C' OR part_type = 'P') --AMENDEZ, 06/03/2010, 68668-FOC-001 Custom Frame Build  
  
		IF (@ol_status IS NULL)  
		BEGIN  
			SELECT @msg = 'Order List Item ([' + CONVERT(varchar,@i_order_no) + '-' + CONVERT(varchar,@i_order_ext) + '.' + CONVERT(varchar,@i_line_no) + ']) Missing.  The transaction is being rolled back.'  
			ROLLBACK TRAN  
			EXEC adm_raiserror 85703 ,@msg  
			RETURN  
		END  

		IF (@ol_part_no = @i_part_no)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 85701 ,'Kit Item Can NOT Be The Same As The Order List Item.  The transaction is being rolled back.'  
			RETURN  
		END  
  
		IF (@ol_location != @i_location)  
		BEGIN  
			UPDATE	ord_list_kit  
			SET		location = @ol_location  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no  
    
			SELECT @i_location = @ol_location  
		END  
  
		IF (@i_status >= 'S' OR @ol_status >= 'S')  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 85731, 'You Can NOT ADD To An Order Item That Is Shipped Or Voided!'  
			RETURN  
		END  
  
		IF (@i_status >= 'R' and @i_qc_flag='Y')     
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 85732, 'You Can NOT Ship/Close An Order Item That Is In QC Check!'  
			RETURN  
		END  
   
		SELECT	@orders_load_no = load_no
		FROM	orders_all (NOLOCK)  
		WHERE	order_no = @i_order_no 
		AND		ext = @i_order_ext  
  
		IF @@ROWCOUNT = 0  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 84101 ,'Primary key values not found in table dbo.orders.  The transaction is being rolled back.'  
			RETURN  
		END  
  
		IF ISNULL(@orders_load_no,0) != 0 
		BEGIN  
			SELECT	@load_master_status = ISNULL((SELECT status FROM load_master_all (NOLOCK) WHERE load_no = @orders_load_no),'N')  
			IF (@load_master_status = 'H')  
			BEGIN  
				SELECT @msg = 'This order is on a Shipment that is in User Hold.  No changes are allowed until the '  
				SELECT @msg = @msg + 'shipment is removed from User Hold.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 85112, @msg  
				RETURN  
			END  
			IF (@load_master_status = 'C')  
			BEGIN  
				SELECT @msg = 'This order is on a Shipment that is in Credit Hold.  No changes are allowed until the '  
				SELECT @msg = @msg + 'shipment is removed from Credit Hold.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 85113, @msg  
				RETURN  
			END  
		END
  
		IF (@i_status IN ('N','P','Q','R') AND @i_ordered - @i_shipped != 0 AND @i_part_type='P' )  
			OR (@i_status IN ('P','Q','R') AND @i_shipped != 0 AND @i_part_type='P')  
			OR (@i_status in ('P','Q','R') AND @i_cr_shipped != 0 AND @i_part_type='P' )  
			OR (@i_shipped != 0 AND @i_status in ('S','R','Q','P') AND @i_qc_flag != 'Y' AND @i_part_type='P')  
		BEGIN  
			/*START: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
			IF ((SELECT status FROM inv_master WHERE part_no = (SELECT part_no FROM ord_list WHERE order_no = @i_order_no AND order_ext = @i_order_ext AND line_no = @i_line_no)) <> 'P')  
			BEGIN  
				UPDATE	inv_sales   
				set		commit_ed = commit_ed + CASE WHEN (@i_status IN ('N','P','Q','R') AND (@i_ordered - @i_shipped) != 0 AND @i_part_type='P' )  
												THEN ((@i_ordered - @i_shipped) * @i_conv_factor * @i_qty_per) ELSE 0 END,  
						hold_ord = hold_ord + CASE WHEN (@i_status IN ('P','Q','R') AND @i_shipped != 0) AND @i_part_type='P'  
												THEN (@i_shipped * @i_conv_factor * @i_qty_per) ELSE 0 END,  
						qty_alloc = qty_alloc + CASE WHEN (@i_status IN ('P','Q','R') AND @i_cr_shipped != 0) AND @i_part_type='P'   
												THEN (@i_cr_shipped * @i_conv_factor * @i_qty_per) ELSE 0 END,  
						sales_qty_mtd = sales_qty_mtd + CASE WHEN @i_shipped != 0 AND (@i_status IN ('S','R','Q','P')) AND @i_qc_flag != 'Y' AND @i_part_type='P'  
												THEN ((@i_shipped - @i_cr_shipped) * @i_conv_factor * @i_qty_per) ELSE 0 END,  
						sales_qty_ytd = sales_qty_ytd + CASE WHEN @i_shipped != 0 AND (@i_status IN ('S','R','Q','P')) AND @i_qc_flag != 'Y' AND @i_part_type='P'  
												THEN ((@i_shipped - @i_cr_shipped) * @i_conv_factor * @i_qty_per) ELSE 0 END  
				WHERE	@i_part_no = inv_sales.part_no 
				AND		@i_location = inv_sales.location   
  
				IF @@rowcount = 0  
				BEGIN  
					SELECT @msg = 'Inventory Item ([' + @i_part_no + '/' + @i_location + ']) Missing.  The transaction is being rolled back.'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 85714, @msg  
					RETURN  
				END  
  
				SELECT	@mtd_qty = CASE WHEN @i_shipped != 0 AND (@i_status IN ('S','R','Q','P')) AND @i_qc_flag != 'Y' AND @i_part_type='P'  
									THEN ((@i_shipped - @i_cr_shipped) * @i_conv_factor * @i_qty_per) ELSE 0 END  
				IF (@mtd_qty <> 0)  
				BEGIN  
					EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @mtd_qty  
					IF (@rc < 1)  
					BEGIN  
						SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 9910141, @msg  
						RETURN  
					END  
				END  
			END  
			/*END: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
		END  
  
		SELECT	@stat = 'ORDKIT_INS',  
				@qty=( (@i_shipped - @i_cr_shipped) * @i_conv_factor)  
  
		EXEC @tdc_rtn = tdc_ord_list_kit_change @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @qty, @stat  
  
		IF (@tdc_rtn < 0 )  
		BEGIN  
			EXEC adm_raiserror 84900 ,'Invalid Inventory Update From TDC'  
		END  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_order_no = i_order_no,
				@i_order_ext = i_order_ext,
				@i_line_no = i_line_no,
				@i_location = i_location,
				@i_part_no = i_part_no,
				@i_part_type = i_part_type,
				@i_ordered = i_ordered,
				@i_shipped = i_shipped,
				@i_status = i_status,
				@i_lb_tracking = i_lb_tracking,
				@i_cr_ordered = i_cr_ordered,
				@i_cr_shipped = i_cr_shipped,
				@i_uom = i_uom,
				@i_conv_factor = i_conv_factor,
				@i_qty_per = i_qty_per,
				@i_qc_flag = i_qc_flag,
				@i_row_id = i_row_id
		FROM	#t700insordkit
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END  
END  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE TRIGGER [dbo].[t700updordkit] 
ON [dbo].[ord_list_kit] 
FOR UPDATE AS   
BEGIN  
  
	DECLARE	@i_order_no			int,   
			@i_order_ext		int,   
			@i_line_no			int,   
			@i_location			varchar(10),   
			@i_part_no			varchar(30),   
			@i_part_type		char(1),  
			@i_ordered			decimal(20,8),   
			@i_shipped			decimal(20,8),  
			@i_status			char(1),   
			@i_lb_tracking		char(1),   
			@i_cr_ordered		decimal(20,8),   
			@i_cr_shipped		decimal(20,8),    
			@i_uom				char(2),   
			@i_conv_factor		decimal(20,8),   
			@i_cost				decimal(20,8),   
			@i_labor			decimal(20,8),   
			@i_direct_dolrs		decimal(20,8),  
			@i_ovhd_dolrs		decimal(20,8),   
			@i_util_dolrs		decimal(20,8),   
			@i_qty_per			decimal(20,8),   
			@i_qc_flag			char(1),   
			@d_order_no			int,   
			@d_order_ext		int,   
			@d_line_no			int,   
			@d_location			varchar(10),   
			@d_part_no			varchar(30),   
			@d_part_type		char(1),  
			@d_ordered			decimal(20,8),   
			@d_shipped			decimal(20,8),  
			@d_status			char(1),   
			@d_lb_tracking		char(1),   
			@d_cr_ordered		decimal(20,8),   
			@d_cr_shipped		decimal(20,8),    
			@d_conv_factor		decimal(20,8),   
			@d_qty_per			decimal(20,8),   
			@d_qc_flag			char(1),   
			@cost				decimal(20,8),  
			@homecode			varchar(8),
			@posting_code		varchar(8),  
			@iloop				int,
			@company_id			int, 
			@type				char(1),  
			@inv_acct			varchar(32), 
			@inv_direct			varchar(32), 
			@inv_ovhd			varchar(32), 
			@inv_util			varchar(32),  
			@cog_acct			varchar(32), 
			@cog_direct			varchar(32), 
			@cog_ovhd			varchar(32), 
			@cog_util			varchar(32),  
			@acct_code			varchar(32), 
			@apply_date			datetime,  
			@temp_qty			decimal(20,8),  
			@ol_part_no			varchar(30), 
			@ol_location		varchar(10), 
			@ol_posting_code	varchar(8), 
			@prev_posting_code	varchar(8),  
			@var_acct			varchar(32), 
			@var_direct			varchar(32), 
			@var_ovhd			varchar(32), 
			@var_util			varchar(32),  
			@cogs_acct			varchar(32), 
			@cogs_direct		varchar(32), 
			@cogs_ovhd			varchar(32), 
			@cogs_util			varchar(32),  
			@cogs_mask			varchar(32),  
			@orders_eprocurement_ind int, 
			@rev_flag			int, 
			@aracct				varchar(32), 
			@ar_cgs_mask1		varchar(32), 
			@mask				varchar(32), 
			@i					int,
			@j					int, 
			@i1					int,	
			@retval				int, 
			@who				varchar(20), 
			@rcode				varchar(10),  
			@COGS				int, 
			@in_stock			decimal(20,8),  
			@qty				decimal(20,8), 
			@account			varchar(10),   
			@unitcost			decimal(20,8), 
			@direct				decimal(20,8), 
			@overhead			decimal(20,8),  
			@labor				decimal(20,8), 
			@utility			decimal(20,8),  
			@line_descr			varchar(50), 
			@tempqty			decimal(20,8),
			@rc					int, 
			@mtd_qty			decimal(20,8),  
			@a_tran_id			int, 
			@a_tran_qty			decimal(20,8), 
			@tempcost			decimal(20,8), 
			@a_tran_data		varchar(255),  
			@d_is_commit_ed		decimal(20,8), 
			@d_is_hold_ord		decimal(20,8), 
			@d_is_qty_alloc		decimal(20,8),  
			@d_is_sales_qty		decimal(20,8),  
			@i_is_commit_ed		decimal(20,8), 
			@i_is_hold_ord		decimal(20,8), 
			@i_is_qty_alloc		decimal(20,8),  
			@i_is_sales_qty		decimal(20,8),  
			@a_unitcost			decimal(20,8), 
			@a_direct			decimal(20,8), 
			@a_overhead			decimal(20,8), 
			@a_utility			decimal(20,8),  
			@a_labor			decimal(20,8),  
			@msg				varchar(255), 
			@d_amt				decimal(20,8), 
			@i_amt				decimal(20,8), 
			@orders_date_shipped datetime,  
			@inv_lot_bin		int,
			@orders_load_no		int, 
			@load_master_status char(1), 
			@orders_type		char(1),  
			@m_lb_tracking		char(1), 
			@lb_sum				decimal(20,8), 
			@part_cnt			int,  
			@lb_part			varchar(30), 
			@lb_loc				varchar(10), 
			@uom_sum			decimal(20,8),  
			@i_qty				decimal(20,8), 
			@outsync_cnt		int,
			@tdc_rtn			int, 
			@stat				varchar(15)    
  
	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int
	-- v1.0 End
  
	SELECT @rev_flag = NULL
  
	IF ((UPDATE(cost) OR UPDATE(qc_no)) AND NOT UPDATE(shipped) AND NOT UPDATE(cr_shipped) AND NOT UPDATE(conv_factor) AND NOT UPDATE(ordered) AND NOT UPDATE(cr_ordered) 
		AND NOT UPDATE(part_no) AND NOT UPDATE(location) AND NOT UPDATE(status) AND NOT UPDATE(qty_per))  
	BEGIN  
		RETURN  
	END  

	CREATE TABLE #t700updordkit (
		row_id				int IDENTITY(1,1),
		i_order_no			int NULL,   
		i_order_ext			int NULL,   
		i_line_no			int NULL,   
		i_location			varchar(10) NULL,   
		i_part_no			varchar(30) NULL,   
		i_part_type			char(1) NULL,  
		i_ordered			decimal(20,8) NULL,   
		i_shipped			decimal(20,8) NULL,  
		i_status			char(1) NULL,   
		i_lb_tracking		char(1) NULL,   
		i_cr_ordered		decimal(20,8) NULL,   
		i_cr_shipped		decimal(20,8) NULL,    
		i_uom				char(2) NULL,   
		i_conv_factor		decimal(20,8) NULL,   
		i_cost				decimal(20,8) NULL,   
		i_labor				decimal(20,8) NULL,   
		i_direct_dolrs		decimal(20,8) NULL,  
		i_ovhd_dolrs		decimal(20,8) NULL,   
		i_util_dolrs		decimal(20,8) NULL,   
		i_qty_per			decimal(20,8) NULL,   
		i_qc_flag			char(1) NULL,   
		d_order_no			int NULL,   
		d_order_ext			int NULL,   
		d_line_no			int NULL,   
		d_location			varchar(10) NULL,   
		d_part_no			varchar(30) NULL,   
		d_part_type			char(1) NULL,  
		d_ordered			decimal(20,8) NULL,   
		d_shipped			decimal(20,8) NULL,  
		d_status			char(1) NULL,   
		d_lb_tracking		char(1) NULL,   
		d_cr_ordered		decimal(20,8) NULL,   
		d_cr_shipped		decimal(20,8) NULL,     
		d_conv_factor		decimal(20,8) NULL,   
		d_qty_per			decimal(20,8) NULL,   
		d_qc_flag			char(1) NULL)

	INSERT	#t700updordkit (i_order_no, i_order_ext, i_line_no, i_location, i_part_no, i_part_type, i_ordered, i_shipped, i_status, i_lb_tracking, i_cr_ordered, i_cr_shipped, 
						i_uom, i_conv_factor, i_cost, i_labor, i_direct_dolrs, i_ovhd_dolrs, i_util_dolrs, i_qty_per, i_qc_flag, d_order_no, d_order_ext, d_line_no, d_location, 
						d_part_no, d_part_type, d_ordered, d_shipped, d_status, d_lb_tracking, d_cr_ordered, d_cr_shipped, d_conv_factor, d_qty_per, d_qc_flag)
	SELECT	i.order_no, i.order_ext, i.line_no, i.location, i.part_no, i.part_type, i.ordered, i.shipped, i.status, i.lb_tracking, i.cr_ordered, i.cr_shipped, i.uom, i.conv_factor, 
			i.cost, i.labor, i.direct_dolrs, i.ovhd_dolrs, i.util_dolrs, i.qty_per, i.qc_flag, d.order_no, d.order_ext, d.line_no, d.location, d.part_no, d.part_type, d.ordered,   
			d.shipped, d.status, d.lb_tracking, d.cr_ordered, d.cr_shipped, d.conv_factor, d.qty_per, d.qc_flag
	FROM	inserted i
	JOIN	deleted d  
	ON		i.row_id = d.row_id  
	ORDER BY i.order_no, i.order_ext, i.line_no  
	
	SELECT	@company_id = company_id,  
			@homecode = home_currency  
	FROM	glco (NOLOCK)  

	SELECT @inv_lot_bin = ISNULL((SELECT 1 FROM config (NOLOCK) WHERE flag = 'INV_LOT_BIN' AND UPPER(value_str) = 'YES' ),0)  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@i_order_no = i_order_no,
			@i_order_ext = i_order_ext,
			@i_line_no = i_line_no,
			@i_location = i_location,
			@i_part_no = i_part_no,
			@i_part_type = i_part_type,
			@i_ordered = i_ordered, 
			@i_shipped = i_shipped,
			@i_status = i_status,
			@i_lb_tracking = i_lb_tracking,
			@i_cr_ordered = i_cr_ordered,
			@i_cr_shipped = i_cr_shipped,
			@i_uom = i_uom,
			@i_conv_factor = i_conv_factor,
			@i_cost = i_cost,
			@i_labor = i_labor,
			@i_direct_dolrs = i_direct_dolrs,
			@i_ovhd_dolrs = i_ovhd_dolrs,
			@i_util_dolrs = i_util_dolrs,
			@i_qty_per = i_qty_per,
			@i_qc_flag = i_qc_flag,
			@d_order_no = d_order_no,
			@d_order_ext = d_order_ext,
			@d_line_no = d_line_no,
			@d_location = d_location,
			@d_part_no = d_part_no,
			@d_part_type = d_part_type,
			@d_ordered = d_ordered,
			@d_shipped = d_shipped,
			@d_status = d_status,
			@d_lb_tracking = d_lb_tracking,
			@d_cr_ordered = d_cr_ordered,
			@d_cr_shipped = d_cr_shipped,
			@d_conv_factor = d_conv_factor,
			@d_qty_per = d_qty_per,
			@d_qc_flag = d_qc_flag
	FROM	#t700updordkit
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
 
		IF @i_order_no != @d_order_no OR @i_order_ext != @d_order_ext OR @i_line_no != @d_line_no OR @i_part_no != @d_part_no OR @i_location != @d_location  
		BEGIN  
			IF EXISTS (SELECT 1 FROM ord_list ref (NOLOCK) WHERE ref.order_no = @i_order_no AND ref.order_ext = @i_order_ext 
						AND ref.line_no = @i_line_no AND ref.part_no=@i_part_no)  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95701, 'Kit Item Can NOT Be The Same As The Order List Item.  The transaction is being rolled back.'  
				RETURN  
			END  
			IF (@i_status >= 'S')  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95701, 'You cannot change a kit item after it has shipped.  The transaction is being rolled back.'  
				RETURN  
			END     
		END  
  
		IF @i_order_no != @d_order_no OR @i_order_ext != @d_order_ext OR @i_line_no != @d_line_no OR @i_status != @d_status OR @i_location != @d_location  
		BEGIN  
			SELECT	@ol_location = ISNULL((SELECT location FROM ord_list ref (NOLOCK) WHERE ref.order_no = @i_order_no AND ref.order_ext = @i_order_ext 
										AND ref.line_no = @i_line_no AND (ref.part_type = 'C' OR ref.part_type = 'P')),'') --AMENDEZ, 06/03/2010, 68668-FOC-001 Custom Frame Build  
  
			IF (@ol_location = '')  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95703, 'Primary key values not found in Order List.  The transaction is being rolled back.'  
				RETURN  
			END  
  
			IF (@ol_location != @i_location)  
			BEGIN  
				UPDATE	ord_list_kit  
				SET		location = @ol_location  
				WHERE	order_no = @i_order_no 
				AND		order_ext = @i_order_ext 
				AND		line_no = @i_line_no  
		
				SELECT @i_location = @ol_location  
			END  
		END  
    
		IF @i_part_type = 'P' AND ((@i_status NOT IN ('E','V') AND @d_status in ('E','V')) OR (@i_part_no != @d_part_no OR @i_location != @d_location))  
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM dbo.inv_list (NOLOCK) WHERE dbo.inv_list.part_no = @i_part_no AND dbo.inv_list.location = @i_location)  
			BEGIN  
				SELECT @msg = 'Inventory Item ([' + @i_part_no + '/' + @i_location + ']) Missing.  The transaction is being rolled back.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95705, @msg  
				RETURN  
			END  
		END  
  
		IF @i_status BETWEEN 'R' AND 'U' AND @i_qc_flag = 'Y'   
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 95731, 'You Can NOT Ship/Close An Order Item That Is In QC Check!'  
			RETURN  
		END  
   
		SELECT	@orders_load_no = load_no,  
				@orders_eprocurement_ind = ISNULL(eprocurement_ind,0),
				@orders_type = type,  
				@orders_date_shipped = date_shipped  
		FROM	orders_all (NOLOCK)  
		WHERE	order_no = @i_order_no 
		AND		ext = @i_order_ext  
  
		IF ISNULL(@orders_load_no,0) != 0          
		BEGIN  
			SELECT @load_master_status = ISNULL((SELECT status FROM load_master_all (NOLOCK) WHERE load_no = @orders_load_no),'N')  
			IF @load_master_status = 'H'  
			BEGIN  
				SELECT @msg = 'This order is on a Shipment that is in User Hold.  No changes are allowed until the '  
				SELECT @msg = @msg + 'shipment is removed from User Hold.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95112 ,@msg  
				RETURN  
			END  
    
			IF @load_master_status = 'C'  
			BEGIN  
				SELECT @msg = 'This order is on a Shipment that is in Credit Hold.  No changes are allowed until the '  
				SELECT @msg = @msg + 'shipment is removed from Credit Hold.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95113, @msg  
				RETURN  
			END  
		END
  
		IF @d_status IN ('S','T') AND @i_status < @d_status        
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94130 ,'You Can Unpost an Order that has posted!'  
			RETURN  
		END
  
		SELECT	@a_unitcost = @i_cost,         
				@a_direct = @i_direct_dolrs,   
				@a_overhead = @i_ovhd_dolrs,   
				@a_utility = @i_util_dolrs,  
				@a_labor = @i_labor   
  
		IF @i_status = 'S'  
		BEGIN  
			SELECT @m_lb_tracking = 'N'  
		
			IF @i_part_type = 'P'  
				SELECT @m_lb_tracking = ISNULL((SELECT lb_tracking FROM inv_master (NOLOCK) WHERE part_no = @i_part_no),NULL)  
    
			IF @m_lb_tracking IS NULL  
			BEGIN  
				SELECT @msg = 'Part ([' + @i_part_no + ']) does not exist in inventory.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832111, @msg  
				RETURN  
			END  
  
			IF @m_lb_tracking != @i_lb_tracking  
			BEGIN  
				SELECT @msg = 'Lot bin tracking flag mismatch with inventory for part [' + @i_part_no + '].'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832112, @msg  
				RETURN  
			END  
  
			SELECT	@lb_sum = ISNULL(SUM(qty * direction),0),  
					@uom_sum = ISNULL(SUM(uom_qty * direction),0),  
					@part_cnt = COUNT(DISTINCT (part_no + '!@#' + location)) ,  
					@outsync_cnt = SUM(CASE WHEN ROUND(qty/ conv_factor,8) <> uom_qty  THEN 1 ELSE 0 END),  
					@lb_part = ISNULL(MIN(part_no),''),  
					@lb_loc = ISNULL(MIN(location),'')  
			FROM	lot_bin_ship (NOLOCK)  
			WHERE	tran_no = @i_order_no 
			AND		tran_ext = @i_order_ext 
			AND		line_no = @i_line_no  
			AND		part_no = @i_part_no 
			AND		location = @i_location  
  
			IF @m_lb_tracking = 'Y'   
			BEGIN  
				IF @orders_type = 'I' OR (@orders_type = 'C' AND @inv_lot_bin = 1)  
				BEGIN  
					IF @part_cnt = 0 AND (@i_shipped - @i_cr_shipped) <> 0  
					BEGIN  
						SELECT @msg = 'No lot bin records found on lot_bin_ship for this kit item ([' + @i_part_no + ']).'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 832113 ,@msg  
						RETURN  
					END  
  
					SELECT @i_qty = -(@i_shipped - @i_cr_shipped) * @i_qty_per  
  
					SELECT @i_qty = @i_qty * @i_conv_factor  
					
					IF @lb_sum != @i_qty  
					BEGIN  
						SELECT @msg = 'Kit item qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) +   
										'] for part ([' + @i_part_no + ']).'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 832113, @msg  
						RETURN  
					END  
				END -- orders type I  
				ELSE  
				BEGIN  
					IF @inv_lot_bin = 0 AND @part_cnt > 0  
					BEGIN  
						SELECT @msg = 'You cannot have lot bin records on an inbound transaction when you are not lb tracking.'  
						ROLLBACK TRAN  
						EXEC adm_raiserror 832114, @msg  
						RETURN  
					END  
				END  
			END  
			ELSE  
			BEGIN  
				IF @part_cnt > 0  
				BEGIN  
					SELECT @msg = 'Lot bin records found on lot_bin_ship for this not lot/bin tracked part ([' + @i_part_no + ']).'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832114, @msg  
					RETURN  
				END  
			END  
		END  
  
		SELECT @a_tran_qty = 0 
		
		IF @i_part_type = 'P' OR @d_part_type = 'P'  
		BEGIN  
			SELECT	@i_is_commit_ed = 0, 
					@d_is_commit_ed = 0, 
					@i_is_hold_ord = 0, 
					@d_is_hold_ord = 0,  
					@i_is_qty_alloc = 0, 
					@d_is_qty_alloc = 0,  
					@i_is_sales_qty = 0, 
					@d_is_sales_qty = 0  
  
			SELECT	@i_is_commit_ed = ISNULL((SELECT CASE WHEN @i_status IN ('N','P','Q','R') AND (@i_ordered - @i_shipped) > 0 AND @i_part_type = 'P'  
												THEN ((@i_ordered - @i_shipped) * @i_conv_factor * @i_qty_per) ELSE 0 END),0),  
					@d_is_commit_ed = ISNULL((SELECT CASE WHEN @d_status IN ('N','P','Q','R') AND (@d_ordered - @d_shipped) > 0 AND @d_part_type = 'P'  
												THEN ((@d_ordered - @d_shipped) * @d_conv_factor * @d_qty_per) ELSE 0 END),0)  
			
			SELECT	@i_is_hold_ord = ISNULL((SELECT CASE WHEN (@i_status IN ('R','Q','P') AND @i_shipped != 0) AND @i_part_type = 'P' 
												THEN (@i_shipped * @i_conv_factor * @i_qty_per) ELSE 0 END),0),  
					@d_is_hold_ord = ISNULL((SELECT CASE WHEN (@d_status IN ('R','Q','P') AND @d_shipped != 0) AND @d_part_type = 'P' 
												THEN (@d_shipped * @d_conv_factor * @d_qty_per) ELSE 0 END),0)  
    
			SELECT	@i_is_qty_alloc = ISNULL((SELECT CASE WHEN (@i_status IN ('R','Q','P') AND @i_cr_shipped != 0) AND @i_part_type = 'P'  
												THEN (@i_cr_shipped * @i_conv_factor * @i_qty_per) ELSE 0 END),0),  
					@d_is_qty_alloc = ISNULL((SELECT CASE WHEN (@d_status IN ('R','Q','P') AND @d_cr_shipped != 0) AND @d_part_type = 'P'  
												THEN (@d_cr_shipped * @d_conv_factor * @d_qty_per) ELSE 0 END),0)  
    
			SELECT	@i_is_sales_qty = ISNULL((SELECT CASE WHEN ((@i_shipped != 0 AND @i_status IN ('P','Q','R','S')) OR (@i_cr_shipped != 0 AND @i_status = 'S')) 
															AND @i_qc_flag != 'Y' AND @i_part_type = 'P'  
												THEN ((@i_shipped - @i_cr_shipped) * @i_qty_per) ELSE 0 END),0),  
					@d_is_sales_qty = ISNULL((SELECT CASE WHEN ((@d_shipped != 0 AND @d_status IN ('P','Q','R','S')) OR (@d_cr_shipped != 0 AND @d_status = 'S')) 
															AND (@i_status <= 'S' OR @i_status = 'V') AND @d_qc_flag != 'Y' AND @d_part_type = 'P'  
												THEN ((@d_shipped - @d_cr_shipped) * @d_qty_per) ELSE 0 END),0)  
  
			SELECT	@d_amt = 0, 
					@i_amt = 0, 
					@a_tran_qty = 0  
		
			IF (@i_part_no != @d_part_no OR @i_location != @d_location OR @i_is_sales_qty != @d_is_sales_qty OR (@i_status = 'S' AND @d_status < 'S'))  
			BEGIN  
				IF (@i_status IN ('S','T') AND @d_status IN ('S','T')) AND (@i_is_sales_qty != @d_is_sales_qty OR @i_part_no != @d_part_no OR @i_location != @d_location)  
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
  
				IF @a_tran_qty != 0  
				BEGIN  
					SELECT	@a_unitcost = @a_unitcost * @a_tran_qty, 
							@a_direct = @a_direct * @a_tran_qty,  
							@a_overhead = @a_overhead * @a_tran_qty, 
							@a_utility = @a_utility * @a_tran_qty,  
							@a_labor = @a_labor * @a_tran_qty  
  
					SELECT  @a_tran_data = @i_part_type +   
							CONVERT(varchar(30),@d_is_hold_ord) + REPLICATE(' ',30 - DATALENGTH(CONVERT(varchar(30),@d_is_hold_ord)))  
  
					EXEC @retval = adm_inv_tran 'K', @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @orders_date_shipped, @i_uom,   
										@i_conv_factor, @i_status, @a_tran_data, DEFAULT, @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,  
										@COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT  
					IF @retval <> 1  
					BEGIN  
						ROLLBACK TRAN  
						SELECT @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'  
						EXEC adm_raiserror 83202, @msg  
						RETURN  
					END  
				END  
			END  
    
			IF (@i_part_no != @d_part_no OR @i_location != @d_location OR @i_is_commit_ed != @d_is_commit_ed OR @i_is_hold_ord != @d_is_hold_ord 
				OR @i_is_qty_alloc != @d_is_qty_alloc OR @i_is_sales_qty != @d_is_sales_qty)  
			BEGIN  
				IF @i_part_no = @d_part_no AND @i_location = @d_location  
				BEGIN  
					/*START: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
					IF ((SELECT status FROM inv_master WHERE part_no = (SELECT part_no FROM ord_list WHERE order_no = @i_order_no AND order_ext = @i_order_ext AND line_no = @i_line_no)) <> 'P')  
					BEGIN  
						UPDATE	inv_sales  
						SET		commit_ed = commit_ed - @d_is_commit_ed + @i_is_commit_ed,  
								hold_ord = hold_ord - @d_is_hold_ord + @i_is_hold_ord,  
								qty_alloc = qty_alloc - @d_is_qty_alloc + @i_is_qty_alloc,  
								sales_qty_mtd = sales_qty_mtd - @d_amt + @i_amt,  
								sales_qty_ytd = sales_qty_ytd - @d_amt + @i_amt  
						WHERE	part_no = @i_part_no 
						AND		location = @i_location  
  
						SELECT	@mtd_qty = (@i_amt - @d_amt)  
						EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @mtd_qty  
						IF @rc < 1  
						BEGIN  
							SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
							ROLLBACK TRAN  
							EXEC adm_raiserror 83203, @msg  
							RETURN  
						END  
					END  
					/*END: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
				END  
				ELSE  
				BEGIN    
					/*START: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
					IF ((SELECT status FROM inv_master WHERE part_no = (SELECT part_no FROM ord_list WHERE order_no = @i_order_no AND order_ext = @i_order_ext AND line_no = @i_line_no)) <> 'P')  
					BEGIN  
						UPDATE	inv_sales  
						set		commit_ed = commit_ed - @d_is_commit_ed,  
								hold_ord = hold_ord - @d_is_hold_ord,  
								qty_alloc = qty_alloc - @d_is_qty_alloc,  
								sales_qty_mtd = sales_qty_mtd - @d_amt,  
								sales_qty_ytd = sales_qty_ytd - @d_amt   
						WHERE	part_no = @d_part_no 
						AND		location = @d_location 
						AND		@d_part_type = 'P'  
  
						SELECT @mtd_qty = -@d_amt  
						EXEC @rc = adm_inv_mtd_upd @d_part_no, @d_location, 'S', @mtd_qty  
						IF @rc < 1  
						BEGIN  
							SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
							ROLLBACK TRAN  
							EXEC adm_raiserror 83204, @msg  
							RETURN  
						END  
  
						UPDATE	inv_sales  
						set		commit_ed = commit_ed + @i_is_commit_ed ,  
								hold_ord = hold_ord + @i_is_hold_ord ,  
								qty_alloc = qty_alloc + @i_is_qty_alloc ,  
								sales_qty_mtd = sales_qty_mtd + @i_amt ,  
								sales_qty_ytd = sales_qty_ytd + @i_amt   
						WHERE	part_no = @i_part_no 
						AND		location = @i_location 
						AND		@i_part_type = 'P'  
  
						EXEC @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'S', @i_amt  
						IF @rc < 1  
						BEGIN  
							SELECT @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
							ROLLBACK TRAN  
							EXEC adm_raiserror 83205, @msg  
							RETURN  
						END  
					END  
					/*END: 06/04/2010, AMENDEZ, 68668-FOC-001 Custom Frame Build*/  
				END -- part/loc changed  
			END -- part/loc or amt changed  
		END -- part type  P  
  
		IF @i_status IN ('V','N') AND @i_part_type = 'P'  
		BEGIN  
			DELETE	lot_bin_ship   
			WHERE	tran_no = @i_order_no 
			AND		tran_ext = @i_order_ext 
			AND		line_no = @i_line_no 
			AND		part_no = @i_part_no  
		END  
  
		IF @i_status = 'S' AND @d_status < 'S' AND @a_tran_qty != 0  
		BEGIN  
			IF @orders_date_shipped IS NULL  
				SELECT @orders_date_shipped = GETDATE()  
  
			SELECT @qty = -@a_tran_qty  
			SELECT	@aracct = gl_rev_acct,  
					@ol_part_no = part_no,
					@ol_location = location  
			FROM	ord_list (NOLOCK)  
			WHERE	order_no = @i_order_no 
			AND		order_ext = @i_order_ext 
			AND		line_no = @i_line_no
  
			SELECT	@posting_code = acct_code  
			FROM	inv_list (NOLOCK)  
			WHERE	part_no = @i_part_no 
			AND		location = @i_location  
  
			IF @posting_code = NULL OR @posting_code = ''  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95726, 'Posting Code not defined on Inv Item. Please Fix Inventory and Re-save!'  
				RETURN  
			END  
  
			SELECT @ol_posting_code = ISNULL((SELECT acct_code FROM inv_list (NOLOCK) WHERE part_no = @ol_part_no and location = @ol_location),NULL)  
  
			IF @ol_posting_code IS NULL  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 95727, 'Posting Code not defined on KIT Item. Please Fix Inventory and Re-save!'  
				RETURN  
			END   
  
			IF ISNULL(@prev_posting_code,'') != @ol_posting_code  
			BEGIN  
				SELECT	@cogs_acct = ar_cgs_code,  
						@cogs_direct = ar_cgs_direct_code,  
						@cogs_ovhd = ar_cgs_ovhd_code,  
						@cogs_util = ar_cgs_util_code,  
						@cogs_mask = ar_cgs_mask  
				FROM	in_account (NOLOCK)  
				WHERE	acct_code = @ol_posting_code         
  
				SELECT @prev_posting_code = @ol_posting_code  
			END    
  
			SELECT	@mask = @cogs_mask,  
					@cog_acct = @cogs_acct,  
					@cog_direct = @cogs_direct,  
					@cog_ovhd = @cogs_ovhd,  
					@cog_util = @cogs_util
  
			SELECT	@inv_acct = inv_acct_code,  
					@inv_direct = inv_direct_acct_code,  
					@inv_ovhd = inv_ovhd_acct_code,  
					@inv_util = inv_util_acct_code,  
					@var_acct = cost_var_code,  
					@var_direct = cost_var_direct_code,  
					@var_ovhd = cost_var_ovhd_code,  
					@var_util = cost_var_util_code  
			FROM	in_account (NOLOCK)  
			WHERE	acct_code = @posting_code  
  
			IF @orders_eprocurement_ind = 1 
			BEGIN  
				SELECT  @cog_acct = @aracct  
				SELECT  @cog_direct = @aracct       
				SELECT  @cog_ovhd = @aracct       
				SELECT  @cog_util = @aracct       
			END  
			ELSE  
			BEGIN   
				IF @rev_flag IS NULL SELECT @rev_flag = ISNULL((SELECT default_rev_flag FROM arco (NOLOCK)),0) 
  
			    IF @rev_flag = 0 AND RTRIM(ISNULL(@mask,'')) <> ''      
				BEGIN  
					IF ( ISNULL(@aracct,'') != '' ) AND ( @aracct != SPACE(32) )    
					BEGIN  
						SELECT @ar_cgs_mask1 = '--------------------------------'  
						SELECT  @j = DATALENGTH( RTRIM( @aracct ) )  
						SELECT @i1 = DATALENGTH(rtrim(@mask))  
						SELECT @i = 1  
						SELECT @ar_cgs_mask1 = STUFF(@ar_cgs_mask1, 1, 1, SUBSTRING(@mask, 1, @i1))  
  
						SELECT @mask = @ar_cgs_mask1  
  
						WHILE ( @i <= @j )  
						BEGIN  
							IF (SUBSTRING( @mask, @i, 1 ) = '_') OR (SUBSTRING( @mask, @i, 1 ) = '-') OR (SUBSTRING( @mask, @i, 1 ) = ' ')  
								SELECT  @mask = STUFF( @mask, @i, 1, SUBSTRING( @aracct, @i, 1 ))  

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
  
			--Insert GL Tran For inventory  
    
			SELECT @iloop = 1  
  
			WHILE @iloop <= 12  
			BEGIN   
  
				SELECT	@cost = CASE @iloop  
								 WHEN 1 THEN @unitcost  --Inventory Adjustments (CR Inv on Invoice / DB on a return)  
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
								 END,  
						@acct_code = CASE @iloop  
								 WHEN 1 THEN @inv_acct  --Inventory Adjustments  
								 WHEN 2 THEN @inv_direct  
								 WHEN 3 THEN @inv_ovhd  
								 WHEN 4 THEN @inv_util  
								 WHEN 5 THEN @cog_acct --COGS Adjustments  
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
  
				SELECT @tempqty = CASE WHEN @iloop BETWEEN 1 AND 4 THEN @qty * -1 ELSE @qty END  
  
				IF @orders_eprocurement_ind = 1 AND @iloop BETWEEN 4 AND 9
					SELECT @line_descr = 'expense account'  
  
				IF @cost <> 0 or @iloop = 1  
				BEGIN  
					SELECT @tempcost = @cost / @tempqty  
					EXEC @retval = adm_gl_insert @i_part_no,@i_location,'S',@i_order_no,@i_order_ext, @i_line_no, @orders_date_shipped,@tempqty,@tempcost,@acct_code,@homecode,DEFAULT,DEFAULT,  
										@company_id, DEFAULT,DEFAULT, @a_tran_id, @line_descr, @cost, @iloop  
					IF @retval <= 0  
					BEGIN  
						ROLLBACK TRAN  
						EXEC adm_raiserror 95721, 'Error Inserting GL Costing Record!'   
						RETURN  
					END  
				END   
  
				SELECT @iloop = @iloop + 1  
			END --While @iloop < 12  
		END -- status = 'S'  
  		
		SELECT @stat = 'ORDKIT_UPD'  
  
		SELECT @qty=((@i_shipped - @i_cr_shipped) * @i_qty_per * @i_conv_factor)  
		EXEC @tdc_rtn = tdc_ord_list_kit_change @i_order_no, @i_order_ext, @i_line_no, @i_part_no, @qty, @stat  
  
		IF (@tdc_rtn< 0 )  
			EXEC adm_raiserror 74900 ,'Invalid Inventory Update From TDC.'  
    
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_order_no = i_order_no,
				@i_order_ext = i_order_ext,
				@i_line_no = i_line_no,
				@i_location = i_location,
				@i_part_no = i_part_no,
				@i_part_type = i_part_type,
				@i_ordered = i_ordered, 
				@i_shipped = i_shipped,
				@i_status = i_status,
				@i_lb_tracking = i_lb_tracking,
				@i_cr_ordered = i_cr_ordered,
				@i_cr_shipped = i_cr_shipped,
				@i_uom = i_uom,
				@i_conv_factor = i_conv_factor,
				@i_cost = i_cost,
				@i_labor = i_labor,
				@i_direct_dolrs = i_direct_dolrs,
				@i_ovhd_dolrs = i_ovhd_dolrs,
				@i_util_dolrs = i_util_dolrs,
				@i_qty_per = i_qty_per,
				@i_qc_flag = i_qc_flag,
				@d_order_no = d_order_no,
				@d_order_ext = d_order_ext,
				@d_line_no = d_line_no,
				@d_location = d_location,
				@d_part_no = d_part_no,
				@d_part_type = d_part_type,
				@d_ordered = d_ordered,
				@d_shipped = d_shipped,
				@d_status = d_status,
				@d_lb_tracking = d_lb_tracking,
				@d_cr_ordered = d_cr_ordered,
				@d_cr_shipped = d_cr_shipped,
				@d_conv_factor = d_conv_factor,
				@d_qty_per = d_qty_per,
				@d_qc_flag = d_qc_flag
		FROM	#t700updordkit
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

END  
GO
CREATE UNIQUE CLUSTERED INDEX [ordlstkit1] ON [dbo].[ord_list_kit] ([order_no], [order_ext], [line_no], [location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ordlstkit2m] ON [dbo].[ord_list_kit] ([part_no], [location], [status], [part_type], [shipped], [conv_factor], [qty_per]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO

GRANT REFERENCES ON  [dbo].[ord_list_kit] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_list_kit] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_list_kit] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_list_kit] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_list_kit] TO [public]
GO
