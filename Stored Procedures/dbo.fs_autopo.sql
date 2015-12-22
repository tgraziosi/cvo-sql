SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_autopo] @batch_id varchar(20), @user varchar(30)  AS
BEGIN





declare		@hrate			decimal(20,8),
		@orate			decimal(20,8),
		@qty			decimal(20,8),
		@min_vq_qty		decimal(20,8)
declare		@working_row	int,
		@i_po_no		int,
		@pltdate		int,
		@error			int,
		@cnt			int,
		@unit_decimals		int,
		@xlp			int,
		@lin			int,
		@err			int,
		@group_row		int,
		@internal_po		int
declare		@acct_from_where	char(1)
declare		@part_no		varchar(30),
		@location		varchar(10),
		@from_loc		varchar(10),
		@vend_loc		varchar(10),
		@vendor			varchar(12),
		@group_no		varchar(20),
		@po_no			varchar(16),
		@home_curr		varchar(10),
		@oper_curr		varchar(10),
		@currency		varchar(10),
		@tax			varchar(10),
		@htype			varchar(8),
		@otype			varchar(8)
declare @combine int
declare @divide_flag smallint

declare @part varchar(30), @line int							-- mls #9
declare @po_qty decimal(20,8), @unit_cost decimal(20,8)					-- mls 8/27/01 SCR 27475
declare @contact_no int									-- mls 2/21/02 SCR 27449
declare @status char(1), @approval_status char(1), @etransmit_status char(1),
  @eproc_ind int
declare @min_sku varchar(30)								-- mls 3/25/02 SCR 28567

declare @vend_curr varchar(10), @one_cur_vendor int, @po_currency varchar(10)		-- mls 11/6/02 SCR 30081
declare @exp_date datetime								-- mls 2/27/03 SCR 30763
declare @row int, @uom char(2), @po_uom char(2), @conv_factor decimal(20,8)		-- mls 8/11/04 SCR 31751
declare @aprv_po_flag int, @approval_code varchar(8)

CREATE TABLE #tpo(	tvend_no	varchar(12),
			tinternal_po	int,
			tpo_no		varchar(16),
			tvend_loc	varchar(10),
			tcurr_code	varchar(10),
			tgroup_no	varchar(20),
			tgroup_row	int,
			tapproval_code varchar(8) NULL,
			trow_id		int identity(1,1) ) 

create index tpo1 on #tpo(tvend_no)

CREATE TABLE #tpo_list(	part_no		varchar(30),
			part_type	char(1),
			description	varchar(255),
			uom		char(2),
			qty		decimal(20,8),
			demand_date	datetime,
			lb_tracking	char(1),
			unit_cost	decimal(20,8),
			po_line int,							-- mls #9
			po_uom          char(2),					-- mls 8/11/04 SCR 31751
                        conv_factor	decimal(20,8),					-- mls 8/11/04 SCR 31751
			line_no		int identity(1,1) )

create index tpo1 on #tpo_list (part_no,line_no)					-- mls 8/11/04 SCR 31751
create index tpo2 on #tpo_list (line_no)						-- mls 8/11/04 SCR 31751

CREATE TABLE #rate(	error		int,
			rate		float NULL,
			divide_flag	int NULL )

CREATE TABLE #tacct(	part_no		varchar(30),
			location	varchar(10),
			invacct		varchar(32) NULL,
			acctcode	varchar(10) NULL,
			part_type	char(1) )

CREATE TABLE #treport(	vendorno	varchar(12),
			pono		varchar(16),
			partno		varchar(30),
			rdate		datetime,
			qty		money,
			uom		char(2),
			description	varchar(255) NULL )

create table #pomask (po_no varchar(16), error int)

--******************************************************************************
--* Get the company's home and operational currency codes, the default 
--* number of decimals for cost values, the config setting for which expense
--* account to use for misc items.
--******************************************************************************
SELECT	@home_curr = home_currency, @oper_curr = oper_currency	FROM	glco (nolock)

declare @po_mask varchar(16)

select @po_mask = isnull((select value_str from config (nolock)	-- mls 7/31/02 SCR i441 start
  where flag = 'PUR_PO_MASK'),NULL)
if @po_mask is NULL
begin
  rollback tran
  raiserror 99111 'PO mask not defined'
  return
end								-- mls 7/31/02 SCR i441 end


select @status = 'O'						-- mls 2/28/02 SCR 28451 start

if exists (select 1 from config (nolock) where flag = 'PUR_PO_HOLD' and upper(value_str) like 'Y%')
begin
  if isnull((select p.write
    from ewusers_vw u
    join smperm_vw p on p.app_id = 18000 and p.user_id = u.user_id 
    join glco g on  p.company_id = g.company_id
    join smmenus_vw m on m.app_id = 18000 and m.form_id = p.form_id and m.form_desc = 'HOLD/RELEASE'
    where u.user_name = @user),0) = 0
  begin
    select @status = 'H'
  end 
end								-- mls 2/28/02 SCR 28451 end

select @eproc_ind = 0

if exists (select 1 from config (nolock) where flag = 'PUR_EPROCUREMENT' and upper(value_str) like 'Y%') -- mls 9/8/03 SCR 31491
begin
  select @eproc_ind = 1
  if isnull((select p.write
    from ewusers_vw u
    join smperm_vw p on p.app_id = 18000 and p.user_id = u.user_id 
    join glco g on  p.company_id = g.company_id
    join smmenus_vw m on m.app_id = 18000 and m.form_id = p.form_id and m.form_id = 16407
    where u.user_name = @user),0) = 0
    select @status = 'H', @approval_status = 'N'
end

select @unit_decimals = IsNull((SELECT convert( integer, value_str ) FROM config (nolock) WHERE flag = 'INV_UNIT_DECIMALS' ), 4 )
select @acct_from_where = IsNull( (	SELECT value_str FROM config (nolock) WHERE flag = 'PLT_AP_POST_OP'), 'I' )
select @aprv_po_flag = aprv_po_flag from apco (nolock)
if @eproc_ind = 1  set @aprv_po_flag = 0

if isnull(@aprv_po_flag,2) not in (0,1)
  set @aprv_po_flag = 0

--******************************************************************************
--* Make sure that we don't try to create any PO's for zero quantity
--******************************************************************************
DELETE	resource_demand_group
WHERE	batch_id	= @batch_id and
	buy_flag	= 'Y' and
	qty		<= 0

--******************************************************************************
--* Find the first location with orders to be created
--******************************************************************************
SELECT @location = IsNull((SELECT MIN(location) FROM resource_demand_group (nolock)
  WHERE batch_id = @batch_id and buy_flag = 'Y' and blanket_order_flag = 'N' ), '' )

while @location > ''
begin
	--**************************************************************************
	--* Check for any items to be transferred from another location.  If yes, 
	--* call fs_auto_xfer to create a transfer order for each summary row to be
	--* transferred.
	--**************************************************************************
	select @group_no= IsNull((	SELECT	MIN(group_no) FROM resource_demand_group
					WHERE	batch_id		= @batch_id and
						location		= @location and
						buy_flag		= 'Y' and
						blanket_order_flag	= 'N' and
						xfer_order_flag		= 'Y'), '')
	while @group_no > ''
	begin
		SELECT	@part_no	= part_no,
			@from_loc	= location_from,
			@qty		= qty,
			@combine	= case when distinct_order_flag = 'Y' then 0 else 1 end
		FROM	resource_demand_group
		WHERE	batch_id	= @batch_id and
			group_no	= @group_no

		EXEC fs_auto_xfer @from_loc, @location, @part_no, @qty, '', 'N', '', @user, @combine

		DELETE	resource_demand_group
		WHERE	batch_id	= @batch_id and
			group_no	= @group_no

		select @group_no= IsNull((	SELECT	MIN(group_no) FROM resource_demand_group
						WHERE	batch_id		= @batch_id and
							location		= @location and
							buy_flag		= 'Y' and
							blanket_order_flag	= 'N' and
							xfer_order_flag		= 'Y' ), '')
	end -- while @group_no > ''

	--**************************************************************************
	--* Now create new purchase orders.  First, insert the temp table with
	--* summary rows that do not have the distinct_order_flag set.  Do a SELECT
	--* DISTINCT so that all items and releases that are being ordered from the
	--* same vendor will be put on the same purchase order.  Set the tgroup_row column
	--* to 0 so that we know later that this PO is a composite of one or more
	--* demand rows.
	--**************************************************************************
	DELETE	#tpo

	INSERT	#tpo (tvend_no, tinternal_po, tpo_no, tvend_loc, tcurr_code,
      tgroup_no, tgroup_row, tapproval_code)
	SELECT	DISTINCT vendor_no,
		isnull(internal_po_ind,0),
		'0',
		location,
		curr_key,
		'0',
		0,
		case when @aprv_po_flag = 1 then approval_code else NULL end
	FROM	resource_demand_group
	WHERE	batch_id		= @batch_id and
		location		= @location and
		buy_flag		= 'Y' and
		blanket_order_flag	= 'N' and
		distinct_order_flag	= 'N' and
		vendor_no		is NOT NULL

	--**************************************************************************
	--* Now get the summary rows that represent distinct PO's which need to be
	--* created.  Each one will have its own entry in the temp po table.  Set 
	--* the tgroup_row column to the actual row number in #tpo so we can construct the 
	--* corresponding pur_list detail line later.
	--**************************************************************************
	INSERT	#tpo (tvend_no, tinternal_po, tpo_no, tvend_loc, tcurr_code,
      tgroup_no, tgroup_row, tapproval_code)
	SELECT	vendor_no,
		isnull(internal_po_ind,0),
		'0',
		location,
		curr_key,
		group_no,
		row_id,
		case when @aprv_po_flag = 1 then approval_code else NULL end
	FROM	resource_demand_group
	WHERE	batch_id		= @batch_id and
		location		= @location and
		buy_flag		= 'Y' and
		blanket_order_flag	= 'N' and
		distinct_order_flag	= 'Y' and
		vendor_no		is NOT NULL

	--**************************************************************************
	--* Don't attempt to create purchase orders for any vendors that are missing
	--* from the vendor master.
	--**************************************************************************
	DELETE	#tpo
	WHERE 	NOT EXISTS(	SELECT 1 FROM adm_vend_all (nolock)
				WHERE  vendor_code = #tpo.tvend_no )

    if @aprv_po_flag = 1
      delete #tpo where tapproval_code is null


	--**************************************************************************
	--* Get the first row from the temp table that needs to have a PO created.
	--**************************************************************************
	select @working_row = IsNull((	SELECT MIN(trow_id) FROM #tpo
					WHERE #tpo.tpo_no = '0'), 0 )

	while @working_row > 0
	begin
		SET ROWCOUNT 1
		SELECT	@vendor		= tvend_no,
			@vend_loc	= tvend_loc,
			@currency	= tcurr_code,
			@group_row	= tgroup_row,
			@internal_po	= tinternal_po,
            @approval_code = tapproval_code
		FROM	#tpo
		WHERE	trow_id		= @working_row
		SET ROWCOUNT 0

		select @vend_curr = nat_cur_code,			-- mls 11/6/02 SCR 30081 start
		 @one_cur_vendor = one_cur_vendor,
                 @etransmit_status = case when @eproc_ind = 1 and isnull(etransmit_ind,0) = 1 then 'N' else NULL end
                from adm_vend_all (nolock)
                where vendor_code = @vendor

		if isnull(@one_cur_vendor,0) = 1 
                begin
                  if not (isnull(@vend_curr,@currency) = @currency or @currency = @home_curr)
                  begin
		    RaisError 9930081 'You must purchase material in either home currency or the currency of the vendor'
		    return
                  end         
                end

                select @po_currency = case				
                  when isnull(@vend_curr,@currency) != @currency and isnull(@one_cur_vendor,0) = 1 then @vend_curr
                  else @currency end					-- mls 11/6/02 SCR 30081 end

		BEGIN TRAN
		
		--**********************************************************************
		--* Get the next unused PO number and set it into the temp table in the
		--* row that we are processing.  Insert the purchase table with the new
		--* PO header.
		--**********************************************************************
		UPDATE next_po_no SET last_no = last_no + 1
		SELECT @i_po_no = last_no FROM next_po_no
	
		delete from #pomask				-- mls 7/31/02 SCR i441 start
		insert #pomask execute fs_fmtctlnm_sp @i_po_no, @po_mask, '',0

		select @po_no = po_no from #pomask

		if isnull((select error from #pomask),1) != 0 or
		  isnull(@po_no,'') = ''
		begin
		  rollback tran
		  raiserror 99111 'PO mask not defined'
		  return
		end						-- mls 7/31/02 SCR i441 end

		UPDATE #tpo SET tpo_no = @po_no WHERE trow_id = @working_row

		INSERT purchase_all (
			po_no           , status          , po_type         ,
			printed         , vendor_no       , date_of_order   ,
			date_order_due  , ship_to_no      , ship_name       ,
			ship_address1   , ship_address2   , ship_address3   ,
			ship_address4   , ship_address5   , ship_city       ,
			ship_state      , ship_zip        , ship_country_cd, ship_via        ,
			fob             , tax_code        , terms           ,
			attn            , footing         , blanket         ,
			who_entered     , total_amt_order , freight         ,
			date_to_pay     , discount        , prepaid_amt     ,
			vend_inv_no     , email           , email_name      ,
			freight_flag    , freight_vendor  , freight_inv_no  ,
			void            , void_who        , void_date       ,
			note            , po_key          , po_ext          ,
			curr_key        , curr_type       , curr_factor     ,
			buyer           , location        , prod_no         ,
			oper_factor     , hold_reason     , phone           ,
			total_tax       , rate_type_home  , rate_type_oper  ,
			reference_code  , posting_code    , 			-- mls 7/31/02 SCR i441
			user_code, expedite_flag, user_category, 
			blanket_flag, approval_status, etransmit_status, internal_po_ind, approval_code, approval_flag)
		SELECT 	@po_no          ,      @status               ,     'A'             ,
		       'N'              ,      @vendor           ,     getdate()       ,
		       getdate()        ,      @vend_loc         ,     l.name          ,
		       l.addr1          ,      l.addr2           ,     l.addr3         ,
		       l.addr4          ,      l.addr5           ,     l.city,
               l.state,  l.zip, l.country_code,
               freight_code    ,
		       fob_code         ,      tax_code          ,     terms_code      ,
		       attention_name   ,      null              ,     'N'             ,
		       @user            ,      0                 ,     0               ,
		       null             ,      0                 ,     0               ,
		       null             ,      null              ,     null            ,
		       'N'              ,      null              ,     null            ,
		       'N'              ,      null              ,     null            ,
		       null             ,      @i_po_no          ,     0               ,
		       @po_currency        ,      null              ,     1.0             ,	-- mls 11/6/02 SCR 30081
		       null             ,      @location         ,     0               ,
		       1.0              ,      null              ,     v.phone_1       ,
		       0                ,      rate_type_home    ,     rate_type_oper  ,
		       null             ,      v.posting_code	 ,
		       isnull((select min(user_stat_code) from po_usrstat	-- mls 7/31/02 SCR i441
                         where status_code = @status and default_flag = 1),''), 0,'',
			0,							-- mls 2/14/03 SCR 30702
                        @approval_status, @etransmit_status,                    -- mls 9/8/03 SCR 31491
			@internal_po, @approval_code, @aprv_po_flag
		FROM 	locations_all l (nolock), adm_vend_all v (nolock)
		WHERE 	v.vendor_code	= @vendor and
			l.location	= @vend_loc


		select @contact_no = isnull((select min(contact_no)	-- mls 2/21/02 SCR 27449 start
                from adm_apcontacts where vendor_code = @vendor),NULL)

                if @contact_no is not NULL
                begin
		  update purchase_all
                  set attn = contact_name,
                    phone = contact_phone	
		  FROM adm_apcontacts 
	 	  WHERE (vendor_code = @vendor) and (contact_no  = @contact_no) and po_no = @po_no
                end							-- mls 2/21/02 SCR 27449 end

		--**********************************************************************
		--* Calculate and set the currency exchange factors for the new PO 
		--* header.
		--**********************************************************************
		select @po_currency=curr_key,    @tax=tax_code,					-- mls 11/6/02 SCR 30081
		@htype=rate_type_home, @otype=rate_type_oper
		from purchase_all where po_no=@po_no

		select @pltdate = datediff(day,'01/01/1900',getdate()) + 693596

		select @hrate = 1.0, @orate = 1.0

		exec @error = adm_mccurate_sp @pltdate, @po_currency,	
		  @home_curr, @htype, @hrate output, 0, @divide_flag OUTPUT
		if @error != 0 select @hrate = 0		

		exec @error = adm_mccurate_sp @pltdate, @po_currency,	
		  @oper_curr, @otype, @orate output, 0, @divide_flag OUTPUT
		if @error != 0 select @orate = 0		

		if @hrate is null select @hrate = 1.0
		if @orate is null select @orate = 1.0

		UPDATE purchase_all SET curr_factor = @hrate, oper_factor = @orate
		WHERE po_no = @po_no

		--**********************************************************************
		--* Now we construct the PO detail lines.  Insert temp table #tpo_list
		--* with all item order lines for this vendor.
		--**********************************************************************
		DELETE #tpo_list
		
		--**********************************************************************
		--* Set the part type to (M)isc for any items that don't exist in
		--* inventory.  If it is an inventory part, then get the description.
		--* We are not handling Misc parts in the new Inv Replenishment feature,
		--* but I'm not sure if the Scheduler will be inserting demand for Misc
		--* parts so I will leave this code as is for now.
		--**********************************************************************
		INSERT	#tpo_list
		SELECT	r.part_no,
			case when i.part_no is null then 'M' else 'P' end,	-- mls 8/11/04 SCR 31751
			case when i.part_no is null then 'description' else m.description end, -- mls 8/11/04 SCR 31751
			r.uom,
			r.qty,
			r.demand_date,
			'N',
			r.unit_cost,
			0,							-- mls 7/11/01 #9
			isnull(i.po_uom,r.uom),					-- mls 8/11/04 SCR 31751
			1							-- mls 8/11/04 SCR 31751
		FROM	resource_demand_group r
		left outer JOIN inv_list i (nolock) on i.part_no = r.part_no and i.location = @location	-- mls 8/11/04 SCR 31751
		left outer join inv_master m (nolock) on m.part_no = r.part_no				-- mls 8/11/04 SCR 31751
		WHERE	r.batch_id			= @batch_id and
			r.location			= @location and
			r.buy_flag			= 'Y' and
			((r.distinct_order_flag = 'N' and @group_row = 0) or
			(r.distinct_order_flag = 'Y' and r.row_id = @group_row)) and
			r.blanket_order_flag	= 'N' and
			r.vendor_no			= @vendor and
			r.curr_key			= @currency 
		ORDER BY r.part_no


		select @line = 1						-- mls 7/11/01 #9 start
		select @part = isnull((select min(part_no) from #tpo_list),NULL)
		while @part is not null
		begin
                  select @row = min(line_no) from #tpo_list where part_no = @part				-- mls 8/11/04 SCR 31751 start
                  select @uom = uom, @po_uom = po_uom from #tpo_list where line_no = @row
                  if isnull(@po_uom,@uom) != @uom
                  begin
                    select @conv_factor = NULL
                    select @conv_factor = conv_factor
                    from uom_table where item = @part and std_uom = @uom and alt_uom = @po_uom

                    if @@rowcount = 0
                    begin
                      select @conv_factor = conv_factor
                      from uom_table where item = 'STD' and std_uom = @uom and alt_uom = @po_uom
                    end
                    if @conv_factor is null
                      select @conv_factor = 1, @po_uom = @uom
                  end
                  else
                    select @po_uom = @uom, @conv_factor = 1							-- mls 8/11/04 SCR 31751 end

  		  update #tpo_list
		  set po_line = @line, po_uom = @po_uom, conv_factor = @conv_factor				-- mls 8/11/04 SCR 31751
		  where part_no = @part
	
		select @line = @line + 1
		select @part = isnull((select min(part_no) from #tpo_list where po_line = 0),NULL)
		end								-- mls 7/11/01 #9 end

		INSERT pur_list (
		    po_no           , part_no         , location        ,
		    type            , vend_sku        , account_no      ,
		    description     , unit_cost       , unit_measure    ,
		    note            , rel_date        , qty_ordered     ,
		    qty_received    , who_entered     , status          ,
		    ext_cost        , conv_factor     , void            ,
		    void_who        , void_date       , lb_tracking     ,
		    line            , taxable         , prev_qty        ,
		    po_key          , weight_ea       , curr_factor     ,
		    oper_factor     , total_tax       , curr_cost       ,
		    oper_cost       , reference_code  , project1        ,
		    project2        , project3        , tax_code        ,
		    shipto_code     , receiving_loc   , 			-- mls 7/31/02 SCR i441
		    shipto_name     , addr1           , addr2           ,
                    addr3           , addr4           , addr5   ,
            city, state, zip, country_cd)			-- mls 3/13/03 SCR 30830
		SELECT
		    @po_no          , part_no         , @vend_loc       ,
		    part_type       , null            , null            ,
		    description     , 0               , po_uom             ,		-- mls 8/11/04 SCR 31751
		    null            , getdate()       , sum(qty) / conv_factor       ,	-- mls 8/11/04 SCR 31751
		    0               , @user           , 'O'             ,
		    0               , conv_factor               , 'N'             ,	-- mls 8/11/04 SCR 31751
		    null            , null            , lb_tracking     ,
		    po_line         , 0               , 0               ,		-- mls #9
		    @i_po_no        , 0               , @hrate          ,
		    @orate          , 0               , 0               ,
		    0               , null            , null            ,
		    null            , null            , @tax,
		    @vend_loc       , @vend_loc       ,                     	-- mls 7/31/02 SCR i441
                    l.name          , l.addr1         , l.addr2         ,
                    l.addr3         , l.addr4         , l.addr5,   		-- mls 3/13/03 SCR 30830
            l.city, l.state, l.zip, l.country_code
		FROM  #tpo_list
                JOIN  locations_all l (nolock) on l.location = @vend_loc		-- mls 3/13/03 SCR 30830
		GROUP BY part_no,part_type,description,po_uom,lb_tracking,po_line,		-- mls #9
                  l.name, l.addr1, l.addr2, l.addr3, l.addr4, l.addr5, conv_factor,
            l.city, l.state, l.zip, l.country_code
		ORDER BY part_no,part_type,description,po_uom,lb_tracking,po_line		-- mls #9


		-- mls 12/06/04 SCR 33889
                insert notes
                (code_type, code, line_no, note_no, form, pick, pack, bol, invoice, extra1, extra2, extra3, other, note)
                select 'P', @po_no, po_line, note_no, form, pick, pack, bol, invoice, extra1, extra2, extra3, other, note
                from #tpo_list p
                join notes n on n.code = p.part_no and n.code_type = 'I' and n.extra3 = 'Y'
                where p.part_type = 'P'
                   
		--**********************************************************************
		--* skk 04/07/01 SCR 26616
		--* Code was here which set last purchase price into pur_list if the 
		--* suggested PO was from the SCHEDULER.  Moved it below so that we only
		--* do that if the costs are still zero after looking for a quote.  This
		--* allows us to only look for a quote if the costs are zero which means
		--* the user didn't specify a purchase price in the Inventory Replenishment
		--* window.
		--**********************************************************************
		
		--**********************************************************************
		--* We should have a suggested PO currency coming from the Inv Replenishment
		--* process.  If its in the home currency, then set the suggested purchase
		--* price into the unit_cost column, otherwise it must be in the 
		--* vendors natural currency so set it into the curr_cost column
		--* skk 04/07/01 SCR 26616:  Execute this code always, not just if batch
		--* was not from SCHEDULER, so that we pick up unit costs that user might
		--* have entered in Inv Repl window for SCHEDULER batches. 
		--**********************************************************************
		UPDATE	l
		SET	lb_tracking	= m.lb_tracking,
			taxable		= m.taxable,
			vend_sku	= m.sku_no,
			weight_ea	= m.weight_ea * l.conv_factor,	-- mls 8/11/04 SCR 31751
			tax_code	= case when isnull(m.tax_code,'') = '' then @tax else m.tax_code end,
                        unit_cost       = case when @currency != @home_curr then l.unit_cost else
					  (SELECT MIN(#tpo_list.unit_cost)
						FROM	#tpo_list
						WHERE	#tpo_list.part_no  = l.part_no) * l.conv_factor end, -- mls 8/11/04 SCR 31751
                        curr_cost       = case when @currency = @home_curr then l.curr_cost else
					  (SELECT MIN(#tpo_list.unit_cost)
						FROM	#tpo_list
						WHERE	#tpo_list.part_no  = l.part_no) * l.conv_factor end,-- mls 8/11/04 SCR 31751
			tolerance_code	= m.tolerance_cd,
			note = isnull(i.note, m.note)		-- mls 5/15/06 SCR 36521
		FROM	pur_list l
		join	inv_master m on m.part_no = l.part_no
		join	inv_list i on i.part_no = l.part_no and i.location = l.location
		WHERE	l.po_no		= @po_no and
			l.location	= @vend_loc and
			l.type		in ('P', 'V')			-- mls 8/12/99 SCR 70 19893

		
		DECLARE c_pur_list CURSOR STATIC LOCAL FOR			-- mls 8/27/01 SCR 27475 start
		select part_no, line, qty_ordered * conv_factor, unit_cost / conv_factor	-- mls 8/11/04 SCR 31751
		from pur_list (nolock)
		where po_no = @po_no and pur_list.type = 'P'

		OPEN c_pur_list
		FETCH NEXT FROM c_pur_list into @part, @line, @po_qty, @unit_cost

		WHILE @@FETCH_STATUS = 0
		begin
                  select @min_sku = isnull((select min(vend_sku)			-- mls 2/27/03 SCR 30763 start
                  from vendor_sku
                  where sku_no = @part and vendor_no = @vendor
                    and last_recv_date >= getdate()),NULL)				-- mls 2/27/03 SCR 30763 end

		  if @min_sku is NULL							-- mls 2/27/03 SCR 30763
                    select @min_sku = isnull((select min(vend_sku)			-- mls 3/25/02 SCR 28567 start
                    from vendor_sku
                    where sku_no = @part and vendor_no = @vendor),NULL)			-- mls 3/25/02 SCR 28567 end

 		  select @min_vq_qty = isnull((select max(qty)				-- mls 2/27/03 SCR 30763
		  from (select qty, min(last_recv_date)
                     from vendor_sku vs where vs.vendor_no = @vendor
                     and vs.sku_no = @part and vs.last_recv_date >= getdate()
                     and vs.curr_key in ('*HOME*',@currency) and vs.last_price = @unit_cost
		     and vs.qty <= @po_qty
		     group by qty)
                     as min_vsku(qty, exp_date)),NULL)
			
		  if @min_vq_qty is not NULL
		  begin
		    select @exp_date = isnull((select min(last_recv_date) from vendor_sku
  		        where  vendor_no=@vendor and sku_no = @part and
		        curr_key in ('*HOME*',@currency) and last_price = @unit_cost and
		        last_recv_date >= getdate() and qty = @min_vq_qty),NULL)

		    update pur_list
		    set vend_sku=v.vend_sku
		    from pur_list, vendor_sku v
		    where  pur_list.po_no=@po_no and pur_list.type='P' and 
		      pur_list.part_no= @part and pur_list.line = @line and
		      v.vendor_no=@vendor and v.sku_no = @part and
		      v.curr_key = @currency and v.last_price = @unit_cost and
		      v.last_recv_date = @exp_date and v.qty = @min_vq_qty
		
		    if @@ROWCOUNT = 0
 		    begin	
		      update pur_list 
                      set vend_sku=v.vend_sku
		      from vendor_sku v
		      where  pur_list.po_no=@po_no and pur_list.type='P' and 
		        pur_list.part_no= @part and pur_list.line = @line and
			v.vendor_no=@vendor and v.sku_no = @part and
			v.curr_key='*HOME*' and v.last_price = @unit_cost and
			v.last_recv_date = @exp_date and v.qty = @min_vq_qty 
		    end
                  end
                  else									-- mls 3/25/02 SCR 28567 start
                  begin
                    if @min_sku is not NULL
                    begin
                      update pur_list
                      set vend_sku = @min_sku
                      where po_no = @po_no and type = 'P' and part_no = @part and line = @line
                    end
                  end									-- mls 3/25/02 SCR 28567 end

		  FETCH NEXT FROM c_pur_list into @part, @line, @po_qty, @unit_cost
		end -- while @@fetch_status

		close c_pur_list
		deallocate c_pur_list


		--**********************************************************************
		--* Adjust the cost columns for the currency exchange factors. Set the 
		--* the correct account number depending on whether item is inventory or
		--* misc.  Set the detail line numbers sequentially.
		--**********************************************************************
		if @hrate > 0
		begin
			update pur_list set curr_cost=Round( (unit_cost / @hrate), @unit_decimals )
			where po_no=@po_no and curr_cost=0
		end
		else
		begin
			update pur_list set curr_cost=Round( (unit_cost * abs(@hrate)), @unit_decimals )
			where po_no=@po_no and curr_cost=0
		end
	
		if @hrate >= 0
		begin
			update pur_list set unit_cost=Round( (curr_cost * @hrate), @unit_decimals )
			where po_no=@po_no and unit_cost=0
		end
		else
		begin
			update pur_list set unit_cost=Round( (curr_cost / abs(@hrate)), @unit_decimals )
			where po_no=@po_no and unit_cost=0
		end
	
		if @orate >= 0
		begin
			update pur_list set oper_cost=Round( (curr_cost * @orate), @unit_decimals )
			where po_no=@po_no
		end
		else begin
			update pur_list set oper_cost=Round( (curr_cost / abs(@orate)), @unit_decimals )
			where po_no=@po_no
		end

		UPDATE	pur_list
		SET	ext_cost= (unit_cost * qty_ordered)
		WHERE	po_no	= @po_no

		--* Set the account code
		DELETE #tacct

		INSERT	#tacct
		SELECT	p.part_no,
			p.location,
			'*acct*',
			case when p.type <> 'M' then l.acct_code else '' end,
			p.type
		FROM	pur_list p
		left outer join inv_list l (nolock) on l.part_no = p.part_no and l.location = p.receiving_loc
		WHERE	p.po_no = @po_no

		if @acct_from_where <> 'I'
		begin
			UPDATE	#tacct
			SET	invacct = v.exp_acct_code,
				acctcode = v.exp_acct_code
			FROM	adm_vend_all v
			WHERE	v.vendor_code = @vendor and
				#tacct.part_type = 'M'						-- skk SCR 25457
		end
		else
		begin	
			UPDATE	#tacct
			SET	invacct = l.apacct_code
			FROM	locations_all l
			WHERE	l.location = #tacct.location and
				#tacct.part_type = 'M'
		end

		UPDATE	#tacct
		SET	invacct = IsNull(in_account.inv_acct_code, '00000000')
		FROM	in_account
		WHERE	in_account.acct_code	= #tacct.acctcode and
			#tacct.invacct			= '*acct*'

		UPDATE	pur_list
		SET	account_no = #tacct.invacct
		FROM	#tacct
		WHERE	pur_list.po_no		= @po_no and
			pur_list.part_no	= #tacct.part_no and
			pur_list.location	= #tacct.location and		-- mls 02/09/01 SCR 25457
			pur_list.type		= #tacct.part_type		-- mls 02/09/01 SCR 25457

		--**********************************************************************
		--* Now create releases for each purchase detail line
		--**********************************************************************
		INSERT releases (
		    po_no          , part_no        , location       ,
		    part_type      , release_date   , quantity       ,
		    received       , status         , confirm_date   ,
		    confirmed      , lb_tracking    , conv_factor    ,
		    prev_qty       , po_key         , due_date       ,		-- rev 4 add due_date
		    po_line		)						-- mls #9
		SELECT
		    @po_no         , part_no        , @vend_loc      ,
		    part_type      , t.demand_date   d1 , sum(qty) / conv_factor       ,
		    0              , 'O'            , t.demand_date    ,
		    'N'            , lb_tracking    , conv_factor    ,			-- mls 8/11/04 SCR 31751
		    0              , @i_po_no	    , t.demand_date,
		    po_line								-- mls #9
		FROM #tpo_list t
		GROUP BY part_no, part_type, t.demand_date, lb_tracking,po_line, conv_factor		-- mls #9
		ORDER BY part_no, part_type, d1, lb_tracking,po_line 		-- mls #9

		
		UPDATE	releases
		SET	release_date= (release_date - i.dock_to_stock - i.lead_time),	-- due_date minus lead_time
			due_date	= (due_date - i.dock_to_stock),			-- minus dock_to_stock
			confirm_date= (due_date - i.dock_to_stock)			-- same as due_date
		FROM	inv_list i
		WHERE	releases.part_no	= i.part_no and
			releases.location	= i.location and
			releases.po_no		= @po_no
		

		--**********************************************************************
		--* Add this PO to the report listing all PO's created by this process
		--**********************************************************************
		INSERT	#treport
		SELECT	p.vendor_no,
			p.po_no,
			x.part_no,
			r.release_date,
			r.quantity,
			x.unit_measure,
			x.description
		FROM	purchase_all p, pur_list x, releases r
		WHERE	p.po_no		= x.po_no and
			x.po_no		= r.po_no and
			x.line = r.po_line and						-- mls #9
			x.part_no	= r.part_no and
			p.po_no		= @po_no
		ORDER BY x.part_no

		--**********************************************************************
		--* Calculate taxes for the PO we are creating
		--**********************************************************************
		EXEC	fs_calculate_potax_wrap @po_no, 1

		DELETE	#tpo_list
		DELETE	resource_demand_group
		WHERE	batch_id		= @batch_id and
			location		= @location and
			buy_flag		= 'Y' and
			((distinct_order_flag = 'N' and @group_row = 0) or
			(distinct_order_flag = 'Y' and row_id = @group_row)) and
			blanket_order_flag	= 'N' and
			vendor_no		= @vendor and
			curr_key		= @currency	and
			case when @aprv_po_flag = 1 then approval_code else '' end = isnull(@approval_code,'') -- mls 11/2/09 SCR 051953

		if @aprv_po_flag = 1
  		  Exec adm_apaprmk_sp @po_no, 0
		COMMIT TRAN

		--**********************************************************************
		--* Get the next row from the temp table that needs to have a PO created.
		--**********************************************************************
		select @working_row = IsNull((	SELECT MIN(trow_id) FROM #tpo
						WHERE 	#tpo.tpo_no	= '0' and
							trow_id		> @working_row), 0 )
  
	end -- while @working_row > 0

	--**************************************************************************
	--* Get the next location with orders to be created
	--**************************************************************************
	SELECT @location	= IsNull((	SELECT	MIN(location)
						FROM	resource_demand_group
						WHERE	batch_id		= @batch_id and
							buy_flag		= 'Y' and
							blanket_order_flag	= 'N' and
							location		> @location ), '' )

end -- while @location > ''

--******************************************************************************
--* Return the result set for the report
--******************************************************************************
SELECT	t.vendorno,
	v.vendor_name,
	t.pono,
	t.partno,
	t.description,
	t.rdate,
	t.qty,
	t.uom
FROM	#treport t, adm_vend_all v (nolock)
WHERE	t.vendorno = v.vendor_code

DROP table #tpo
DROP table #tpo_list
DROP table #rate
DROP table #tacct
DROP table #treport

END


GO
GRANT EXECUTE ON  [dbo].[fs_autopo] TO [public]
GO
