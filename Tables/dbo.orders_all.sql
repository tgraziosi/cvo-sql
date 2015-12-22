CREATE TABLE [dbo].[orders_all]
(
[timestamp] [timestamp] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[req_ship_date] [datetime] NOT NULL,
[sch_ship_date] [datetime] NULL,
[date_shipped] [datetime] NULL,
[date_entered] [datetime] NOT NULL,
[cust_po] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attention] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[routing] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[special_instr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_date] [datetime] NULL,
[total_invoice] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__orders_al__total__2452ACB0] DEFAULT ((0)),
[total_amt_order] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__orders_al__total__2546D0E9] DEFAULT ((0)),
[salesperson] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_perc] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__orders_al__tax_p__263AF522] DEFAULT ((0)),
[invoice_no] [int] NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__freig__272F195B] DEFAULT ((0)),
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[discount] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__disco__28233D94] DEFAULT ((0)),
[label_no] [int] NULL,
[cancel_date] [datetime] NULL,
[new] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_add_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_country] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cash_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[back_ord_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_allow_pct] [decimal] (20, 8) NULL,
[route_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[route_no] [decimal] (20, 8) NULL,
[date_printed] [datetime] NULL,
[date_transfered] [datetime] NULL,
[cr_invoice_no] [int] NULL,
[who_picked] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[changed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remit_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[forwarder_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_comm] [decimal] (20, 8) NULL,
[freight_allow_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_dfpa] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__total__291761CD] DEFAULT ((0)),
[total_discount] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__total__2A0B8606] DEFAULT ((0)),
[f_note] [varchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[invoice_edi] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[edi_batch] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[post_edi_date] [datetime] NULL,
[blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[gross_sales] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__gross__2AFFAA3F] DEFAULT ((0)),
[load_no] [int] NULL CONSTRAINT [DF__orders_al__load___2BF3CE78] DEFAULT ((0)),
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__curr___2CE7F2B1] DEFAULT ((1)),
[bill_to_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__oper___2DDC16EA] DEFAULT ((1)),
[tot_ord_tax] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__tot_o__2ED03B23] DEFAULT ((0)),
[tot_ord_disc] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__tot_o__2FC45F5C] DEFAULT ((0)),
[tot_ord_freight] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__tot_o__30B88395] DEFAULT ((0)),
[posting_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dest_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_no] [int] NULL CONSTRAINT [DF__orders_al__orig___31ACA7CE] DEFAULT ((0)),
[orig_ext] [int] NULL CONSTRAINT [DF__orders_al__orig___32A0CC07] DEFAULT ((0)),
[tot_tax_incl] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__tot_t__3394F040] DEFAULT ((0)),
[process_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__orders_al__proce__34891479] DEFAULT (' '),
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__orders_al__batch__357D38B2] DEFAULT ('0'),
[tot_ord_incl] [decimal] (20, 8) NULL CONSTRAINT [DF__orders_al__tot_o__36715CEB] DEFAULT ((0)),
[barcode_status] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[multiple_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__orders_al__multi__37658124] DEFAULT ('N'),
[so_priority_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FO_order_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket_amt] [float] NULL,
[user_priority] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_date] [datetime] NULL,
[to_date] [datetime] NULL,
[consolidate_flag] [smallint] NULL CONSTRAINT [DF_orders_consolidate_flag] DEFAULT ((0)),
[proc_inv_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_proc_inv_no] DEFAULT (''),
[sold_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_def_fld1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_user_def_fld1] DEFAULT (''),
[user_def_fld2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_user_def_fld2] DEFAULT (''),
[user_def_fld3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_user_def_fld3] DEFAULT (''),
[user_def_fld4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_user_def_fld4] DEFAULT (''),
[user_def_fld5] [float] NULL CONSTRAINT [DF_orders_user_def_fld5] DEFAULT ((0.0)),
[user_def_fld6] [float] NULL CONSTRAINT [DF_orders_user_def_fld6] DEFAULT ((0.0)),
[user_def_fld7] [float] NULL CONSTRAINT [DF_orders_user_def_fld7] DEFAULT ((0.0)),
[user_def_fld8] [float] NULL CONSTRAINT [DF_orders_user_def_fld8] DEFAULT ((0.0)),
[user_def_fld9] [int] NULL CONSTRAINT [DF_orders_user_def_fld9] DEFAULT ((0)),
[user_def_fld10] [int] NULL CONSTRAINT [DF_orders_user_def_fld10] DEFAULT ((0)),
[user_def_fld11] [int] NULL CONSTRAINT [DF_orders_user_def_fld11] DEFAULT ((0)),
[user_def_fld12] [int] NULL CONSTRAINT [DF_orders_user_def_fld12] DEFAULT ((0)),
[eprocurement_ind] [int] NULL CONSTRAINT [DF_orders_eprocurement_ind] DEFAULT ((0)),
[sold_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sopick_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_orders_sopick_ctrl_num] DEFAULT (''),
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_picked_dt] [datetime] NULL,
[internal_so_ind] [int] NULL,
[ship_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sold_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_valid_ind] [int] NULL,
[addr_valid_ind] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE TRIGGER [dbo].[EAI_orders_insupd] ON [dbo].[orders_all]	FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @ord_no int, @ord_ext int
	DECLARE @data varchar(150)
	DECLARE @status varchar(1)		-- rev 1
	DECLARE @post_shipments_flag varchar(1)	-- rev 1
	/* begin rev 2 */
	DECLARE @type varchar(1), @credit_return_flag varchar(1), @pur_prod_part varchar(30), @line_no int
	DECLARE @shipped decimal(20,8), @serial_flag int, @pur_prod_qty decimal(20,8), @sa_part varchar(30)
	DECLARE @serial_no varchar(25)
	/* end rev 2 */
	Declare @last_ord_no int, @last_ord_ext int	-- rev 4
	Declare @kit_code char(1), @counter int		-- rev 9

	IF Exists( SELECT * FROM config  WHERE 	flag = 'EAI' and value_str like 'Y%') BEGIN	--EAI enabled
	   /* rev 1, 2 */
	   select @post_shipments_flag = 'N'	-- assume we're updating orders, not posting shipments
	   select @credit_return_flag = 'N'	-- assume it's not a credit return

	   select @status = i.status, @type = i.type from inserted i
	   if @status in ('S', 'T') select @post_shipments_flag = 'Y'
	   if @type = 'C' select @credit_return_flag = 'Y'
	   
	   select @status = d.status, @type = d.type from deleted d
	   if @status in ('S', 'T') select @post_shipments_flag = 'Y'	-- rev 3
	   if @type = 'C' select @credit_return_flag = 'Y'
		
	   if (@credit_return_flag = 'N') begin	-- rev 5
	     if (@post_shipments_flag = 'N') begin
		-- check to see if we need to send orders document
	   /* end rev 1, 2 */	   
		IF ((Exists( select distinct 'X'
			from inserted i, deleted d
			where (i.order_no <> d.order_no) or 
				(i.ext <> d.ext) or
				(i.cust_code <> d.cust_code) or 
				(i.bill_to_key <> d.bill_to_key) or 
				(i.remit_key <> d.remit_key) or 
				(i.attention <> d.attention) or 
				(i.cust_po <> d.cust_po) or
				(i.back_ord_flag <> d.back_ord_flag) or 
				(i.blanket <> d.blanket) or 
				(i.curr_key <> d.curr_key) or 
				(i.req_ship_date <> d.req_ship_date) or 
				(i.sch_ship_date <> d.sch_ship_date) or
				(i.discount <> d.discount) or 
				(i.fob <> d.fob) or 
				(i.forwarder_key <> d.forwarder_key) or 
				(i.freight <> d.freight) or 
				(i.freight_allow_type<> d.freight_allow_type) or
				(i.hold_reason <> d.hold_reason) or 
				(i.location <> d.location) or 
				(i.ship_to_region <> d.ship_to_region) or 
				(i.note <> d.note) or 
				(i.special_instr <> d.special_instr) or 
				(i.posting_code <> d.posting_code) or 
				(i.phone <> d.phone) or 
				(i.type <> d.type) or 
				(i.status <> d.status) or 
				(i.tax_id <> d.tax_id) or 
				(i.tax_perc <> d.tax_perc) or 
				(i.terms <> d.terms) or 
				(i.routing <> d.routing) or 
				(i.cancel_date <> d.cancel_date) or 
				(i.total_amt_order <> d.total_amt_order) or 
				(i.tot_ord_disc <> d.tot_ord_disc) or 
				(i.tot_ord_tax <> d.tot_ord_tax) or 
				(i.tot_ord_freight <> d.tot_ord_freight) or 
				(i.date_entered <> d.date_entered) or 
				(i.who_entered <> d.who_entered))) 
			or (Not Exists(select 'X' from deleted))
			or (Not Exists(select 'X' from inserted)))
		BEGIN	--orders has been changed or new orders, send data to Front Office
			/* begin rev 4 */
			select @last_ord_no = ''
			select @last_ord_ext = ''
			select @data = ''

			while 1 = 1 begin	-- loop through until the break

				Set ROWCOUNT 1
				
				if (exists(select 'X' from inserted)) begin	-- insert or update
					select @ord_no = order_no, @ord_ext = ext from inserted
					where convert(char(12), order_no) + convert(char(12), ext) >
					      convert(char(12), @last_ord_no) + convert(char(12),  @last_ord_ext)
					order by order_no, ext
				end
				else begin	-- deleted 
					select @ord_no = order_no, @ord_ext = ext from deleted
					where convert(char(12), order_no) + convert(char(12), ext) >
					      convert(char(12), @last_ord_no) + convert(char(12),  @last_ord_ext)
					order by order_no, ext
				end
				
				If @@Rowcount <= 0 BREAK	-- this will exit the loop!
				Set ROWCOUNT 0

				if exists(select @ord_no) and exists(select @ord_ext)
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)
				else
					select @data = '|'	-- rev 6
				
				if (@data > '') and (@data <> '|') begin	-- orders
				   IF (Exists( SELECT 'X' FROM	config WHERE flag = 'EAI_SEND_SO_IMAGE' and value_str like 'Y%'))
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
				   END
				end	-- end
				
				select @last_ord_no = @ord_no
				select @last_ord_ext = @ord_ext
				select @data = ''
			end -- end while loop	/* end rev 4 */
		END
	    end	-- end of not credit return, rev 5
	   /* rev 1, 2 */
	   end -- end orders update


	/*--------------------------------------------------------------------------------------------------------*/
	-- the status is for posting shipments
	-- send the shipments notice if the shipment has changed.
	-- may also have to send the purchased products and/or the service agreement
	/*--------------------------------------------------------------------------------------------------------*/
	   if @post_shipments_flag = 'Y' begin	
		-- first check for shipments document -- if we're posting shipments, there should be one!
			/* begin rev 4 */
			select @last_ord_no = ''
			select @last_ord_ext = ''
			select @data = ''

			while 1 = 1 begin	-- loop through until the break

				Set ROWCOUNT 1
				
				if (exists(select 'X' from inserted)) begin	-- insert or update
					select @ord_no = order_no, @ord_ext = ext from inserted
					where convert(char(12), order_no) + convert(char(12), ext) >
					      convert(char(12), @last_ord_no) + convert(char(12),  @last_ord_ext)
					order by order_no, ext
				end
				else begin	-- deleted 
					select @ord_no = order_no, @ord_ext = ext from deleted
					where convert(char(12), order_no) + convert(char(12), ext) >
					      convert(char(12), @last_ord_no) + convert(char(12),  @last_ord_ext)
					order by order_no, ext
				end
				
				If @@Rowcount <= 0 BREAK	-- this will exit the loop!
				Set ROWCOUNT 0
	
				if (exists(select @ord_no) and exists(select @ord_ext))
					select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no)

			        if @credit_return_flag = 'N' begin
				   /* Shipment document */
				   if (@data > '') and (@data <> '|')  begin	-- shipments
					-- Check EAI_SEND_SO_IMAGE to see if sending all shipments to Front Office,
					-- or just those shipments from sales orders that came from Front Office
					IF (Exists( SELECT 'X' FROM config WHERE flag = 'EAI_SEND_SO_IMAGE' and value_str like 'Y%')) 
					BEGIN	--Send shipping image that goes from BO to FO
						exec EAI_process_insert 'ShippingNotice', @data, 'BO'
					END
					ELSE --Check to see if the order number is in EAI_ord_xref cross reference table 
					BEGIN
						IF (Exists (SELECT 'X' from EAI_ord_xref 
						WHERE BO_order_no = @ord_no and BO_order_ext = @ord_ext)) begin
							-- Customized to avoid sending SN for any with Misc Parts
							IF not exists(select part_no from ord_list where part_type='M' and order_no = @ord_no and order_ext = @ord_ext)
							BEGIN
								exec EAI_process_insert 'ShippingNotice', @data, 'BO'
							END
							-- End
						end
					END
				   end
	
				   /* Service Agreement document */
					DECLARE c_sa_list CURSOR FOR
					SELECT	ord_list.part_no, ord_list.line_no FROM ord_list (NOLOCK)
					WHERE (ord_list.order_no = @ord_no) AND (ord_list.order_ext = @ord_ext) AND
						(ord_list.service_agreement_flag = 'Y')
					ORDER BY ord_list.line_no ASC
	
					OPEN c_sa_list
		
					FETCH c_sa_list INTO @sa_part, @line_no
				        while @@Fetch_Status = 0 begin
						select @data = convert(varchar(12),@ord_ext) + '|' + convert(varchar(12),@ord_no) + '|'
							+ convert(varchar(12), @line_no) 
							if (@data > '') and (@data <> '|') begin	-- service agreements
								exec EAI_process_insert 'SARequest', @data, 'BO'
							end
						FETCH c_sa_list INTO @sa_part, @line_no
					end -- end of while loop
					CLOSE c_sa_list
					DEALLOCATE c_sa_list
				end -- end not credit return


				/* Purchased products document */
				-- need to loop through for the purchased products information
				-- the @ord_no and @ord_ext are already set....
				-- Purchased Product documents will be sent for credit returns and shipments both
			    if exists(select @ord_no) and exists(select @ord_ext) begin	-- rev 4

			      if @credit_return_flag = 'N' begin
				DECLARE c_ord_list CURSOR FOR
				SELECT	ord_list.part_no, ord_list.line_no, ord_list.shipped FROM ord_list (NOLOCK)
				WHERE (ord_list.order_no = @ord_no) AND (ord_list.order_ext = @ord_ext) 
					and ord_list.part_no in (select part_no from inv_master where pur_prod_flag like 'Y%') and ord_list.shipped > 0
				ORDER BY ord_list.line_no ASC
				
			      end
			      else begin	-- for credit returns, get the cr_shipped
				DECLARE c_ord_list CURSOR FOR
				SELECT	ord_list.part_no, ord_list.line_no, ord_list.cr_shipped FROM ord_list (NOLOCK)
				WHERE (ord_list.order_no = @ord_no) AND (ord_list.order_ext = @ord_ext) 
					and ord_list.part_no in (select part_no from inv_master where pur_prod_flag like 'Y%') and ord_list.cr_shipped > 0
				ORDER BY ord_list.line_no ASC
			      end
	
				OPEN c_ord_list
		
				FETCH c_ord_list INTO @pur_prod_part, @line_no, @shipped
			        while @@Fetch_Status = 0 begin
					-- need to check to see if it is a serialized part, or a kit
					select @serial_flag = serial_flag,
					@kit_code = status		-- rev 9
					from inv_master where part_no = @pur_prod_part
					
					if ((@serial_flag = 0) and (@kit_code <> 'K')) begin	-- can just send the current quantity
						select @data = convert(varchar(12),@ord_no) + '|' + convert(varchar(12),@ord_ext) + '|'
							+ convert(varchar(12), @line_no) + '|' + convert(varchar(12),@shipped) + '|null|null'
						if (@data > '')  and (@data <> '|') begin	-- purchased products
							exec EAI_process_insert 'PurProdRequest', @data, 'BO'
						end
					end
					else begin
					   If (@kit_code = 'K') begin	-- rev 9:  need to send multiple documents
						select @counter = 1
						while (@counter <= @shipped) begin
							select @data = convert(varchar(12),@ord_no) + '|' + 
								convert(varchar(12),@ord_ext) + '|'
								+ convert(varchar(12), @line_no) + '|1|null|' 
								+ convert(varchar(12),@counter)
							if (@data > '')  and (@data <> '|') begin	-- purchased products
								exec EAI_process_insert 'PurProdRequest', @data, 'BO'
							end
							select @counter = @counter + 1
						end
					   end 
					   else begin

						DECLARE c_ser_list CURSOR FOR
						SELECT	lot_bin_ship.lot_ser FROM lot_bin_ship (NOLOCK)
						WHERE (lot_bin_ship.tran_no = @ord_no) AND (lot_bin_ship.tran_ext = @ord_ext) 
						and (lot_bin_ship.line_no = @line_no)
						ORDER BY lot_bin_ship.lot_ser ASC
	
						OPEN c_ser_list
		
						FETCH c_ser_list INTO @serial_no
						select @counter = 1
						while @@Fetch_Status = 0 begin
							select @data = convert(varchar(12),@ord_no) + '|' + 
								convert(varchar(12),@ord_ext) + '|' + convert(varchar(12), @line_no)
								+ '|1|' + @serial_no + '|' 
								+ convert(varchar(12),isnull(@counter,0))
							if (@data > '')  and (@data <> '|') begin	-- purchased products
								exec EAI_process_insert 'PurProdRequest', @data, 'BO'		
							end
							Fetch c_ser_list Into @serial_no
							select @counter = @counter + 1
						end	-- end serial number loop
						Close c_ser_list
						Deallocate c_ser_list
					    end
					end
				    FETCH c_ord_list INTO @pur_prod_part, @line_no, @shipped
				end -- end of while loop for purchased products
				CLOSE c_ord_list
				DEALLOCATE c_ord_list
			     end

			     select @last_ord_no = @ord_no
			     select @last_ord_ext = @ord_ext
			     select @data = ''
			end -- end while loop	/* end rev 4 */
	   end -- end post shipments timing...
	   /* end rev 1,2 */
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		orders_ins_trg		
Type:		Trigger
Description:	Stores designation codes for the order
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	30/03/2011	Original Version
v1.1	CT	12/05/2011	For Credit Returns, write a cvo_orders_all record
v1.2	CT	17/05/2011	Removed designation codes logic (this has been moved to an UPDATE trigger)
v1.3	CB	19/03/2012	For Credits populate the buying group
v1.4	CB	16/07/2013 - Issue #927 - Buying Group Switching
v1.5	CB	19/06/2014	Performance
v1.6	CB	19/03/2015 - Performance Changes
*/

CREATE TRIGGER [dbo].[orders_ins_trg] ON [dbo].[orders_all]
FOR INSERT
AS
BEGIN
	DECLARE	@order_no	int,
			@ext		int,
			@cust_code	varchar(10),
			@orig_no	int,	-- v1.1
			@orig_ext	int,		-- v1.1
			@buy_group	varchar(10) -- v1.3

	-- START v1.2 - comment out designation code logic
--	SET @order_no = 0
--		
--	-- Get the order to action
--	WHILE 1=1
--	BEGIN
--	
--		SELECT TOP 1 
--			@order_no = order_no
--		FROM 
--			inserted 
--		WHERE
--			order_no > @order_no
--			AND type = 'I'
--		ORDER BY 
--			order_no
--
--		IF @@RowCount = 0
--			Break
--
--		-- Loop through order extensions
--		SET @ext = -1
--		WHILE 1=1
--		BEGIN
--		
--			SELECT TOP 1 
--				@ext = ext,
--				@cust_code = cust_code
--			FROM 
--				inserted 
--			WHERE
--				order_no = @order_no
--				AND ext > @ext
--				AND type = 'I'
--			ORDER BY 
--				ext
--
--			IF @@RowCount = 0
--				Break
--		
--			INSERT INTO cvo_ord_designation_codes(
--				order_no,
--				order_ext,
--				code)
--			SELECT 
--				@order_no,
--				@ext,
--				a.code
--			FROM
--				cvo_cust_designation_codes a (NOLOCK)
--			INNER JOIN
--				cvo_designation_codes b (NOLOCK)
--			ON
--				a.code = b.code
--			WHERE
--				b.void = 0
--				AND a.customer_code = @cust_code
--				AND a.date_reqd = 1 
--				AND (getdate() BETWEEN a.start_date AND ISNULL(a.end_date,'01 january 2999'))
--				
--		END
--
--	END	
	-- END v1.2	

	-- START v1.1 - Credit returns
	SET @order_no = 0
		
	-- Get the CR to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = order_no
		FROM 
			inserted 
		WHERE
			order_no > @order_no
			AND type = 'C'
		ORDER BY 
			order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = ext,
				@orig_no = orig_no,
				@orig_ext = orig_ext
			FROM 
				inserted 
			WHERE
				order_no = @order_no
				AND ext > @ext
				AND type = 'C'
			ORDER BY 
				ext

			IF @@RowCount = 0
				Break

			-- If it's based on a SO (orig_no <> 0), copy record, if not create it
			IF ISNULL(@orig_no,0) = 0
			BEGIN

				-- v1.3 Start
				SELECT	@cust_code = cust_code
				FROM	inserted
				WHERE	order_no = @order_no
				AND		ext = @ext

				SET		@buy_group = NULL

				-- v1.4 Start
				SELECT	@buy_group = dbo.f_cvo_get_buying_group(@cust_code,GETDATE())

--				SELECT	@buy_group = a.customer_code
--				FROM	armaster_all a (NOLOCK)
--				JOIN	arnarel b (NOLOCK)
--				ON		a.customer_code = b.parent
--				WHERE	a.address_type = 0
--				AND		b.child = @cust_code
				-- v1.3 End
				-- v1.4 End

				INSERT INTO cvo_orders_all WITH (ROWLOCK) (
					order_no,
					ext,
					buying_group) -- v1.3
				SELECT
					@order_no,
					@ext,
					@buy_group -- v1.3

			END
			ELSE
			BEGIN
				INSERT INTO cvo_orders_all WITH (ROWLOCK)(
					order_no,
					ext,
					add_case,
					add_pattern,
					promo_id,
					promo_level,
					free_shipping,
					split_order,
					flag_print,
					buying_group,
					commission_pct,
					allocation_date)
				SELECT
					@order_no,
					@ext,
					add_case,
					add_pattern,
					promo_id,
					promo_level,
					free_shipping,
					split_order,
					flag_print,
					buying_group,
					commission_pct,
					allocation_date
				FROM
					cvo_orders_all (NOLOCK) -- v1.6
				WHERE
					order_no = @orig_no
					AND ext = @orig_ext
			END
		END
	END
	-- END v1.1
END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		orders_insupd_trg		
Type:		Trigger
Desc:		Writes details of credit returns going on or coming off hold
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	30/03/2011	Original Version
*/


CREATE TRIGGER [dbo].[orders_insupd_trg] ON [dbo].[orders_all]  
FOR INSERT,UPDATE  
AS  
BEGIN 
	DECLARE @order_no		INT,
			@istatus		VARCHAR(1),
			@dstatus		VARCHAR(1),
			@hold_reason	VARCHAR(10),
			@location		VARCHAR(10)
	
	SET @order_no = 0

	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@order_no = i.order_no,
			@istatus = i.status,
			@dstatus = ISNULL(d.status,'N'),
			@hold_reason = i.hold_reason,
			@location = i.location
		FROM
			inserted i
		LEFT JOIN
			deleted d
		ON
			i.order_no = d.order_no
			AND i.ext = d.ext
		WHERE
			i.order_no > @order_no
			AND i.ext = 0
			AND i.type = 'C'
			AND ((i.status = 'A' AND ISNULL(d.status,'N') <> 'A') -- Going on hold
				OR (i.status = 'N' AND ISNULL(d.status,'N') = 'A') -- Coming off hold
				OR (i.status = 'A' AND ISNULL(d.status,'N') = 'A' AND i.hold_reason <> ISNULL(d.hold_reason,''))) -- Change of hold reason
		ORDER BY
			i.order_no

		IF @@ROWCOUNT = 0
			BREAK	

		-- Going on hold/change of hold reason
		IF @istatus = 'A' 
		BEGIN
			INSERT INTO tdc_log (
				tran_date,
				userid,
				trans_source,
				module,
				trans,
				tran_no,
				tran_ext,
				part_no,
				lot_ser,
				bin_no,
				location,
				quantity,
				data)
			SELECT
				GETDATE(),
				SUSER_SNAME(),
				'BO',
				'ADM',
				CASE @dstatus WHEN 'A' THEN 'CR HOLD UPDATE' ELSE 'CR HOLD' END,
				CAST(@order_no AS VARCHAR(10)),
				'0',
				'',
				'',
				'',
				@location,
				'',
				'CREDIT RETURN HOLD; HOLD REASON: ' + UPPER(ISNULL(@hold_reason,'')) 
		END

		-- Going off hold
		IF @istatus = 'N' AND @dstatus = 'A'
		BEGIN
			INSERT INTO tdc_log (
				tran_date,
				userid,
				trans_source,
				module,
				trans,
				tran_no,
				tran_ext,
				part_no,
				lot_ser,
				bin_no,
				location,
				quantity,
				data)
			SELECT
				GETDATE(),
				SUSER_SNAME(),
				'BO',
				'ADM',
				'CR RELEASE HOLD',
				CAST(@order_no AS VARCHAR(10)),
				'0',
				'',
				'',
				'',
				@location,
				'',
				'CREDIT RETURN RELEASE HOLD'
		END
		

		
	END


END 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		orders_upd_trg		
Type:		Trigger
Description:	When an order is voided, remove any matching entries from cvo_pattern_tracking
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	04/04/2011	Original Version
v1.1	CT	17/05/2011	For Sales Orders and Credit Returns, write designation codes to cvo_ord_designation_codes when SO/CR is posted
v1.2	CT	31/07/2012	For Sales Orders coming off of credit hold call routine to print pickticket/wo
v1.3	CT	22/08/2012	If the order goes onto credit hold (status C) then call code to send email
v1.4	CT	04/11/2013	Issue #864 - When order posts (status = T), call routine to enroll customer in debit promo (if applicable)
v1.5	CT	04/11/2013	Issue #864 - When order posts (status = T), call routine to update drawdown promo (if applicable) 
v1.6	CT	04/11/2013	Issue #864 - When order is voided, call routine to update drawdown promo (if applicable) 
v1.7	CB	19/06/2014	Performance
v1.8	CB	18/08/2014 - Populate RB data table
v1.9	CT	16/09/2014	Issue #1483 - Promo hold reason
v2.0	CB	26/02/2015  Do no apply promo hold if update is from the release of stock consolidation orders
v2.1	CB	05/03/2015	Do not apply promo hold if order is a rebill
v2.2	CB  24/04/2015  If RB is resaved with bg set ensure data is updated in cvo_rb_data
*/

CREATE TRIGGER [dbo].[orders_upd_trg] ON [dbo].[orders_all]
FOR UPDATE
AS
BEGIN
	DECLARE	@order_no		int,
			@ext			int,
			@cust_code		varchar(10),-- v1.1
			@date_shipped	datetime,	-- v1.1
			@type			CHAR(1),	-- v1.4
			-- START v1.9
			@hold_reason	VARCHAR(10),
			@location		VARCHAR(10),
			@data			VARCHAR(7500),
			@hold_desc		VARCHAR(40),
			@order_type		VARCHAR(10),
			@promo_id		VARCHAR(20),
			@promo_level	VARCHAR(30)
			-- END v1.9

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
			AND type = 'I'
			-- START v1.6 
			-- Add the void check in here so we don't loop through orders which aren't voided
			AND [status] = 'V'
			-- END v1.6
		ORDER BY 
			order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			-- Select next order that has been marked as void in this update
			SELECT TOP 1 
				@ext = i.ext
			FROM 
				inserted i
			INNER JOIN
				deleted d
			ON 
				i.order_no = d.order_no
				AND i.ext = d.ext
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND i.type = 'I'
				AND i.status = 'V'
				AND d.status <> 'V'
			ORDER BY 
				i.ext

			IF @@RowCount = 0
				Break
		
			DELETE FROM
				dbo.cvo_pattern_tracking
			WHERE
				order_no = @order_no
				AND order_ext = @ext

			-- START v1.6
			EXEC CVO_remove_debit_promo_sp @order_no, @ext
			-- END v1.6
				
		END

	END	

	
	-- START v1.1 - designation codes
	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = i.order_no
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.order_no = d.order_no
			AND i.ext = d.ext
		WHERE
			i.order_no > @order_no
			AND i.status = 'T'
			AND d.status <> 'T'
		ORDER BY 
			i.order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = i.ext,
				@cust_code = i.cust_code,
				@date_shipped = i.date_shipped,
				@type = i.type -- v1.4
			FROM 
				inserted i
			INNER JOIN
				deleted d
			ON
				i.order_no = d.order_no
				AND i.ext = d.ext 
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND i.status = 'T'
				AND d.status <> 'T'
			ORDER BY 
				i.ext

			IF @@RowCount = 0
				Break
		
			INSERT INTO cvo_ord_designation_codes WITH (ROWLOCK)(
				order_no,
				order_ext,
				code)
			SELECT 
				@order_no,
				@ext,
				a.code
			FROM
				cvo_cust_designation_codes a (NOLOCK)
			INNER JOIN
				cvo_designation_codes b (NOLOCK)
			ON
				a.code = b.code
			WHERE
				b.void = 0
				AND a.customer_code = @cust_code
				AND a.date_reqd = 1 
				AND (@date_shipped BETWEEN a.start_date AND ISNULL(a.end_date,'01 january 2999'))

			-- START v1.4
			IF @type = 'I'
			BEGIN
				-- Check if customer should be enrolled in a debit promo
				EXEC CVO_debit_promo_enrollment_sp	@order_no, @ext

				-- Check if order is linked to a drawdown promo
				EXEC CVO_debit_promo_posted_order_sp @order_no, @ext -- v1.5
			END	
			-- END v1.4
		END
	END	
	-- END v1.1	

	-- START v1.2 - designation codes
	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = i.order_no
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.order_no = d.order_no
			AND i.ext = d.ext
		WHERE
			i.order_no > @order_no
			AND i.status = 'N'
			AND d.status = 'C'
		ORDER BY 
			i.order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = i.ext
			FROM 
				inserted i
			INNER JOIN
				deleted d
			ON
				i.order_no = d.order_no
				AND i.ext = d.ext 
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND i.status = 'N'
				AND d.status = 'C'
			ORDER BY 
				i.ext

			IF @@RowCount = 0
				Break
			
		-- Call print routine
		EXEC dbo.cvo_print_custom_frame_picklist_wo_sp @order_no = @order_no, @order_ext = @ext
				
		END
	END	
	-- END v1.2

	-- START v1.3
	SET @order_no = 0
		
	-- Get the next order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = i.order_no
		FROM 
			inserted i
		INNER JOIN
			deleted d
		ON
			i.order_no = d.order_no
			AND i.ext = d.ext
		WHERE
			i.order_no > @order_no
			AND i.type = 'I'
			AND i.status = 'C'
			AND d.status <> 'C'
		ORDER BY 
			i.order_no

		IF @@RowCount = 0
			Break
	
		EXEC dbo.CVO_email_credithold_sp @order_no 
		
	END
	-- END v1.3


	-- v1.8 Start
	INSERT  cvo_rb_data WITH (ROWLOCK)(order_no, order_ext, order_ctrl_num, user_category, buying_group, cust_code)
	SELECT	a.order_no, a.ext, CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)), a.user_category, 
			CASE WHEN b.buying_group = 'None' THEN '' ELSE ISNULL(b.buying_group,'') END, a.cust_code
	FROM	inserted a 
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	LEFT JOIN cvo_rb_data c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.ext = c.order_ext
	WHERE	RIGHT(a.user_category,2) = 'RB'
	AND		c.order_no IS NULL

	-- v2.2 Start
	UPDATE	a
	SET		buying_group = c.buying_group
	FROM	cvo_rb_data a
	JOIN	inserted b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	JOIN	cvo_orders_all c (NOLOCK)
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.ext
	WHERE	a.buying_group <> c.buying_group
	-- v2.2 End
--
--	DELETE	a
--	FROM	cvo_rb_data a
--	JOIN	inserted b
--	ON		a.order_no = b.order_no
--	AND		a.order_ext = b.ext
--	WHERE	RIGHT(b.user_category,2) <> 'RB'

	-- v1.8 End

	-- START v1.9
	-- Promo hold reason
	SET @order_no = 0
		
	-- Get the order to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@order_no = i.order_no
		FROM 
			inserted i 
		INNER JOIN
			dbo.cvo_orders_all o (NOLOCK)
		ON
			i.order_no = o.order_no
			AND i.ext = o.ext
		INNER JOIN
			dbo.cvo_promotions p (NOLOCK)
		ON
			o.promo_id = p.promo_id
			AND o.promo_level = p.promo_level
		-- v2.1 Start
		JOIN	orders_all ord (NOLOCK)
		ON		o.order_no = ord.order_no
		AND		o.ext = ord.ext
		-- v2.1 End
		WHERE
			i.order_no > @order_no
			AND i.[type] = 'I'
			AND i.[status] = 'N'
			AND ISNULL(i.hold_reason,'') = ''
			AND ISNULL(o.prior_hold,'') = ''
			AND ISNULL(p.hold_reason,'') <> ''
			AND RIGHT(ord.user_category,2) <> 'RB' -- v2.1
		ORDER BY 
			i.order_no

		IF @@RowCount = 0
			Break

		-- Loop through order extensions
		SET @ext = -1
		WHILE 1=1
		BEGIN
		
			SELECT TOP 1 
				@ext = i.ext,
				@hold_reason = p.hold_reason,
				@location = i.location,
				@order_type = i.user_category,
				@promo_id = o.promo_id,
				@promo_level = o.promo_level
			FROM 
				inserted i
			INNER JOIN
				dbo.cvo_orders_all o (NOLOCK)
			ON
				i.order_no = o.order_no
				AND i.ext = o.ext
			INNER JOIN
				dbo.cvo_promotions p (NOLOCK)
			ON
				o.promo_id = p.promo_id
				AND o.promo_level = p.promo_level
			-- v2.1 Start
			JOIN	orders_all ord (NOLOCK)
			ON		o.order_no = ord.order_no
			AND		o.ext = ord.ext
			-- v2.1 End
			WHERE
				i.order_no = @order_no
				AND i.ext > @ext
				AND i.[type] = 'I'
				AND i.[status] = 'N'
				AND ISNULL(i.hold_reason,'') = ''
				AND ISNULL(o.prior_hold,'') = ''
				AND ISNULL(p.hold_reason,'') <> ''
				AND RIGHT(ord.user_category,2) <> 'RB' -- v2.1
			ORDER BY 
				i.ext

			IF @@RowCount = 0
				Break

			-- v2.0 Start
			IF OBJECT_ID('tempdb..#cvo_stop_promo_hold')IS NOT NULL 
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM #cvo_stop_promo_hold WHERE order_no = @order_no AND order_ext = @ext)
				BEGIN			
					-- Put order on hold
					UPDATE
						dbo.orders_all
					SET 
						[status] = 'A',
						hold_reason = @hold_reason
					WHERE
						order_no = @order_no
						AND ext = @ext
				END
				ELSE
				BEGIN
					INSERT INTO dbo.cvo_tdc_log_written (spid, order_no, ext)
					SELECT	@@SPID, @order_no, @ext
				END
			END
			ELSE
			BEGIN				
			
				-- Put order on hold
				UPDATE
					dbo.orders_all
				SET 
					[status] = 'A',
					hold_reason = @hold_reason
				WHERE
					order_no = @order_no
					AND ext = @ext
			END
			-- v2.0 End			
	

			-- Write tdc_log record (was being written twice, use cvo_tdc_log_written to track this)
			IF NOT EXISTS (SELECT 1 FROM dbo.cvo_tdc_log_written (NOLOCK) WHERE spid = @@SPID AND order_no = @order_no AND ext = @ext)
			BEGIN
				SELECT @hold_desc = hold_reason FROM dbo.adm_oehold (NOLOCK) WHERE hold_code = @hold_reason
				
				SET @data = 'STATUS:A/USER HOLD; HOLD REASON:' + @hold_reason + ' - ' + @hold_desc + '; ORDER TYPE: ' + @order_type + '; PROMO ID: ' + @promo_id + ' ; PROMO LEVEL: ' + @promo_level


				INSERT INTO tdc_log(
					tran_date,
					UserID,
					trans_source,
					module,
					trans,
					tran_no,
					tran_ext,
					part_no,
					lot_ser,
					bin_no,
					location,
					quantity,
					data)
				SELECT
					GETDATE(),
					SUSER_SNAME(),
					'BO',
					'ADM',
					'ORDER UPDATE',
					CAST(@order_no AS VARCHAR),
					CAST(@ext AS VARCHAR),
					'',
					'',
					'',
					@location,
					'',
					@data

				INSERT INTO dbo.cvo_tdc_log_written (
					spid,
					order_no,
					ext)
				SELECT	
					@@SPID,
					@order_no,
					@ext
			END
			ELSE
			BEGIN
				DELETE FROM dbo.cvo_tdc_log_written WHERE spid = @@SPID AND order_no = @order_no AND ext = @ext
			END
		END

	END			
	-- END v1.9	
END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delord] ON [dbo].[orders_all]   FOR DELETE AS 
begin

if exists (select * from deleted where status='@' and ext > 0) return
if exists (select * from config where flag='TRIG_DEL_ORD' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 74099, 'You Can Not Delete An ORDER!' 
	return
	end
end
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE TRIGGER [dbo].[t700insord] 
ON [dbo].[orders_all] 
FOR INSERT   
AS
BEGIN  
  
	DECLARE @i_order_no				int, 
			@i_ext					int,			
			@i_cust_code			varchar(10), 
			@i_ship_to				varchar(10),  
			@i_routing				varchar(20),
			@i_status				char(1),  
			@i_total_amt_order		decimal(20,8), 
			@i_salesperson			varchar(10),
			@i_tax_id				varchar(10),  
			@i_freight				decimal(20,8),  
			@i_ship_to_add_1		varchar(40),  
			@i_ship_to_add_2		varchar(40), 
			@i_ship_to_add_3		varchar(40), 
			@i_ship_to_add_4		varchar(40),  
			@i_ship_to_add_5		varchar(40), 
			@i_ship_to_region		varchar(10),  
			@i_type					char(1), 
			@i_freight_allow_type	varchar(10), 
			@i_location				varchar(10),  
			@i_total_tax			decimal(20,8), 
			@i_total_discount		decimal(20,8), 
			@i_gross_sales			decimal(20,8), 
			@i_curr_factor			decimal(20,8), 
			@i_oper_factor			decimal(20,8),  
			@i_tot_ord_tax			decimal(20,8), 
			@i_tot_ord_disc			decimal(20,8), 
			@i_tot_ord_freight		decimal(20,8),  
			@i_user_code			varchar(8), 
			@i_organization_id		varchar(30),  
			@i_addr_valid_ind		int,  
			@i_ship_to_country_cd	varchar(3),  
			@price_code				varchar(8),  
			@amt_home				decimal(20,8),  
			@amt_oper				decimal(20,8),  
			@hprecision				decimal(20,8), 
			@oprecision				decimal(20,8),
			@addr1					varchar(255), 
			@addr2					varchar(255), 
			@addr3					varchar(255), 
			@addr4					varchar(255),  
			@addr5					varchar(255), 
			@addr6					varchar(255),  
			@city					varchar(255), 
			@state					varchar(255), 
			@zip					varchar(255),  
			@country_cd				varchar(3), 
			@country				varchar(255),  
			@rtn					int, 
			@rc						int  

	-- v1.0 Start
	DECLARE	@row_id					int,
			@last_row_id			int
	-- v1.0 End
  
	IF EXISTS (SELECT 1 FROM config (NOLOCK) WHERE UPPER(flag) = 'TRIG_INS_ORD' AND UPPER(value_str) = 'DISABLE')   
		RETURN  

	-- v1.0 Start
	-- Working table
	CREATE TABLE #t700insord (
		row_id					int IDENTITY(1,1),
		i_order_no				int NULL, 
		i_ext					int NULL,			
		i_cust_code				varchar(10) NULL, 
		i_ship_to				varchar(10) NULL,  
		i_routing				varchar(20) NULL,
		i_status				char(1) NULL,  
		i_total_amt_order		decimal(20,8) NULL, 
		i_salesperson			varchar(10) NULL,
		i_tax_id				varchar(10) NULL,  
		i_freight				decimal(20,8) NULL,  
		i_ship_to_add_1			varchar(40) NULL,  
		i_ship_to_add_2			varchar(40) NULL, 
		i_ship_to_add_3			varchar(40) NULL, 
		i_ship_to_add_4			varchar(40) NULL,  
		i_ship_to_add_5			varchar(40) NULL, 
		i_ship_to_region		varchar(10) NULL,  
		i_type					char(1) NULL, 
		i_freight_allow_type	varchar(10) NULL, 
		i_location				varchar(10) NULL,  
		i_total_tax				decimal(20,8) NULL, 
		i_total_discount		decimal(20,8) NULL, 
		i_gross_sales			decimal(20,8) NULL, 
		i_curr_factor			decimal(20,8) NULL, 
		i_oper_factor			decimal(20,8) NULL,  
		i_tot_ord_tax			decimal(20,8) NULL, 
		i_tot_ord_disc			decimal(20,8) NULL, 
		i_tot_ord_freight		decimal(20,8) NULL,  
		i_user_code				varchar(8) NULL, 
		i_organization_id		varchar(30) NULL,  
		i_addr_valid_ind		int NULL,  
		i_ship_to_country_cd	varchar(3) NULL)

	SET @last_row_id = 0

	INSERT	#t700insord (i_order_no, i_ext, i_cust_code, i_ship_to, i_routing, i_status, i_total_amt_order, i_salesperson, i_tax_id, i_freight, i_ship_to_add_1, i_ship_to_add_2, 
					i_ship_to_add_3, i_ship_to_add_4, i_ship_to_add_5, i_ship_to_region, i_type, i_freight_allow_type, i_location, i_total_tax, i_total_discount, 
					i_gross_sales, i_curr_factor, i_oper_factor, i_tot_ord_tax, i_tot_ord_disc, i_tot_ord_freight, i_user_code, i_organization_id, 
					i_addr_valid_ind, i_ship_to_country_cd)
	SELECT	i.order_no, i.ext, i.cust_code, i.ship_to, i.routing, i.status, i.total_amt_order, i.salesperson, i.tax_id, i.freight, i.ship_to_add_1, i.ship_to_add_2,  
			i.ship_to_add_3, i.ship_to_add_4, i.ship_to_add_5, i.ship_to_region, i.type, i.freight_allow_type, i.location, i.total_tax, 
			i.total_discount, i.gross_sales, i.curr_factor, i.oper_factor, i.tot_ord_tax, i.tot_ord_disc, i.tot_ord_freight, i.user_code, 
			ISNULL(i.organization_id,''), ISNULL(i.addr_valid_ind,0), i.ship_to_country_cd  
	FROM	inserted i

	SELECT	TOP 1 @row_id = row_id,
			@i_order_no = i_order_no, 
			@i_ext = i_ext,
			@i_cust_code = i_cust_code,
			@i_ship_to = i_ship_to,
			@i_routing = i_routing,
			@i_status = i_status,
			@i_total_amt_order = i_total_amt_order,
			@i_salesperson = i_salesperson,
			@i_tax_id = i_tax_id,
			@i_freight = i_freight,
			@i_ship_to_add_1 = i_ship_to_add_1,
			@i_ship_to_add_2 = i_ship_to_add_2,
			@i_ship_to_add_3 = i_ship_to_add_3, 
			@i_ship_to_add_4 = i_ship_to_add_4,
			@i_ship_to_add_5 = i_ship_to_add_5, 
			@i_ship_to_region = i_ship_to_region,
			@i_type = i_type,
			@i_freight_allow_type = i_freight_allow_type, 
			@i_location = i_location,
			@i_total_tax = i_total_tax,
			@i_total_discount = i_total_discount,
			@i_gross_sales = i_gross_sales, 
			@i_curr_factor = i_curr_factor,
			@i_oper_factor = i_oper_factor,
			@i_tot_ord_tax = i_tot_ord_tax,
			@i_tot_ord_disc = i_tot_ord_disc,
			@i_tot_ord_freight = i_tot_ord_freight,
			@i_user_code = i_user_code,
			@i_organization_id = i_organization_id,
			@i_addr_valid_ind = i_addr_valid_ind,
			@i_ship_to_country_cd = i_ship_to_country_cd
	FROM	#t700insord
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@i_organization_id = '')
		BEGIN
			UPDATE	orders_all
			SET		organization_id = 'CVO'
			WHERE	order_no = @i_order_no
			AND		ext = @i_ext
		END

		IF (@i_addr_valid_ind = 0 AND EXISTS (SELECT 1 FROM artax (NOLOCK) WHERE tax_code = @i_tax_id AND ISNULL(tax_connect_flag,0) = 1))
		BEGIN  
			SELECT	@addr1 = @i_ship_to_add_1,  
					@addr2 = @i_ship_to_add_2,  
					@addr3 = @i_ship_to_add_3,  
					@addr4 = @i_ship_to_add_4,  
					@addr5 = @i_ship_to_add_5,  
					@addr6 = '',  
					@city = '',  
					@state = '',  
					@zip = '',  
					@country_cd = @i_ship_to_country_cd  
  
			EXEC @rtn = adm_parse_address 1, 0, @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,  
												@city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT  
  
			EXEC @rc = adm_validate_address_wrap 'AR', @addr1 OUT, @addr2 OUT, @addr3 OUT, @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0  
  
			IF (@rtn <> 2 or @rc <> 2)   
			BEGIN  
				UPDATE	orders_all  
				SET		ship_to_add_1 = @addr1,  
						ship_to_add_2 = @addr2,  
						ship_to_add_3 = @addr3,  
						ship_to_add_4 = @addr4,  
						ship_to_add_5 = @addr5,  
						ship_to_city = @city,  
						ship_to_state = @state,  
						ship_to_zip = @zip,  
						ship_to_country_cd = @country_cd,  
						addr_valid_ind = CASE WHEN @rc > 0 THEN 1 ELSE 0 END  
				WHERE	order_no = @i_order_no 
				AND		ext = @i_ext  
			END  
		END  
  
		IF EXISTS (SELECT 1 FROM cust_carrier_account (NOLOCK) WHERE cust_code = @i_cust_code AND ISNULL(ship_to,'') = ISNULL(@i_ship_to,'')   
				AND freight_allow_type = ISNULL(@i_freight_allow_type,'') AND routing = ISNULL(@i_routing,''))  
		BEGIN
			UPDATE	o  
			SET		ship_to_add_5 = '3PB=' + a.account  
			FROM	cust_carrier_account a (NOLOCK)
			JOIN	orders_all o (NOLOCK)
			ON		a.cust_code = o.cust_code
			AND		ISNULL(a.ship_to,'') = ISNULL(o.ship_to,'')
			AND		a.freight_allow_type = o.freight_allow_type
			AND		a.routing = o.routing
			WHERE	o.order_no = @i_order_no 
			AND		o.ext = @i_ext 
			AND		a.cust_code = @i_cust_code  
			AND		ISNULL(a.ship_to,'') = ISNULL(@i_ship_to,'') 
			AND		a.freight_allow_type = ISNULL(@i_freight_allow_type,'')   
			AND		a.routing = ISNULL(@i_routing,'')  
		END
		ELSE IF EXISTS (SELECT 1 FROM cust_carrier_account (NOLOCK) WHERE cust_code = @i_cust_code AND ISNULL(ship_to,'') = ''  
						AND freight_allow_type = ISNULL(@i_freight_allow_type,'') AND routing = ISNULL(@i_routing,''))  
		BEGIN  
			UPDATE	o  
			SET		ship_to_add_5 = '3PB=' + a.account  
			FROM	cust_carrier_account a (NOLOCK) 
			JOIN	orders_all o (NOLOCK)
			ON		a.cust_code = o.cust_code
			AND		ISNULL(a.ship_to,'') = ISNULL(o.ship_to,'')
			AND		a.freight_allow_type = o.freight_allow_type
			AND		a.routing = o.routing		  
			WHERE	o.order_no = @i_order_no 
			AND		o.ext = @i_ext 
			AND		a.cust_code = @i_cust_code  
			AND		ISNULL(a.ship_to,'') = '' 
			AND		a.freight_allow_type = ISNULL(@i_freight_allow_type,'')   
			AND		a.routing = ISNULL(@i_routing,'')  
		END  
    
		IF (@i_status = 'S')  
		BEGIN  
			IF EXISTS (SELECT 1 FROM lot_bin_ship s (NOLOCK) WHERE tran_no = @i_order_no AND tran_ext = @i_ext  
				AND NOT EXISTS (SELECT 1 FROM ord_list l (NOLOCK) WHERE l.order_no = @i_order_no AND l.order_ext = @i_ext AND l.line_no = s.line_no))  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832114 ,'Lot bin records on lot_bin_ship do not relate to a line on the order.'  
				RETURN  
			END  
		END  
  
		IF (@i_status BETWEEN 'N' AND 'S' AND @i_type = 'I')  
		BEGIN  
			SELECT	@amt_home = @i_total_amt_order - @i_tot_ord_disc + @i_tot_ord_tax + @i_tot_ord_freight,  
					@amt_oper = @i_gross_sales - @i_total_discount + @i_total_tax + @i_freight  
	  
			-- TDC Inventory Update Call  
			EXEC @rtn = tdc_order_hdr_change @i_order_no, @i_ext  
			IF (@rtn< 0 )  
			BEGIN  
				EXEC adm_raiserror 84900 ,'Invalid Inventory Update From TDC.'  
			END  
	  
			IF (@i_status = 'S')
				SELECT  @amt_home = @amt_oper  
			ELSE   
				SELECT  @amt_oper = @amt_home  
	  
			SELECT	@price_code = price_code   
			FROM	adm_cust_all (NOLOCK)  
			WHERE	customer_code = @i_cust_code  
	  
			SELECT	@hprecision = glcurr_vw.curr_precision  
			FROM	glcurr_vw (NOLOCK)
			JOIN	glco (NOLOCK)  
			ON		glcurr_vw.currency_code = glco.home_currency   
	    
			SELECT	@oprecision = glcurr_vw.curr_precision  
			FROM	glcurr_vw (NOLOCK)
			JOIN	glco (NOLOCK)  
			ON		glcurr_vw.currency_code = glco.oper_currency   
	  
			SELECT	@i_ship_to = ISNULL(@i_ship_to,'')  
	  
			IF (@i_curr_factor >= 0)
				SELECT @amt_home = ROUND((@amt_home * @i_curr_factor), @hprecision)  
			ELSE   
				SELECT @amt_home = ROUND(@amt_home / ABS(@i_curr_factor), @hprecision)  
	  
			IF (@i_oper_factor >= 0)   
				SELECT @amt_oper = ROUND(@amt_oper * @i_oper_factor, @oprecision)  
			ELSE   
				SELECT @amt_oper = ROUND(@amt_oper / ABS(@i_oper_factor), @oprecision)  
	  
			EXEC @rtn = aractinp_sp @i_cust_code,  @i_ship_to, @price_code, @i_salesperson,  
									@i_ship_to_region, @amt_home, @amt_oper, 1000  
	  
			IF (@@error <> 0 OR @rtn <> 0)
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 84001 ,'Error updating activity tables with new amount.'  
				RETURN  
			END  
		END 
  
		IF NOT EXISTS (SELECT 1 FROM so_usrstat (NOLOCK) WHERE user_stat_code = @i_user_code AND status_code = @i_status AND isnull(void,'N') = 'N')  
		BEGIN  
			UPDATE	p  
			SET		user_code = s.user_stat_code  
			FROM	orders_all p, so_usrstat s (NOLOCK) 
			WHERE	p.order_no = @i_order_no 
			AND		p.ext = @i_ext  
			AND		s.status_code = @i_status 
			AND		ISNULL(s.void,'N') = 'N' 
			AND		s.default_flag = 1  
		END 
  
		SET @Last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_order_no = i_order_no, 
				@i_ext = i_ext,
				@i_cust_code = i_cust_code,
				@i_ship_to = i_ship_to,
				@i_routing = i_routing,
				@i_status = i_status,
				@i_total_amt_order = i_total_amt_order,
				@i_salesperson = i_salesperson,
				@i_tax_id = i_tax_id,
				@i_freight = i_freight,
				@i_ship_to_add_1 = i_ship_to_add_1,
				@i_ship_to_add_2 = i_ship_to_add_2,
				@i_ship_to_add_3 = i_ship_to_add_3, 
				@i_ship_to_add_4 = i_ship_to_add_4,
				@i_ship_to_add_5 = i_ship_to_add_5, 
				@i_ship_to_region = i_ship_to_region,
				@i_type = i_type,
				@i_freight_allow_type = i_freight_allow_type, 
				@i_location = i_location,
				@i_total_tax = i_total_tax,
				@i_total_discount = i_total_discount,
				@i_gross_sales = i_gross_sales, 
				@i_curr_factor = i_curr_factor,
				@i_oper_factor = i_oper_factor,
				@i_tot_ord_tax = i_tot_ord_tax,
				@i_tot_ord_disc = i_tot_ord_disc,
				@i_tot_ord_freight = i_tot_ord_freight,
				@i_user_code = i_user_code,
				@i_organization_id = i_organization_id,
				@i_addr_valid_ind = i_addr_valid_ind,
				@i_ship_to_country_cd = i_ship_to_country_cd
		FROM	#t700insord
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE TRIGGER [dbo].[t700updord]
ON [dbo].[orders_all] 
FOR UPDATE AS   
BEGIN  

	DECLARE @i_order_no				int, 
			@i_ext					int,			
			@i_cust_code			varchar(10), 
			@i_ship_to				varchar(10),  
			@i_routing				varchar(20),
			@i_status				char(1),  
			@i_total_amt_order		decimal(20,8), 
			@i_salesperson			varchar(10),
			@i_tax_id				varchar(10),  
			@i_freight				decimal(20,8),
			@i_ship_to_name			varchar(40),  
			@i_ship_to_add_1		varchar(40),  
			@i_ship_to_add_2		varchar(40), 
			@i_ship_to_city			varchar(40),
			@i_ship_to_state		varchar(40),  
			@i_ship_to_zip			varchar(15), -- v1.2
			@i_ship_to_add_5		varchar(40),
			@i_ship_to_region		varchar(10),  
			@i_type					char(1), 
			@i_freight_allow_type	varchar(10), 
			@i_location				varchar(10),  
			@i_total_tax			decimal(20,8), 
			@i_total_discount		decimal(20,8), 
			@i_gross_sales			decimal(20,8), 
			@i_total_invoice		decimal(20,8),
			@i_curr_factor			decimal(20,8), 
			@i_oper_factor			decimal(20,8),  
			@i_tot_ord_tax			decimal(20,8), 
			@i_tot_ord_disc			decimal(20,8), 
			@i_tot_ord_freight		decimal(20,8),  
			@i_user_code			varchar(8), 
			@i_organization_id		varchar(30),  
			@i_addr_valid_ind		int,  
			@i_ship_to_country_cd	varchar(3),  
			@price_code				varchar(8),  
			@amt_home				decimal(20,8),  
			@amt_oper				decimal(20,8),  
			@hprecision				decimal(20,8), 
			@oprecision				decimal(20,8),
			@addr1					varchar(255), 
			@addr2					varchar(255), 
			@addr3					varchar(255), 
			@addr4					varchar(255),  
			@addr5					varchar(255), 
			@addr6					varchar(255),  
			@city					varchar(255), 
			@state					varchar(255), 
			@zip					varchar(255),  
			@country_cd				varchar(3), 
			@country				varchar(255),  
			@rtn					int, 
			@rc						int,
			@order_count			int,
			@d_order_no				int,
			@d_ext					int,
			@d_ship_to_name			varchar(40),
			@d_ship_to_add_1		varchar(40),
			@d_ship_to_add_2		varchar(40),
			@d_ship_to_city			varchar(40),
			@d_ship_to_state		varchar(40),
			@d_ship_to_zip			varchar(15), -- v1.1
			@d_cust_code			varchar(10),
			@d_ship_to				varchar(10),
			@d_freight_allow_type	varchar(10),
			@d_routing				varchar(20), -- v1.1
			@d_status				char(1),
			@d_tot_ord_disc			decimal(20,8),
			@d_tot_ord_freight		decimal(20,8),
			@d_tot_ord_tax			decimal(20,8),
			@d_total_amt_order		decimal(20,8),
			@d_total_discount		decimal(20,8),
			@d_total_tax			decimal(20,8),
			@d_total_invoice		decimal(20,8),
			@d_gross_sales			decimal(20,8),
			@d_salesperson			varchar(10),
			@d_ship_to_region		varchar(10),
			@i_invoice_no			int,
			@d_invoice_no			int,
			@customer_code			varchar(10),
			@ship_to_code			varchar(10),
			@salesperson_code		varchar(10),
			@territory_code			varchar(10),
			@hstat					char(1),
			@hrate					decimal(20,8),	
			@orate					decimal(20,8),
			@d_curr_factor			decimal(20,8),
			@d_oper_factor			decimal(20,8),
			@i_consolidate_flag		smallint,
			@d_consolidate_flag		smallint,
			@d_user_code			varchar(8),
			@d_type					char(1),
			@tdc_rtn				int,
			@d_freight				decimal(20,8),
			@msg					varchar(255),
			@xlk					int,
			@i_tax_valid_ind		int,
			@retval					int,
			@i_date_shipped			datetime  
	
	-- v1.0 Start
	DECLARE	@row_id					int,
			@last_row_id			int
	-- v1.0 End

	-- Working table
	CREATE TABLE #t700updord (
		row_id					int IDENTITY(1,1),
		i_order_no				int NULL, 
		i_ext					int NULL,			
		i_cust_code				varchar(10) NULL, 
		i_ship_to				varchar(10) NULL,  
		i_routing				varchar(20) NULL,
		i_status				char(1) NULL,  
		i_total_amt_order		decimal(20,8) NULL, 
		i_salesperson			varchar(10) NULL,
		i_tax_id				varchar(10) NULL,  
		i_freight				decimal(20,8) NULL,  
		i_ship_to_name			varchar(40) NULL,  
		i_ship_to_add_1			varchar(40) NULL,  
		i_ship_to_add_2			varchar(40) NULL, 
		i_ship_to_add_5			varchar(40) NULL,
		i_ship_to_city			varchar(40) NULL, 
		i_ship_to_state			varchar(40) NULL,  
		i_ship_to_zip			varchar(15) NULL, -- v1.1
		i_ship_to_region		varchar(10) NULL,  
		i_type					char(1) NULL, 
		i_freight_allow_type	varchar(10) NULL, 
		i_location				varchar(10) NULL,  
		i_total_tax				decimal(20,8) NULL, 
		i_total_discount		decimal(20,8) NULL, 
		i_gross_sales			decimal(20,8) NULL, 
		i_total_invoice			decimal(20,8) NULL,
		i_curr_factor			decimal(20,8) NULL, 
		i_oper_factor			decimal(20,8) NULL,  
		i_tot_ord_tax			decimal(20,8) NULL, 
		i_tot_ord_disc			decimal(20,8) NULL, 
		i_tot_ord_freight		decimal(20,8) NULL,  
		i_user_code				varchar(8) NULL, 
		i_organization_id		varchar(30) NULL,  
		i_addr_valid_ind		int NULL,  
		i_ship_to_country_cd	varchar(3) NULL,
		d_order_no				int NULL,
		d_ext					int NULL,
		d_ship_to_name			varchar(40) NULL,
		d_ship_to_add_1			varchar(40) NULL,
		d_ship_to_add_2			varchar(40) NULL,
		d_ship_to_city			varchar(40) NULL,
		d_ship_to_state			varchar(40) NULL,
		d_ship_to_zip			varchar(15) NULL, -- v1.1
		d_cust_code				varchar(10) NULL,
		d_ship_to				varchar(10) NULL,
		d_freight_allow_type	varchar(10) NULL,
		d_routing				varchar(20) NULL, -- v1.1
		d_status				char(1) NULL,
		d_tot_ord_disc			decimal(20,8) NULL,
		d_tot_ord_freight		decimal(20,8) NULL,
		d_tot_ord_tax			decimal(20,8) NULL,
		d_total_amt_order		decimal(20,8) NULL,
		d_total_discount		decimal(20,8) NULL,
		d_total_tax				decimal(20,8) NULL,
		d_total_invoice			decimal(20,8) NULL,
		d_gross_sales			decimal(20,8) NULL,
		d_salesperson			varchar(10) NULL,
		d_ship_to_region		varchar(10) NULL,
		i_invoice_no			int NULL,
		d_invoice_no			int NULL,
		d_curr_factor			decimal(20,8) NULL,
		d_oper_factor			decimal(20,8) NULL,
		i_consolidate_flag		smallint NULL,
		d_consolidate_flag		smallint NULL,
		d_user_code				varchar(8) NULL,
		d_type					char(1) NULL,
		d_freight				decimal(20,8) NULL,
		i_tax_valid_ind			int NULL,
		i_date_shipped			datetime NULL)

	SET @last_row_id = 0

	INSERT	#t700updord (i_order_no, i_ext, i_cust_code, i_ship_to, i_routing, i_status, i_total_amt_order, i_salesperson, i_tax_id, i_freight, i_ship_to_name, i_ship_to_add_1, i_ship_to_add_2, 
					i_ship_to_add_5, i_ship_to_city, i_ship_to_state, i_ship_to_zip, i_ship_to_region, i_type, i_freight_allow_type, i_location, i_total_tax, i_total_discount, 
					i_gross_sales, i_total_invoice, i_curr_factor, i_oper_factor, i_tot_ord_tax, i_tot_ord_disc, i_tot_ord_freight, i_user_code, i_organization_id, 
					i_addr_valid_ind, i_ship_to_country_cd, d_order_no, d_ext, d_ship_to_name, d_ship_to_add_1, d_ship_to_add_2, d_ship_to_city, d_ship_to_state, d_ship_to_zip, d_cust_code,
					d_ship_to, d_freight_allow_type, d_routing, d_status, d_tot_ord_disc, d_tot_ord_freight, d_tot_ord_tax, d_total_amt_order, d_total_discount, d_total_tax,
					d_total_invoice, d_gross_sales, d_salesperson, d_ship_to_region, i_invoice_no, d_invoice_no, d_curr_factor, d_oper_factor, i_consolidate_flag,
					d_consolidate_flag, d_user_code, d_type, d_freight, i_tax_valid_ind, i_date_shipped)
	SELECT	i.order_no, i.ext, i.cust_code, i.ship_to, i.routing, i.status, i.total_amt_order, i.salesperson, i.tax_id, i.freight, i.ship_to_name, i.ship_to_add_1, i.ship_to_add_2,  
			i.ship_to_add_5, i.ship_to_city, i.ship_to_state, i.ship_to_zip, i.ship_to_region, i.type, i.freight_allow_type, i.location, i.total_tax, 
			i.total_discount, i.gross_sales, i.total_invoice, i.curr_factor, i.oper_factor, i.tot_ord_tax, i.tot_ord_disc, i.tot_ord_freight, i.user_code, 
			ISNULL(i.organization_id,''), ISNULL(i.addr_valid_ind,0), i.ship_to_country_cd, d.order_no, d.ext, d.ship_to_name, d.ship_to_add_1, d.ship_to_add_2, d.ship_to_city,
			d.ship_to_state, d.ship_to_zip, d.cust_code, d.ship_to, d.freight_allow_type, d.routing, d.status, d.tot_ord_disc, d.tot_ord_freight, d.tot_ord_tax,
			d.total_amt_order, d.total_discount, d.total_tax, d.total_invoice, d.gross_sales, d.salesperson, d.ship_to_region, i.invoice_no, d.invoice_no, d.curr_factor,
			d.oper_factor, i.consolidate_flag, d.consolidate_flag, d.user_code, d.type, d.freight, i.tax_valid_ind, i.date_shipped  
	FROM	inserted i
	LEFT OUTER JOIN deleted d 
	ON		i.order_no = d.order_no 
	AND		i.ext = d.ext  
	ORDER BY i.order_no, i.ext 

	IF UPDATE (order_no) OR UPDATE (ext)  
	BEGIN  
		-- Get number of orders being modified -- rduke 11/21/00 SCR 25107 Begin  
		SELECT	@order_count = COUNT(DISTINCT inserted.order_no)  
		FROM	inserted  
  
		IF (@order_count > 1)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94500, 'You Can Not Update An Order No/Ext No On More Than One Order At A Time'  
			RETURN		
		END  
	END  

	SELECT	TOP 1 @row_id = row_id,
			@i_order_no = i_order_no, 
			@i_ext = i_ext,
			@i_cust_code = i_cust_code,
			@i_ship_to = i_ship_to,
			@i_routing = i_routing,
			@i_status = i_status,
			@i_total_amt_order = i_total_amt_order,
			@i_salesperson = i_salesperson,
			@i_tax_id = i_tax_id,
			@i_freight = i_freight,
			@i_ship_to_name = i_ship_to_name,
			@i_ship_to_add_1 = i_ship_to_add_1,
			@i_ship_to_add_2 = i_ship_to_add_2,
			@i_ship_to_add_5 = i_ship_to_add_5,
			@i_ship_to_city = i_ship_to_city, 
			@i_ship_to_state = i_ship_to_state,
			@i_ship_to_zip = i_ship_to_zip, 
			@i_ship_to_region = i_ship_to_region,
			@i_type = i_type,
			@i_freight_allow_type = i_freight_allow_type, 
			@i_location = i_location,
			@i_total_tax = i_total_tax,
			@i_total_discount = i_total_discount,
			@i_gross_sales = i_gross_sales, 
			@i_total_invoice = i_total_invoice,
			@i_curr_factor = i_curr_factor,
			@i_oper_factor = i_oper_factor,
			@i_tot_ord_tax = i_tot_ord_tax,
			@i_tot_ord_disc = i_tot_ord_disc,
			@i_tot_ord_freight = i_tot_ord_freight,
			@i_user_code = i_user_code,
			@i_organization_id = i_organization_id,
			@i_addr_valid_ind = i_addr_valid_ind,
			@i_ship_to_country_cd = i_ship_to_country_cd,
			@d_order_no = d_order_no,
			@d_ext = d_ext,
			@d_ship_to_name = d_ship_to_name, 
			@d_ship_to_add_1 = d_ship_to_add_1,
			@d_ship_to_add_2 = d_ship_to_add_2,
			@d_ship_to_city = d_ship_to_city,
			@d_ship_to_state = d_ship_to_state,
			@d_ship_to_zip = d_ship_to_zip,
			@d_cust_code = d_cust_code,
			@d_ship_to = d_ship_to,
			@d_freight_allow_type = d_freight_allow_type,
			@d_routing = d_routing,
			@d_status = d_status,
			@d_tot_ord_disc = d_tot_ord_disc,
			@d_tot_ord_freight = d_tot_ord_freight,
			@d_tot_ord_tax = d_tot_ord_tax,
			@d_total_amt_order = d_total_amt_order,
			@d_total_discount = d_total_discount,
			@d_total_tax = d_total_tax,
			@d_total_invoice = d_total_invoice,
			@d_gross_sales = d_gross_sales,
			@d_salesperson = d_salesperson,
			@d_ship_to_region = d_ship_to_region,
			@i_invoice_no = i_invoice_no,
			@d_invoice_no = d_invoice_no,
			@d_curr_factor = d_curr_factor,
			@d_oper_factor = d_oper_factor,
			@i_consolidate_flag = i_consolidate_flag,
			@d_consolidate_flag = d_consolidate_flag,
			@d_user_code = d_user_code,
			@d_type = d_type,
			@d_freight = d_freight,
			@i_tax_valid_ind = i_tax_valid_ind,
			@i_date_shipped = i_date_shipped
	FROM	#t700updord
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN

		IF (@d_order_no is NULL)  
		BEGIN  
			ROLLBACK TRAN  
			EXEC adm_raiserror 94131, 'You Can NOT Change The order number of an order!'  
			RETURN  
		END  
	  
		IF (@i_organization_id = '')
		BEGIN  
			UPDATE	orders_all  
			SET		organization_id = 'CVO'   
			WHERE	order_no = @i_order_no 
			AND		ext = @i_ext
		END  
      
		IF (@i_ship_to_name != @d_ship_to_name OR @i_ship_to_add_1 != @d_ship_to_add_1  
			OR @i_ship_to_add_2 != @d_ship_to_add_2 OR @i_ship_to_city != @d_ship_to_city   
			OR @i_ship_to_state != @d_ship_to_state OR @i_ship_to_zip != @d_ship_to_zip)  
		BEGIN  
			IF EXISTS (SELECT 1 FROM orders_auto_po p (NOLOCK) WHERE @i_order_no=p.order_no AND p.status > 'N')  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94031, 'You Can NOT Change The Shipping Information On Orders That Have Drop Shipments - Contact Purchasing!'  
				RETURN  
			END    
		END  
  
		IF (@i_status < 'R' AND (@i_cust_code != @d_cust_code OR ISNULL(@i_ship_to,'') != ISNULL(@d_ship_to,'') 
			OR ISNULL(@i_freight_allow_type,'') != ISNULL(@d_freight_allow_type,'') OR ISNULL(@i_routing,'') != ISNULL(@d_routing,'')))  
		BEGIN  
			IF EXISTS (SELECT 1 FROM cust_carrier_account (NOLOCK) WHERE cust_code = @i_cust_code AND ISNULL(ship_to,'') = ISNULL(@i_ship_to,'')   
					AND freight_allow_type = ISNULL(@i_freight_allow_type,'') AND routing = ISNULL(@i_routing,''))  
			BEGIN  
				UPDATE	o  
				SET		ship_to_add_5 = '3PB=' + a.account  
				FROM	cust_carrier_account a (NOLOCK), orders_all o  
				WHERE	o.order_no = @i_order_no 
				AND		o.ext = @i_ext 
				AND		a.cust_code = @i_cust_code  
				AND		ISNULL(a.ship_to,'') = ISNULL(@i_ship_to,'') 
				AND		a.freight_allow_type = ISNULL(@i_freight_allow_type,'')   
				AND		a.routing = ISNULL(@i_routing,'')  
			END  
			ELSE IF EXISTS (SELECT 1 FROM cust_carrier_account (NOLOCK) WHERE cust_code = @i_cust_code AND ISNULL(ship_to,'') = ''  
					AND freight_allow_type = ISNULL(@i_freight_allow_type,'') AND routing = ISNULL(@i_routing,''))  
			BEGIN  
				UPDATE	o  
				SET		ship_to_add_5 = '3PB=' + a.account  
				FROM	cust_carrier_account a , orders_all o  
				WHERE	o.order_no = @i_order_no 
				AND		o.ext = @i_ext 
				AND		a.cust_code = @i_cust_code  
				AND		ISNULL(a.ship_to,'') = '' 
				AND		a.freight_allow_type = ISNULL(@i_freight_allow_type,'')   
				AND		a.routing = ISNULL(@i_routing,'')  
			END  
			ELSE  
			BEGIN  
				IF ISNULL(@i_ship_to_add_5,'') LIKE '3PB%'  
				BEGIN  
					UPDATE	o  
					SET		ship_to_add_5 = ''  
					FROM	orders_all o  
					WHERE	o.order_no = @i_order_no 
					AND		o.ext = @i_ext  
				END  
			END  
		END  
  
		IF (@i_status != @d_status OR @i_tot_ord_disc != @d_tot_ord_disc OR @i_tot_ord_freight != @d_tot_ord_freight  
			OR @i_tot_ord_tax != @d_tot_ord_tax OR @i_total_amt_order != @d_total_amt_order OR @i_total_discount != @d_total_discount 
			OR @i_total_tax != @d_total_tax OR @i_total_invoice != @d_total_invoice OR @i_gross_sales != @d_gross_sales OR @i_cust_code != @d_cust_code   
			OR @i_ship_to != @d_ship_to OR @i_salesperson != @d_salesperson OR @i_ship_to_region != @d_ship_to_region  
			OR ISNULL(@i_invoice_no,0) != ISNULL(@d_invoice_no,0))
		BEGIN  
			IF (@hprecision IS NULL)  
			BEGIN  
				SELECT	@hprecision = glcurr_vw.curr_precision 
				FROM	glcurr_vw (NOLOCK), glco	(NOLOCK)  
				WHERE	glcurr_vw.currency_code = glco.home_currency   
			END   
  
			IF (@oprecision IS NULL)
			BEGIN  
				SELECT	@oprecision = glcurr_vw.curr_precision 
				FROM	glcurr_vw (NOLOCK), glco (NOLOCK)  
				WHERE	glcurr_vw.currency_code = glco.oper_currency   
			END  
  
			IF (@i_status IN ('R','S'))
			BEGIN  
				IF EXISTS (SELECT 1 FROM adm_cust_all a (NOLOCK)  
							WHERE @i_cust_code = a.customer_code AND a.status_type = 2)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94036, 'You Can NOT Ship An Order That Has A Customer Hold Or Inactive Flag Set.'  
					RETURN  
				END 
			END  
  
			IF (@d_status BETWEEN 'N' AND 'S' AND @d_type = 'I')  
			BEGIN  
				EXEC @tdc_rtn = tdc_order_hdr_change @d_order_no, @d_ext   
  
				IF (@tdc_rtn< 0 )  
				BEGIN  
					EXEC adm_raiserror 94900 ,'Invalid Inventory Update From TDC.'  
				END  
			END  
  
			IF (@d_status BETWEEN 'N' AND 'S' AND @d_type = 'I' AND ISNULL(@d_consolidate_flag,0) = 0) OR  
				(@d_status BETWEEN 'N' AND 'T' AND @d_type = 'I' AND ISNULL(@d_consolidate_flag,0) = 1 AND ISNULL(@d_invoice_no,0) = 0)   
			BEGIN   
				SELECT	@customer_code = @d_cust_code, 
						@ship_to_code = @d_ship_to,  
						@salesperson_code = @d_salesperson, 
						@territory_code = @d_ship_to_region,  
						@hstat = @d_status, 
						@hrate = @d_curr_factor, 
						@orate = @d_oper_factor,  
						@amt_home = @d_total_amt_order - @d_tot_ord_disc + @d_tot_ord_tax + @d_tot_ord_freight,  
						@amt_oper = @d_gross_sales - @d_total_discount +  @d_total_tax + @d_freight  
      
				IF (@hstat = 'S')
					SELECT @amt_home = @amt_oper  
				ELSE 
					SELECT @amt_oper = @amt_home  
      
				SELECT	@price_code = price_code 
				FROM	adm_cust_all (NOLOCK) 
				WHERE	customer_code = @customer_code  
  
				IF (@ship_to_code IS NULL) 
					SELECT @ship_to_code = ''  
  
				IF (@hrate >= 0)  
					SELECT @amt_home = -1 * ROUND((@amt_home * @hrate), @hprecision)  
				ELSE 
					SELECT @amt_home = -1 * ROUND(@amt_home / ABS(@hrate), @hprecision)  
  
				IF (@orate >= 0)  
					SELECT @amt_oper = -1 * ROUND(@amt_oper * @orate, @oprecision)  
				ELSE  
					SELECT @amt_oper = -1 * ROUND(@amt_oper / ABS(@orate), @oprecision)  
  
				EXEC @rtn = aractinp_sp @customer_code, @ship_to_code, @price_code, @salesperson_code,  
						@territory_code, @amt_home, @amt_oper, 1000  
  
				IF (@@ERROR <> 0 OR @rtn <> 0)   
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94038 ,'Error updating activity tables.'  
					RETURN  
				END  
			END    
  
			IF (@i_status BETWEEN 'N' AND 'S' AND @i_type = 'I' AND ISNULL(@i_consolidate_flag,0) = 0) OR  
				(@i_status BETWEEN 'N' AND 'T' AND @i_type = 'I' AND ISNULL(@i_consolidate_flag,0) = 1 AND ISNULL(@i_invoice_no,0) = 0)   
			BEGIN  
				SELECT	@customer_code = @i_cust_code, 
						@ship_to_code = @i_ship_to,  
						@salesperson_code = @i_salesperson, 
						@territory_code = @i_ship_to_region,  
						@hstat = @i_status, 
						@hrate = @i_curr_factor, 
						@orate = @i_oper_factor,  
						@amt_home = @i_total_amt_order - @i_tot_ord_disc +  @i_tot_ord_tax + @i_tot_ord_freight,  
						@amt_oper = @i_gross_sales - @i_total_discount +  @i_total_tax + @i_freight  
  
				IF (@hstat IN ('S','T')) 
					SELECT @amt_home = @amt_oper  
				ELSE 
					SELECT @amt_oper = @amt_home  
  
				SELECT	@price_code = price_code 
				FROM	adm_cust_all (NOLOCK) 
				WHERE	customer_code = @customer_code  
  
				IF (@ship_to_code IS NULL) 
					SELECT @ship_to_code = ''  
  
				IF (@hrate >= 0)  
					SELECT @amt_home = ROUND(@amt_home * @hrate, @hprecision)  
				ELSE 
					SELECT @amt_home = ROUND(@amt_home / ABS(@hrate), @hprecision)  
  
				IF (@orate >= 0)  
					SELECT @amt_oper = ROUND(@amt_oper * @orate, @oprecision)  
				ELSE  
					SELECT @amt_oper = ROUND(@amt_oper / ABS(@orate), @oprecision)  
  
				EXEC @rtn = aractinp_sp @customer_code, @ship_to_code, @price_code, @salesperson_code,  
						@territory_code, @amt_home, @amt_oper, 1000  
  
				IF (@@ERROR <> 0 OR @rtn <> 0)   
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94039, 'Error updating activity tables with new amount.'  
					RETURN  
				END  
			END   
		END   
  
		IF (@i_status != @d_status OR @i_user_code != @d_user_code OR @i_user_code = '')
		BEGIN  
			IF NOT EXISTS (SELECT 1 FROM so_usrstat (NOLOCK) WHERE user_stat_code = @i_user_code AND status_code = @i_status AND ISNULL(void,'N') = 'N')  
			BEGIN  
				UPDATE	p  
				SET		user_code = s.user_stat_code  
				FROM	orders_all p, so_usrstat s (NOLOCK) 
				WHERE	p.order_no = @i_order_no 
				AND		p.ext = @i_ext  
				AND		s.status_code = @i_status 
				AND		ISNULL(s.void,'N') = 'N' 
				AND		s.default_flag = 1  
			END  
		END            

		IF (@i_status = 'S')  
		BEGIN  
			IF EXISTS (SELECT 1 FROM lot_bin_ship s (NOLOCK) WHERE tran_no = @i_order_no AND tran_ext = @i_ext  
				AND NOT EXISTS (SELECT 1 FROM ord_list l (NOLOCK) WHERE l.order_no = @i_order_no AND l.order_ext = @i_ext  
								AND l.line_no = s.line_no AND l.part_no = s.part_no)  
				AND NOT EXISTS (SELECT 1 FROM ord_list_kit l (NOLOCK) WHERE l.order_no = @i_order_no AND l.order_ext = @i_ext  
								AND l.line_no = s.line_no AND l.part_no = s.part_no))  
			BEGIN  
				SELECT @msg = 'Lot bin records on lot_bin_ship do not relate to a line on the order.'  
				ROLLBACK TRAN  
				EXEC adm_raiserror 832114, @msg  
				RETURN  
			END  
		END  
  
		IF (@i_status != @d_status)  
		BEGIN  
			IF (@d_status >= 'S' AND @i_status < 'S')  
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94033 ,'You Can NOT Change A Order That Is Shipped Or Voided!'  
				RETURN  
			END  
  
			IF (@d_status IN ('T','V'))   
			BEGIN  
				ROLLBACK TRAN  
				EXEC adm_raiserror 94033 ,'You Can NOT Change A Order That Is Transfered Or Voided!'  
				RETURN  
			END           
  
			IF (@i_status = 'N' AND @d_status = 'R')  
			BEGIN  
				IF EXISTS (SELECT 1 FROM ord_list ref (NOLOCK) WHERE ref.order_no = @i_order_no AND ref.order_ext = @i_ext   
							AND ref.shipped > 0 AND ref.location LIKE 'DROP%')  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94037, 'Order Is Ready For Shipping From DROP Shipment Via Purchasing...You Can NOT Change The Shipping Information On Orders That Have Drop Shipments - Contact Purchasing!'  
					RETURN  
				END    
			END  
  
			IF (@i_status = 'V')   
			BEGIN  
				IF EXISTS (SELECT 1 FROM orders_auto_po o (NOLOCK) WHERE o.order_no = @i_order_no AND o.status ='P')  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94035, 'You Can NOT Void An Order With DROP Shipments Pending - Contact Purchasing!'  
					RETURN  
				END  
			END  
  
			SELECT @xlk = ISNULL((SELECT MIN(line_no) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no 
								AND order_ext = @i_ext AND status != @i_status),0)  
			WHILE (@xlk > 0)  
			BEGIN  
				UPDATE	ord_list   
				SET		status = @i_status,  
						shipped = CASE WHEN (@i_status = 'N' AND (ord_list.location NOT LIKE 'DROP%' AND ord_list.create_po_flag = 0))   
										THEN 0 ELSE shipped END,  
						price_type = CASE WHEN ord_list.price_type = 'X' AND @i_status >= 'M' AND @i_status < 'P'  
										THEN 'Y' ELSE price_type END
				WHERE	ord_list.order_no = @i_order_no 
				AND		ord_list.order_ext = @i_ext 
				AND		ord_list.line_no = @xlk   
   
				SELECT @xlk = ISNULL((SELECT MIN(line_no) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no 
								AND order_ext = @i_ext AND line_no > @xlk AND status != @i_status),0)  
			END   
  
			IF (@i_status != @d_status)
			BEGIN  
				UPDATE	lot_bin_ship  
				SET		tran_code = @i_status  
				WHERE	tran_no = @i_order_no 
				AND		tran_ext = @i_ext 
				AND		tran_code != @i_status  
			END            
  
			IF (@i_status = 'S')  
			BEGIN           
				IF (@i_total_invoice < 0)  
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94034 ,'Net amount on order cannot be negative. Please do a Credit Memo.'  
					RETURN  
				END  
  
				SELECT @xlk = ISNULL((SELECT MIN(line_no) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no 
									AND order_ext = @i_ext AND part_type = 'C' AND shipped !=0),0)  
				WHILE (@xlk > 0)  
				BEGIN  
					UPDATE	ord_list 
					SET		cost = ISNULL((SELECT SUM(cost * shipped * qty_per) / ord_list.shipped  
											FROM	ord_list_kit (NOLOCK)  
											WHERE	ord_list_kit.order_no = @i_order_no 
											AND		ord_list_kit.order_ext = @i_ext 
											AND		ord_list_kit.line_no = @xlk),0),  
							direct_dolrs = ISNULL((SELECT SUM(direct_dolrs * shipped * qty_per) / ord_list.shipped  
												FROM	ord_list_kit (NOLOCK)   
												WHERE	ord_list_kit.order_no = @i_order_no 
												AND		ord_list_kit.order_ext = @i_ext 
												AND		ord_list_kit.line_no=@xlk),0),  
							ovhd_dolrs	= ISNULL((SELECT SUM(ovhd_dolrs * shipped * qty_per) / ord_list.shipped  
												FROM	ord_list_kit (NOLOCK)  
												WHERE	ord_list_kit.order_no = @i_order_no 
												AND		ord_list_kit.order_ext = @i_ext 
												AND		ord_list_kit.line_no=@xlk),0),  
							util_dolrs = ISNULL((SELECT SUM(util_dolrs * shipped * qty_per) / ord_list.shipped  
												FROM	ord_list_kit (NOLOCK)  
												WHERE	ord_list_kit.order_no = @i_order_no 
												AND		ord_list_kit.order_ext = @i_ext 
												AND		ord_list_kit.line_no = @xlk),0),  
							labor =	ISNULL((SELECT SUM(labor * shipped * qty_per) / ord_list.shipped  
											FROM	ord_list_kit (NOLOCK)   
											WHERE	ord_list_kit.order_no = @i_order_no 
											AND		ord_list_kit.order_ext = @i_ext 
											AND		ord_list_kit.line_no = @xlk),0)  
					FROM	ord_list   
					WHERE	order_no = @i_order_no 
					AND		order_ext = @i_ext 
					AND		line_no = @xlk  
  
					SELECT @xlk = ISNULL((SELECT MIN(line_no) FROM ord_list (NOLOCK) WHERE order_no = @i_order_no 
										AND order_ext = @i_ext AND line_no > @xlk AND part_type='C' AND shipped !=0),0)  
				END   
      
				DECLARE @err int  
				SELECT @err = 1  
  
				EXEC @err = fs_updordtots @i_order_no, @i_ext  
  
				IF (@@error != 0)
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94031, 'Error Updating Order Totals.'  
					RETURN  
				END  
				IF (@err != 1)   
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94032, 'Error Updating Order Totals.'  
					RETURN  
				END  
			END
  
			IF (@i_status = 'T' AND @d_status != 'W')  
			BEGIN  
				IF (ISNULL(@i_tax_valid_ind,1) = 0)  
				BEGIN  
					SELECT @msg = 'Tax calculation has not completed successfully.  Cannot post order.'  
					ROLLBACK TRAN  
					EXEC adm_raiserror 832115, @msg  
					RETURN  
				END  
  
				EXEC @retval = fs_create_backorder @i_order_no, @i_ext  
				IF (@retval != 1)   
				BEGIN  
					ROLLBACK TRAN  
					EXEC adm_raiserror 94032, 'Error Creating Backorder.'  
					RETURN  
				END  
  
				DECLARE @ext int  
				SELECT	@ext = ISNULL((SELECT MIN(ext) FROM orders_all (NOLOCK) WHERE order_no = @i_order_no AND ext > @i_ext AND status='N'),-1)  
  
				IF (@ext > 0)  
				BEGIN  
					EXEC @tdc_rtn = tdc_order_hdr_change @i_order_no, @ext   
    
					IF (@tdc_rtn < 0 )  
					BEGIN  
						EXEC adm_raiserror 94900, 'Invalid Inventory Update From TDC.'  
					END  
				END  
  
				IF EXISTS (SELECT 1 FROM shippers (NOLOCK) WHERE order_no = @i_order_no AND order_ext = @i_ext)
				BEGIN  
					UPDATE	shippers  
					SET		part_type = '@'  
					WHERE	order_no = @i_order_no 
					AND		order_ext = @i_ext  
   
					DELETE	shippers 
					WHERE	order_no = @i_order_no 
					AND		order_ext = @i_ext  
				END           
  
				INSERT INTO shippers (cust_code, ship_to_no, ship_to_region, order_no, order_ext,  
								location, part_no, category, date_shipped, ordered, shipped, price,  
								price_type, cost, sales_comm, cr_ordered, cr_shipped, salesperson, labor,  
								direct_dolrs, ovhd_dolrs, util_dolrs, line_no, cust_type, conv_factor, part_type)  
				SELECT	@i_cust_code, @i_ship_to, @i_ship_to_region, @i_order_no, @i_ext, l.location, l.part_no,  
						inventory.category, @i_date_shipped, l.ordered, l.shipped, l.price, l.price_type,  
						CASE WHEN l.part_type = 'A' THEN 0 ELSE l.cost END, l.sales_comm, l.cr_ordered, l.cr_shipped,  
						@i_salesperson, CASE WHEN l.part_type = 'A' THEN 0 ELSE l.labor END, 
						CASE WHEN l.part_type = 'A' THEN 0 ELSE l.direct_dolrs END, 
						CASE WHEN l.part_type = 'A' THEN 0 ELSE l.ovhd_dolrs END, 
						CASE WHEN l.part_type = 'A' THEN 0 ELSE l.util_dolrs END, 
						l.line_no,adm_cust_all.price_code, l.conv_factor, l.part_type  
				FROM	ord_list l (NOLOCK), inventory (NOLOCK), adm_cust_all (NOLOCK) 
				WHERE	l.order_no = @i_order_no 
				AND		l.order_ext = @i_ext 
				AND		(l.part_type ='P' OR l.part_type='A' OR l.part_type='C') 
				AND		(l.shipped - l.cr_shipped) != 0 
				AND		l.part_no = inventory.part_no 
				AND		l.location=inventory.location 
				AND		adm_cust_all.customer_code = @i_cust_code   
  
				INSERT INTO shippers (cust_code, ship_to_no, ship_to_region, order_no, order_ext,  
								location, part_no, category, date_shipped, ordered, shipped, price,  
								price_type, cost, sales_comm, cr_ordered, cr_shipped, salesperson, labor,  
								direct_dolrs, ovhd_dolrs, util_dolrs, line_no, cust_type, conv_factor, part_type)  
				SELECT	 @i_cust_code, @i_ship_to, @i_ship_to_region, @i_order_no, @i_ext, l.location, l.part_no,  
						CASE l.part_type WHEN 'J' THEN 'JOBSHOP' WHEN 'M' THEN 'MISC' ELSE 'UNKNOWN' END,  
						@i_date_shipped, l.ordered, l.shipped, l.price, l.price_type, l.cost, l.sales_comm, l.cr_ordered, l.cr_shipped,  
						@i_salesperson, l.labor, l.direct_dolrs, l.ovhd_dolrs, l.util_dolrs, l.line_no, adm_cust_all.price_code, l.conv_factor, l.part_type  
				FROM	ord_list l (NOLOCK), adm_cust_all (NOLOCK) 
				WHERE	l.order_no = @i_order_no 
				AND		l.order_ext = @i_ext 
				AND		(l.shipped - l.cr_shipped) != 0 
				AND		(l.part_type !='P' AND l.part_type !='A' AND l.part_type !='C') 
				AND		adm_cust_all.customer_code = @i_cust_code  
  
				INSERT INTO shippers (cust_code, ship_to_no, ship_to_region, order_no, order_ext,  
								location, part_no, category, date_shipped, ordered, shipped, price,  
								price_type, cost, sales_comm, cr_ordered, cr_shipped, salesperson, labor,  
								direct_dolrs, ovhd_dolrs, util_dolrs, line_no, cust_type, conv_factor, part_type)  
				SELECT	@i_cust_code, @i_ship_to, @i_ship_to_region, @i_order_no, @i_ext, l.location, l.part_no,  
						inventory.category, @i_date_shipped, (l.ordered * l.qty_per), (l.shipped * l.qty_per), 
						0, 'K', 0, 0, (l.cr_ordered * l.qty_per), (l.cr_shipped * l.qty_per),  
						@i_salesperson, 0, 0, 0, 0, l.line_no, adm_cust_all.price_code, l.conv_factor, l.part_type  
				FROM	ord_list_kit l (NOLOCK), inventory (NOLOCK), adm_cust_all (NOLOCK) 
				WHERE	l.order_no = @i_order_no 
				AND		l.order_ext = @i_ext 
				AND		(l.part_type ='P' OR l.part_type='A' or l.part_type='C') 
				AND		(l.shipped - l.cr_shipped) != 0 
				AND		l.part_no=inventory.part_no 
				AND		l.location = inventory.location 
				AND		adm_cust_all.customer_code = @i_cust_code   
  
  				INSERT INTO shippers (cust_code, ship_to_no, ship_to_region, order_no, order_ext,  
								location, part_no, category, date_shipped, ordered, shipped, price,  
								price_type, cost, sales_comm, cr_ordered, cr_shipped, salesperson, labor,  
								direct_dolrs, ovhd_dolrs, util_dolrs, line_no, cust_type, conv_factor, part_type)  
				SELECT	@i_cust_code, @i_ship_to, @i_ship_to_region, @i_order_no, @i_ext, l.location, l.part_no,  
						CASE l.part_type WHEN 'J' THEN 'JOBSHOP' WHEN 'M' THEN 'MISC' ELSE 'UNKNOWN' END,  
						@i_date_shipped, (l.ordered * l.qty_per), (l.shipped * l.qty_per),    -- mls 5/11/00 SCR 22800  
						0, 'K', 0, 0, (l.cr_ordered * l.qty_per), (l.cr_shipped * l.qty_per),  
						@i_salesperson, 0, 0, 0, 0, l.line_no, adm_cust_all.price_code, l.conv_factor, l.part_type  
				FROM	ord_list_kit l (NOLOCK), adm_cust_all (NOLOCK) 
				WHERE	l.order_no = @i_order_no 
				AND		l.order_ext = @i_ext 
				AND		(l.shipped - l.cr_shipped) != 0 
				AND		(l.part_type !='P' AND l.part_type !='A' AND l.part_type !='C') 
				AND		adm_cust_all.customer_code = @i_cust_code  
			END 
		END

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@i_order_no = i_order_no, 
				@i_ext = i_ext,
				@i_cust_code = i_cust_code,
				@i_ship_to = i_ship_to,
				@i_routing = i_routing,
				@i_status = i_status,
				@i_total_amt_order = i_total_amt_order,
				@i_salesperson = i_salesperson,
				@i_tax_id = i_tax_id,
				@i_freight = i_freight,
				@i_ship_to_name = i_ship_to_name,
				@i_ship_to_add_1 = i_ship_to_add_1,
				@i_ship_to_add_2 = i_ship_to_add_2,
				@i_ship_to_add_5 = i_ship_to_add_5,
				@i_ship_to_city = i_ship_to_city, 
				@i_ship_to_state = i_ship_to_state,
				@i_ship_to_zip = i_ship_to_zip, 
				@i_ship_to_region = i_ship_to_region,
				@i_type = i_type,
				@i_freight_allow_type = i_freight_allow_type, 
				@i_location = i_location,
				@i_total_tax = i_total_tax,
				@i_total_discount = i_total_discount,
				@i_gross_sales = i_gross_sales,
				@i_total_invoice = i_total_invoice, 
				@i_curr_factor = i_curr_factor,
				@i_oper_factor = i_oper_factor,
				@i_tot_ord_tax = i_tot_ord_tax,
				@i_tot_ord_disc = i_tot_ord_disc,
				@i_tot_ord_freight = i_tot_ord_freight,
				@i_user_code = i_user_code,
				@i_organization_id = i_organization_id,
				@i_addr_valid_ind = i_addr_valid_ind,
				@i_ship_to_country_cd = i_ship_to_country_cd,
				@d_order_no = d_order_no,
				@d_ext = d_ext,
				@d_ship_to_name = d_ship_to_name, 
				@d_ship_to_add_1 = d_ship_to_add_1,
				@d_ship_to_add_2 = d_ship_to_add_2,
				@d_ship_to_city = d_ship_to_city,
				@d_ship_to_state = d_ship_to_state,
				@d_ship_to_zip = d_ship_to_zip,
				@d_cust_code = d_cust_code,
				@d_ship_to = d_ship_to,
				@d_freight_allow_type = d_freight_allow_type,
				@d_routing = d_routing,
				@d_status = d_status,
				@d_tot_ord_disc = d_tot_ord_disc,
				@d_tot_ord_freight = d_tot_ord_freight,
				@d_tot_ord_tax = d_tot_ord_tax,
				@d_total_amt_order = d_total_amt_order,
				@d_total_discount = d_total_discount,
				@d_total_tax = d_total_tax,
				@d_total_invoice = d_total_invoice,
				@d_gross_sales = d_gross_sales,
				@d_salesperson = d_salesperson,
				@d_ship_to_region = d_ship_to_region,
				@i_invoice_no = i_invoice_no,
				@d_invoice_no = d_invoice_no,
				@d_curr_factor = d_curr_factor,
				@d_oper_factor = d_oper_factor,
				@i_consolidate_flag = i_consolidate_flag,
				@d_consolidate_flag = d_consolidate_flag,
				@d_user_code = d_user_code,
				@d_type = d_type,
				@d_freight = d_freight,
				@i_tax_valid_ind = i_tax_valid_ind,
				@i_date_shipped = i_date_shipped
		FROM	#t700updord
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC


	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 16/06/2011 - When an order goes on credit hold with a custom frame the order does not save
-- v1.1 CB 21/06/2013 - Issue #1322 - When releasing a C&C status it was not updating all pick queue records - bug in standard code
-- v1.2 CB 19/03/2015 - Performance Changes

CREATE TRIGGER [dbo].[tdc_updordl] ON [dbo].[orders_all]
FOR UPDATE AS
BEGIN

DECLARE @ord_no int, @ord_ext int, @i_status varchar(1), @d_status varchar(1)

SELECT @ord_no = 0
SELECT @ord_ext = -1

IF NOT UPDATE (status)
BEGIN
	return
END

WHILE( @ord_no >= 0)
BEGIN
	SELECT @ord_no = isnull((SELECT min(order_no) from inserted WHERE order_no > @ord_no), -1)
	SET @ord_ext = -1 -- v1.1 Need to reset the ord_ext for each order

	WHILE( @ord_ext >= -1)
	BEGIN
		SELECT @ord_ext = isnull((SELECT min(ext) from inserted WHERE ext > @ord_ext AND order_no = @ord_no), -2)

		IF @ord_ext < 0 BREAK

		SELECT @i_status = status FROM inserted WHERE order_no = @ord_no AND ext = @ord_ext
		SELECT @d_status = status FROM deleted  WHERE order_no = @ord_no AND ext = @ord_ext

		-- try to change the order from new to hold
		IF (@i_status < 'N' AND @d_status = 'N')
		BEGIN
			IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @ord_no AND order_ext = @ord_ext AND order_type = 'S') -- v1.2
			BEGIN
				IF EXISTS (SELECT DISTINCT consolidation_no FROM tdc_cons_ords (nolock) WHERE consolidation_no IN 
					  (SELECT consolidation_no FROM tdc_cons_ords (nolock)
									WHERE order_no = @ord_no and order_ext = @ord_ext) 
									GROUP BY consolidation_no 
									HAVING count(*) > 1)
				BEGIN
					rollback tran
					raiserror ('This order is in a consolidation set and must be unallocated before a status change', 16, 1) 
					return
				END			
				
				IF EXISTS (SELECT * FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @ord_no AND -- v1.2
									trans_type_ext = @ord_ext AND tx_lock NOT IN ('R','3','H')) -- v1.0 Allow 'H'
				BEGIN
					rollback tran
					raiserror ('Queue Transaction are in process for this order', 16, 1)
					return
				END
				
				UPDATE tdc_pick_queue 
				SET tx_lock = 'E' 
				WHERE trans_type_no = @ord_no AND trans_type_ext = @ord_ext AND (tx_lock = 'R'	OR tx_lock = '3')
			END
		END

		-- try to release order from hold
		IF (@i_status = 'N' AND @d_status < 'N')
		BEGIN
			IF EXISTS (SELECT * FROM tdc_pick_queue (nolock) WHERE trans_type_no = @ord_no 
									 AND trans_type_ext = @ord_ext 
									 AND tx_lock = 'E')
			BEGIN					
				IF EXISTS(SELECT * FROM tdc_cons_ords (NOLOCK) WHERE order_no = @ord_no AND order_ext = @ord_ext AND alloc_type = 'PP') -- v1.2
				BEGIN
					UPDATE tdc_pick_queue 
					SET tx_lock = '3' 
					WHERE trans_type_no = @ord_no AND trans_type_ext = @ord_ext AND tx_lock = 'E'
				END
				ELSE
				BEGIN
					UPDATE tdc_pick_queue 
					SET tx_lock = 'R' 
					WHERE trans_type_no = @ord_no AND trans_type_ext = @ord_ext AND tx_lock = 'E'				
				END
			END
		END
	END
END
END
GO
ALTER TABLE [dbo].[orders_all] ADD CONSTRAINT [orders_multiple_flag_cc1] CHECK (([multiple_flag]='N' OR [multiple_flag]='Y'))
GO
ALTER TABLE [dbo].[orders_all] ADD CONSTRAINT [CK_orders_so_priority_code] CHECK (([so_priority_code]='' OR [so_priority_code]='8' OR [so_priority_code]='7' OR [so_priority_code]='6' OR [so_priority_code]='5' OR [so_priority_code]='4' OR [so_priority_code]='3' OR [so_priority_code]='2' OR [so_priority_code]='1'))
GO
CREATE NONCLUSTERED INDEX [ord2] ON [dbo].[orders_all] ([cust_code], [order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord4] ON [dbo].[orders_all] ([cust_po], [order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [orders_all_ind_ext_type_date] ON [dbo].[orders_all] ([ext], [type], [date_entered]) INCLUDE ([salesperson], [cust_code], [order_no], [ship_to], [user_category]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [orders_all_ind_ext_typ_date_cat] ON [dbo].[orders_all] ([ext], [type], [date_entered], [user_category]) INCLUDE ([ship_to], [order_no], [salesperson], [cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord6] ON [dbo].[orders_all] ([invoice_no], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord8] ON [dbo].[orders_all] ([load_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord1] ON [dbo].[orders_all] ([order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_orders_ord11] ON [dbo].[orders_all] ([order_no], [ext], [hold_reason]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord10] ON [dbo].[orders_all] ([order_no], [ext], [type], [user_category], [cust_code], [status], [sch_ship_date], [hold_reason], [req_ship_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord7] ON [dbo].[orders_all] ([process_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord5] ON [dbo].[orders_all] ([ship_to_name], [order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord9] ON [dbo].[orders_all] ([status], [cust_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord3] ON [dbo].[orders_all] ([status], [order_no], [ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ord10_110613] ON [dbo].[orders_all] ([type], [orig_no], [orig_ext], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [orders_all_idx_hs] ON [dbo].[orders_all] ([user_def_fld4], [date_entered], [who_entered], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ord_void_status_051415] ON [dbo].[orders_all] ([void], [status]) INCLUDE ([gross_sales], [type], [total_tax], [cust_code], [order_no], [ext], [total_discount], [freight]) ON [PRIMARY]
GO
CREATE STATISTICS [_dta_stat_337396967_4_44] ON [dbo].[orders_all] ([cust_code], [type])
GO
CREATE STATISTICS [_dta_stat_337396967_3_73] ON [dbo].[orders_all] ([ext], [load_no])
GO
CREATE STATISTICS [_dta_stat_337396967_73_4_74_5_2_77] ON [dbo].[orders_all] ([load_no], [cust_code], [curr_key], [ship_to], [order_no], [bill_to_key])
GO
CREATE STATISTICS [_dta_stat_337396967_2_4_44] ON [dbo].[orders_all] ([order_no], [cust_code], [type])
GO
CREATE STATISTICS [_dta_stat_337396967_2_3_73_4_74_5_77] ON [dbo].[orders_all] ([order_no], [ext], [load_no], [cust_code], [curr_key], [ship_to], [bill_to_key])
GO
CREATE STATISTICS [_dta_stat_337396967_2_44] ON [dbo].[orders_all] ([order_no], [type])
GO
GRANT REFERENCES ON  [dbo].[orders_all] TO [public]
GO
GRANT SELECT ON  [dbo].[orders_all] TO [public]
GO
GRANT INSERT ON  [dbo].[orders_all] TO [public]
GO
GRANT DELETE ON  [dbo].[orders_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[orders_all] TO [public]
GO
