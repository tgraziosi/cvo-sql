SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			fs_get_i_price.sql
Type:			Stored Procedure
Called From:	Enterprise
Description:	Gets price for inventory items
Developer:		Chris Tyler
Date:			6th April 2011

Revision History
v1.1	CT	06/04/11	Changes from standard. Customer pricing for group now contains resource type and style. Price Class pricing for group may contains resource type and style
v1.2	CT	16/05/11	For Customer pricing resource type and style are no optional (same as Price Class pricing)
v1.3	CB	09/01/12	Request to round the price returned to 2 decimal places (T McGrady)
*/

CREATE PROCEDURE [dbo].[fs_get_i_price] 
                 @cust varchar(10), @shipto varchar(10), 
                 @clevel char(1),   @pn varchar(30),
                 @loc varchar(10),  @qty money  AS




declare @plevel char(1), @pct money
select @plevel=@clevel
select @pct=0

declare @plevel2 char(1),            @tlevel char(1)
declare @promo char(1),              @qflag char(1)
declare @i_method_price varchar(20), @i_method_promo varchar(20)
declare @next_type char(1),          @next_qty decimal(20,8)
declare @next_price decimal(20,8),   @inv_cat varchar(10)
declare @q_type char(1),             @q_item varchar(30)
declare @qloop integer,              @custtype varchar(10)

declare @qty_a decimal(20,8), @qty_b decimal(20,8) 
declare @qty_c decimal(20,8), @qty_d decimal(20,8)
declare @qty_e decimal(20,8), @qty_f decimal(20,8)
declare @qcnt decimal(20,8)

declare @price_a decimal(20,8), @price_b decimal(20,8),     @price_c decimal(20,8) 
declare @price_d decimal(20,8), @price_e decimal(20,8),     @price_f decimal(20,8)
declare @price decimal(20,8),   @q_price decimal(20,8),     @tot_cost decimal(20,8)
declare @promo_date datetime,   @promo_price decimal(20,8), @q_comm decimal(20,8)
declare @scomm decimal(20,8),   @promo_rate decimal(20,8)

declare @std_cost decimal(20,8),       @std_direct_dolrs decimal(20,8)
declare @std_ovhd_dolrs decimal(20,8), @std_util_dolrs decimal(20,8)

declare @dt datetime
declare @ilevel integer, @q_level integer

declare @style		varchar(40)	-- v1.1
declare @res_type	varchar(10) -- v1.1

select @qcnt=0
select @qty_a=0, @qty_b=0 
select @qty_c=0, @qty_d=0
select @qty_e=0, @qty_f=0

select @scomm=0,    @q_comm=0
select @price=0,    @price_a=0 
select @price_b=0,  @price_c=0 
select @price_d=0,  @price_e=0
select @price_f=0,  @q_price=0

select @tot_cost=0
select @std_cost=0,       @std_direct_dolrs=0
select @std_ovhd_dolrs=0, @std_util_dolrs=0

select @next_type='',     @next_qty=0,          @next_price=0
select @promo_rate=0,     @promo_price=0,       @pct=0


if @plevel Is Null or @plevel = '' begin
   select @plevel = '?'
end
if @clevel Is Null or @clevel = '' begin
   select @clevel = 'A'
end

select @plevel = case 
   when @plevel='?' or @plevel='A' or @plevel='B' or @plevel='C' or 
        @plevel='D' or @plevel='E' or @plevel='P' or @plevel='Q' or 
        @plevel='+' or @plevel='-' then @plevel
   else '?' end

select @clevel = case 
   when @clevel='B' or @clevel='C' or @clevel='D' or 
        @clevel='E' or @clevel='F' or @clevel='P' or 
        @clevel='Q' or @clevel='+' or @clevel='-' then @clevel
   else 'A' end

select @i_method_price = isnull( (select value_str from config
                                 where flag='OE_PRICING_METHOD' ), 'QTY' )
select @i_method_promo = isnull( (select value_str from config
                                 where flag='OE_PROMO_METHOD' ), 'MANUAL' )


if @plevel = '+' select @i_method_price = 'COST_PLUS'
if @plevel = '-' select @i_method_price = 'LIST_LESS'

select @tlevel = case 
   when (@plevel <> 'P' AND @plevel > @clevel) then @plevel
   else @clevel end


select @custtype=isnull( (select price_code from adm_cust_all where customer_code=@cust),'')

SELECT @qty_a=qty_a, @qty_b=qty_b, @qty_c=qty_c, 
       @qty_d=qty_d, @qty_e=qty_e, @qty_f=qty_f,
       @price_a=price_a, @price_b=price_b, @price_c=price_c, 

       @price_d=price_d, @price_e=price_e, @price_f=price_f,  
       @promo=promo_type, @promo_rate=promo_rate, 
       @dt=promo_date_expires,
       @std_cost=std_cost, @std_direct_dolrs=std_direct_dolrs, 
       @std_ovhd_dolrs=std_ovhd_dolrs, @std_util_dolrs=std_util_dolrs,
       @inv_cat=category
FROM dbo.inventory
WHERE part_no = @pn AND location = @loc

select @tot_cost = @std_cost + @std_direct_dolrs + @std_ovhd_dolrs + 
                   @std_util_dolrs

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

if @promo Is Null select @promo = 'N'
if @promo_rate Is Null select @promo = 'N'

if @promo = 'D' OR @promo = 'P' begin
	if @dt is Null select @dt = getdate()
   select @dt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+
              DateName(dd, @dt)+' 23:59:59'
	select @promo_date = @dt
end
else begin
   select @promo = 'N'
end

if @i_method_price = 'QTY' begin
   select @plevel2 = 'A'
   select @price   = case
             when @qty_f > 0 and @qty >= @qty_f then @price_f
             when @qty_e > 0 and @qty >= @qty_e then @price_e
             when @qty_d > 0 and @qty >= @qty_d then @price_d
             when @qty_c > 0 and @qty >= @qty_c then @price_c
             when @qty_b > 0 and @qty >= @qty_b then @price_b
             else @price_a end,
          @plevel2   = case
             when @qty_f > 0 and @qty >= @qty_f then 'F'
             when @qty_e > 0 and @qty >= @qty_e then 'E'
             when @qty_d > 0 and @qty >= @qty_d then 'D'
             when @qty_c > 0 and @qty >= @qty_c then 'C'
             when @qty_b > 0 and @qty >= @qty_b then 'B'
             else 'A' end
end

if @i_method_price = 'CUSTOMER' begin
   if @promo = 'N' AND @plevel = 'P' select @plevel = @clevel 
   select @price   = case
             when @tlevel = 'F' OR (@qty_f > 0 and @qty >= @qty_f) then @price_f
             when @tlevel = 'E' OR (@qty_e > 0 and @qty >= @qty_e) then @price_e
             when @tlevel = 'D' OR (@qty_d > 0 and @qty >= @qty_d) then @price_d
             when @tlevel = 'C' OR (@qty_c > 0 and @qty >= @qty_c) then @price_c
             when @tlevel = 'B' OR (@qty_b > 0 and @qty >= @qty_b) then @price_b
             else @price_a end,
          @plevel2 = case
             when @tlevel = 'F' OR (@qty_f > 0 and @qty >= @qty_f) then 'F'

             when @tlevel = 'E' OR (@qty_e > 0 and @qty >= @qty_e) then 'E'
             when @tlevel = 'D' OR (@qty_d > 0 and @qty >= @qty_d) then 'D'
             when @tlevel = 'C' OR (@qty_c > 0 and @qty >= @qty_c) then 'C'
             when @tlevel = 'B' OR (@qty_b > 0 and @qty >= @qty_b) then 'B'
             else 'A' end
end

if @i_method_price = 'COST_PLUS' begin
   select @plevel2 = '+'
   select @price   = @tot_cost + ceiling( @tot_cost * @pct * 100 ) / 10000
end
if @i_method_price = 'LIST_LESS' begin
   select @plevel2 = '-'
   select @price   = @price_a - ceiling( @price_a * @pct * 100 ) / 10000
end


select @qloop=1
select @dt = getdate()
select @dt=DateName(yy, @dt)+'-'+DateName(mm, @dt)+'-'+
           DateName(dd, @dt)+' 23:59:59'

-- Customer and ship_to
SELECT @qcnt=isnull( (select count(*) from dbo.c_quote  
                       where dbo.c_quote.customer_key = @cust AND  
	                     dbo.c_quote.ship_to_no = @shipto AND
                             dbo.c_quote.date_expires >= @dt), 0 )

-- Customer and no ship_to
if @qcnt = 0 begin 
   select @qloop=2
   select @shipto='ALL'
   SELECT @qcnt=isnull( (select count(*) from dbo.c_quote  
                          where dbo.c_quote.customer_key = @cust AND  
	                        dbo.c_quote.ship_to_no = @shipto AND
                                dbo.c_quote.date_expires >= @dt), 0 )
end

-- Price class
if @qcnt = 0 begin 
   select @qloop=3
   select @shipto='*TYPE*'
   SELECT @qcnt=isnull( (select count(*) from dbo.c_quote  
                          where dbo.c_quote.customer_key = @custtype AND  
	                        dbo.c_quote.ship_to_no = '*TYPE*' AND
                                dbo.c_quote.date_expires >= @dt), 0 )
end


if @qcnt = 0 begin 
   select @qloop=4
   select @shipto='ALL'
   SELECT @qcnt=isnull( (select count(*) from dbo.c_quote  
                          where dbo.c_quote.customer_key = 'ALL' AND  
	                        dbo.c_quote.ship_to_no = 'ALL' AND
                                dbo.c_quote.date_expires >= @dt), 0 )
end

if @qcnt = 0 select @qloop=5

select @q_price=-1
select @q_level=0

while @qloop <= 4 and @q_price < 0 begin

   select @cust = case
                  when @qloop <= 2 then @cust
                  when @qloop = 3  then @custtype
                  when @qloop = 4  then 'ALL'
                  else 'ALL'
                  end
   select @shipto = case
                    when @qloop = 1 then @shipto
                    when @qloop = 2 then 'ALL'
                    when @qloop = 3 then '*TYPE*'
                    when @qloop = 4 then 'ALL'
                    else 'ALL'

                    end

   select @q_item  = @pn
   select @q_level = 0
   -- Find price at item level (level=0)
   select @q_price  = isnull(dbo.c_quote.rate, -1),
          @q_type   = isnull(dbo.c_quote.type, ''),
          @q_comm   = isnull(dbo.c_quote.sales_comm, -1),
          @next_qty = isnull(dbo.c_quote.min_qty, -1)
   from   dbo.c_quote
   where  ( dbo.c_quote.customer_key = @cust AND  
            dbo.c_quote.ship_to_no = @shipto ) AND  
            dbo.c_quote.ilevel = 0 AND 
            dbo.c_quote.item = @pn AND  
            dbo.c_quote.min_qty <= @qty AND 
            dbo.c_quote.date_expires >= @dt
   order by dbo.c_quote.min_qty ASC

   -- START v1.2 - CVO bespoke for group level (level=1), for ShipTo (qloop 1), Customer (qloop 2) and Price Class (qloop 3), style and res_type may be set so  
   -- should be factored in. For other pricing (qloop >3), style and res_type must not be factored in
   -- START v1.1	
   if @q_price < 0 begin
      select @q_level = 1
	  -- Find price at group level (level=1)

	  -- v1.2 - commenting, now done in loop below
--	  IF @qloop <=2 -- ShipTo or Customer
--	  BEGIN
--		select 
--			@q_price = isnull(dbo.c_quote.rate, -1), 
--			@q_type   = isnull(dbo.c_quote.type, ''),
--			@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
--			@next_qty = isnull(dbo.c_quote.min_qty, -1)
--		from   
--			dbo.c_quote
--		where  
--			(dbo.c_quote.customer_key = @cust AND  
--			dbo.c_quote.ship_to_no = @shipto ) AND  
--			dbo.c_quote.ilevel = 1 AND 
--			dbo.c_quote.item = @inv_cat AND  
--			dbo.c_quote.min_qty <= @qty AND 
--			dbo.c_quote.date_expires >= @dt
--			AND ISNULL(dbo.c_quote.style,'') = @style
--			AND ISNULL(dbo.c_quote.res_type,'') = @res_type
--		order by 
--			dbo.c_quote.min_qty ASC
--	END
--	
--	IF @qloop = 3 -- Price Class
	-- v1.2 end of commenting out

	IF @qloop <= 3 -- ShipTo, Customer or Price Class
	-- END v1.2
	BEGIN
		-- There are multiple checks to do here, find the first quote that matches from:
		 -- 1. Group/Style/Resource Type
		 -- 2. Group/Style
		 -- 3. Group/Resource Type
		 -- 4. Group

		-- 1. Group/Style/Resource Type
		select 
			@q_price = isnull(dbo.c_quote.rate, -1), 
			@q_type   = isnull(dbo.c_quote.type, ''),
			@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
			@next_qty = isnull(dbo.c_quote.min_qty, -1)
		from   
			dbo.c_quote
		where  
			(dbo.c_quote.customer_key = @cust AND  
			dbo.c_quote.ship_to_no = @shipto ) AND  
			dbo.c_quote.ilevel = 1 AND 
			dbo.c_quote.item = @inv_cat AND  
			dbo.c_quote.min_qty <= @qty AND 
			dbo.c_quote.date_expires >= @dt
			AND ISNULL(dbo.c_quote.style,'') = @style
			AND ISNULL(dbo.c_quote.res_type,'') = @res_type
		order by 
			dbo.c_quote.min_qty ASC	 

		-- 2. Group/Style
		IF @q_price < 0
		BEGIN
			select 
				@q_price = isnull(dbo.c_quote.rate, -1), 
				@q_type   = isnull(dbo.c_quote.type, ''),
				@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty <= @qty AND 
				dbo.c_quote.date_expires >= @dt
				AND ISNULL(dbo.c_quote.style,'') = @style
				AND ISNULL(dbo.c_quote.res_type,'') = ''
			order by 
				dbo.c_quote.min_qty ASC	
		END

		-- 3. Group/Resource Type
		IF @q_price < 0
		BEGIN
			select 
				@q_price = isnull(dbo.c_quote.rate, -1), 
				@q_type   = isnull(dbo.c_quote.type, ''),
				@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty <= @qty AND 
				dbo.c_quote.date_expires >= @dt
				AND ISNULL(dbo.c_quote.style,'') = ''
				AND ISNULL(dbo.c_quote.res_type,'') = @res_type
			order by 
				dbo.c_quote.min_qty ASC	
		END

		-- 4. Group
		IF @q_price < 0
		BEGIN
			select 
				@q_price = isnull(dbo.c_quote.rate, -1), 
				@q_type   = isnull(dbo.c_quote.type, ''),
				@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty <= @qty AND 
				dbo.c_quote.date_expires >= @dt
				AND ISNULL(dbo.c_quote.style,'') = ''
				AND ISNULL(dbo.c_quote.res_type,'') = ''
			order by 
				dbo.c_quote.min_qty ASC	
		END
	END

	IF @qloop > 3 -- Other
	BEGIN
		select 
			@q_price = isnull(dbo.c_quote.rate, -1), 
			@q_type   = isnull(dbo.c_quote.type, ''),
			@q_comm   = isnull(dbo.c_quote.sales_comm, -1),
			@next_qty = isnull(dbo.c_quote.min_qty, -1)
		from   
			dbo.c_quote
		where  
			(dbo.c_quote.customer_key = @cust AND  
			dbo.c_quote.ship_to_no = @shipto ) AND  
			dbo.c_quote.ilevel = 1 AND 
			dbo.c_quote.item = @inv_cat AND  
			dbo.c_quote.min_qty <= @qty AND 
			dbo.c_quote.date_expires >= @dt
		order by 
			dbo.c_quote.min_qty ASC
	END
	-- END v1.1
   end

   -- Get the next level	       
   if @q_price >= 0 begin

      if @q_level = 0 begin
		 -- Find price at item level (level=0)
         select @next_price = isnull(dbo.c_quote.rate, -1), 
                @next_type   = isnull(dbo.c_quote.type, ''),
                @next_qty = isnull(dbo.c_quote.min_qty, -1)
         from   dbo.c_quote
         where  ( dbo.c_quote.customer_key = @cust AND  
                  dbo.c_quote.ship_to_no = @shipto ) AND  
                  dbo.c_quote.ilevel = 0 AND 
                  dbo.c_quote.item = @pn AND  
                  dbo.c_quote.min_qty > @next_qty AND 
                  dbo.c_quote.date_expires >= @dt
           order by dbo.c_quote.min_qty DESC
      end

	  -- START v1.1 - CVO bespoke for group level (level=1), for ShipTo (qloop 1) and Customer (qloop 2), style and res_type must also be factored in
	  -- For Price Class (qloop 3), style and res_type may be factored in. For other pricing (qloop >3), style and res_type must not be factored in

      if @q_level = 1 begin
		-- Find price at group level (level=1)
		IF @qloop <=2 -- ShipTo or Customer
		BEGIN
			select 
				@next_price = isnull(dbo.c_quote.rate, -1), 
				@next_type   = isnull(dbo.c_quote.type, ''),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty > @next_qty AND 
				dbo.c_quote.date_expires >= @dt
				AND ISNULL(dbo.c_quote.style,'') = @style
				AND ISNULL(dbo.c_quote.res_type,'') = @res_type
			order by 
				dbo.c_quote.min_qty DESC
		END

		IF @qloop = 3 -- Price Class
		BEGIN
			-- There are multiple checks to do here, find the first quote that matches from:
			-- 1. Group/Style/Resource Type
			-- 2. Group/Style
			-- 3. Group/Resource Type
			-- 4. Group

			-- 1. Group/Style/Resource Type
			select 
				@next_price = isnull(dbo.c_quote.rate, -1), 
				@next_type   = isnull(dbo.c_quote.type, ''),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty > @next_qty AND 
				dbo.c_quote.date_expires >= @dt
				AND ISNULL(dbo.c_quote.style,'') = @style
				AND ISNULL(dbo.c_quote.res_type,'') = @res_type
			order by 
				dbo.c_quote.min_qty DESC

			-- 2. Group/Style
			IF @next_price < 0
			BEGIN
				select 
					@next_price = isnull(dbo.c_quote.rate, -1), 
					@next_type   = isnull(dbo.c_quote.type, ''),
					@next_qty = isnull(dbo.c_quote.min_qty, -1)
				from   
					dbo.c_quote
				where  
					(dbo.c_quote.customer_key = @cust AND  
					dbo.c_quote.ship_to_no = @shipto ) AND  
					dbo.c_quote.ilevel = 1 AND 
					dbo.c_quote.item = @inv_cat AND  
					dbo.c_quote.min_qty > @next_qty AND 
					dbo.c_quote.date_expires >= @dt
					AND ISNULL(dbo.c_quote.style,'') = @style
					AND ISNULL(dbo.c_quote.res_type,'') = ''
				order by 
					dbo.c_quote.min_qty DESC
			END

			-- 3. Group/Resource Type
			IF @next_price < 0
			BEGIN
				select 
					@next_price = isnull(dbo.c_quote.rate, -1), 
					@next_type   = isnull(dbo.c_quote.type, ''),
					@next_qty = isnull(dbo.c_quote.min_qty, -1)
				from   
					dbo.c_quote
				where  
					(dbo.c_quote.customer_key = @cust AND  
					dbo.c_quote.ship_to_no = @shipto ) AND  
					dbo.c_quote.ilevel = 1 AND 
					dbo.c_quote.item = @inv_cat AND  
					dbo.c_quote.min_qty > @next_qty AND 
					dbo.c_quote.date_expires >= @dt
					AND ISNULL(dbo.c_quote.style,'') = ''
					AND ISNULL(dbo.c_quote.res_type,'') = @res_type
				order by 
					dbo.c_quote.min_qty DESC
			END

			-- 4. Group
			IF @next_price < 0
			BEGIN
				select 
					@next_price = isnull(dbo.c_quote.rate, -1), 
					@next_type   = isnull(dbo.c_quote.type, ''),
					@next_qty = isnull(dbo.c_quote.min_qty, -1)
				from   
					dbo.c_quote
				where  
					(dbo.c_quote.customer_key = @cust AND  
					dbo.c_quote.ship_to_no = @shipto ) AND  
					dbo.c_quote.ilevel = 1 AND 
					dbo.c_quote.item = @inv_cat AND  
					dbo.c_quote.min_qty > @next_qty AND 
					dbo.c_quote.date_expires >= @dt
					AND ISNULL(dbo.c_quote.style,'') = ''
					AND ISNULL(dbo.c_quote.res_type,'') = ''
				order by 
					dbo.c_quote.min_qty DESC
			END

		END

		IF @qloop > 3 -- Other
		BEGIN
			select 
				@next_price = isnull(dbo.c_quote.rate, -1), 
				@next_type   = isnull(dbo.c_quote.type, ''),
				@next_qty = isnull(dbo.c_quote.min_qty, -1)
			from   
				dbo.c_quote
			where  
				(dbo.c_quote.customer_key = @cust AND  
				dbo.c_quote.ship_to_no = @shipto ) AND  
				dbo.c_quote.ilevel = 1 AND 
				dbo.c_quote.item = @inv_cat AND  
				dbo.c_quote.min_qty > @next_qty AND 
				dbo.c_quote.date_expires >= @dt
			order by 
				dbo.c_quote.min_qty DESC
		END
		-- END v1.1
      end

   end 
   select @qloop = @qloop + 1
END 

if @q_price < 0 begin
   select @qloop   = 0
   select @q_level = 0
end 
if @q_price >= 0 begin
   select @qloop = @qloop - 1
   select @plevel2 = 'Q'


   select @scomm = @q_comm,


          @price = case
            when @q_type='P' then @q_price
            when @q_type='L' then (@price_a - @q_price)
            when @q_type='C' then (@tot_cost + @q_price)
            when @q_type='-' then 
                     @price_a - ( ceiling( @price_a * @q_price * 100 ) / 10000 )
            when @q_type='+' then 
                     @tot_cost + ( ceiling( @tot_cost * @q_price * 100 ) / 10000 )
            else -1 end
end




if @next_price >= 0 begin 
   select @next_price = case
                        when @next_type='P' then @next_price
                        when @next_type='L' then (@price_a - @next_price)
                        when @next_type='C' then (@tot_cost + @next_price)
                        when @next_type='-' then 
                                 @price_a - ( ceiling( @next_price * @next_price * 100 ) / 10000 )
                        when @next_type='+' then 
                                 @tot_cost + ( ceiling( @tot_cost * @next_price * 100 ) / 10000 )
                        else -1 end
end
select @next_qty = case
            when @plevel2='A' then @qty_b
            when @plevel2='B' then @qty_c
            when @plevel2='C' then @qty_d
            when @plevel2='D' then @qty_e
            when @plevel2='E' then @qty_f
            else @next_qty end,

       @next_price = case
            when @plevel2='A' then @price_b
            when @plevel2='B' then @price_c

            when @plevel2='C' then @price_d
            when @plevel2='D' then @price_e
            when @plevel2='E' then @price_f
            else @next_price end


select @promo_price=0

if @promo = 'P' or @promo = 'D'  begin
   if @promo_date >= getdate() begin
      if @promo = 'D' begin
         select @promo_rate = @price_a - ceiling( @price_a * @promo_rate * 100 ) / 10000

      end
      if @promo_rate > 0 begin
         select @promo_price = @promo_rate
         if @promo_rate < @price begin
            if @plevel  = 'P' or @i_method_promo = 'AUTO' begin
               select @plevel2 = 'P'
               select @price   = @promo_rate
            end
         end

      end
   end
end

select '{ord_list.price='+ltrim(convert(varchar(20),ROUND(@price,2))), 'ord_list.price_type='+@plevel2+'}'

GO
GRANT EXECUTE ON  [dbo].[fs_get_i_price] TO [public]
GO
