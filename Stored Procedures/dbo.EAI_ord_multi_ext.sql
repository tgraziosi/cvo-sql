SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[EAI_ord_multi_ext] @order_no int AS
BEGIN

-- variables for the cursor
Declare @order_ext int, @line_no int, @part_no varchar(30), @description varchar(255), @part_type char(1)
Declare	@ordered decimal(20,8), @shipped decimal (20,8), @uom char(2), @conv_factor decimal(20,8), @weight_ea decimal(20,8)
Declare	@cubic_feet decimal(20,8), @back_ord_flag char(1), @status char(1), @curr_price decimal(20,8)
Declare @discount decimal(20,8), @cost decimal(20,8), @tax_code varchar(10), @taxable int, @location varchar(10)
Declare @price decimal(20,8), @gl_rev_acct varchar(32), @note varchar(255), @time_entered datetime, @who_entered varchar(20)
Declare @total_tax decimal(20,8) 
Declare @price_type char(1)

-- assign the line_no since the part will show up on different line nos as the orders are shipped
Declare @assign_line_no int

-- running totals
Declare @total_amt_order decimal(20,8), @total_ord_disc decimal(20,8), @total_ord_tax decimal(20,8)
Declare @total_ord_freight decimal(20,8)

CREATE TABLE #total_ord_list (order_no int, order_ext int, line_no int, part_no varchar(30), description varchar(255), 
			part_type char(1), ordered decimal(20, 8), shipped decimal(20,8), uom char(2), 
			conv_factor decimal(20,8), weight_ea decimal(20, 8), cubic_feet decimal(20, 8), back_ord_flag 
			char(1), status char(1), curr_price decimal(20, 8), discount decimal(20, 8), cost decimal(20, 8),
			tax_code varchar(10), taxable int, location varchar(10), price decimal(20, 8), gl_rev_acct 
			varchar(32), note varchar(255), time_entered datetime, who_entered varchar(20), total_tax 
			decimal(20,8), price_type char(1))

CREATE TABLE #total_orders (order_no int, total_amt_order decimal(20,8), total_ord_disc decimal(20,8),
			total_ord_tax decimal(20,8), total_ord_freight decimal(20,8))

CREATE TABLE #ord_list_kit (order_no int, order_ext int, line_no int, part_no varchar(30), qty_per decimal(20,8))

DELETE FROM EAI_ext_order_list WHERE order_no = @order_no
DELETE FROM EAI_ext_ordl_kit WHERE order_no = @order_no


-- initialize values
select @total_amt_order = 0
select @total_ord_disc = 0
select @total_ord_tax = 0
select @total_ord_freight = 0
select @assign_line_no = 1


DECLARE c_open_orders CURSOR FOR 
SELECT order_no, order_ext, line_no, part_no, description, part_type, ordered, shipped, uom, conv_factor, weight_ea, 
	       cubic_feet, back_ord_flag, status, curr_price, discount, cost, tax_code, taxable, location, price,
	       gl_rev_acct, note, time_entered, who_entered, total_tax , price_type 
FROM ord_list (NOLOCK)
WHERE order_no = @order_no AND
      status NOT IN ('M','L','V','X','T','S')	-- not shipped/posted or shipped/transferred, nor void
ORDER BY part_no, order_ext DESC, line_no ASC

OPEN c_open_orders
  
FETCH NEXT FROM c_open_orders 
INTO	@order_no, @order_ext, @line_no, @part_no, @description, @part_type, @ordered, @shipped, @uom, @conv_factor,
	@weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, @tax_code, @taxable, @location,
	@price, @gl_rev_acct, @note, @time_entered, @who_entered, @total_tax , @price_type
  
WHILE @@FETCH_STATUS = 0
BEGIN
	if not exists (select 'X' from #total_ord_list where part_no = @part_no) begin
		insert #total_ord_list (order_no, order_ext, line_no, part_no, description, part_type, ordered,
			shipped, uom, conv_factor, weight_ea, cubic_feet, back_ord_flag, status, curr_price, 
			discount, cost, tax_code, taxable, location, price, gl_rev_acct, note, time_entered, who_entered,
			total_tax , price_type)
		values (@order_no, @order_ext, @assign_line_no, @part_no, @description, @part_type, @ordered, @shipped, @uom,
			@conv_factor, @weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, 
			@tax_code, @taxable, @location, @price, @gl_rev_acct, @note, @time_entered, @who_entered, 
			@total_tax , @price_type)

		select	@assign_line_no = @assign_line_no + 1	-- increment so that the next part has the next line_no
		select	@total_amt_order = @total_amt_order + (@ordered * @curr_price)
		select	@total_ord_disc = @total_ord_disc + (@ordered * @curr_price * @discount/100)
		select	@total_ord_tax = @total_ord_tax + @total_tax

		if exists (select 'X' from inv_master where part_no = @part_no and status = 'K') begin	-- if it is a kit
		-- selects non-voided rows for this order from ord_list_kit and inserts them into #ord_list_kit
			INSERT #ord_list_kit
			select order_no = @order_no, order_ext = @order_ext, line_no = @assign_line_no, part_no, qty
			from what_part (nolock)
			where asm_no = @part_no and (location = @location or location = 'ALL') and 
			((active = 'A') or						-- the part is active
			(active = 'B' and DateDiff(d, eff_date, GetDate()) > 0) or	-- the part is pending inactive, but not yet
			(active = 'U' and DateDiff(d, eff_date, GetDate()) < 0))	-- the part is pending active & the date has arrived
		end
	end
	else begin				-- update the quantities for this part because there are 2 rows for same part
		update #total_ord_list
		set	ordered = ordered + @ordered,
			shipped = shipped + @shipped,
			status = @status	-- update the line to open or whatever status, if that is the case
		where	part_no = @part_no

		select	@total_amt_order = @total_amt_order + (@ordered * @curr_price)
		select	@total_ord_disc = @total_ord_disc + (@ordered * @curr_price * @discount/100)
		select	@total_ord_tax = @total_ord_tax + @total_tax
	end

	FETCH NEXT FROM c_open_orders 
	INTO	@order_no, @order_ext, @line_no, @part_no, @description, @part_type, @ordered, @shipped, @uom, @conv_factor,
		@weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, @tax_code, @taxable, @location,
		@price, @gl_rev_acct, @note, @time_entered, @who_entered, @total_tax ,@price_type

END
  
CLOSE c_open_orders
DEALLOCATE c_open_orders


DECLARE c_shipped_orders CURSOR FOR 
SELECT order_no, order_ext, line_no, part_no, description, part_type, ordered, shipped, uom, conv_factor, weight_ea, 
	       cubic_feet, back_ord_flag, status, curr_price, discount, cost, tax_code, taxable, location, price,
	       gl_rev_acct, note, time_entered, who_entered, total_tax ,price_type
FROM ord_list (NOLOCK)
WHERE order_no = @order_no AND
      status NOT IN ('M','L','V','X')	-- not void
      AND status in ('T', 'S')
ORDER BY part_no, order_ext DESC, line_no ASC	--take the most recent shipments first, to get the current price, &c

OPEN c_shipped_orders
  
FETCH NEXT FROM c_shipped_orders 
INTO	@order_no, @order_ext, @line_no, @part_no, @description, @part_type, @ordered, @shipped, @uom, @conv_factor,
	@weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, @tax_code, @taxable, @location,
	@price, @gl_rev_acct, @note, @time_entered, @who_entered, @total_tax , @price_type
  
WHILE @@FETCH_STATUS = 0
BEGIN
	if not exists (select 'X' from #total_ord_list where part_no = @part_no) begin
		insert #total_ord_list (order_no, order_ext, line_no, part_no, description, part_type, ordered,
			shipped, uom, conv_factor, weight_ea, cubic_feet, back_ord_flag, status, curr_price, 
			discount, cost, tax_code, taxable, location, price, gl_rev_acct, note, time_entered, who_entered,
			total_tax , price_type)			
		values (@order_no, 0, @assign_line_no, @part_no, @description, @part_type, @shipped, @shipped, @uom,
			@conv_factor, @weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, 
			@tax_code, @taxable, @location, @price, @gl_rev_acct, @note, @time_entered, @who_entered, 
			@total_tax , @price_type)
		
		select	@assign_line_no = @assign_line_no + 1	-- increment so that the next part has the next line_no
		select	@total_amt_order = @total_amt_order + (@shipped * @curr_price)
		select	@total_ord_disc = @total_ord_disc + (@shipped * @curr_price * @discount/100)
		select	@total_ord_tax = @total_ord_tax + ((@shipped/@ordered) * @total_tax)

		if exists (select 'X' from inv_master where part_no = @part_no and status = 'K') begin	-- if it is a kit
		-- selects non-voided rows for this order from ord_list_kit and inserts them into #ord_list_kit
			INSERT #ord_list_kit
			select order_no = @order_no, order_ext = @order_ext, line_no = @assign_line_no, part_no, qty
			from what_part (nolock)
			where asm_no = @part_no and (location = @location or location = 'ALL') and 
			(what_part.active = 'A' OR					-- part is active
			( what_part.active = 'B' and GetDate() < what_part.eff_date)	-- pending inactive but still active
			 or (what_part.active = 'U' and GetDate() >= what_part.eff_date) )	-- pending active
		end

	end
	else begin
		update #total_ord_list
		set	ordered = ordered + @shipped,	-- update the quantities
			shipped = shipped + @shipped
		where	part_no = @part_no

		select	@total_amt_order = @total_amt_order + (@shipped * @curr_price)
		select	@total_ord_disc = @total_ord_disc + (@shipped * @curr_price * @discount/100)
		select	@total_ord_tax = @total_ord_tax + ((@shipped/@ordered) * @total_tax)
	end

	FETCH NEXT FROM c_shipped_orders 
	INTO	@order_no, @order_ext, @line_no, @part_no, @description, @part_type, @ordered, @shipped, @uom, @conv_factor,
		@weight_ea, @cubic_feet, @back_ord_flag, @status, @curr_price, @discount, @cost, @tax_code, @taxable, @location,
		@price, @gl_rev_acct, @note, @time_entered, @who_entered, @total_tax ,@price_type

END
  
CLOSE c_shipped_orders
DEALLOCATE c_shipped_orders


SELECT @total_ord_freight = SUM(freight) FROM orders WHERE order_no = @order_no

Insert #total_orders (order_no, total_amt_order, total_ord_disc, total_ord_tax, total_ord_freight)
	values (@order_no, @total_amt_order, @total_ord_disc, @total_ord_tax, @total_ord_freight)

INSERT EAI_ext_order_list
	SELECT 	#total_ord_list.order_no, 0, line_no, part_no, description, part_type, ordered, uom, conv_factor, 
		weight_ea, cubic_feet, back_ord_flag, status, curr_price, discount, cost, tax_code,
		taxable, location, price, gl_rev_acct, note, time_entered, who_entered, 
		total_amt_order, total_ord_disc, total_ord_tax, total_ord_freight, total_tax , price_type
	FROM 	#total_ord_list, #total_orders
	Where	#total_ord_list.order_no = #total_orders.order_no
	ORDER BY line_no
	
if exists(select 'X' from #ord_list_kit) begin
	INSERT EAI_ext_ordl_kit
   	SELECT order_no, order_ext = 0, line_no, part_no, qty_per
	FROM #ord_list_kit
   	ORDER BY line_no, part_no
end

End
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_multi_ext] TO [public]
GO
