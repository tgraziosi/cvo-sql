SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			fs_show_price.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Displays prices for inventory items
Developer:		Chris Tyler
Date:			6th April 2011

Revision History
v1.1	CT	06/04/11	Changes from standard. Customer pricing for group now contains resource type and style. Price Class pricing for group may contains resource type and style
v1.2	CT	16/05/11	For Customer pricing resource type and style are no optional (same as Price Class pricing)
*/


CREATE PROCEDURE [dbo].[fs_show_price]
  @cust varchar(10), @shipto varchar(10), @clevel char(1),   @pn varchar(30),
  @loc varchar(10), @curr_key varchar(10), @curr_factor decimal(20,8) ,
  @svc_agr char(1), @in_qty decimal(20,8), @conv_factor decimal(20,8),
  @mask varchar(255)  AS

declare @price_list_curr varchar(10), @promo_type char(1),
  @i_method_price varchar(20), @i_method_promo varchar(20), @inv_cat varchar(10),
  @quote_type char(1), @qloop integer, @priceclass varchar(10),
  @apply_disc_promo varchar(3), @base_price_qty_breaks varchar(3),
  @customer_level_int tinyint, @promo_dt datetime,
  @qty_1 decimal(20,8), @qty_2 decimal(20,8),
  @qty_3 decimal(20,8), @qty_4 decimal(20,8), @qty_5 decimal(20,8),
  @price_1 decimal(20,8), @price_2 decimal(20,8),     @price_3 decimal(20,8),
  @price_4 decimal(20,8), @price_5 decimal(20,8),	@price_list_price decimal(20,8),
  @price decimal(20,8),   @quote_price decimal(20,8),     @tot_cost decimal(20,8),
  @promo_date datetime,   @promo_price decimal(20,8), 
  @promo_rate decimal(20,8), @static_price_1 decimal(20,8),
  @dt datetime, @promo_start_date datetime,   @home_curr varchar(10),
  @quote_curr varchar(10), @ilevel integer, @quote_level integer,
  @row_id int, @min_qty decimal(20,8), @cust_price decimal(20,8),
  @tot_orig_cost decimal(20,8),
  @org_id varchar(30),
  @loc_org_id varchar(30), @org_level int

declare @style		varchar(40)	-- v1.1
declare @res_type	varchar(10) -- v1.1

select
  @qty_1=0, @qty_2=0, @qty_3=0, @qty_4=0, @qty_5 = 0,
  @price=0, @price_1=0, @price_2=0,  @price_3=0, @price_4=0,  @price_5=0,
  @quote_price=0, @tot_cost=0, @tot_orig_cost = 0,
  @promo_rate=0, @promo_price=0

select @org_id = dbo.adm_get_locations_org_fn(@loc)
-- If @clevel is none of the valid values then set them to '?' and '1' respectively
if ( charindex( isnull( @clevel, '0' ), '12345PQ+-' ) = 0 ) select @clevel = '1'	--thl SCR 20368 08/18/1999

-- Security flag (order entry) settings are retrieved:
-- Method for calculating pricing setting: (CUSTOMER or QTY BREAKS)
select @i_method_price = isnull( (select value_str from config (nolock)
  where flag='OE_PRICING_METHOD' ), 'QTY' )
-- Method for applying promos (ASK, ASK ON NEW, AUTO, DISABLED, MANUAL)
select @i_method_promo = isnull( (select value_str from config (nolock)
  where flag='OE_PROMO_METHOD' ), 'MANUAL' )
-- Method for determining base price (list price) Either use qty breaks ('YES') or use qty 1 ('NO')
select @base_price_qty_breaks = (select value_str from config (nolock)
  where flag = 'OE_SPEC_PRICING')
-- Retrieve the customer's price class
-- customers can be assigned to a price class on the Maintain Customer Screen/ADM tab (ie WHLSE, RETAIL)
select @priceclass=isnull( (select price_code from adm_cust_all (nolock) 
  where customer_code=@cust),'')
-- Home currency is the currency used by the company that installed Distribution Suite
-- It has nothing to do with the customer's currency
-- Home currency is used if the transaction currency has no quotes
select @home_curr=isnull( (select home_currency from glco (nolock)),'')

-- Apply discount to promo prices setting
select 	@apply_disc_promo = isnull(( select value_str from config (nolock)
  where flag = 'OE_APPLY_DISC'),'')

-- skk 03/27/00 F.2.2.2 start
-- Price break quantities, prices, and promo info are stored in the part_price table.
-- The table is keyed on part number and currency so that an item can have a price list established
-- in multiple currencies.  There is ALWAYS a price list in the home currency, even if the 
-- prices are zero.
-- Check to see if a price list exists for the item in the transaction currency of this sales order
create table #breaks (
  rcd_type int, qloop int, customer_key varchar(10) null, ship_to_no varchar(10) null, 
  ilevel int null, item varchar(30) null, min_qty decimal(20,8) null, 
  type varchar(8) null, rate decimal(20,8) null, curr_key varchar(10) null, 
  start_date datetime null, end_date datetime null, promo_rate decimal(20,8) null, 
  price_level_price decimal(20,8), price_1 decimal(20,8), price decimal(20,8), 
  promo_dt datetime null, loc_org_id varchar(30) NULL, org_level int NULL, row_id int identity(1,1))

create index r1 on #breaks(rcd_type,row_id)

if @svc_agr = 'Y'
begin
  if exists (SELECT 1 from service_agreement_price (nolock) 
    where item_id = @pn and curr_code = @curr_key)
  begin
    SELECT  @price_1 = price
    FROM service_agreement_price (nolock)
    WHERE  item_id = @pn and curr_code = @curr_key
    select @price_list_curr = @curr_key
  end
  else
  begin
    SELECT  @price_1 = price
    FROM service_agreement_price (nolock)
    WHERE item_id = @pn and curr_code =  @home_curr
    select @price_list_curr = @home_curr
  end
end
else
begin
	SELECT	top 1 @qty_1 =		qty_a,
			@qty_2 =		qty_b,
			@qty_3 =		qty_c,
			@qty_4 =		qty_d,
			@qty_5 =		qty_e,
			@price_1 =		price_a,
			@price_2 = 		price_b,
			@price_3 =		price_c,
			@price_4 =		price_d,
			@price_5 =		price_e,
			@promo_type =	promo_type,
			@promo_rate =	promo_rate,
			@dt = 		promo_date_expires,
			@promo_start_date = promo_start_date ,
      @loc_org_id = loc_org_id,
      @org_level = org_level
	FROM part_price_vw
	WHERE	part_no = @pn and curr_key = @curr_key and active_ind = 1
    and (org_level = 0 or (org_level = 1 and loc_org_id = @org_id) or (org_level = 2 and loc_org_id = @loc))
  order by org_level desc

  	-- save the currency used for the price list
  if @@rowcount > 0
	  select @price_list_curr = @curr_key
  else
  begin
	SELECT	top 1 @qty_1 =		qty_a,
			@qty_2 =		qty_b,
			@qty_3 =		qty_c,
			@qty_4 =		qty_d,
			@qty_5 =		qty_e,
			@price_1 =		price_a,
			@price_2 = 		price_b,
			@price_3 =		price_c,
			@price_4 =		price_d,
			@price_5 =		price_e,
			@promo_type =	promo_type,
			@promo_rate =	promo_rate,
			@dt = 		promo_date_expires,
			@promo_start_date = promo_start_date ,
      @loc_org_id = loc_org_id,
      @org_level = org_level
	FROM part_price_vw
	WHERE	part_no = @pn and curr_key = @home_curr and active_ind = 1
    and (org_level = 0 or (org_level = 1 and loc_org_id = @org_id) or (org_level = 2 and loc_org_id = @loc))

	select @price_list_curr = @home_curr
  end
end
--skk 03/27/00 F.2.2.2 end

-- Set the static price 1 variable for 0 qty price
-- Save the price list currency in @quote_curr which is returned in the final select. It will be changed later in
-- this procedure if a quote is found in a different currency.  @quote_curr is returned
-- to the datawindow executing this procedure.
Select @static_price_1 = @price_1,
  @quote_curr = @price_list_curr

-- Make sure that promo info was found, if not then set the promo variable to 'N' (No Promo Price)
if @promo_type Is Null select @promo_type = 'N'
if @promo_rate Is Null select @promo_type = 'N'

-- Set the promotional price expiration date
-- promo type is either N=NONE, P=PRICE, or D=DISCOUNT
-- if promo type is Discount or Price then there must be an expiration date
if @promo_type in ('D','P')
begin
   -- If the user did not enter an expiration date then that promo price is good indefinitely
   -- so set the expiration date to today's date
   if @dt is Null select @dt = getdate()

   -- Make sure the time of the expiration is END OF DAY
   select @dt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+
              DateName(dd, @dt)+' 23:59:59'
   select @promo_date = @dt
end

-- Get the std costs and inventory category for the item
-- The inventory category is necessary for item specific quotes to be checked in the qloop
-- so the standard costs may as well be retrieved now also to limit the number of selects needed
-- inventory category is (FINISHED, EQUIP, CHEMICALS etc...)
-- skk 03/27/00 F.2.2.2 Removed price break and promo variables from this select

if @svc_agr = 'N' 
begin
  SELECT @tot_orig_cost = std_cost + std_direct_dolrs + std_ovhd_dolrs +
    std_util_dolrs, 
    @inv_cat=category
  FROM inventory (nolock)
  WHERE part_no = @pn AND location = @loc
end

-- START v1.1 - get additional fields of resource type and style
SELECT 
	@style = ISNULL(b.field_2,''),
	@res_type = ISNULL (a.type_code,'')
FROM
	dbo.inv_master a (NOLOCK)
INNER JOIN
	dbo.inv_master_add b (NOLOCK)
ON
	a.part_no = b.part_no
WHERE 
	a.part_no = @pn
-- END v1.1

-- Now verify that a price exists at the customer level 
-- If it doesn't exist then set the customer level to the highest level below the
-- customer level that does have a price
-- convert customer level to a number to make this easier
select @customer_level_int = CONVERT(tinyint, @clevel)
select @clevel = case
  when (@customer_level_int > 4 AND @price_5 <> 0) THEN '5'
  when (@customer_level_int > 3 AND @price_4 <> 0) THEN '4'
  when (@customer_level_int > 2 AND @price_3 <> 0) THEN '3'
  when (@customer_level_int > 1 AND @price_2 <> 0) THEN '2'
  else '1'
  end -- end case

-- SCENARIO 1: If qty breaks are to be used and pricing method is 'CUSTOMER' then choose highest price level
--             that qualifies, the minimum level possible is the customer level
if ((@i_method_price = 'CUSTOMER') AND (@base_price_qty_breaks = 'YES')) 
begin
  select @cust_price = case
	 when @clevel = '5' then @price_5
       	 when @clevel = '4' then @price_4
       	 when @clevel = '3' then @price_3
       	 when @clevel = '2' then @price_2
       	 else @price_1 end -- end case
  -- If customer level is better than the qty break level then use the customer level

  select @qty_1 = 0
  if @clevel = 1
    insert #breaks (
      rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
      rate, curr_key, start_date, end_date,
      promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
    select 0, 99, '','',0,@pn,0,'I1', @price_1 ,@price_list_curr,NULL,NULL,
      @promo_rate, 0, @static_price_1, 0, @loc_org_id, @org_level

  if @clevel <= 2
    insert #breaks (
      rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
      rate, curr_key, start_date, end_date,
      promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
    select 0, 99, '','',0,@pn,case when @clevel < 2 then @qty_2 else 0 end,'I2',
      @price_2 ,@price_list_curr,NULL,NULL, @promo_rate, 0, @static_price_1, 0,
      @loc_org_id, @org_level
  if @clevel <= 3
    insert #breaks (
      rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
      rate, curr_key, start_date, end_date,
      promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
    select 0, 99, '','',0,@pn,case when @clevel < 3 then @qty_3 else 0 end,'I3',
      @price_3 ,@price_list_curr,NULL,NULL, @promo_rate, 0, @static_price_1, 0,
      @loc_org_id, @org_level

  if @clevel <= 4
    insert #breaks (
      rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
      rate, curr_key, start_date, end_date,
      promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
    select 0, 99, '','',0,@pn,case when @clevel < 4 then @qty_4 else 0 end,'I4',
      @price_4 ,@price_list_curr,NULL,NULL, @promo_rate, 0, @static_price_1, 0,
      @loc_org_id, @org_level

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,case when @clevel < 5 then @qty_5 else 0 end,'I5',
    @price_5,@price_list_curr,NULL,NULL, @promo_rate, 0, @static_price_1, 0,
      @loc_org_id, @org_level

  select @qty_1 = 0,
    @qty_2 = case when @clevel < 2 then @qty_2 else 0 end,
    @qty_3 = case when @clevel < 3 then @qty_3 else 0 end,
    @qty_4 = case when @clevel < 4 then @qty_4 else 0 end,
    @qty_5 = case when @clevel < 5 then @qty_5 else 0 end,
    @price_1 = @cust_price,
    @price_2 = case when @clevel < 2 then @price_2 else @cust_price end,
    @price_3 = case when @clevel < 3 then @price_3 else @cust_price end,
    @price_4 = case when @clevel < 4 then @price_4 else @cust_price end,
    @price_5 = case when @clevel < 5 then @price_5 else @cust_price end

  update #breaks
  set price_level_price = rate, price = rate
end -- end Scenario 1

--SCENARIO 2: If qty breaks are NOT to be used and pricing method is 'CUSTOMER' then choose better of qty_1 and customer level
if ((@i_method_price = 'CUSTOMER') AND (@base_price_qty_breaks = 'NO'))
begin
  select @cust_price = case
	 when @clevel = '2' then @price_2
	 when @clevel = '3' then @price_3
	 when @clevel = '4' then @price_4
	 when @clevel = '5' then @price_5
	 else @price_1
	 end

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,0,'I1', @cust_price ,@price_list_curr,NULL,NULL,
    @promo_rate, @cust_price, @static_price_1, @cust_price, @loc_org_id, @org_level


  select @qty_1 = 0, @qty_2 = 0, @qty_3 = 0, @qty_4 = 0, @qty_5 = 0,
    @price_1 = @cust_price, @price_2 = @cust_price, @price_3 = @cust_price, 
    @price_4 = @cust_price, @price_5 = @cust_price
end --end Scenario 2

--SCENARIO 3: If qty breaks are to be used and pricing method is 'QTY BREAKS' then just use qty breaks
if ((@i_method_price = 'QTY') AND (@base_price_qty_breaks = 'YES'))
begin
  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,0,'I1',@price_1,@price_list_curr,NULL,NULL,
    @promo_rate, 0, @price_1, 0, @loc_org_id, @org_level

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,@qty_2,'I2',@price_2,@price_list_curr,NULL,NULL,
    @promo_rate, 0, @price_1, 0, @loc_org_id, @org_level

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,@qty_3,'I3',@price_3,@price_list_curr,NULL,NULL,
    @promo_rate, 0, @price_1, 0, @loc_org_id, @org_level

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,@qty_4,'I4',@price_4,@price_list_curr,NULL,NULL,
    @promo_rate, 0, @price_1, 0, @loc_org_id, @org_level

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,@qty_5,'I5',@price_5,@price_list_curr,NULL,NULL,
    @promo_rate, 0, @price_1, 0, @loc_org_id, @org_level

  update #breaks
  set price_level_price = rate, price = rate
end --end Scenario 3

--SCENARIO 4: If qty breaks are not to be used and pricing method is 'QTY BREAKS' then just use price 1
if ((@i_method_price = 'QTY') AND (@base_price_qty_breaks = 'NO'))
begin

  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
  select 0, 99, '','',0,@pn,0,'I5',@price_1,@price_list_curr,NULL,NULL,
    @promo_rate, @price_1, @price_1, 0, @loc_org_id, @org_level

  select @price_2 = @price_1, @price_3 = @price_1, @price_4 = @price_1, 
    @price_5 = @price_1
end --end Scenario 4


declare @expdt datetime										-- mls 6/4/04 SCR 32928

select @qloop = 1, @dt = getdate()
select @dt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+
           DateName(dd, @dt)+' 23:59:59'
select @expdt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+					-- mls 6/4/04 SCR 32928
           DateName(dd, @dt)+' 00:00:00'

while @qloop <= 6
begin
  -- Determine if @cust should be the actual customer key, if it should be set to the priceclass
  -- for this customer or if it should be set to ALL. If it is set to the actual customer then there
  -- are customer specific quotes. If it is set to the priceclass then there are quotes for the price
  -- class that this customer belongs to. Otherwise the customer is set to 'ALL'. These values are 
  -- set according to the value of @qloop which was set in the above step that checked for quote existence.
  -- NOTE THIS IS THE HIERARCHY OF PRICING:
  -- Customer Specific Pricing Is Highest Priority
  -- Price Class Specific Pricing Is Next Priority
  -- Pricing For 'ALL' Customers is Third Priority
  select @cust = case
                  when @qloop <= 4 then @cust  -- qloop 1 through 4 are Customer specific quotes
                  when @qloop = 5  then @priceclass   -- qloop 5 is a priceclass quote
                  else 'ALL'
                  end,
    @shipto = case
                when @qloop <= 2 then @shipto   -- qloop 1 and 2 are ship-to specific quotes
                when @qloop = 5 then '*TYPE*' -- qloop 5 is a priceclass quote so ship_to = *TYPE*
                else 'ALL'
              end,
    @quote_curr = case
       when @qloop = 1 or @qloop = 3 then @curr_key  -- qloop 1 and 3 are currency specific quotes
				  	 	     -- in the transaction currency from Sales Order
       else @home_curr -- otherwise the home currency is used
       end
	
  -- Select the maximum "min_qty" value of all quotes for customer_key, ship_to, ilevel of 0(Item Specific Quote),
  -- item will be a part no, the minimum qty requirement on the quote must be less than or equal to the qty
  -- ordered 
  -- In short this returns the best "item-specific" quote that the qty ordered qualifies for
  insert #breaks (
    rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, end_date,
    promo_rate, price_level_price, price_1, price)
  select 0,@qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
    rate, curr_key, start_date, date_expires,
    @promo_rate, case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
    when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
    when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
    when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
    else @price_1 end, @static_price_1, 0
  from c_quote
  where ( customer_key = @cust AND ship_to_no = @shipto ) AND
    ilevel = 0 AND item = @pn AND  curr_key = @quote_curr AND
    date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928

  -- Select the price and other info from the quote with the "min_qty" value that was met in the previous select
  -- This will be Item Specific pricing

  -- If no item specific quotes were found then check for inventory category quotes (FINISHED, EQUIP, CHEMICALS etc...)
  -- using ilevel = 1 in the query

  -- START v1.2 - CVO bespoke for group level, for ShipTo (qloop 1 or 2), Customer (qloop 3 or 4) or Price Class (qloop 5), style and res_type may be set so should be 
  -- factored in. For other pricing (qloop >5), style and res_type must not be factored in

  -- v1.2 - commenting, now done in loop below
--  IF @qloop <=4 -- ShipTo or Customer
--  BEGIN
--	  insert #breaks (
--		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
--		rate, curr_key, start_date, end_date,
--		promo_rate, price_level_price, price_1, price)
--	  select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
--		rate, curr_key, start_date, date_expires,
--		@promo_rate, 
--		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
--		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
--		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
--		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
--		else @price_1 end, @static_price_1, 0
--	  from   c_quote
--	  where  ( customer_key = @cust AND ship_to_no = @shipto ) AND
--		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
--		date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928
--		AND ISNULL(style,'') = @style
--		AND ISNULL(res_type,'') = @res_type
--  END
--
--  IF @qloop = 5 -- Price Class
  -- v1.2 end of commenting out

  IF @qloop <= 5 -- Price Class
  -- END v1.2
  BEGIN
	-- There are multiple quotes here:
	-- 1. Group/Style/Resource Type
	insert #breaks (
		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, end_date,
		promo_rate, price_level_price, price_1, price)
	select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, date_expires,
		@promo_rate, 
		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
		else @price_1 end, @static_price_1, 0
    from  c_quote
    where ( customer_key = @cust AND ship_to_no = @shipto ) AND
		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
		date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928
		AND ISNULL(style,'') = @style
		AND ISNULL(res_type,'') = @res_type

	-- 2. Group/Style
	insert #breaks (
		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, end_date,
		promo_rate, price_level_price, price_1, price)
	select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, date_expires,
		@promo_rate, 
		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
		else @price_1 end, @static_price_1, 0
    from  c_quote
    where ( customer_key = @cust AND ship_to_no = @shipto ) AND
		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
		date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928
		AND ISNULL(style,'') = @style
		AND ISNULL(res_type,'') = ''

	-- 3. Group/Resource Type
	insert #breaks (
		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, end_date,
		promo_rate, price_level_price, price_1, price)
	select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, date_expires,
		@promo_rate, 
		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
		else @price_1 end, @static_price_1, 0
    from  c_quote
    where ( customer_key = @cust AND ship_to_no = @shipto ) AND
		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
		date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928
		AND ISNULL(style,'') = ''
		AND ISNULL(res_type,'') = @res_type

	-- 4. Group
	insert #breaks (
		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, end_date,
		promo_rate, price_level_price, price_1, price)
	select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, date_expires,
		@promo_rate, 
		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
		else @price_1 end, @static_price_1, 0
    from  c_quote
    where ( customer_key = @cust AND ship_to_no = @shipto ) AND
		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
		date_expires >= @expdt and start_date <= @dt						-- mls 6/4/04 SCR 32928
		AND ISNULL(style,'') = ''
		AND ISNULL(res_type,'') = ''
  END

  IF @qloop > 5 -- Other
  BEGIN
	  insert #breaks (
		rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, end_date,
		promo_rate, price_level_price, price_1, price)
	  select 0, @qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
		rate, curr_key, start_date, date_expires,
		@promo_rate, 
		case when (@qty_5 > 0 and min_qty >= @qty_5) then @price_5
		when (@qty_4 > 0 and min_qty >= @qty_4) then @price_4
		when (@qty_3 > 0 and min_qty >= @qty_3) then @price_3
		when (@qty_2 > 0 and min_qty >= @qty_2) then @price_2
		else @price_1 end, @static_price_1, 0
	  from   c_quote
	  where  ( customer_key = @cust AND ship_to_no = @shipto ) AND
		ilevel = 1 AND item = @inv_cat AND  curr_key = @quote_curr AND
		date_expires >= @expdt and start_date <= @dt
  END

  update #breaks
  set price = price_level_price
  where qloop = @qloop

  -- Increment loop counter and start loop over
  select @qloop = @qloop + 1
END -- end quote loop

insert #breaks (
  rcd_type, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
  rate, curr_key, start_date, end_date,
  promo_rate, price_level_price, price_1, price, loc_org_id, org_level)
select 1, qloop, customer_key, ship_to_no, ilevel,item, min_qty, type,
  rate, curr_key, start_date, end_date,
  @promo_rate, price_level_price, price_1, price, loc_org_id, org_level
from #breaks
order by min_qty,qloop,ilevel

select @row_id = isnull((select min(row_id) from #breaks where rcd_type = 1),0)
while @row_id <> 0
begin
  select @qloop = qloop,
    @ilevel = ilevel,
    @min_qty = min_qty,
    @quote_curr = curr_key,
    @quote_type = case when qloop <=6 then substring(type,1,1) else '' end,
    @quote_price = rate,
    @price = price,
    @price_list_price = price_level_price,
    @price_1 = price_1,
    @promo_rate = promo_rate
  from #breaks 
  where row_id = @row_id

  select @tot_cost = @tot_orig_cost
  if @qloop <= 6
  begin
    if ((@quote_curr <> @home_curr) AND ((@quote_type = 'C') OR (@quote_type = '+'))) 
    begin -- RODNEY CHANGE 7/11/00
        select @tot_cost = 
          case when @curr_factor > 0
            then @tot_cost / ABS(@curr_factor)
            else @tot_cost * abs(@curr_factor)
          end
    end -- end Cost Plus Amount conversion

    -- If the quote currency is not the same as the price list currency then adjust the price from the price list
    -- by the currency factor as well as the price_list_price and the promo price if it is a fixed price
    if @price_list_curr <> @quote_curr 
    begin
      -- If the currency factor is a positive number then multiply, if not then divide
      if @curr_factor <= 0 									-- mls 1/6/04 SCR 31602
      begin
        select @price = @price * abs(@curr_factor),
	  @price_list_price = @price_list_price * abs(@curr_factor),
	  @price_1 = @price_1 * abs(@curr_factor)
	if @promo_type = 'P' 
          select @promo_rate = @promo_rate * abs(@curr_factor)
      end
      else
      begin
        select @price = @price / ABS(@curr_factor),
          @price_list_price = @price_list_price / ABS(@curr_factor),
          @price_1 = @price_1 / ABS(@curr_factor)
        if @promo_type = 'P' 
          select @promo_rate = @promo_rate / ABS(@curr_factor)
      end
    end

    if @quote_type = 'P'  
      select @price = @quote_price -- price type is Fixed Price so just use quote price
    else if @quote_type = 'L'  
      select @price = (@price - @quote_price) -- price type is List Minus Amount so deduct quote rate from base price
    else if @quote_type = 'C'  
      select @price = (@tot_cost + @quote_price) -- price type is Cost plus amount so add quote rate to total cost
    -- price type is List Minus Percent so reduce base price by quote rate percent
    else if @quote_type = '-'  
      select @price = @price - ( ceiling( @price * @quote_price * 100 ) / 10000 )
    -- price type is Cost plus percent so add quote rate percent to total cost
    else if @quote_type = '+'  
      select @price = @tot_cost + ( ceiling( @tot_cost * @quote_price * 100 ) / 10000 )
    else select @price = -1
  end

  select @promo_price=0, @promo_dt = NULL
  -- If the promo type is either Price(P) or Discount(D) then set the promo price to be returned
  if @promo_type = 'P' or @promo_type = 'D'  
  begin
    -- Make sure the promo has not expired. If it has then do not set the promo price.
    if (@promo_date >= getdate() AND @promo_start_date <= getdate()) 
    begin 
      -- DISCOUNT PROMO SECTION
      if @promo_type = 'D' 
      begin  
        -- If apply discount to promo flag is yes then adjust promo price accordingly
        if @apply_disc_promo = 'YES' 
        begin
          -- Make sure quote type is a type that can be applied to promo pricing
          if @quote_type = 'L' OR @quote_type = '-' 
            select @promo_price = @price - ( ceiling(@price * @promo_rate * 100) / 10000 )
          else -- use the qty break list price as the base price for the promo discount
          begin
            -- if use qty breaks is set to 'YES' then use price list price 
            if @base_price_qty_breaks = 'YES' 
              select @promo_price = 
                case when @base_price_qty_breaks = 'YES'
                  then @price_list_price - ceiling( @price_list_price * @promo_rate * 100 ) / 10000
                  else @price_1 - ceiling( @price_1 * @promo_rate * 100 ) / 10000
                end
          end
        end
        else 
        begin -- compute promo price normally without applying special pricing
	      -- If qty breaks-base price setting is 'YES' then use price list price as base price for promo
          if @base_price_qty_breaks = 'YES' 
            select @promo_price = 
              case when @base_price_qty_breaks = 'YES'
                then @price_list_price - ceiling( @price_list_price * @promo_rate * 100 ) / 10000
                else @price_1 - ceiling( @price_1 * @promo_rate * 100 ) / 10000
              end
        end -- end apply_disc_promo = 'YES'
      end -- end if @promo_type = 'D'

      if @promo_type = 'P' 
      begin 
        -- If apply discount to promo flag is yes then adjust promo price accordingly
        select @promo_price = @promo_rate
        if @apply_disc_promo = 'YES' 
          select @promo_price = case
            when @quote_type='L' then @promo_rate - @quote_price
            when @quote_type='-' then @promo_rate - (ceiling(@promo_rate * @quote_price * 100) / 10000)
            else @promo_rate
          end -- end case
      end -- end if @promo_type = 'P'
      if @promo_price > 0 
      begin
        select @promo_dt = @promo_date
        -- if method for applying promos is AUTO then set price to promo price
        if @i_method_promo = 'AUTO' 
          select @price   = @promo_price
      end -- end if @promo_price > 0
    end -- end if (@promo_date >= getdate() AND @promo_start_date <= getdate())
  end -- end if @promo_type = 'P' or @promo_type = 'D'
  

  
  if @curr_key <> @quote_curr 
  begin
    if @curr_factor > 0 
      select @price = @price / ABS(@curr_factor),
	@promo_price = @promo_price / ABS(@curr_factor),
	@quote_curr = @curr_key
    else 
      select @price = @price * ABS(@curr_factor),
        @promo_price = @promo_price * ABS(@curr_factor),
        @quote_curr = @curr_key
  end

  update #breaks
  set promo_rate = @promo_price,
    price = @price,
    price_level_price = @price_list_price,
    price_1 = @price_1,
    promo_dt = @promo_dt
  where row_id = @row_id

  delete #breaks
    where rcd_type = 1 and row_id > @row_id and qloop > @qloop 
  delete #breaks
    where rcd_type = 1 and row_id > @row_id and qloop = @qloop and ilevel > @ilevel
  delete #breaks
    where rcd_type = 1 and row_id > @row_id and qloop = @qloop and min_qty = @min_qty

  select @row_id = isnull((select min(row_id) from #breaks
    where rcd_type = 1 and row_id > @row_id),0)
end


-- If a qualifying quote was not found then quote variables are set to 0
-- and quote_curr is set back to price list currency
update #breaks
set price = price * @conv_factor,
  promo_rate = promo_rate * @conv_factor,
  min_qty = min_qty / @conv_factor
where rcd_type = 1

select 
  case 
    when qloop = 99 then 
       case when @org_level = 2 then 'Inventory Location Price'
         when @org_level = 1 then 'Inventory Organization Price'
         else 'Inventory Base Price' end
    when qloop < 5 then 
      case when ilevel = 0 then 'Customer Quote on Item'
        else 'Customer Quote on Group (' + item + ')'  
      end
    when qloop = 5 then 
      case when ilevel = 0 then 'Price Class (' + customer_key + ') Quote on Item'
        else 'Price Class ('  + customer_key +  ') Quote on Group (' + item + ')'
      end
    else '' 
  end,
  price, promo_rate, min_qty, customer_key, ship_to_no, ilevel, 
  item, start_date, end_date, type , qloop, rate, curr_key, promo_dt,
  case when min_qty <= (@in_qty / @conv_factor) then 1 else 0 end curr_ind,
  @pn in_part, @loc in_loc, @mask curr_mask
from #breaks
where rcd_type = 1
order by row_id

GO
GRANT EXECUTE ON  [dbo].[fs_show_price] TO [public]
GO
