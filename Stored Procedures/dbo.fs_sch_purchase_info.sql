SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_purchase_info] @part varchar(30), @location varchar(10),
			@vendor varchar(12) OUTPUT, @order_qty decimal(20,8),
			@po_curr varchar(10) OUTPUT, @unit_cost decimal(20,8) OUTPUT, @blanket_po varchar(16) OUTPUT
  as 


declare	@quote_found	char(1)
declare @quote_price	decimal(20,8),
	@quote_qty	decimal(20,8)
declare	@quote_curr	varchar(10),
	@home_curr	varchar(10)
declare @po_line	int				-- mls #2

declare @vend_curr varchar(10), @one_cur_vendor int					-- mls 11/6/02 SCR 30081
declare @exp_date datetime								-- mls 2/27/03 SCR 03763

--******************************************************************************
--* Look for an open blanket purchase order
--******************************************************************************
SELECT	@blanket_po	= isnull((select MAX(p.po_no)	-- mls #2
FROM	purchase_all p (nolock), pur_list l (nolock)
WHERE	p.po_no		= l.po_no and
	p.location	= @location and
	l.part_no	= @part and
	p.blanket	= 'Y' and
	p.status	= 'O'),NULL)			-- mls #2

if @blanket_po is NOT NULL
begin
	select  @po_line = isnull((select MAX(l.line)	-- mls #2 start
	from pur_list l (nolock)
 	where 	l.po_no = @blanket_po and
		l.part_no = @part),NULL)		-- mls #2 end
        
	SELECT	@unit_cost	= l.curr_cost,
		@vendor		= p.vendor_no,
		@po_curr	= p.curr_key
	FROM	purchase_all p (nolock), pur_list l (nolock)
	WHERE	p.po_no		= l.po_no and
		p.po_no		= @blanket_po and
		l.part_no	= @part	and
		l.line		= isnull(@po_line,l.line)	-- mls #2

	return
end

--******************************************************************************
--* Look for a quote
--******************************************************************************
select @unit_cost = 0
select @quote_found = 'N'
select @home_curr = IsNull((SELECT home_currency FROM glco (nolock)),'')

select @vend_curr = nat_cur_code,			-- mls 11/6/02 SCR 30081 start
 @one_cur_vendor = one_cur_vendor
from adm_vend_all
where vendor_code = @vendor

DECLARE	quote_cursor CURSOR FOR
SELECT	curr_key,   
	qty,
	min(last_recv_date)
FROM	vendor_sku (nolock)
WHERE	vendor_no	= @vendor and
	sku_no		= @part and  
	convert( char(8), last_recv_date, 112 ) >= getdate()
        and (isnull(@one_cur_vendor,0) = 0 or				-- mls 11/6/02 SCR 30081
        (curr_key = '*HOME*' or curr_key = @vend_curr))
group by curr_key, qty
ORDER BY qty, curr_key ASC   

OPEN quote_cursor

FETCH NEXT FROM quote_cursor
INTO @quote_curr, @quote_qty, @exp_date

WHILE @@FETCH_STATUS = 0
begin
	if (@quote_qty is NULL or @quote_qty > @order_qty) break

	select	@unit_cost = last_price,
		@po_curr = curr_key
        from vendor_sku
        where vendor_no = @vendor and sku_no = @part and
          last_recv_date = @exp_date and curr_key = @quote_curr and
          qty = @quote_qty
	select @quote_found = 'Y'

	FETCH NEXT FROM quote_cursor
	INTO @quote_curr, @quote_qty, @exp_date
end

CLOSE quote_cursor
DEALLOCATE quote_cursor

--******************************************************************************
--* Vendor quotes entered in the home currency when the vendor's natural 
--* currency is other than home are stored with a curr_key value of '*HOME*'.
--* We need to return the actual currency code to the calling procedure.
--******************************************************************************
if @po_curr = '*HOME*' select @po_curr = @home_curr

if @quote_found = 'N'
--******************************************************************************
--* No quote was found so get the last price paid
--******************************************************************************
begin
	SELECT	@unit_cost	= cost			-- skk 03/08/01 SCR 26096
	FROM	inventory (nolock)
	WHERE	part_no		= @part and
		location	= @location

	select @po_curr = @home_curr
end

GO
GRANT EXECUTE ON  [dbo].[fs_sch_purchase_info] TO [public]
GO
