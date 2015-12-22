SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- exec [fs_populate_eforecast_tables] '001','ALL','','','',''

-- v1.0 CB 13/07/2011 - 68668-006 - Order History
-- v2.0 TM 08/16/2011 - 68668-012 - Include Order History data

CREATE PROC [dbo].[fs_populate_eforecast_tables]
	@location_filter varchar(10) = 'ALL',
	@start_date_filter varchar(10) = 'ALL',
	@cust_code_from varchar(10), -- v1.0
	@cust_code_to varchar(10), -- v1.0
	@order_type_from varchar(10), -- v1.0
	@order_type_to varchar(10) -- v1.0
as



declare @part_no varchar(30),
	@location varchar(10),
	@shipped decimal(20, 8),
	@cr_shipped decimal(20, 8),
	@conv_factor decimal(20, 8),
	@date_shipped datetime,
	@part_type char(1),
	@ord_no int,
	@ord_ext int,
	@ord_line int,
	@all_dates char(1)

-- v1.0
IF ISNULL(@cust_code_from,'') = ''
	SET @cust_code_from = ''

IF ISNULL(@cust_code_to,'') = ''
	SET @cust_code_to = 'ZZZZZZZZZZ'

IF ISNULL(@order_type_from,'') = ''
	SET @order_type_from = ''

IF ISNULL(@order_type_to,'') = ''
	SET @order_type_to = 'ZZZZZZZZZZ'

-- Create a valid start date filter
select @start_date_filter = rtrim(ltrim(@start_date_filter))
if @start_date_filter != 'ALL'
begin
	select @start_date_filter  = right(@start_date_filter, 2) + '/01/' + left(@start_date_filter, 4)
	select @all_dates = 'N'
end
else
begin
	SELECT @start_date_filter = LEFT(convert(varchar, GETDATE(), 101), 8)
	select @all_dates = 'Y'
end

-- now populate the history (SALESALL) table
delete from EFORECAST_SALESALL 
 WHERE (@location_filter = 'ALL' OR LOCATIONID IN (select LOCATIONID 
						      from EFORECAST_LOCATION (NOLOCK) 
						     where LOCATION = @location_filter))

-- v2.0		START
CREATE TABLE #tmp_orders
	(part_no		varchar(30)	NOT NULL,
	 location		varchar(10)	NOT NULL,
	 ordered		decimal(20,2) NOT NULL,
	 cr_ordered		decimal(20,2) NOT NULL,
	 date_shipped	datetime NULL,
	 part_type		varchar(1) NOT NULL,
	 order_no		int	NOT NULL,
	 order_ext		int	NOT NULL,
	 line_no		int NOT NULL
	)

INSERT INTO #tmp_orders
	SELECT ord_list.part_no, ord_list.location, ord_list.ordered * ord_list.conv_factor, ord_list.cr_ordered * ord_list.conv_factor, 
		orders_all.date_entered, ord_list.part_type, ord_list.order_no,
		ord_list.order_ext, ord_list.line_no
	FROM ord_list (NOLOCK), orders_all (NOLOCK)
	where orders_all.order_no = ord_list.order_no 
	and orders_all.ext = ord_list.order_ext 
	and ord_list.part_type in ('P', 'C')
	AND ord_list.status between 'N' AND 'Q'
	AND (@location_filter   = 'ALL' OR ord_list.location = @location_filter)
	AND (@all_dates = 'Y' OR datediff(day, orders_all.date_shipped, @start_date_filter) <= 0)
 	AND orders_all.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST) 
	AND orders_all.cust_code BETWEEN @cust_code_from AND @cust_code_to -- v1.0
	AND orders_all.user_category BETWEEN @order_type_from AND @order_type_to -- v1.0

INSERT INTO #tmp_orders
	SELECT ord_list.part_no, ord_list.location, 
		CASE orders_all.type WHEN 'I' THEN IsNull(ord_list.ordered,0) * IsNull(ord_list.conv_factor,1)
								 ELSE 0
		END,
		CASE orders_all.type WHEN 'C' THEN IsNull(ord_list.ordered,0) * IsNull(ord_list.conv_factor,1)
								 ELSE 0
		END,
		orders_all.date_shipped, ord_list.part_type,ord_list.order_no, ord_list.order_ext, ord_list.line_no
	FROM cvo_ord_list_hist ord_list (NOLOCK), cvo_orders_all_hist orders_all (NOLOCK)
	where orders_all.order_no = ord_list.order_no 
	and orders_all.ext = ord_list.order_ext 
	and ord_list.part_type in ('P', 'C')
	AND ord_list.status = 'T'
	AND ord_list.part_no in (select part_no from inv_master)
	AND (@location_filter   = 'ALL' OR ord_list.location = @location_filter)
	AND (@all_dates = 'Y' OR datediff(day, orders_all.date_shipped, @start_date_filter) <= 0)
 	--AND orders_all.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST) 
	AND orders_all.cust_code BETWEEN @cust_code_from AND @cust_code_to
	AND orders_all.user_category BETWEEN @order_type_from AND @order_type_to

--
-- CVO Use the Ordered Qty not Shipped
--
--v2.0
DECLARE ol_cursor CURSOR FOR
	SELECT part_no, location, ordered, cr_ordered, date_shipped, part_type, order_no, order_ext, line_no
	FROM #tmp_orders

--DECLARE ol_cursor CURSOR FOR
--	--SELECT ord_list.part_no, ord_list.location, ord_list.shipped * ord_list.conv_factor, ord_list.cr_shipped * ord_list.conv_factor, 
--	SELECT ord_list.part_no, ord_list.location, ord_list.ordered * ord_list.conv_factor, ord_list.cr_ordered * ord_list.conv_factor, 
--		orders_all.date_shipped, ord_list.part_type, ord_list.order_no,
--		ord_list.order_ext, ord_list.line_no
--	FROM ord_list, orders_all
--	where orders_all.order_no = ord_list.order_no 
--	and orders_all.ext = ord_list.order_ext 
--	and ord_list.part_type in ('P', 'C')
--	AND ord_list.status = 'T'
--	AND (@location_filter   = 'ALL' OR ord_list.location = @location_filter)
--	AND (@all_dates = 'Y' OR datediff(day, orders_all.date_shipped, @start_date_filter) <= 0)
-- 	AND orders_all.cust_code NOT IN (SELECT DISTINCT CUST_CODE FROM EFORECAST_CUSTOMER_FORECAST) 
--	AND orders_all.cust_code BETWEEN @cust_code_from AND @cust_code_to -- v1.0
--	AND orders_all.user_category BETWEEN @order_type_from AND @order_type_to -- v1.0
 
OPEN ol_cursor
FETCH NEXT FROM ol_cursor INTO @part_no, @location, @shipped, @cr_shipped, 
						@date_shipped, @part_type, @ord_no, @ord_ext, @ord_line
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC fs_eforecast_record_sale @part_no, @location, @date_shipped, @shipped , @cr_shipped, 0
	
	--record component parts for custom kits
	IF (@part_type = 'C') --this is a custom kit
	BEGIN
	--
	-- CVO Use the Ordered Qty not Shipped
	--
		DECLARE kit_cursor CURSOR LOCAL FOR 
			--SELECT part_no, location, shipped * qty_per * conv_factor, cr_shipped * qty_per * conv_factor
			SELECT part_no, location, ordered * qty_per * conv_factor, cr_ordered * qty_per * conv_factor
			from ord_list_kit
			where order_no = @ord_no 
			and order_ext = @ord_ext 
			and line_no = @ord_line 

		OPEN kit_cursor
		FETCH NEXT FROM kit_cursor INTO
			@part_no, @location, @shipped, @cr_shipped

		while @@FETCH_STATUS = 0
		begin
			EXEC fs_eforecast_record_sale @part_no, @location, @date_shipped, @shipped, @cr_shipped, 0
			FETCH NEXT FROM kit_cursor INTO
				@part_no, @location, @shipped, @cr_shipped
		end 
		close kit_cursor
		deallocate kit_cursor 
	end

	FETCH NEXT FROM ol_cursor INTO @part_no, @location, @shipped, @cr_shipped, 
						@date_shipped, @part_type, @ord_no, @ord_ext, @ord_line
END
CLOSE ol_cursor
DEALLOCATE ol_cursor

IF EXISTS (SELECT 1 FROM config WHERE flag = 'INV_LOSTSALES_HIST' and value_str = 'YES')
BEGIN
	DECLARE ls_cursor CURSOR FOR 
		SELECT part_no, location, qty * conv_factor, date_entered
		FROM lost_sales
		WHERE (@location_filter = 'ALL' OR location = @location_filter)
		AND (@all_dates = 'Y' OR datediff(day, date_entered, @start_date_filter) <= 0)
		
	open ls_cursor
	fetch next from ls_cursor into @part_no, @location, @shipped, @date_shipped
	while @@FETCH_STATUS = 0
	begin
		exec fs_eforecast_record_sale @part_no, @location, @date_shipped, @shipped, 0, 0
		fetch next from ls_cursor into @part_no, @location, @shipped, @date_shipped
	end
	close ls_cursor
	deallocate ls_cursor
END
 
DROP TABLE #tmp_orders

return 0







GO
GRANT EXECUTE ON  [dbo].[fs_populate_eforecast_tables] TO [public]
GO
