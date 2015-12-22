SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			fs_get_price.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Gets price for inventory items
Developer:		Chris Tyler
Date:			17th March 2011

Revision History
v1.1	CT	17/03/11	Changes from standard. Customer pricing for group now contains resource type and style. Price Class pricing for group may contains resource type and style
v1.2	CT	16/05/11	For Customer pricing resource type and style are no optional (same as Price Class pricing)
v1.3	CB	19/10/11	Performance
v1.4	CB	09/01/12	Request to round the price returned to 2 decimal places (T McGrady)
v1.5	CT	03/07/13	Issue #863 - If called from discount adjutsment screen, then get price class from temporary table
*/


CREATE PROCEDURE [dbo].[fs_get_price]
                 @cust varchar(10), @shipto varchar(10),
                 @clevel char(1),   @pn varchar(30),
                 @loc varchar(10),  @plevel char(1),
                 @qty money,        @pct money,
                 @curr_key varchar(10), @curr_factor decimal(20,8) ,@svc_agr char(1)  AS


declare @price_list_level char(1),	 @price_list_curr varchar(10), 	@price_level char(1)
declare @promo_type char(1),              @qflag char(1)
declare @i_method_price varchar(20), @i_method_promo varchar(20)
declare @next_type char(1),          @next_qty decimal(20,8)
declare @next_price decimal(20,8),   @inv_cat varchar(10)
declare @quote_type char(1)
declare @qloop integer,              @priceclass varchar(10)
declare @apply_disc_promo varchar(3) -- F.2.3.2
declare @base_price_qty_breaks varchar(3) -- F.2.3.2
declare @customer_level_int tinyint
declare @style		varchar(40)	-- v1.1
declare @res_type	varchar(10) -- v1.1

declare @qty_1 decimal(20,8), @qty_2 decimal(20,8)
declare @qty_3 decimal(20,8), @qty_4 decimal(20,8)
declare @qty_5 decimal(20,8),	@quote_qty decimal(20,8)
declare @quote_count decimal(20,8),  @mqty  decimal(20,8)

declare @price_1 decimal(20,8), @price_2 decimal(20,8),     @price_3 decimal(20,8)
declare @price_4 decimal(20,8), @price_5 decimal(20,8),	@price_list_price decimal(20,8)
declare @price decimal(20,8),   @quote_price decimal(20,8),     @tot_cost decimal(20,8)
declare @promo_date datetime,   @promo_price decimal(20,8), @quote_comm decimal(20,8)
declare @sales_comm decimal(20,8),   @promo_rate decimal(20,8), @static_price_1 decimal(20,8)

declare @std_cost decimal(20,8),       @std_direct_dolrs decimal(20,8)
declare @std_ovhd_dolrs decimal(20,8), @std_util_dolrs decimal(20,8)

declare @dt datetime, @promo_start_date datetime,   @home_curr varchar(10), @quote_curr varchar(10)
declare @ilevel integer, @quote_level integer
declare @org_id varchar(30)

select @quote_count=0
select @qty_1=0, @qty_2=0
select @qty_3=0, @qty_4=0
select @qty_5=0

select @sales_comm=0,    @quote_comm=0
select @price=0,    @price_1=0
select @price_2=0,  @price_3=0

select @price_4=0,  @price_5=0
select @quote_price=0

select @tot_cost=0
select @std_cost=0,       @std_direct_dolrs=0
select @std_ovhd_dolrs=0, @std_util_dolrs=0

select @next_type='',     @next_qty=0,          @next_price=0
select @promo_rate=0,     @promo_price=0,       @pct=0

select @org_id = dbo.adm_get_locations_org_fn(@loc)

-- If @plevel and @clevel are none of the valid values then set them to '?' and '1' respectively
if ( charindex( isnull( @plevel, '0' ), '12345PQ+-'  ) = 0 ) select @plevel = '?'	--thl SCR 20368 08/18/1999 -- rwd SCR 20866 added 'P' to list 10/6/99
if ( charindex( isnull( @clevel, '0' ), '12345PQ+-' ) = 0 ) select @clevel = '1'	--thl SCR 20368 08/18/1999

-- Security flag (order entry) settings are retrieved:
-- Method for calculating pricing setting: (CUSTOMER or QTY BREAKS)
select @i_method_price = isnull( (select value_str from config (NOLOCK) -- v1.3
                                 where flag='OE_PRICING_METHOD' ), 'QTY' )
-- Method for applying promos (ASK, ASK ON NEW, AUTO, DISABLED, MANUAL)
select @i_method_promo = isnull( (select value_str from config (NOLOCK) -- v1.3
                                 where flag='OE_PROMO_METHOD' ), 'MANUAL' )
-- Method for determining base price (list price) Either use qty breaks ('YES') or use qty 1 ('NO')
select @base_price_qty_breaks = (select value_str from config (NOLOCK) -- v1.3
					   where flag = 'OE_SPEC_PRICING')
-- Retrieve the customer's price class
-- customers can be assigned to a price class on the Maintain Customer Screen/ADM tab (ie WHLSE, RETAIL)

-- START V1.5 - if this is called by the discount adjustment routine, get customers price class from temp table
IF OBJECT_ID('tempdb..#cvo_discount_adjustment_pass_price_class') IS NOT NULL
BEGIN
	SELECT @priceclass = price_class FROM #cvo_discount_adjustment_pass_price_class
END
ELSE
BEGIN
	select @priceclass=isnull( (select price_code from adm_cust_all (NOLOCK) where customer_code=@cust),'') -- v1.3
END
-- END v1.5

-- Home currency is the currency used by the company that installed Distribution Suite
-- It has nothing to do with the customer's currency
-- Home currency is used if the transaction currency has no quotes
select @home_curr=isnull( (select home_currency from glco (NOLOCK)),'') -- v1.3

-- Apply discount to promo prices setting
   select 	@apply_disc_promo = value_str
   from	dbo.config (NOLOCK) -- v1.3
   where	flag = 'OE_APPLY_DISC'

-- skk 03/27/00 F.2.2.2 start
-- Price break quantities, prices, and promo info are stored in the part_price table.
-- The table is keyed on part number and currency so that an item can have a price list established
-- in multiple currencies.  There is ALWAYS a price list in the home currency, even if the 
-- prices are zero.
-- Check to see if a price list exists for the item in the transaction currency of this sales order

if @svc_agr = 'Y'
    begin
        if (SELECT count(*) from dbo.service_agreement_price (NOLOCK) where item_id = @pn and curr_code = @curr_key) <> 0 -- v1.3
   	    begin
	        SELECT  @price_1 = price
		FROM   dbo.service_agreement_price (NOLOCK) -- v1.3
		WHERE  item_id = @pn and curr_code = @curr_key
		select @price_list_curr = @curr_key
    	    end
        else
            begin
	        SELECT  @price_1 = price
	        FROM   dbo.service_agreement_price (NOLOCK) -- v1.3
	        WHERE	item_id = @pn and curr_code =  @home_curr
	        select @price_list_curr = @home_curr
           end
     end
else
begin

-- org_level, loc_org_id, curr_key

--if (SELECT count(*) from dbo.part_price where part_no = @pn and curr_key = @curr_key) <> 0
--    begin -- Get the price breaks and promotion info for the transaction currency
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
			@promo_start_date = promo_start_date 
	FROM part_price_vw (NOLOCK) -- v1.3
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
			@promo_start_date = promo_start_date 
	FROM part_price_vw (NOLOCK) -- v1.3
	WHERE	part_no = @pn and curr_key = @home_curr and active_ind = 1
    and (org_level = 0 or (org_level = 1 and loc_org_id = @org_id) or (org_level = 2 and loc_org_id = @loc))

	select @price_list_curr = @home_curr
  end
end
-- Set the static price 1 variable for 0 qty price
Select @static_price_1 = @price_1

-- Save the price list currency in @quote_curr which is returned in the final select. It will be changed later in
-- this procedure if a quote is found in a different currency.  @quote_curr is returned
-- to the datawindow executing this procedure.
select @quote_curr = @price_list_curr

-- Make sure that promo info was found, if not then set the promo variable to 'N' (No Promo Price)
if @promo_type Is Null select @promo_type = 'N'
if @promo_rate Is Null select @promo_type = 'N'

-- Set the promotional price expiration date
-- promo type is either N=NONE, P=PRICE, or D=DISCOUNT
-- if promo type is Discount or Price then there must be an expiration date
if @promo_type = 'D' OR @promo_type = 'P' begin
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

-- v1.3
SELECT	@std_cost = l.std_cost, 
		@std_direct_dolrs = l.std_direct_dolrs,
		@std_ovhd_dolrs = std_ovhd_dolrs, 
		@std_util_dolrs= l.std_ovhd_dolrs,   
		@inv_cat = m.category
FROM	dbo.inv_master m (NOLOCK)
JOIN	dbo.inv_list l (NOLOCK)
ON		m.part_no = l.part_no	
WHERE	l.part_no = @pn 
AND		l.location = @loc

/* v1.3 Original
SELECT @std_cost=std_cost, @std_direct_dolrs=std_direct_dolrs,
       @std_ovhd_dolrs=std_ovhd_dolrs, @std_util_dolrs=std_util_dolrs,
       @inv_cat=category
FROM dbo.inventory
WHERE part_no = @pn AND location = @loc
*/

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

end
-- Get a total of all the std cost types
select @tot_cost = @std_cost + @std_direct_dolrs + @std_ovhd_dolrs +
                   @std_util_dolrs










-- First determine the price list level and price list price
select @price_list_level = case
				when @qty_5 > 0 and @qty >= @qty_5 then '5'
             		when @qty_4 > 0 and @qty >= @qty_4 then '4'
             		when @qty_3 > 0 and @qty >= @qty_3 then '3'
             		when @qty_2 > 0 and @qty >= @qty_2 then '2'
            		else '1' end,
	 @price_list_price = case
				when @qty_5 > 0 and @qty >= @qty_5 then @price_5
             		when @qty_4 > 0 and @qty >= @qty_4 then @price_4
             		when @qty_3 > 0 and @qty >= @qty_3 then @price_3
             		when @qty_2 > 0 and @qty >= @qty_2 then @price_2
             		else @price_1 end

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
  -- If customer level is better than the qty break level then use the customer level
  if @clevel > @price_list_level
  begin
  	select @price = case
			 when @clevel = '5' OR (@qty_5 > 0 and @qty >= @qty_5) then @price_5
             	 when @clevel = '4' OR (@qty_4 > 0 and @qty >= @qty_4) then @price_4
             	 when @clevel = '3' OR (@qty_3 > 0 and @qty >= @qty_3) then @price_3
             	 when @clevel = '2' OR (@qty_2 > 0 and @qty >= @qty_2) then @price_2
             	 else @price_1 end, -- end case
		 @price_level = case
			 when @clevel = '5' OR (@qty_5 > 0 and @qty >= @qty_5) then '5'
             	 when @clevel = '4' OR (@qty_4 > 0 and @qty >= @qty_4) then '4'
             	 when @clevel = '3' OR (@qty_3 > 0 and @qty >= @qty_3) then '3'
             	 when @clevel = '2' OR (@qty_2 > 0 and @qty >= @qty_2) then '2'
             	 else '1' end -- end case
  end --end @clevel > @price_list_level
  else -- qty break is better than customer level
  begin
	select @price 	  = @price_list_price,
	       @price_level = @price_list_level
  end
end -- end Scenario 1

--SCENARIO 2: If qty breaks are NOT to be used and pricing method is 'CUSTOMER' then choose better of qty_1 and customer level
if ((@i_method_price = 'CUSTOMER') AND (@base_price_qty_breaks = 'NO'))
begin
  if @clevel > '1' -- SCR 23759
  begin
  	select @price = case
		   	 when @clevel = '2' then @price_2
		  	 when @clevel = '3' then @price_3
		  	 when @clevel = '4' then @price_4
		   	 when @clevel = '5' then @price_5
		   end, -- end case
		 @price_level = @clevel
  end
  else -- no customer level so just use price 1
  begin
	select @price = @price_1,
		 @price_level = '1'
  end
end --end Scenario 2

--SCENARIO 3: If qty breaks are to be used and pricing method is 'QTY BREAKS' then just use qty breaks
if ((@i_method_price = 'QTY') AND (@base_price_qty_breaks = 'YES'))
begin
  select @price 	    = @price_list_price,
	   @price_level = @price_list_level
end --end Scenario 3

--SCENARIO 4: If qty breaks are not to be used and pricing method is 'QTY BREAKS' then just use price 1
if ((@i_method_price = 'QTY') AND (@base_price_qty_breaks = 'NO'))
begin
  select @price = @price_1,
	   @price_level = '1'
end --end Scenario 4


declare @expdt datetime										-- mls 6/4/04 SCR 32928

select @qloop=1
select @dt = getdate()
select @dt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+
           DateName(dd, @dt)+' 23:59:59'
select @expdt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+					-- mls 6/4/04 SCR 32928
           DateName(dd, @dt)+' 00:00:00'


-- Special Pricing By Customer takes precedence over all other special pricing
SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                       where dbo.c_quote.customer_key = @cust AND
	                       dbo.c_quote.ship_to_no = @shipto AND
                             dbo.c_quote.curr_key = @curr_key AND
                             dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			     dbo.c_quote.start_date <= @dt), 0 )


-- Same as above select except for home currency being used in where clause
if (@quote_count = 0 AND @curr_key <> @home_curr) begin
   select @qloop=2
   SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                          where dbo.c_quote.customer_key = @cust AND
	                          dbo.c_quote.ship_to_no = @shipto AND
					  dbo.c_quote.curr_key = @home_curr AND
                                dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			        dbo.c_quote.start_date <= @dt), 0 )
end


-- Quotes for this customer that are not specific to a ship-to and in the transaction currency
if @quote_count = 0 begin
   select @qloop=3
   select @shipto='ALL'
   SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                          where dbo.c_quote.customer_key = @cust AND
	                          dbo.c_quote.ship_to_no = @shipto AND
                                dbo.c_quote.curr_key = @curr_key AND
                                dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			        dbo.c_quote.start_date <= @dt), 0 )
end


-- Quotes for this customer that are not specific to a ship-to in the home currency
if @quote_count = 0 begin
   select @qloop=4
   select @shipto='ALL'
   SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                          where dbo.c_quote.customer_key = @cust AND
	                          dbo.c_quote.ship_to_no = @shipto AND
					  dbo.c_quote.curr_key = @home_curr AND
                                dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			        dbo.c_quote.start_date <= @dt), 0 )
end


-- Are there quotes for the Price Class that this customer belongs to
if @quote_count = 0 begin
   select @qloop=5
   select @shipto='*TYPE*'
   SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                          where dbo.c_quote.customer_key = @priceclass AND
	                          dbo.c_quote.ship_to_no = '*TYPE*' AND
                                dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			        dbo.c_quote.start_date <= @dt), 0 )
end


if @quote_count = 0 begin
   select @qloop=6
   select @shipto='ALL'
   SELECT @quote_count=isnull( (select count(*) from dbo.c_quote (NOLOCK) -- v1.3
                          where dbo.c_quote.customer_key = 'ALL' AND
	                          dbo.c_quote.ship_to_no = 'ALL' AND
                                dbo.c_quote.date_expires >= @expdt AND				-- mls 6/4/04 SCR 32928
			        dbo.c_quote.start_date <= @dt), 0 )
end

-- The qloop value determined by the if statements above is used to determine the 
-- @cust, @shipto and @quote_curr values below. 




-- Initialize loop variables
select @quote_price=-1
select @quote_level=0


-- The initial value of @qloop was set above in the check for quote existence section
-- The value of @qloop will determine the type of quotes that are retrieved
-- Each time through the loop a different type of quote is being retrieved

-- Loop until a price is retrieved (a maximum of 6 times as there are only 6 different types of quotes to look for)
while @qloop <= 6 and @quote_price < 0 begin

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
                  end
   select @shipto = case
                    when @qloop <= 2 then @shipto   -- qloop 1 and 2 are ship-to specific quotes
                    when @qloop = 5 then '*TYPE*' -- qloop 5 is a priceclass quote so ship_to = *TYPE*
                    else 'ALL'
                    end
   select @quote_curr = case
                      when @qloop = 1 or @qloop = 3 then @curr_key  -- qloop 1 and 3 are currency specific quotes
											  -- in the transaction currency from Sales Order
                      else @home_curr -- otherwise the home currency is used
                      end
	
   -- Select the maximum "min_qty" value of all quotes for customer_key, ship_to, ilevel of 0(Item Specific Quote),
   -- item will be a part no, the minimum qty requirement on the quote must be less than or equal to the qty
   -- ordered 
   -- In short this returns the best "item-specific" quote that the qty ordered qualifies for
   select @mqty = isnull(max(dbo.c_quote.min_qty), -1)
   from   dbo.c_quote (NOLOCK) -- v1.3
   where  ( dbo.c_quote.customer_key = @cust AND
            dbo.c_quote.ship_to_no = @shipto ) AND
            dbo.c_quote.ilevel = 0 AND
            dbo.c_quote.item = @pn AND  dbo.c_quote.curr_key = @quote_curr AND
            dbo.c_quote.min_qty <= @qty AND
            dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
            and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303

   -- Select the price and other info from the quote with the "min_qty" value that was met in the previous select
   -- This will be Item Specific pricing
   select @quote_level = 0 -- this matches ilevel (which indicates Item Specific Quotes (1) or Item Category Quotes (0))
   select @quote_price  = isnull(dbo.c_quote.rate, -1),
          @quote_type   = isnull(dbo.c_quote.type, ''),
          @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
          @quote_qty = isnull(dbo.c_quote.min_qty, -1)
   from   dbo.c_quote (NOLOCK) -- v1.3
   where  ( dbo.c_quote.customer_key = @cust AND
            dbo.c_quote.ship_to_no = @shipto ) AND
            dbo.c_quote.ilevel = 0 AND
            dbo.c_quote.item = @pn AND  dbo.c_quote.curr_key = @quote_curr AND
            dbo.c_quote.min_qty = @mqty AND
            dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
            and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303

   -- If no item specific quotes were found then check for inventory category quotes (FINISHED, EQUIP, CHEMICALS etc...)
   -- using ilevel = 1 in the query
   if @quote_price < 0 begin
      select @quote_level  = 1 -- @quote_level is equivalent to the ilevel column (0 is item specific, 1 is item category)

	-- START v1.2 - CVO bespoke for group level, for ShipTo (qloop 1 or 2), Customer (qloop 3 or 4) or Price Class (qloop 5), style and res_type may be set so must be factored in. 
	-- For other pricing (qloop >5), style and res_type must not be factored in

	-- START v1.1
	  -- v1.2 - commenting, now done in loop below
--	  IF @qloop <=4 -- ShipTo or Customer
--	  BEGIN
--		  select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
--		  from   dbo.c_quote
--		  where  ( dbo.c_quote.customer_key = @cust AND
--				dbo.c_quote.ship_to_no = @shipto ) AND
--				dbo.c_quote.ilevel = 1 AND
--				dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
--				dbo.c_quote.min_qty <= @qty AND
--				dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
--				and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
--				AND ISNULL(dbo.c_quote.style,'') = @style
--				AND ISNULL(dbo.c_quote.res_type,'') = @res_type
--
--		  select @quote_price  = isnull(dbo.c_quote.rate, -1),
--				 @quote_type   = isnull(dbo.c_quote.type, ''),
--				 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
--				 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
--		  from   dbo.c_quote
--		  where  ( dbo.c_quote.customer_key = @cust AND
--				   dbo.c_quote.ship_to_no = @shipto ) AND
--				   dbo.c_quote.ilevel = 1 AND
--				   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
--				   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
--				   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
--				   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
--				   AND ISNULL(dbo.c_quote.style,'') = @style
--				   AND ISNULL(dbo.c_quote.res_type,'') = @res_type
--	  END
--
--	  IF @qloop = 5 -- Price Class
	  -- v1.2 end of commenting out

	  IF @qloop <= 5 -- ShipTo, Customer or Price Class
	-- END v1.2
	  BEGIN

		 -- There are multiple checks to do here, find the first quote that matches from:
		 -- 1. Group/Style/Resource Type
		 -- 2. Group/Style
		 -- 3. Group/Resource Type
		 -- 4. Group

		 -- 1. Group/Style/Resource Type
		 select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
		 from   dbo.c_quote (NOLOCK) -- v1.3
		 where  ( dbo.c_quote.customer_key = @cust AND
				dbo.c_quote.ship_to_no = @shipto ) AND
				dbo.c_quote.ilevel = 1 AND
				dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
				dbo.c_quote.min_qty <= @qty AND
				dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
				and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				AND ISNULL(dbo.c_quote.style,'') = @style
				AND ISNULL(dbo.c_quote.res_type,'') = @res_type

		 select @quote_price  = isnull(dbo.c_quote.rate, -1),
				 @quote_type   = isnull(dbo.c_quote.type, ''),
				 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
				 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
		 from   dbo.c_quote (NOLOCK) -- v1.3
		 where  ( dbo.c_quote.customer_key = @cust AND
				   dbo.c_quote.ship_to_no = @shipto ) AND
				   dbo.c_quote.ilevel = 1 AND
				   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
				   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
				   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
				   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				   AND ISNULL(dbo.c_quote.style,'') = @style
				   AND ISNULL(dbo.c_quote.res_type,'') = @res_type

		-- 2. Group/Style
		IF @quote_price < 0
		BEGIN
			select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				dbo.c_quote.ship_to_no = @shipto ) AND
				dbo.c_quote.ilevel = 1 AND
				dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
				dbo.c_quote.min_qty <= @qty AND
				dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
				and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				AND ISNULL(dbo.c_quote.style,'') = @style
				AND ISNULL(dbo.c_quote.res_type,'') = ''

			select @quote_price  = isnull(dbo.c_quote.rate, -1),
				 @quote_type   = isnull(dbo.c_quote.type, ''),
				 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
				 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				   dbo.c_quote.ship_to_no = @shipto ) AND
				   dbo.c_quote.ilevel = 1 AND
				   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
				   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
				   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
				   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				   AND ISNULL(dbo.c_quote.style,'') = @style
				   AND ISNULL(dbo.c_quote.res_type,'') = ''
		END

		-- 3. Group/Resource Type
		IF @quote_price < 0
		BEGIN
			select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				dbo.c_quote.ship_to_no = @shipto ) AND
				dbo.c_quote.ilevel = 1 AND
				dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
				dbo.c_quote.min_qty <= @qty AND
				dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
				and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				AND ISNULL(dbo.c_quote.res_type,'') = @res_type
				AND ISNULL(dbo.c_quote.style,'') = ''

			select @quote_price  = isnull(dbo.c_quote.rate, -1),
				 @quote_type   = isnull(dbo.c_quote.type, ''),
				 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
				 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				   dbo.c_quote.ship_to_no = @shipto ) AND
				   dbo.c_quote.ilevel = 1 AND
				   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
				   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
				   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
				   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				   AND ISNULL(dbo.c_quote.res_type,'') = @res_type
				   AND ISNULL(dbo.c_quote.style,'') = ''
		END

		-- 4. Group
		IF @quote_price < 0
		BEGIN
			select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				dbo.c_quote.ship_to_no = @shipto ) AND
				dbo.c_quote.ilevel = 1 AND
				dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
				dbo.c_quote.min_qty <= @qty AND
				dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
				and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				AND ISNULL(dbo.c_quote.style,'') = ''
				AND ISNULL(dbo.c_quote.res_type,'') = ''

			select @quote_price  = isnull(dbo.c_quote.rate, -1),
				 @quote_type   = isnull(dbo.c_quote.type, ''),
				 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
				 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
			from   dbo.c_quote (NOLOCK) -- v1.3
			where  ( dbo.c_quote.customer_key = @cust AND
				   dbo.c_quote.ship_to_no = @shipto ) AND
				   dbo.c_quote.ilevel = 1 AND
				   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
				   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
				   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
				   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
				   AND ISNULL(dbo.c_quote.style,'') = ''
				   AND ISNULL(dbo.c_quote.res_type,'') = ''
		END

	  END

	  IF @qloop > 5
	  BEGIN

		select @mqty = isnull(max(dbo.c_quote.min_qty), -1)			-- mls 5/17/00 SCR 20944 start
		from   dbo.c_quote (NOLOCK) --  v1.3
		where  ( dbo.c_quote.customer_key = @cust AND
			dbo.c_quote.ship_to_no = @shipto ) AND
			dbo.c_quote.ilevel = 1 AND
			dbo.c_quote.item = @inv_cat AND  dbo.c_quote.curr_key = @quote_curr AND
			dbo.c_quote.min_qty <= @qty AND
			dbo.c_quote.date_expires >= @expdt							-- mls 6/4/04 SCR 32928
			and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303

		select @quote_price  = isnull(dbo.c_quote.rate, -1),
			 @quote_type   = isnull(dbo.c_quote.type, ''),
			 @quote_comm   = isnull(dbo.c_quote.sales_comm, -1),
			 @quote_qty    = isnull(dbo.c_quote.min_qty, -1)
		from   dbo.c_quote (NOLOCK) -- v1.3
		where  ( dbo.c_quote.customer_key = @cust AND
			   dbo.c_quote.ship_to_no = @shipto ) AND
			   dbo.c_quote.ilevel = 1 AND
			   dbo.c_quote.min_qty = @mqty AND					-- mls 5/17/00 SCR 20944
			   dbo.c_quote.item = @inv_cat AND dbo.c_quote.curr_key = @quote_curr AND
			   dbo.c_quote.date_expires >= @expdt						-- mls 6/4/04 SCR 32928
			   and dbo.c_quote.start_date <= @dt				-- mls 2/11/02 SCR 28303
	  END	
	  -- END v1.1
   end

  -- Increment loop counter and start loop over
  select @qloop = @qloop + 1
END -- end quote loop

-- If a qualifying quote was not found then quote variables are set to 0
-- and quote_curr is set back to price list currency
if @quote_price < 0 begin
   select @qloop   = 0
   select @quote_level = 0
   select @quote_curr = @price_list_curr
   -- If no quote was found and Pricing Scenario is 4 then reset the price to use qty breaks   SCR 24041
   if ((@i_method_price = 'QTY') AND (@base_price_qty_breaks = 'NO'))
	begin
	 select @price 	   = @price_list_price,
		  @price_level = @price_list_level
	end
end
else begin
   -- If the quote type is Cost Plus Amount then convert the total cost (standard costs) amount to transaction currency when applicable
   if ((@quote_curr <> @home_curr) AND ((@quote_type = 'C') OR (@quote_type = '+'))) begin -- RODNEY CHANGE 7/11/00
	if @curr_factor > 0 begin
	   select @tot_cost = @tot_cost / ABS(@curr_factor)
	end
	else begin
	   select @tot_cost = @tot_cost * abs(@curr_factor)	-- mls 8/7/02 SCR i389
	end
   end -- end Cost Plus Amount conversion
   -- If the quote currency is not the same as the price list currency then adjust the price from the price list
   -- by the currency factor as well as the price_list_price and the promo price if it is a fixed price
   if @price_list_curr <> @quote_curr begin
     -- If the currency factor is a positive number then multiply, if not then divide
     if @curr_factor <= 0 begin											-- mls 1/6/04 SCR 31602
  	   select @price = @price * ABS(@curr_factor),
		    @price_list_price = @price_list_price * ABS(@curr_factor),
		    @price_1 = @price_1 * ABS(@curr_factor)
	   if @promo_type = 'P' begin
		select @promo_rate = @promo_rate * ABS(@curr_factor)
	   end
     end
     else
     begin
	   select @price = @price / ABS(@curr_factor),
		    @price_list_price = @price_list_price / ABS(@curr_factor),
		    @price_1 = @price_1 / ABS(@curr_factor)
	   if @promo_type = 'P' begin
		select @promo_rate = @promo_rate / ABS(@curr_factor)
	   end

     end
   end
end

-- If a qualifying quote was found then apply the special pricing of the quote to the base price
if @quote_price >= 0 begin
   -- Set the qloop variable back to the value where a quote was found (it was incremented again at top of loop so 1 must 
   -- be subtracted)
   select @qloop = @qloop - 1
   -- set the price level to Q to indicate that the price returned is a quote price
   select @price_level = 'Q' -- SCR 24041
   -- set the sales commission variable to the quoted commission amount and apply special pricing to base price
   select @sales_comm = @quote_comm

   -- mls 1/15/02 SCR 27939  - removed case statement because it was rounding decimals to 6 positions
   if @quote_type = 'P'  select @price = @quote_price -- price type is Fixed Price so just use quote price
   else if @quote_type = 'L'  select @price = (@price - @quote_price) -- price type is List Minus Amount so deduct quote rate from base price
   else if @quote_type = 'C'  select @price = (@tot_cost + @quote_price) -- price type is Cost plus amount so add quote rate to total cost
   -- price type is List Minus Percent so reduce base price by quote rate percent
   else if @quote_type = '-'  select @price = @price - ( ceiling( @price * @quote_price * 100 ) / 10000 )
   -- price type is Cost plus percent so add quote rate percent to total cost
   else if @quote_type = '+'  select @price = @tot_cost + ( ceiling( @tot_cost * @quote_price * 100 ) / 10000 )
   else select @price = -1
end



-- Start out with no promo price
select @promo_price=0

-- If the promo type is either Price(P) or Discount(D) then set the promo price to be returned
if @promo_type = 'P' or @promo_type = 'D'  begin
   -- Make sure the promo has not expired. If it has then do not set the promo price.
   if (@promo_date >= getdate() AND @promo_start_date <= getdate()) begin 
      -- DISCOUNT PROMO SECTION
      if @promo_type = 'D' begin  
	   -- If apply discount to promo flag is yes then adjust promo price accordingly
	   if @apply_disc_promo = 'YES' begin
		set @quote_type = isnull(@quote_type,'')
		-- Make sure quote type is a type that can be applied to promo pricing
		if @quote_type = 'L' OR @quote_type = '-' begin
         		select @promo_price = @price - ( ceiling(@price * @promo_rate * 100) / 10000 )
		end
		else -- use the qty break list price as the base price for the promo discount
            begin
			-- if use qty breaks is set to 'YES' then use price list price 
			if @base_price_qty_breaks = 'YES' begin
				select @promo_price = @price - ceiling( @price * @promo_rate * 100 ) / 10000
			end
			-- otherwise use price1
			else begin
				select @promo_price = @price_1 - ceiling( @price_1 * @promo_rate * 100 ) / 10000
			end
		end
         end
         else begin -- compute promo price normally without applying special pricing
		-- If qty breaks-base price setting is 'YES' then use price list price as base price for promo
		if @base_price_qty_breaks = 'YES' begin
         		select @promo_price = @price - ceiling( @price * @promo_rate * 100 ) / 10000
		end
		else -- If qty breaks-base price setting is 'NO' then use price 1 as the base price for promo
		begin
			select @promo_price = @price_1 - ceiling( @price_1 * @promo_rate * 100 ) / 10000
		end -- end else
         end -- end apply_disc_promo = 'YES'
      end -- end if @promo_type = 'D'
  	-- END DISCOUNT PROMO SECTION

	-- FIXED PROMO PRICE SECTION
      if @promo_type = 'P' begin 
	   -- If apply discount to promo flag is yes then adjust promo price accordingly
	   if @apply_disc_promo = 'YES' begin
            select @promo_price = case
			 		   when @quote_type='L' then @promo_rate - @quote_price
					   when @quote_type='-' then @promo_rate - (ceiling(@promo_rate * @quote_price * 100) / 10000)
					   else @promo_rate
					   end -- end case
         end -- end if@apply_disc_promo
	   else
	   begin
		select @promo_price = @promo_rate
	   end
      end -- end if @promo_type = 'P'
	-- END FIXED PROMO PRICE SECTION
	
	--If a promo price exists
      if @promo_price > 0 begin
	   -- If method for applying promos is MANUAL/AUTO or price is currently 0
         if ((@price = 0) OR (@i_method_promo = 'MANUAL' OR @i_method_promo = 'AUTO')) begin -- SCR 20866 01/13/00 -- rduke 3/24/00 F.2.3.2 SCR 23331
	   	-- If price level from Sales Order is 'P' or if method for applying promos is AUTO then set price to promo price
            if @plevel  = 'P' or @i_method_promo = 'AUTO' begin
               select @price_level = 'P'
               select @price   = @promo_rate
            end
         end
      end -- end if @promo_price > 0
   end -- end if (@promo_date >= getdate() AND @promo_start_date <= getdate())
end -- end if @promo_type = 'P' or @promo_type = 'D'




-- SCR 23760
if @qty = 0  AND @i_method_promo <> 'ASK_NEW' begin -- SCR 25409
   select @promo_price = 0,
          @price = @static_price_1
   if @price_list_curr <> @curr_key begin
      select @quote_curr = @price_list_curr
   end
end




if @curr_key <> @quote_curr begin
   if @curr_factor > 0 begin 
	select @price = @price / ABS(@curr_factor),
		 @promo_price = @promo_price / ABS(@curr_factor),
		 @quote_curr = @curr_key
   end
   else begin -- SCR 23759
	select @price = @price * ABS(@curr_factor),
		 @promo_price = @promo_price * ABS(@curr_factor),
		 @quote_curr = @curr_key
   end
end





select @price_level 'plevel', ROUND(@price,2) 'price', @next_qty 'nextqty',
       @next_price 'nextprice', @promo_price 'promo', @sales_comm 'sales_comm',
       @qloop 'quote loop#', @quote_level 'quote level', @quote_curr 'curr_key'


GO
GRANT EXECUTE ON  [dbo].[fs_get_price] TO [public]
GO
