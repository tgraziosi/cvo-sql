SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[imSoeVal_e7_sp] (
    @p_batchno  		int = NULL,
    @p_start_rec    		int = 0,
    @p_end_rec 			int = 0,
    @p_record_type		int = 0x000000FF,
    @p_debug_level 		int = 0
) as

declare @w_cc			varchar(8)
declare @w_start                int
declare @w_end                  int

select @w_start = 0
select @w_end = 0

select @w_cc = company_code from glco

if @p_debug_level > 0
begin
	select @p_batchno as Batch, @w_start as Start_Record, @w_end as End_Record
end

create table #t1 (
	record_id_num			int
	constraint imsoe_t1_key unique nonclustered (record_id_num)
)


if @p_batchno is not NULL
begin

	print 'batch is not null'

	select 		@w_start = min(record_id_num)
	from 		imsoe_vw
	where 		company_code = @w_cc
	and 		batch_no = @p_batchno
	and 	 	process_status = 0

	if @@rowcount = 0
	begin
		select @w_start = @p_start_rec
		select @w_end = @p_end_rec
	end
	else
	begin
		select 		@w_end = max(record_id_num)
		from 		imsoe_vw
		where 		company_code = @w_cc
		and 		batch_no = @p_batchno
		and 	 	process_status = 0

		if @p_end_rec < @w_end
		begin
		    select @w_end = @p_end_rec
		end

		if @p_start_rec > @w_start
		begin
		    select @w_start = @p_start_rec
		end
	end

end
else
begin

	if @p_start_rec > 0
	begin
		print 'p_start_rec > 0'

		select 		@w_start = @p_start_rec
	end
	else
	begin
		print 'p_start_rec = 0'

		select 		@w_start = min(record_id_num)
		from 		imsoe_vw
		where 		company_code = @w_cc
		and 		process_status = 0

		print '@w_start=' + convert(char(30),@w_start)
	end

	if @p_end_rec > 0
	begin
		select @w_end = @p_end_rec
	end
	else
	begin
		select 		@w_end = max(record_id_num)
		from 		imsoe_vw
		where 		company_code = @w_cc
		and 		process_status = 0
	end
end

insert 	into #t1
select 	record_id_num
from 	imsoe_vw
where	company_code = @w_cc
and 	process_status = 0
and 	record_id_num >= @w_start
and 	record_id_num <= @w_end

if @p_debug_level > 0
begin
	select @w_cc as company_code, @p_batchno as Batch, @w_start as Start_Record, @w_end as End_Record
end

if @p_debug_level >= 6
begin
	select * from #t1
	print 'Exiting on debug request'
	return
end





declare	@RECTYPE_OE_HDR			int
declare @RECTYPE_OE_LINE		int
declare @RECTYPE_OE_HIST		int

declare @ERR_OE_HDR			int
declare	@ERR_OE_CUSTCODE		int
declare @ERR_OE_SHIPTO			int
declare @ERR_OE_TERMS			int
declare	@ERR_OE_ROUTING			int
declare @ERR_OE_SHIPTOREG		int
declare @ERR_OE_SALES			int
declare @ERR_OE_TAXCODE			int
declare @ERR_OE_FWDR			int
declare	@ERR_OE_FRTTO			int
declare	@ERR_OE_LOC			int
declare	@ERR_OE_CURR			int
declare	@ERR_OE_BILLTO			int
declare	@ERR_OE_POSTN_CODE		int
declare @ERR_OE_ZONE_CODE		int
declare @ERR_OE_RATE_TYPE		int
declare @ERR_OE_HOLD_REASON		int
declare @ERR_OE_PRINTCODE		int
-- defined selection
declare	@ERR_OE_STATUS			int
declare	@ERR_OE_TYPE			int
declare @ERR_OE_BOFLG			int
declare @ERR_OE_ORDNO           	int
declare @ERR_OE_INVLD_LIN		int
declare	@ERR_OE_TOTALS			int
declare @ERR_OE_DUP			int
declare @ERR_IE_MC			int
declare @ERR_OE_NOLIN			int


declare	@ERR_OE_LINE			int
declare @ERR_OE_L_ORDNO			int
declare @ERR_OE_L_PARTNO		int
declare @ERR_OE_L_LOCATION		int
declare @ERR_OE_L_UOM			int
declare @ERR_OE_L_TAXCODE		int
declare @ERR_OE_L_GLREF			int
declare @ERR_OE_L_DUP			int
declare @ERR_OE_L_PRICTYP		int
declare @ERR_OE_L_LOCMISMATCH		int
declare @ERR_OE_L_DESCBLANK		int
declare @ERR_OE_L_PARTTYPE		int

declare @ERR_OE_LINE2			int
declare @ERR_OE_L_ORDQTY		int

select	@RECTYPE_OE_HDR			= 0x00000001
select	@RECTYPE_OE_LINE		= 0x00000002
select 	@RECTYPE_OE_HIST		= 0x00000010

-- lookups
select	@ERR_OE_CUSTCODE		= 0x00000001
select 	@ERR_OE_SHIPTO			= 0x00000002
select 	@ERR_OE_TERMS			= 0x00000004
select	@ERR_OE_ROUTING			= 0x00000008
select 	@ERR_OE_SHIPTOREG	    	= 0x00000010
select 	@ERR_OE_SALES			= 0x00000020
select 	@ERR_OE_TAXCODE			= 0x00000040
select 	@ERR_OE_FWDR			= 0x00000080
select	@ERR_OE_FRTTO			= 0x00000100
select	@ERR_OE_LOC			= 0x00000200
select	@ERR_OE_CURR			= 0x00000400
select	@ERR_OE_BILLTO			= 0x00000800
select	@ERR_OE_POSTN_CODE		= 0x00001000
select 	@ERR_OE_ZONE_CODE		= 0x00002000
-- for record_status_2
select	@ERR_OE_RATE_TYPE		= 0x00000001
select	@ERR_OE_HOLD_REASON		= 0x00000010
select  @ERR_OE_PRINTCODE		= 0x00000020
-- defined selection
select	@ERR_OE_STATUS			= 0x00004000
select	@ERR_OE_TYPE			= 0x00008000
select 	@ERR_OE_BOFLG			= 0x00010000
select	@ERR_OE_TOTALS			= 0x00020000
select  @ERR_OE_ORDNO           	= 0x00040000
select  @ERR_OE_INVLD_LIN		= 0x00080000
select  @ERR_OE_DUP             	= 0x08000000
select  @ERR_OE_NOLIN			= 0x10000000
select	@ERR_IE_MC              	= 0x00000002



select @ERR_OE_HDR = @ERR_OE_CUSTCODE 	+ @ERR_OE_SHIPTO 	+ @ERR_OE_TERMS 	+ @ERR_OE_ROUTING
select @ERR_OE_HDR = @ERR_OE_HDR 	+ @ERR_OE_SHIPTOREG 	+ @ERR_OE_SALES 	+ @ERR_OE_TAXCODE 	+ @ERR_OE_FWDR 			+ @ERR_OE_FRTTO
select @ERR_OE_HDR = @ERR_OE_HDR 	+ @ERR_OE_LOC 		+ @ERR_OE_CURR 		+ @ERR_OE_BILLTO 	+ @ERR_OE_POSTN_CODE 		+ @ERR_OE_ZONE_CODE
select @ERR_OE_HDR = @ERR_OE_HDR 	+ @ERR_OE_STATUS 	+ @ERR_OE_TYPE 		+ @ERR_OE_BOFLG 	+ @ERR_OE_ORDNO			+ @ERR_OE_DUP
select @ERR_OE_HDR = @ERR_OE_HDR 	+ @ERR_OE_NOLIN

--- + @ERR_OE_INVLD_LIN	+ @ERR_OE_TOTALS this now done seperated so it can be based on status


select @ERR_OE_L_ORDNO			= 0x00100000
select @ERR_OE_L_PARTNO			= 0x00200000
select @ERR_OE_L_LOCATION		= 0x00400000
select @ERR_OE_L_UOM			= 0x00800000
select @ERR_OE_L_TAXCODE		= 0x01000000
select @ERR_OE_L_GLREF			= 0x02000000
select @ERR_OE_L_DUP			= 0x04000000
select @ERR_OE_L_PRICTYP		= 0x20000000


select @ERR_OE_LINE = @ERR_OE_L_ORDNO 	+ @ERR_OE_L_PARTNO 	+ @ERR_OE_L_LOCATION 	+ @ERR_OE_L_TAXCODE 	+ @ERR_OE_L_UOM
select @ERR_OE_LINE = @ERR_OE_LINE 	+ @ERR_OE_L_GLREF 	+ @ERR_OE_L_DUP 	+ @ERR_OE_L_PRICTYP	+ @ERR_OE_STATUS

-- record status 2
select @ERR_OE_L_ORDQTY			= 0x00000004
select @ERR_OE_L_LOCMISMATCH		= 0x00000040
select @ERR_OE_L_DESCBLANK		= 0x00000080
select @ERR_OE_L_PARTTYPE		= 0x00000100

select @ERR_OE_LINE2 			= @ERR_OE_L_ORDQTY 	+ @ERR_OE_L_LOCMISMATCH	+ @ERR_OE_L_DESCBLANK	+ @ERR_OE_L_PARTTYPE

--- sales order history validation setup
declare @ERR_OE_TRANSMIX		int
declare @ERR_OE_SHIP			int
declare @ERR_OE_SHIP2			int

select  @ERR_OE_TRANSMIX 		= 0x00000008

select 	@ERR_OE_SHIP			= @ERR_OE_CUSTCODE	+ @ERR_OE_SHIPTO	+ @ERR_OE_SHIPTOREG		+ @ERR_OE_SALES
select  @ERR_OE_SHIP			= @ERR_OE_SHIP		+ @ERR_OE_LOC		+ @ERR_OE_L_ORDNO		+ @ERR_OE_L_PRICTYP
select  @ERR_OE_SHIP			= @ERR_OE_SHIP		+ @ERR_OE_L_PARTNO	+ @ERR_OE_L_LOCATION
select 	@ERR_OE_SHIP2			= @ERR_OE_TRANSMIX


-- working variables --
declare @p_highest_pos_order_num    int


if @p_debug_level > 0
begin
    select @ERR_OE_HDR as ERR_OE_HDR,@ERR_OE_LINE as ERR_OE_LINE
end


-- fill in some defaults
update	vw
set 	vw.rate_type_oper = arco.rate_type_oper
from 	imsoe_hdr_vw vw,
	glco,
	arco
where	vw.company_code = glco.company_code
and 	vw.process_status = 0
and 	glco.company_id = arco.company_id

update	vw
set 	vw.rate_type_home = arco.rate_type_home
from 	imsoe_hdr_vw vw,
	glco,
	arco
where	vw.company_code = glco.company_code
and 	vw.process_status = 0
and 	glco.company_id = arco.company_id

update 	vw
set	vw.curr_key = arco.def_curr_code
from 	imsoe_hdr_vw vw,
	glco,
	arco
where 	vw.company_code = glco.company_code
and 	( 	vw.curr_key <= ' '
	or	vw.curr_key is null )
and	vw.process_status = 0
and 	glco.company_id = arco.company_id

----
---- set validation bits
----
update	imsoe_vw
set	imsoe_vw.record_status_1 = 0x00000000,
	imsoe_vw.record_status_2 = 0x00000000
from 	#t1
where	imsoe_vw.record_id_num = #t1.record_id_num

update 	imsoe_hdr_vw
set	imsoe_hdr_vw.record_status_1 = @ERR_OE_HDR
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num


-- validation bits record_status_2
update 	imsoe_hdr_vw
set	record_status_2 = @ERR_OE_HOLD_REASON + @ERR_OE_PRINTCODE
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num

-- turn the error bit on for all sale orders where the
-- currency on the order not the same as the co currency
update 	hdr
set	hdr.record_status_2 = hdr.record_status_2 | (@ERR_IE_MC +  @ERR_OE_RATE_TYPE )
from 	imsoe_hdr_vw hdr,
	dbo.glco,
	#t1
where 	hdr.company_code = glco.company_code
and	hdr.curr_key <> glco.home_currency
and 	hdr.record_id_num = #t1.record_id_num

-- SET ERR_OE_TOTALS ON --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 | @ERR_OE_TOTALS
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	status = 'T'

-- SET OE_LINE ERRORS ON --

update 	imsoe_line_vw
set	record_status_1 = record_status_1 | @ERR_OE_LINE,
	record_status_2 = record_status_2 | @ERR_OE_LINE2
from 	imsoe_line_vw,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num

-- SET OE_SHIP ERRORS ON --

update 	imsoe_shipr_vw
set	record_status_1 = record_status_1 | @ERR_OE_SHIP,
	record_status_2 = record_status_2 | @ERR_OE_SHIP2
from 	imsoe_shipr_vw,
	#t1
where 	imsoe_shipr_vw.record_id_num = #t1.record_id_num

-- ERR_OE_CUSTCODE --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_CUSTCODE
from 	imsoe_hdr_vw,
	arcust,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.cust_code = arcust.customer_code


-- ERR_OE_SHIPTO --

update	im
set	im.ship_to_name = ars.addr1,
	im.ship_to_add_1 = ars.addr2,
	im.ship_to_add_2 = ars.addr3,
	im.ship_to_add_3 = ars.addr4,
	im.ship_to_add_5 = ars.addr5,
	im.ship_to_state = left(ars.state,2),
	im.ship_to_zip = ars.postal_code,
	im.ship_to_country = ars.country,
	im.ship_to_region = ars.dest_zone_code,
	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
from 	imsoe_hdr_vw 	im,
	arshipto	ars,
	#t1
where 	im.record_id_num = #t1.record_id_num
and 	im.cust_code = ars.customer_code
and	im.ship_to = ars.ship_to_code

update 	im
set	im.ship_to = '',
	im.ship_to_name = ar.addr1,
	im.ship_to_add_1 = ar.addr2,
	im.ship_to_add_2 = ar.addr3,
	im.ship_to_add_3 = ar.addr4,
	im.ship_to_add_5 = ar.addr5,
	im.ship_to_state = left(ar.state,2),
	im.ship_to_zip = ar.postal_code,
	im.ship_to_country = ar.country,
	im.ship_to_region = ar.dest_zone_code,
	im.record_status_1 = im.record_status_1 ^ @ERR_OE_SHIPTO
from 	imsoe_hdr_vw im,
	arcust ar,
	#t1
where	im.record_id_num = #t1.record_id_num
and	(im.record_status_1 & @ERR_OE_SHIPTO ) > 0
and 	(im.ship_to = '' or im.ship_to is NULL)
and	im.ship_to_name = ''
and	im.ship_to_add_1 = ''
and	im.ship_to_add_2 = ''
and	im.ship_to_add_3 = ''
and	im.ship_to_add_4 = ''
and	im.ship_to_add_5 = ''
and	im.ship_to_city = ''
and	im.ship_to_state = ''
and	im.ship_to_zip = ''
and	im.ship_to_country = ''
and	im.ship_to_region = ''
and 	im.cust_code = ar.customer_code


update 	imsoe_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_SHIPTO) > 0
and 	(	ship_to <= ' '
	or	ship_to is null
	)


-- ERR_OE_TERMS --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_TERMS
from 	imsoe_hdr_vw,
	arterms,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and	imsoe_hdr_vw.terms = arterms.terms_code

-- ERR_OE_ROUTING --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_ROUTING
from 	imsoe_hdr_vw,
	arshipv,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.routing = arshipv.ship_via_code

-- ERR_OE_SALES --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_SALES
from 	imsoe_hdr_vw,
	arsalesp,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.salesperson = arsalesp.salesperson_code

update	im
set	im.record_status_1 = im.record_status_1 ^ @ERR_OE_SALES,
	im.salesperson = arcust.salesperson_code
from 	imsoe_hdr_vw im,
	arcust,
	#t1
where	im.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_SALES) > 0
and 	(	im.salesperson <= ' '
	or	im.salesperson is null
	)
and 	im.cust_code = arcust.customer_code

-- ERR_OE_TAXCODE --
-- if the tax code of blank, and the customer is valid
-- then update it with the code off of the vendor

update 	imsoe_hdr_vw
set	imsoe_hdr_vw.record_status_1 = imsoe_hdr_vw.record_status_1 ^ @ERR_OE_TAXCODE,
	imsoe_hdr_vw.tax_id = arcust.tax_code
from 	imsoe_hdr_vw,
	arcust,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.cust_code = arcust.customer_code

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_TAXCODE
from 	imsoe_hdr_vw,
	artax,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.tax_id = artax.tax_code
and 	(imsoe_hdr_vw.record_status_1 & @ERR_OE_TAXCODE) > 0

-- ERR_OE_FWDR --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_FWDR
from 	imsoe_hdr_vw,
	arfwdr,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.forwarder_key = arfwdr.kys

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_FWDR
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_FWDR ) > 0
and 	(	forwarder_key <= ' '
	or 	forwarder_key is null )

-- ERR_OE_FRTTO --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_FRTTO
from 	imsoe_hdr_vw,
	arfrt_to,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.freight_to = arfrt_to.kys

update 	imsoe_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_FRTTO
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_FRTTO) > 0
and 	(	freight_to < = ' '
	or 	freight_to is null)

-- ERR_OE_SHIPTOREG --

update 	imsoe_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
from 	imsoe_hdr_vw,
	arterr,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.ship_to_region = arterr.territory_code

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_SHIPTOREG) > 0
and 	ship_to_region < = ' '

-- ERR_OE_LOC --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_LOC
from 	imsoe_hdr_vw,
	locations,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.location = locations.location

-- ERR_OE_CURR --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_CURR
from 	imsoe_hdr_vw,
	glcurr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.curr_key = glcurr_vw.currency_code

-- ERR_OE_BILLTO --

update 	imsoe_hdr_vw
set 	bill_to_key = cust_code
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(	bill_to_key <= ' '
	or 	bill_to_key is null)

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_BILLTO
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	cust_code = bill_to_key

-- ERR_OE_POSTN_CODE --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_POSTN_CODE
from 	imsoe_hdr_vw
	,araccts
	,#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.posting_code = araccts.posting_code

-- ERR_OE_ZONE_CODE --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_ZONE_CODE
from 	imsoe_hdr_vw,
	arzone,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and	imsoe_hdr_vw.dest_zone_code = arzone.zone_code

update 	imsoe_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_ZONE_CODE
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_OE_ZONE_CODE) > 0
and 	(	dest_zone_code <= ' '
	or 	dest_zone_code is null)

-- ERR_OE_STATUS --

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_STATUS
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	status in ('N')  ---,'T') only new orders for the moment

-- if the status is 'T' then have to check the totals

-- ERR_OE_TYPE --

update  imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_TYPE
from 	imsoe_hdr_vw,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	type = 'I'

-- ERR_OE_BOFLG --

update 	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_BOFLG
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	back_ord_flag >= '0' and back_ord_flag <= '2'




-- ERR_OE_HOLD_REASON --

update 	vw
set 	vw.record_status_2 = vw.record_status_2 ^ @ERR_OE_HOLD_REASON
from 	imsoe_hdr_vw vw,
	adm_oehold ao,
	#t1
where 	vw.record_id_num = #t1.record_id_num
and 	vw.hold_reason = ao.hold_code


update	imsoe_hdr_vw
set 	record_status_2 = record_status_2 ^ @ERR_OE_HOLD_REASON
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(	hold_reason <= ' '
	or 	hold_reason is null )

-- ERR_OE_PRINTCODE --

update 	imsoe_hdr_vw
set	record_status_2 = record_status_2 ^ @ERR_OE_PRINTCODE
from 	imsoe_hdr_vw,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and	(	printed = 'N'
	or 	printed = 'S'
	or 	printed = 'T' )

-- ERR_OE_ORDNO --

select  @p_highest_pos_order_num = last_no
from    next_order_num

update  imsoe_hdr_vw
set     record_status_1 = record_status_1 ^ @ERR_OE_ORDNO
from 	imsoe_hdr_vw,
	#t1
where   imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(	imsoe_hdr_vw.order_no  >= 0
	and 	imsoe_hdr_vw.order_no <= @p_highest_pos_order_num )

update 	imsoe_hdr_vw
set 	record_status_1 = record_status_1 & @ERR_OE_ORDNO
from 	imsoe_hdr_vw,
	orders,
	#t1
where 	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	(imsoe_hdr_vw.record_status_1 & @ERR_OE_ORDNO) = 0 	-- error has been turned off
and	imsoe_hdr_vw.order_no = orders.order_no

-- ERR_OE_DUP --

-- check to see if this hdr record is a duplicate in the staging table
update	imsoe_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_DUP
from 	( 	select		count(*) as _count,
				order_no
		from 		imsoe_hdr_vw
		where		company_code = @w_cc
		and 		process_status = 0
		group by 	order_no
		having		count(*) = 1
		) as singles,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.order_no = singles.order_no

---**********

-- check to see if this record already exists in the production tables

update	imsoe_hdr_vw
set	record_status_1 = record_status_1 | @ERR_OE_DUP		-- turn the bit n
from 	imsoe_hdr_vw,
	orders,
	#t1
where	imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 	imsoe_hdr_vw.order_no = orders.order_no
and 	(imsoe_hdr_vw.record_status_1 & @ERR_OE_DUP) = 0	-- bit is currently turned off from above query
	-- can be zero , this will signal an order number to be applied

-- ERR_OE_NOLIN
-- now check that header lines must have at least one order line assocated with then

update 		hdr
set		hdr.record_status_1  = hdr.record_status_1 ^ @ERR_OE_NOLIN
from 		imsoe_hdr_vw hdr,
		imsoe_line_vw lin,
		#t1
where 		hdr.record_id_num = #t1.record_id_num
and		hdr.order_no = lin.order_no
and 		lin.company_code = @w_cc
and 		lin.process_status = 0


----------- order line validations ------------

-- ERR_OE_LINE --
update  imsoe_line_vw
set	record_status_1 = record_status_1 | @ERR_OE_LINE
from 	imsoe_line_vw,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	(record_type & @RECTYPE_OE_LINE) > 0

-- turn the ERR_OE_BOFLG bit on for all records that are
-- only lin recs
update	imsoe_vw
set	record_status_1 = record_status_1 | @ERR_OE_BOFLG
from 	imsoe_vw,
	#t1
where	imsoe_vw.record_id_num = #t1.record_id_num
and 	record_type = @RECTYPE_OE_LINE

-- ERR_OE_L_PARTNO --

update 	imsoe_line_vw
set 	record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_PARTNO
from 	imsoe_line_vw,
	inv_master,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.part_no = inv_master.part_no

-- ERR_OE_L_PARTTYPE --

update 	imsoe_line_vw
set 	record_status_2 = record_status_2 ^ @ERR_OE_L_PARTTYPE
from 	imsoe_line_vw,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	(	part_type = 'M'
	or 	part_type = 'P' )

-- ERR_OE_L_LOCATION --

update 	imsoe_line_vw
set	record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_LOCATION
from 	imsoe_line_vw,
	inv_list,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.part_no = inv_list.part_no
and 	imsoe_line_vw.line_location = inv_list.location

-- ERR_OE_L_DESCBLANK --

update	vw
set 	vw.description = im.description
from 	imsoe_line_vw vw,
	inv_master im,
	#t1
where	vw.record_id_num = #t1.record_id_num
and 	vw.part_no = im.part_no
and 	( 	vw.description <= ' '
	or 	vw.description is null )

update	vw
set 	vw.description = hdr.description
from 	imsoe_line_vw vw,
	iminvmast_mstr_vw hdr,
	#t1
where 	vw.record_id_num = #t1.record_id_num
and 	(	vw.description <= ' '
	or	vw.description is null )
and 	vw.part_no = hdr.part_no
and 	hdr.company_code = @w_cc
and 	hdr.process_status = 0

update 	imsoe_line_vw
set	record_status_2 = record_status_2 ^ @ERR_OE_L_DESCBLANK
from 	imsoe_line_vw,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	description is not null
and 	description > ''

-- ERR_OE_L_UOM --

update	imsoe_line_vw
set 	record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_UOM
from 	imsoe_line_vw,
	uom_list,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.uom = uom_list.uom

-- ERR_OE_L_TAXCODE --

update 	imsoe_line_vw
set	imsoe_line_vw.record_status_1 = imsoe_hdr_vw.record_status_1 ^ @ERR_OE_L_TAXCODE,
	imsoe_line_vw.tax_code = arcust.tax_code
from 	imsoe_line_vw,
	imsoe_hdr_vw,
	arcust,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.order_no = imsoe_hdr_vw.order_no
and 	imsoe_hdr_vw.company_code = @w_cc
and 	imsoe_hdr_vw.process_status = 0
and 	imsoe_hdr_vw.cust_code = arcust.customer_code
and 	(	imsoe_line_vw.tax_code is null
	or 	imsoe_line_vw.tax_code <= ' ')


update 	imsoe_line_vw
set	record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_TAXCODE
from 	imsoe_line_vw,
	artax,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.tax_code = artax.tax_code
and 	(imsoe_line_vw.record_status_1 & @ERR_OE_L_TAXCODE ) > 0

-- ERR_OE_L_GLREF --

update 	imsoe_line_vw
set 	imsoe_line_vw.gl_rec_acct = in_account.sales_acct_code,
	imsoe_line_vw.record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_GLREF
from 	imsoe_line_vw,
	in_account,
	inv_list,
	#t1
where 	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	(imsoe_line_vw.record_status_1 & @ERR_OE_L_LOCATION) = 0
and 	imsoe_line_vw.part_type = 'P'
and 	imsoe_line_vw.part_no = inv_list.part_no
and 	imsoe_line_vw.line_location = inv_list.location
and 	inv_list.acct_code = in_account.acct_code

update  imsoe_line_vw
set     record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_GLREF
from    imsoe_line_vw,
        in_account,
	#t1
where   imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.gl_rec_acct = in_account.sales_acct_code
and 	imsoe_line_vw.part_type = 'M'

-- ERR_OE_L_PRICETYP --

update	imsoe_line_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_L_PRICTYP
from 	imsoe_line_vw,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	price_type in ('1','2','3','4','5','P','Q','Y')

-- ERR_OE_L_ORDQTY --

update 	imsoe_line_vw
set 	record_status_2 = record_status_2 ^ @ERR_OE_L_ORDQTY
from 	imsoe_line_vw,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	ordered > 0

-- ERR_OE_BOFLG --

update 	imsoe_line_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_BOFLG
from 	imsoe_line_vw,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	record_type = @RECTYPE_OE_LINE
and 	back_ord_flag >= '0' and back_ord_flag <= '2'

-- ERR_OE_STATUS for soelines

update	imsoe_line_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_STATUS
from 	imsoe_line_vw,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	line_status in ('N')  ---,'T') only new orders for the moment

-- ERR_OE_L_DUP --

-- here is a tricky bit of sql for you, it checks for duplicates order_no,line_no in the
-- staging table and set the bit off where there is only one record in the group
update 	imsoe_line_vw
set		record_status_1 = record_status_1 ^ @ERR_OE_L_DUP
from 	( 	select 		count(*) as _count,
				order_no,
				line_no
		from 		imsoe_line_vw
		where		company_code = @w_cc
		group by 	order_no,
				line_no
		having 		count(*) = 1
		) as v2,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	imsoe_line_vw.order_no = v2.order_no
and 	imsoe_line_vw.line_no = v2.line_no

-- now check the see that if any of the lines that were not duplicated
-- belong to orders that are already in the
-- production tables. This scheme will not allow appending to an existing order!
update	imsoe_line_vw
set 	record_status_1 = record_status_1 | @ERR_OE_L_DUP -- turn the bit on
from 	imsoe_line_vw,
	orders,
	#t1
where	imsoe_line_vw.record_id_num = #t1.record_id_num
and 	(imsoe_line_vw.record_status_1 & @ERR_OE_L_DUP) = 0 -- bit is not set
and 	imsoe_line_vw.order_no = orders.order_no

-- now check turn the line error off for all rows that

update 	lin
set	lin.record_status_1 = lin.record_status_1 ^ @ERR_OE_L_ORDNO
from 	imsoe_line_vw lin,
	imsoe_hdr_vw  hdr,
	#t1
where 	lin.record_id_num = #t1.record_id_num
and 	lin.order_no = hdr.order_no

-- this is a little different, in this case I turn the bit on in the hdr, if an error exists in any
-- of the line records for a given header
update	imsoe_hdr_vw
set	record_status_1 = record_status_1 | @ERR_OE_INVLD_LIN
from 	(	select		lin.order_no
		from 		imsoe_line_vw lin
		where 		lin.company_code = @w_cc
		and 		lin.record_status_1 <> 0
		and			lin.process_status = 0
		group by 	lin.order_no) as t1,
	#t1
where		imsoe_hdr_vw.record_id_num = #t1.record_id_num
and 		imsoe_hdr_vw.order_no = t1.order_no

-- ERR_OE_L_LOCMISMATCH --

update 	lin
set	lin.record_status_2 = lin.record_status_2 ^ @ERR_OE_L_LOCMISMATCH
from 	imsoe_line_vw lin,
	imsoe_hdr_vw hdr,
	#t1
where	lin.record_id_num = #t1.record_id_num
and 	lin.order_no = hdr.order_no
and 	lin.line_location = hdr.location
and 	lin.company_code = hdr.company_code

------- imsoe_shipr_vw validation [start]

-- ERR_OE_TRANSMIX --

update	imsoe_shipr_vw
set	record_status_2 = record_status_2 ^ @ERR_OE_TRANSMIX
from 	imsoe_shipr_vw,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	imsoe_shipr_vw.record_type = @RECTYPE_OE_HIST

-- ERR_OE_CUSTCODE --

update	imsoe_shipr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_CUSTCODE
from 	imsoe_shipr_vw
	,arcust
	,#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	imsoe_shipr_vw.cust_code = arcust.customer_code
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_SHIPTO --

update 	imsoe_shipr_vw
set 	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
from 	imsoe_shipr_vw,
	arshipto,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	( 	imsoe_shipr_vw.ship_to = arshipto.ship_to_code
	or	imsoe_shipr_vw.ship_to <= ' '
	or 	imsoe_shipr_vw.ship_to is null)
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_SHIPTOREG --

update 	imsoe_shipr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
from 	imsoe_shipr_vw,
	arterr,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	(	imsoe_shipr_vw.ship_to_region = arterr.territory_code
	or	imsoe_shipr_vw.ship_to_region <= ' '
	or 	imsoe_shipr_vw.ship_to_region is null)
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_SALES --

update	imsoe_shipr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_SALES
from 	imsoe_shipr_vw,
	arsalesp,
	#t1
where	imsoe_shipr_vw.record_id_num  = #t1.record_id_num
and 	(	imsoe_shipr_vw.salesperson = arsalesp.salesperson_code
	or	imsoe_shipr_vw.salesperson <= ' '
	or	imsoe_shipr_vw.salesperson is null)
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_LOC --

update 	imsoe_shipr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_LOC
from 	imsoe_shipr_vw,
	locations,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	imsoe_shipr_vw.location = locations.location
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_ORD_NO --

update 	imsoe_shipr_vw
set	record_status_1 = record_status_1 ^ @ERR_OE_ORDNO
from 	imsoe_shipr_vw,
	orders,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	imsoe_shipr_vw.order_no = orders.order_no
and 	imsoe_shipr_vw.order_ext = orders.ext
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

update 	imsoe_shipr_vw
set 	imsoe_shipr_vw.record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_ORDNO
from 	imsoe_shipr_vw,
	imsoe_hdr_vw,
	#t1
where	imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 	imsoe_shipr_vw.order_no = imsoe_hdr_vw.order_no
and 	imsoe_hdr_vw.company_code = @w_cc
and 	imsoe_hdr_vw.record_status_1 = 0
and 	imsoe_hdr_vw.record_status_2 = 0
and	imsoe_hdr_vw.process_status = 0
and 	imsoe_shipr_vw.process_status = 0
and 	(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
and 	(imsoe_shipr_vw.record_status_1 & @ERR_OE_ORDNO) > 0

-- ERR_OE_L_PRICETYP --

update		imsoe_shipr_vw
set		record_status_1 = record_status_1 ^ @ERR_OE_L_PRICTYP
from		imsoe_shipr_Vw,
		#t1
where		imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 		price_type in ('1','2','3','4','5','P','Q','Y')
and 		(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

-- ERR_OE_L_PART_NO --
		-- check production
update 		imsoe_shipr_vw
set 		record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_PARTNO
from 		imsoe_shipr_vw,
		inv_master,
		#t1
where		imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 		imsoe_shipr_vw.part_no = inv_master.part_no
and 		(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0

		-- check staging table
update 		imsoe_shipr_vw
set 		record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_PARTNO
from 		imsoe_shipr_vw,
		iminvmast_mstr_vw,
		#t1
where		imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 		imsoe_shipr_vw.part_no = iminvmast_mstr_vw.part_no
and 		iminvmast_mstr_vw.process_status = 0
and 		iminvmast_mstr_vw.record_status_1 = 0
and 		iminvmast_mstr_vw.record_status_2 = 0
and 		(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
and 		(imsoe_shipr_vw.record_status_1 & @ERR_OE_L_PARTNO) > 0



-- ERR_OE_L_LOCATION --
		-- check production
update 		imsoe_shipr_vw
set		record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_LOCATION
from 		imsoe_shipr_vw,
		inv_list,
		#t1
where		imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 		imsoe_shipr_vw.part_no = inv_list.part_no
and 		imsoe_shipr_vw.location = inv_list.location
and 		(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0


update 		imsoe_shipr_vw
set		record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_LOCATION
from 		imsoe_shipr_vw,
		iminvmast_loc_vw,
		#t1
where		imsoe_shipr_vw.record_id_num = #t1.record_id_num
and 		imsoe_shipr_vw.part_no = iminvmast_loc_vw.part_no
and 		imsoe_shipr_vw.location = iminvmast_loc_vw.location
and		iminvmast_loc_vw.record_status_1 = 0
and 		iminvmast_loc_vw.process_status = 0
and 		(imsoe_shipr_vw.record_status_1 & @ERR_OE_L_LOCATION) > 0
and 		(imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0


--------imsoe_shipr_vw validation [end]

-- now do some lookups and validations here, check that the currencies can be converted
declare	@w_req_ship_date	datetime
declare @w_curr_key		varchar(10)
declare @w_rate_type_home	varchar(8)
declare @w_rate_type_oper	varchar(8)
declare @w_record_id_num 	int
declare @w_julian 		int
declare @w_error_int		int
declare @w_home			float
declare @w_oper			float

declare hdr_cursor cursor for
select 	hdr.req_ship_date
	,hdr.curr_key
	,hdr.rate_type_home
	,hdr.rate_type_oper
	,hdr.record_id_num
from 	imsoe_hdr_vw hdr,
	apco,
	#t1
where 	hdr.record_id_num = #t1.record_id_num
and	hdr.curr_key <> apco.currency_code

open hdr_cursor

fetch next
from hdr_cursor
into @w_req_ship_date,@w_curr_key,@w_rate_type_home,@w_rate_type_oper,@w_record_id_num

while @@fetch_status <> -1
begin
	exec imCvtJulFrmDte_sp @w_req_ship_date, @w_julian OUTPUT

	exec imcurate_e7_sp @w_julian,@w_curr_key,@w_rate_type_home,@w_rate_type_oper,@w_error_int OUTPUT, @w_home OUTPUT, @w_oper OUTPUT

	if @w_error_int = 0
	begin
		update	imsoe_hdr_vw
		set	record_status_2 = record_status_2 ^ @ERR_IE_MC,
			curr_factor = @w_home,
			oper_factor = @w_oper
		where	record_id_num = @w_record_id_num
	end

	fetch next
	from hdr_cursor
	into @w_req_ship_date,@w_curr_key,@w_rate_type_home,@w_rate_type_oper,@w_record_id_num
end

close hdr_cursor
deallocate hdr_cursor


GO
GRANT EXECUTE ON  [dbo].[imSoeVal_e7_sp] TO [public]
GO
