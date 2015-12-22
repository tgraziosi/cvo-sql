SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 26/03/2014 - Issue #1388 - If customer is an employee then return a pass
CREATE PROC [dbo].[fs_archklmt_sp]	@customer_code	varchar(10),   
							@date_entered	int,  
							@ordno			int,   
							@ordext			int,  
                            @chk			int OUT AS  
  
Declare	@ordamt   float,  
		@shpamt   float,  
		@amount_home  float,  
		@amount_oper  float,  
		@module   smallint,  
		@amt_over  float,   
		@date_over  int,  
		@credit_failed  varchar(8),   
		@aging_failed  varchar(8),   
		@credit_check_rel_code varchar(8),  
		@ordstat  char(1),  
		@hrate   decimal(20,8),  
		@orate   decimal(20,8),  
		@balfwd   int,  
		@payamt   float  
  
-- mls 2/9/01 SCR 25907 start  

-- v1.1 Start
IF EXISTS (SELECT 1 FROM arcust (NOLOCK) WHERE customer_code = @customer_code AND UPPER(addr_sort1) = 'EMPLOYEE')
BEGIN
	SET @chk = 0
	RETURN
END
-- v1.1 End
  
delete #arcrchk  
  
select  @module=6500, @amt_over=0.0, @date_over=0, @chk=(-3),  
		@credit_failed='', @aging_failed='', @credit_check_rel_code=''  
  
select  @ordamt=(total_amt_order - tot_ord_disc + tot_ord_tax + tot_ord_freight),   
		@shpamt=(gross_sales - total_discount + total_tax + freight),   
		@ordstat=status, @hrate=curr_factor, @orate=oper_factor  
from	orders_all (nolock)  
where	order_no=@ordno and ext=@ordext  
  
-- consider payments from totals  
select	@payamt = isnull( (select sum(amt_payment) 
from	ord_payment  
where	order_no=@ordno 
and		order_ext=@ordext), 0 )  

if @payamt is null select @payamt = 0  
  
if @ordstat >= 'N' 
begin  
	-- we have already saved the order and updated activity tables (except 'Hold' statuses),  
	-- so send zero for the amount to prevent double-dipping the amount.  
	select @ordamt = 0, @shpamt = 0 -- we always save first, even at shipping.  
end  
  
select @ordamt = @ordamt - @payamt -- back off payment amount  
select @shpamt = @shpamt - @payamt -- back off payment amount  
  
if @hrate = 0 select @hrate = 1  
if @orate = 0 select @orate = 1  
  
if @ordstat >= 'R' and @ordstat < 'V' 
begin  
	select @ordamt = @shpamt * (-1)  
end  
  
if @hrate < 0 
begin  
	select @hrate = @hrate * (-1)  
	select @amount_home = @ordamt / @hrate  
end  
else 
begin  
	select @amount_home = @ordamt * @hrate  
end  
  
if @orate < 0 
begin  
	select @orate = @orate * (-1)  
	select @amount_oper = @ordamt / @orate  
end  
else 
begin  
	select @amount_oper = @ordamt * @orate  
end  
  
  
exec @chk = archklmt_sp @customer_code  ,  
						@amount_home  ,  
						@amount_oper  ,  
						@date_entered  ,  
						@module   ,  
						@amt_over  OUTPUT,   
						@date_over  OUTPUT,  
						@credit_failed  OUTPUT,   
						@aging_failed  OUTPUT,   
						@credit_check_rel_code  
  
if @@error != 0 
begin  
	select @chk = -1  
	return   
end  
  
return   

GO
GRANT EXECUTE ON  [dbo].[fs_archklmt_sp] TO [public]
GO
