SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[EAI_get_orders_totals] @ordno int, @ordext int AS
Begin
	declare @tot_tax decimal(20,8),
		@tot_disc decimal(20,8), @sub_tot decimal(20,8), @disc decimal(20,8),
		@currency varchar(10), @precision int, @qty decimal(20,8),
		@ord_tot decimal(20,8), @ord_disc decimal(20,8),
		@ord_incl decimal(20,8), @tax_incl decimal(20,8)

	declare @result int, @err int


	/* first we calculate invoice amounts */
	select @currency=curr_key, 
		@disc=discount, @tot_tax=total_tax, 
		@ord_incl=tot_ord_incl, @tax_incl=tot_tax_incl
	from orders where
		order_no=@ordno and ext=@ordext

	if @@error != 0
	begin
		return @@error
	end

	select @precision=isnull( (select curr_precision from glcurr_vw where currency_code=@currency), 2)
  	if @@error != 0
	begin
		return @@error
	end

  	if @@error != 0
	begin
		return @@error
	end

	select @ord_tot=isnull((select sum(Round((ordered + cr_ordered) * curr_price, @precision))
		from ord_list
		where	order_no=@ordno and order_ext=@ordext and
			part_type in ('P', 'C')), 0)

  	if @@error != 0 
	begin
		return @@error
	end

	select @ord_disc=isnull((select 
		sum(Round(((ordered + cr_ordered) * curr_price) * (discount/100), @precision))		
		from 	ord_list 
		where	order_no=@ordno and order_ext=@ordext and
			part_type in ('P', 'C')), 0)

  	if @@error != 0 
	begin	
		return @@error
	end

	select @sub_tot=isnull((select sum(Round((shipped + cr_shipped) * curr_price, @precision))
		from ord_list 
		where	order_no=@ordno and order_ext=@ordext and
			part_type in ('P', 'C')), 0)
	
  	if @@error != 0 
	begin
		return @@error
	end

	select @tot_disc=isnull((select 
		sum(Round(((shipped + cr_shipped) * curr_price) * (discount/100), @precision))	
		from ord_list 
		where	order_no=@ordno and order_ext=@ordext and
			part_type in ('P', 'C')), 0)

  	if @@error != 0 
	begin
		return @@error
	end


	select @tot_tax=isnull((select 
		sum(Round(total_tax, @precision))	
		from ord_list where
			order_no=@ordno and order_ext=@ordext and
			part_type in ('P', 'C')), 0)

  	if @@error != 0 
	begin
		return @@error
	end

	select @ord_tot = @ord_tot - @ord_incl 	/* take out tax_included from gross_sales */
	select @sub_tot = @sub_tot - @tax_incl 	/* and total_amt_order                    */

	select	total_amt_order=@ord_tot,
		tot_ord_disc=@ord_disc,
		gross_sales=@sub_tot,
		total_discount=@tot_disc,
		tot_ord_tax=@tot_tax
end
GO
GRANT EXECUTE ON  [dbo].[EAI_get_orders_totals] TO [public]
GO
