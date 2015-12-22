SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_orders_autopo] @who varchar(10)  AS
begin




declare @no int, @vend varchar(12), @loc varchar(10), @ordno int, @err int
declare @pono varchar(16), @acctflag varchar(20), @xlp int, @lin int
declare @pltdate int, @error int, @cnt int
declare @currency varchar(10), @htype varchar(8), @otype varchar(8)
declare @home_curr varchar(8), @oper_curr varchar(8)
declare @hrate decimal(20,8), @orate decimal(20,8), @crate decimal(20,8)
declare @tax varchar(10), @unit_decimals int, @acct_from_where char(1)
declare @line int											-- mls 5/10/01 #5
declare @max_vq_qty decimal(20,8)
declare @contact_no int									-- mls 2/21/02 SCR 27449
declare @part varchar(30), @po_line int, @po_qty decimal(20,8), @unit_cost decimal(20,8)	-- mls 3/25/02 SCR 28567
declare @min_sku varchar(30)									-- mls 3/25/02 SCR 28567
DECLARE @mask varchar(16), @result int 							-- JGT 436
declare @exp_date datetime									-- mls 2/27/03 SCR 30763
declare @ord_line int, @ord_ext int								-- mls 3/26/03 SCR 30749
declare @part_type char(1), @descr varchar(255)
declare @uom char(2)
declare @internal_po_ind int
declare @divide_flag smallint
declare @aprv_po_flag int, @approval_code varchar(8)


Create Table #rate ( error int, rate float NULL, divide_flag int NULL )

create table #temppo (vendorno varchar(12),  ordno int,   pono varchar(16),
                      location varchar(10), ord_line int , ord_ext int, internal_po_ind int,
					  approval_code varchar(8) null)		-- mls 4/1/03 SCr 30749

create table #temp_pur_list (part_no varchar(30), part_type char(1), uom char(2),			-- mls 5/10/01 #5
  qty decimal(20,8), line int,
  description varchar(255) NULL, po_description varchar(255) NULL,
  unit_cost decimal(20,8), conv_factor decimal(20,8))

select @acct_from_where = isnull( (select value_str from config (nolock) where flag='PLT_AP_POST_OP'), 'I' )

select @unit_decimals = isnull( (select convert( integer, dbo.config.value_str )
				 from dbo.config (nolock) where dbo.config.flag='INV_UNIT_DECIMALS' ), 4 )

SELECT @home_curr=dbo.glco.home_currency, @oper_curr=dbo.glco.oper_currency
FROM   dbo.glco (nolock)

select @aprv_po_flag = aprv_po_flag from apco (nolock)

select @acctflag = isnull( (select value_str from config (nolock) where flag='ACCOUNTING'), 'NOT INSTALLED' )

insert #temppo 
select oap.vendor, oap.order_no, '0', oap.location, min(oap.line_no) , l.order_ext,		-- mls 4/1/03 SCR 30749
  isnull(internal_po_ind,0), 
  case when @aprv_po_flag = 1 then approval_code else NULL end
from orders_auto_po oap (nolock) , ord_list l (nolock)
where oap.order_no = l.order_no and oap.line_no = l.line_no and 
oap.part_no = l.part_no and oap.status='O' and l.status between 'N' and 'R'
group by oap.vendor, oap.order_no, oap.location, l.order_ext, isnull(internal_po_ind,0),
oap.approval_code


delete #temppo where not exists ( select 1 from adm_vend_all (nolock) where vendor_code=#temppo.vendorno)
delete #temppo where not exists ( select 1 from orders_all (nolock) where order_no=#temppo.ordno and
  ext = #temppo.ord_ext and								-- mls 4/1/03 SCR 30749
  status>='N' and status <= 'R')
if @aprv_po_flag = 1  delete #temppo where approval_code is null

SELECT @mask = isnull((select value_str  FROM config (nolock) WHERE config.flag = 'PUR_PO_MASK'),'')

select @no=(select count(*) from #temppo where pono='0')
while @no > 0
begin
set rowcount 1
select @vend=vendorno, @ordno=ordno, @loc=location, @ord_line = ord_line, @ord_ext = ord_ext,	-- mls 4/1/03 SCR 30749
  @internal_po_ind = internal_po_ind,
  @approval_code = approval_code
from #temppo where pono='0'

set rowcount 0

BEGIN TRAN
update next_po_no 
set last_no =last_no + 1

select 	@no = last_no 
from 	next_po_no





EXEC fmtctlnm_sp @no, @mask, @pono OUTPUT, @result OUTPUT

IF (@result != 0)
  RETURN -1




UPDATE 	oap 
SET 	po_no	= @pono 
from orders_auto_po oap, ord_list l
where l.order_no = oap.order_no and l.line_no = oap.line_no and			-- mls 4/1/03 SCR 30749
l.order_ext = @ord_ext and oap.status = 'O' and 
oap.order_no = @ordno and oap.vendor = @vend and oap.location = @loc

update #temppo 
set pono 	= @pono 
where vendorno	= @vend and ordno	= @ordno and
  location = @loc and ord_line = @ord_line and ord_ext = @ord_ext		-- mls 4/1/03 SCR 30749

insert purchase_all (
	po_no           , status          , po_type         ,
	printed         , vendor_no       , date_of_order   ,
	date_order_due  , ship_to_no      , ship_name       ,
	ship_address1   , ship_address2   , ship_address3   ,
	ship_address4   , ship_address5   , ship_city       ,
	ship_state      , ship_zip        , ship_country_cd ,
    ship_via        ,
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
	reference_code  , posting_code	,	blanket_flag,
	expedite_flag	, user_code	,	user_category	,
	internal_po_ind , approval_code, approval_flag)
select @pono            ,      'O'               ,     'A'              ,
       'N'              ,      @vend             ,     getdate()        ,
       l.req_ship_date  ,      @loc              ,     
       case when @loc like 'DROP%' then l.ship_to_name else h.name end,		-- mls 3/13/03 SCR 30830 start
       case when @loc like 'DROP%' then l.ship_to_add_1 else h.addr1 end,
       case when @loc like 'DROP%' then l.ship_to_add_2 else h.addr2 end,
       case when @loc like 'DROP%' then l.ship_to_add_3 else h.addr3 end,
       case when @loc like 'DROP%' then l.ship_to_add_4 else h.addr4 end,
       case when @loc like 'DROP%' then l.ship_to_add_5 else h.addr5 end,	-- mls 3/13/03 SCR 30830 end
       case when @loc like 'DROP%' then l.ship_to_city else h.city end,	-- mls 6/26/08 SCR 050502 start
       case when @loc like 'DROP%' then l.ship_to_state else h.state end,	
       case when @loc like 'DROP%' then l.ship_to_zip else h.zip end,	
       case when @loc like 'DROP%' then l.ship_to_country_cd else h.country_code end,	-- mls 6/26/08 SCR 050502 end
	   l.routing	,	-- mls 2/21/02 SCR 26748
       isnull(af.fob_code,v.fob_code),      v.tax_code        ,     v.terms_code     ,
       attention_name   ,      null              ,     'N'              ,
       @who             ,      0                 ,     0                ,
       null             ,      0                 ,     0                ,
       null             ,      null              ,     null             ,
       'N'              ,      null              ,     null             ,
       'N'              ,      null              ,     null             ,
       null             ,      @no               ,     0                ,
       nat_cur_code     ,      null              ,     1.0              ,
       null             ,      @loc              ,     0                ,
       1.0              ,      null              ,     v.phone_1        ,
       0                ,      v.rate_type_home  ,     v.rate_type_oper ,
       null             ,      v.posting_code	 ,	0		,
	0		,      ''		 ,	''		,
	@internal_po_ind	,	    @approval_code	 ,     @aprv_po_flag
     from orders_all l (nolock)
     join adm_vend_all v (nolock) on v.vendor_code = @vend
     join locations_all h (nolock) on h.location = @loc
     left outer join apfob af (nolock) on af.fob_code = l.fob
     where l.order_no=@ordno and l.status <= 'R' and l.ext = @ord_ext



UPDATE 	purchase_all
SET	user_code = user_stat_code
FROM 	po_usrstat usr (nolock) ,  purchase_all p (nolock) 
WHERE 	p.status = usr.status_code and po_no = @pono				-- mls 4/1/03 SCR 30749
  and   usr.default_flag = 1							-- mls 1/14/05 SCR 34082


select @contact_no = isnull((select min(contact_no)	-- mls 2/21/02 SCR 27449 start
from adm_apcontacts (nolock) where vendor_code = @vend),NULL)

if @contact_no is not NULL
begin
  update purchase_all
  set attn = contact_name,
    phone = contact_phone	
  FROM adm_apcontacts (nolock) 
  WHERE (vendor_code = @vend) and (contact_no  = @contact_no) and po_no = @pono
end							-- mls 2/21/02 SCR 27449 end

select @currency=curr_key,    @tax=tax_code,
       @htype=rate_type_home, @otype=rate_type_oper
       from purchase_all (nolock) where po_no=@pono

select @pltdate = datediff(day,'01/01/1900',getdate()) + 693596

select @hrate = 1.0, @orate = 1.0

exec @error = adm_mccurate_sp @pltdate, @currency,
  @home_curr, @htype, @hrate output, 0, @divide_flag OUTPUT
if @error != 0 select @hrate = 0

exec @error = adm_mccurate_sp @pltdate, @currency,
  @oper_curr, @otype, @orate output, 0, @divide_flag OUTPUT
if @error != 0 select @orate = 0

if @hrate is null select @hrate = 1.0
if @orate is null select @orate = 1.0
if @crate is null select @crate = 1.0

update purchase_all set curr_factor=@hrate, oper_factor=@orate
       where po_no=@pono


truncate table #temp_pur_list									-- mls 5/10/01 #5 start

insert #temp_pur_list
select
    oap.part_no         , 
    oap.part_type       , isnull(oap.uom,l.uom)             ,
    sum(oap.qty)        , 0, l.description, l.description, 0 as unit_cost, 1 as conv_factor
from orders_auto_po oap, ord_list l (nolock)
where l.order_no = oap.order_no and l.line_no = oap.line_no and l.order_ext = @ord_ext and -- mls 4/1/03 SCR 30749
  @ordno=oap.order_no and @vend=oap.vendor and oap.location = @loc and oap.status='O'
group by oap.part_no, oap.part_type, isnull(oap.uom,l.uom), l.description
order by oap.part_no, oap.part_type, isnull(oap.uom,l.uom), l.description

update pl
set unit_cost=(i.cost * isnull(u.conv_factor,1)),
    qty = (pl.qty / case when isnull(u.conv_factor,0) = 0 then 1.0 else isnull(u.conv_factor,1.0) end),
    conv_factor = case when isnull(u.conv_factor,0) = 0 then 1.0 else isnull(u.conv_factor,1.0) end,
    po_description = i.description,
    uom = isnull(u.alt_uom,i.uom)
from #temp_pur_list pl
join inventory i on pl.part_no  = i.part_no and i.location = @loc
  left outer join 
  (select uomt.item, uomt.std_uom, uomt.alt_uom, uomt.conv_factor
    from uom_table uomt
    join uom_list uoml on uoml.uom =  uomt.alt_uom and isnull(uoml.void,'N') = 'N')
  as u (part_no, std_uom, alt_uom, conv_factor) 
  on u.part_no in (i.part_no,'STD') and u.std_uom = i.uom and u.alt_uom = i.po_uom
where pl.part_type in ('P','V')

select @line = 1
set rowcount 1
while exists (select 1 from #temp_pur_list where line = 0)
begin
  update #temp_pur_list set line = @line where line = 0
  select @line = @line + 1
end
set rowcount 0											-- mls 5/10/01 #5 end


insert pur_list (
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
    project2        , project3		, shipto_code,
    receiving_loc   , shipto_name     , addr1           ,					-- mls 3/13/03 SCR 30830
    addr2           , addr3           , addr4           ,
    addr5			, city			  , state			,
	zip				, country_cd)
select
    @pono           , tpl.part_no         , @loc           ,
    case when tpl.part_type in ('P','V') then 'P' else tpl.part_type end, 
    null            , null            ,
    tpl.po_description, tpl.unit_cost              , 
    tpl.uom,
    null            , getdate()       , qty 	        ,						-- mls 5/10/01 #5
    0               , @who            , 'O'             ,
    tpl.unit_cost * tpl.qty        , tpl.conv_factor               , 'N'             ,
    null            , null            , 'N'             ,
    tpl.line            , 0               , 0               ,						-- mls 5/10/01 #5
    @no             , 0               , @hrate          ,
    @orate          , 0               , 0               ,
    0               , null            , null            ,
    null            , null	      , @loc,
    @loc            , 
    case when @loc like 'DROP%' then l.ship_to_name else h.name end,		-- mls 3/13/03 SCR 30830 start
    case when @loc like 'DROP%' then l.ship_to_add_1 else h.addr1 end,
    case when @loc like 'DROP%' then l.ship_to_add_2 else h.addr2 end,
    case when @loc like 'DROP%' then l.ship_to_add_3 else h.addr3 end,
    case when @loc like 'DROP%' then l.ship_to_add_4 else h.addr4 end,
    case when @loc like 'DROP%' then l.ship_to_add_5 else h.addr5 end,		-- mls 3/13/03 SCR 30830 end
    case when @loc like 'DROP%' then l.ship_to_city else h.city end,	-- mls 6/26/08 SCR 050502 start
    case when @loc like 'DROP%' then l.ship_to_state else h.state end,	
    case when @loc like 'DROP%' then l.ship_to_zip else h.zip end,	
    case when @loc like 'DROP%' then l.ship_to_country_cd else h.country_code end	-- mls 6/26/08 SCR 050502 end
from #temp_pur_list	tpl										-- mls 5/10/01 #5
join orders_all l (nolock) on l.order_no = @ordno and l.ext = @ord_ext		-- mls 4/1/03 SCR 30749
join locations_all h (nolock) on h.location = @loc

-- mls 12/6/04 SCR 33889
insert notes
(code_type, code, line_no, note_no, form, pick, pack, bol, invoice, extra1, extra2, extra3, other, note)
select 'P', @pono, line, note_no, form, pick, pack, bol, invoice, extra1, extra2, extra3, other, note
from #temp_pur_list p
join notes n on n.code = p.part_no and n.code_type = 'I' and n.extra3 = 'Y'
where p.part_type in ( 'P','V')

update pl
  set lb_tracking=i.lb_tracking,
	taxable=i.taxable,
	vend_sku=i.sku_no,
	weight_ea = i.weight_ea,
	unit_measure=i.uom,
	tax_code = i.tax_code
    from pur_list pl
	join inventory i on pl.part_no  = i.part_no and pl.location=i.location
	where pl.po_no=@pono  and pl.location = @loc and pl.type = 'P' -- mls 8/12/99 SCR 70 19893

update pur_list set tax_code=@tax
where po_no=@pono and isnull(tax_code,'') = ''



DECLARE c_pur_list CURSOR STATIC LOCAL FOR			-- mls 8/27/01 SCR 27475 start
select part_no, line, qty_ordered * conv_factor, unit_cost , type, description, unit_measure
from pur_list (nolock)
where po_no = @pono 

OPEN c_pur_list
FETCH NEXT FROM c_pur_list into @part, @po_line, @po_qty, @unit_cost, @part_type, @descr, @uom

WHILE @@FETCH_STATUS = 0
begin
--  select @ord_ext = isnull((select max(order_ext) from ord_list (nolock) 
--    where order_no = @ordno and line_no = @ord_line and part_no = @part),0)












  if @part_type = 'M'
  begin
    select @ord_line = isnull((select min(line_no) from ord_list l (nolock)
      where l.order_no = @ordno and l.order_ext = @ord_ext and
      l.part_no = @part and l.description = @descr and l.uom = @uom
      and l.part_type = 'M' ),0)

    update pur_list
    set weight_ea = l.weight_ea
    from ord_list l (nolock)
    where l.order_no = @ordno and l.order_ext = @ord_ext and l.line_no = @ord_line
      and pur_list.part_no = l.part_no and pur_list.po_no = @pono and pur_list.line = @po_line
  end

  if @part_type = 'P'
  begin

  select @min_sku = isnull((select min(vend_sku)			-- mls 2/27/03 SCR 30763 start
  from vendor_sku
  where sku_no = @part and vendor_no = @vend
    and last_recv_date >= getdate()),NULL)				-- mls 2/27/03 SCR 30763 end

  if @min_sku is NULL							-- mls 2/27/03 SCR 30763
    select @min_sku = isnull((select min(vend_sku)			-- mls 3/25/02 SCR 28567 start
    from vendor_sku
    where sku_no = @part and vendor_no = @vend),NULL)			-- mls 3/25/02 SCR 28567 end

  select @max_vq_qty = isnull((select max(qty)				-- mls 2/27/03 SCR 30763
  from (select qty, min(last_recv_date)
    from vendor_sku vs where vs.vendor_no = @vend
    and vs.sku_no = @part and vs.last_recv_date >= getdate()
    and vs.curr_key in ('*HOME*',@currency) and vs.qty <= @po_qty
    group by qty)
    as min_vsku(qty, exp_date)),NULL)
			
  if @max_vq_qty is not NULL
  begin
    select @exp_date = isnull((select min(last_recv_date) from vendor_sku
    where  vendor_no=@vend and sku_no = @part and
      curr_key in ('*HOME*',@currency) and 
      last_recv_date >= getdate() and qty = @max_vq_qty),NULL)

    update pur_list
    set vend_sku=v.vend_sku, unit_cost=0, curr_cost=v.last_price * pur_list.conv_factor
    from  vendor_sku v
    where  pur_list.po_no=@pono and pur_list.type='P' and 
      pur_list.part_no= @part and pur_list.line = @po_line and
      v.vendor_no=@vend and v.sku_no = @part and
      v.curr_key=@currency and v.last_recv_date = @exp_date and v.qty = @max_vq_qty 
		
    if @@ROWCOUNT = 0
    begin	
      update pur_list 
      set vend_sku=v.vend_sku, unit_cost=v.last_price * pur_list.conv_factor, curr_cost=0
      from vendor_sku v
      where  pur_list.po_no=@pono and pur_list.type='P' and 
        pur_list.part_no= @part and pur_list.line = @po_line and
	v.vendor_no=@vend and v.sku_no = @part and
	v.curr_key='*HOME*' and v.last_recv_date = @exp_date and v.qty = @max_vq_qty 
    end
  end
  else									-- mls 3/25/02 SCR 28567 start
  begin
    if @min_sku is not NULL
    begin
      update pur_list
      set vend_sku = @min_sku
      where po_no = @pono and type = 'P' and part_no = @part and line = @po_line
    end
  end									-- mls 3/25/02 SCR 28567 end

  update pur_list 
  set pur_list.receiving_loc = @loc,pur_list.shipto_code=@loc
  where po_no=@pono and pur_list.receiving_loc = ''

  end -- part type P
  FETCH NEXT FROM c_pur_list into @part, @po_line, @po_qty, @unit_cost, @part_type, @descr, @uom	-- mls 1/03/02 SCR 30481
end -- while @@fetch_status

close c_pur_list
deallocate c_pur_list

if @hrate > 0 begin							-- mls 11/26/02 SCR 30369
	update pur_list set curr_cost=Round( (unit_cost / @hrate), @unit_decimals ),
		unit_cost = round(unit_cost, @unit_decimals)
	where po_no=@pono and curr_cost=0
	end
else begin
	update pur_list set curr_cost=Round( (unit_cost * abs(@hrate)), @unit_decimals ),
		unit_cost = round(unit_cost, @unit_decimals)
	where po_no=@pono and curr_cost=0
	end

if @hrate >= 0 begin
	update pur_list set unit_cost=Round( (curr_cost * @hrate), @unit_decimals ),
		curr_cost = round(curr_cost , @unit_decimals)
	where po_no=@pono and unit_cost=0
	end
else begin
	update pur_list set unit_cost=Round( (curr_cost / abs(@hrate)), @unit_decimals ),
		curr_cost = round(curr_cost , @unit_decimals)
	where po_no=@pono and unit_cost=0
	end

if @orate >= 0 begin
	update pur_list set oper_cost=Round( (curr_cost * @orate), @unit_decimals )
	where po_no=@pono
	end
else begin
	update pur_list set oper_cost=Round( (curr_cost / abs(@orate)), @unit_decimals )
	where po_no=@pono
	end

Create table #tacct( part_type char(1), part_no varchar(30), location varchar(10),
                     invacct varchar(32) NULL, acctcode varchar(32) NULL )

insert #tacct
  select l.type, l.part_no, l.location, '*acct*', i.acct_code
   from pur_list l
   left outer join inv_list i (nolock) on i.part_no = l.part_no and i.location = l.location
   where l.po_no=@pono


if @acct_from_where <> 'I' begin
	update #tacct
	   set invacct=v.exp_acct_code, acctcode=v.exp_acct_code
	  from adm_vend_all v
	 where v.vendor_code=@vend and #tacct.part_type='M'			-- skk SCR 25457
end
else begin
	update #tacct
	   set acctcode=l.apacct_code
	  from locations_all l
	 where l.location=#tacct.location and #tacct.part_type='M'
end

update #tacct
   set invacct = isnull(dbo.in_account.inv_acct_code, '00000000')
   from dbo.in_account
   where dbo.in_account.acct_code = #tacct.acctcode and
         #tacct.invacct          = '*acct*'

update pur_list
  set account_no = #tacct.invacct
  from #tacct
  where pur_list.po_no=@pono and
        pur_list.part_no=#tacct.part_no and
        pur_list.location = #tacct.location and				-- mls 1/12/01 SCR 25457
	pur_list.type = #tacct.part_type				-- mls 1/12/01 SCR 25457

drop table #tacct


insert releases (
	po_no,		part_no,		location, 
	part_type,	release_date,	quantity,
	received,	status,			confirm_date,
	confirmed,	lb_tracking,	conv_factor,
	prev_qty,	po_key,			due_date,						-- skk SCR 25457			
	ord_line ,											-- mls 5/3/01 SCR 19502
	po_line )											-- mls 5/10/01 #5
select
	@pono,		oap.part_no,		@loc,
	oap.part_type,	dateadd(hour,oap.line_no,getdate()) ,	
    sum(oap.qty / tp.conv_factor),				-- mls 5/3/01 SCR 19502
	0,			'O',			null,
	'N',		'N',			tp.conv_factor,
	0,		@no,			dateadd(hour,oap.line_no,getdate()),			-- mls 5/3/01 SCR 19502
													-- skk SCR 25457
	oap.line_no,
	tp.line												-- mls 5/10/01 #5
from orders_auto_po oap, #temp_pur_list tp, ord_list l (nolock)						-- mls 5/10/01 #5
where l.order_no = oap.order_no and l.line_no = oap.line_no and l.order_ext = @ord_ext and		-- mls 4/1/03 SCR 30749
  oap.part_no = tp.part_no and oap.part_type = tp.part_type and 
  oap.location = @loc and l.description = tp.description and
  oap.order_no=@ordno and @vend=oap.vendor and oap.status='O'
group by oap.part_no, oap.line_no,oap.part_type, tp.line, tp.conv_factor				-- mls 5/3/01 SCR 19502
order by oap.part_no, oap.line_no,oap.part_type, tp.line						-- mls 5/3/01 SCR 19502

update releases set lb_tracking=i.lb_tracking,
	release_date=dateadd(minute,ord_line,date_order_due),						-- mls 5/3/01 SCR 19502
	confirm_date=date_order_due
	from  inventory i, purchase_all p
	where releases.po_no=convert(varchar(16),@no) and
	releases.part_no=i.part_no and releases.location=i.location
	and @loc=releases.location and p.po_no=@pono

update oap 
set status='P', po_no=@pono
from orders_auto_po oap, ord_list l (nolock)
where l.order_no = oap.order_no and l.line_no = oap.line_no and l.order_ext = @ord_ext and
  oap.order_no = @ordno and oap.vendor = @vend and oap.location = @loc and oap.status='O'


exec fs_calculate_potax_wrap @pono, 1

if @aprv_po_flag = 1
  exec adm_apaprmk_sp @pono, 0

commit tran
select @no=(select count(*) from #temppo where pono='0')
end 
--select * from releases where po_no = @pono
--select * from orders_auto_po where po_no = @pono

drop table #rate
drop table #temppo

END
GO
GRANT EXECUTE ON  [dbo].[fs_orders_autopo] TO [public]
GO
