SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/03/2012 - CVO-CF-4 Generate Invoice Number at carton Close  
-- v1.1 CB 13/07/2012 - Use invoice date stored  
-- v1.2 CT 17/08/2012 - Custom routine for calculating promotions should only be called for orders, call std for credits
-- v1.3 CT 21/08/2012 - As v1.2, but also for total order discount
-- v1.4 CB 16/06/2014 - Performance
-- v1.5 CB 15/07/2014 - Fix Rounding issue on discount

-- exec [fs_updordtots] 1420371,0
  
CREATE PROCEDURE [dbo].[fs_updordtots] @ordno int, @ordext int AS  
  
declare @ext int, @xlp int, @tot_inv decimal(20,8), @tot_tax decimal(20,8),  
 @tot_disc decimal(20,8), @sub_tot decimal(20,8), @disc decimal(20,8),  
 @frt decimal(20,8), @tax decimal(20,8), @invno int, @edi_inv char(1),  
 @currency varchar(10), @precision int, @newstat char(1), @qty decimal(20,8),  
 @invdate datetime, @ord_tot decimal(20,8), @ord_disc decimal(20,8),  
 @ord_incl decimal(20,8), @tax_incl decimal(20,8)  
  
declare @o_ord_tot decimal(20,8), @o_ord_disc decimal(20,8), @o_sub_tot decimal(20,8),   
        @o_tot_disc decimal(20,8), @o_invno int, @o_invdate datetime, @o_tot_inv decimal(20,8),  
        @o_edi_inv char(1)  
  
declare @type char(1), @result int, @err int, @doc_ctrl_num varchar(16)  
declare @consolidate_flag int  
  
  
select @currency=curr_key, @frt=freight, @tax=tax_perc, @newstat=status,  
 @disc=discount, @tot_tax=total_tax, @invno=invoice_no, @invdate=invoice_date,  
 @ord_incl=tot_ord_incl, @tax_incl=tot_tax_incl, @type=type,  
       @consolidate_flag = isnull(consolidate_flag,0)  
from orders_all (NOLOCK)  
where order_no=@ordno and ext=@ordext  
  
if @@error != 0  
begin  
  return @@error  
end  
  
select @precision=isnull( (select curr_precision from glcurr_vw where currency_code=@currency), 2)  
  
if @@error != 0  
begin  
  return @@error  
end  
  
select @edi_inv=isnull((select min(c.invoice_edi)   
  from arcust_edi c (NOLOCK), orders_all o (NOLOCK) 
  where o.order_no=@ordno and o.ext=@ordext and c.customer_key=o.cust_code),'N')   
  
if @@error != 0  
begin  
  return @@error  
end  
  
select @edi_inv=isnull(@edi_inv,'N')  
select @ord_tot=isnull((select sum(Round((ordered + cr_ordered) * curr_price, @precision))  
from ord_list (NOLOCK)  
where order_no=@ordno and order_ext=@ordext), 0)  
    
if @@error != 0   
begin  
  return @@error  
end  


-- START v1.2
IF @type = 'I'
BEGIN 
	/*START: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
-- v1.5 Start
--	select @ord_disc= isnull((SELECT SUM(CASE ISNULL(co.is_amt_disc, '')  
--			 WHEN 'Y' THEN Round(((l.ordered + l.cr_ordered) * co.amt_disc), @precision)  
--			 ELSE Round(((l.ordered + l.cr_ordered) * l.curr_price) * (l.discount/100), @precision) END) -- mls 9/23/99 SCR 70 20885  
--		   FROM ord_list l (NOLOCK) 
--			LEFT JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext AND l.line_no = co.line_no  
--		   where l.order_no=@ordno and l.order_ext=@ordext), 0)  

	select @ord_disc= isnull((SELECT SUM(CASE ISNULL(co.is_amt_disc, '')  
			 WHEN 'Y' THEN ((l.ordered + l.cr_ordered) * ROUND(co.amt_disc, @precision))  
			 ELSE ((l.ordered + l.cr_ordered) * ROUND((l.curr_price) * (l.discount/100), @precision)) END) -- mls 9/23/99 SCR 70 20885  
		   FROM ord_list l (NOLOCK) 
			LEFT JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext AND l.line_no = co.line_no  
		   where l.order_no=@ordno and l.order_ext=@ordext), 0)  
-- v1.5 End

END

IF @type = 'C'
BEGIN  
	select @ord_disc=isnull((select sum(Round(((ordered + cr_ordered) * curr_price) * (discount/100), @precision))  -- mls 9/23/99 SCR 70 20885  
	from ord_list (NOLOCK)  
	where order_no=@ordno and order_ext=@ordext), 0)
	/*END: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
END
-- END v1.2
  
if @@error != 0   
begin  
  return @@error  
end  
  
select @sub_tot=isnull((select sum(Round((shipped + cr_shipped) * curr_price, @precision))  
from ord_list  (NOLOCK) 
where order_no=@ordno and order_ext=@ordext), 0)  
  
if @@error != 0   
begin  
  return @@error  
end  

-- START v1.3
IF @type = 'I'
BEGIN   
	/*START: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
-- v1.5 Start
	select @tot_disc= isnull((SELECT SUM(CASE ISNULL(co.is_amt_disc, '')  
			 WHEN 'Y' THEN ((l.shipped + l.cr_shipped) * ROUND(co.amt_disc, @precision))  
			 ELSE ((l.shipped + l.cr_shipped) * Round((l.curr_price) * (l.discount/100), @precision)) END) -- mls 9/23/99 SCR 70 20885  
		   FROM ord_list l (NOLOCK) 
			LEFT JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext AND l.line_no = co.line_no  
		   where l.order_no=@ordno and l.order_ext=@ordext), 0)  

--	select @tot_disc= isnull((SELECT SUM(CASE ISNULL(co.is_amt_disc, '')  
--			 WHEN 'Y' THEN Round(((l.shipped + l.cr_shipped) * co.amt_disc), @precision)  
--			 ELSE Round(((l.shipped + l.cr_shipped) * l.curr_price) * (l.discount/100), @precision) END) -- mls 9/23/99 SCR 70 20885  
--		   FROM ord_list l (NOLOCK) 
--			LEFT JOIN CVO_ord_list co (NOLOCK) ON l.order_no = co.order_no AND l.order_ext = co.order_ext AND l.line_no = co.line_no  
--		   where l.order_no=@ordno and l.order_ext=@ordext), 0)  
-- v1.5 End
END
IF @type = 'C'
BEGIN    
	select @tot_disc=isnull((select   
	  sum(Round(((shipped + cr_shipped) * curr_price) * (discount/100), @precision)) -- mls 9/23/99 SCR 70 20885  
	from ord_list (NOLOCK)  
	where order_no=@ordno and order_ext=@ordext), 0)
	/*END: 04/19/2010, AMENDEZ, 68668-001-MOD Promotions modification*/  
END
-- END v1.3
  
if @@error != 0   
begin  
  return @@error  
end  
  
select @tot_inv=(@sub_tot - @tot_disc + @tot_tax + @frt) - @tax_incl  
  
if @consolidate_flag = 1   
begin  
  if exists (select 1 from ord_payment (nolock)   
    where order_no = @ordno and order_ext = @ordext and (amt_payment > 0 or isnull(doc_ctrl_num,'') != ''))  
  begin  
    update orders_all WITH (ROWLOCK) 
    set consolidate_flag = 0   
    where order_no = @ordno and ext = @ordext  
  
    select @invno=invoice_no, @consolidate_flag = isnull(consolidate_flag,0)  
    from orders_all  (NOLOCK) 
    where order_no=@ordno and ext=@ordext  
  end  
end   
  
if @invno is null select @invno = 0  
  
select @doc_ctrl_num = ''  
if @newstat = 'S' and @invno = 0 and @consolidate_flag = 0  
begin  
  select @invdate=getdate()  
  
  -- Use A/R invoice numbering scheme 9/24/98 raf  
  -- SCR 22477 Add code to check for duplicate invoice numbers/credit memos in artrx and arinpchg tables  
  IF @type = 'I'   
  BEGIN  
    SELECT @doc_ctrl_num = NULL  
    WHILE (@doc_ctrl_num IS NULL)  
    BEGIN  

	  -- v1.0 Start Check if the invoice number has been assigned at carton close
	  SELECT	@doc_ctrl_num = doc_ctrl_num,
				@invno = inv_number,
				@invdate = CASE WHEN inv_date IS NULL THEN GETDATE() ELSE inv_date END
	  FROM		dbo.cvo_order_invoice (NOLOCK)
	  WHERE		order_no = @ordno
	  AND		order_ext = @ordext
	  AND		ISNULL(inv_number,0) <> 0

	  -- v1.0 If no invoice number was assigned then call standard routine
	  IF @doc_ctrl_num IS NULL
	  BEGIN
		EXEC @result = ARGetNextControl_SP 2001, @doc_ctrl_num OUTPUT, @invno OUTPUT, 0  

        IF @doc_ctrl_num IS NULL RETURN  
  
        SELECT @doc_ctrl_num = RTRIM(@doc_ctrl_num)  
        IF EXISTS( SELECT doc_ctrl_num  
          FROM  artrx  (NOLOCK)
          WHERE  doc_ctrl_num = @doc_ctrl_num AND  trx_type = 2021)  
        BEGIN  
          SELECT @doc_ctrl_num = NULL  
          CONTINUE  
        END  
        IF EXISTS( SELECT doc_ctrl_num FROM  arinpchg  (NOLOCK)
          WHERE doc_ctrl_num = @doc_ctrl_num AND  trx_type = 2021)  
        BEGIN  
          SELECT @doc_ctrl_num = NULL  
          CONTINUE  
        END  
	  END -- v1.0 End
    END -- End While Loop  
  END -- End @type = 'I'  
  ELSE  
  BEGIN   
    SELECT @doc_ctrl_num = NULL  
    WHILE (@doc_ctrl_num IS NULL)  
    BEGIN  
      EXEC @result = ARGetNextControl_SP 2021, @doc_ctrl_num OUTPUT, @invno OUTPUT, 0  
      IF @doc_ctrl_num IS NULL RETURN  
  
      SELECT @doc_ctrl_num = RTRIM(@doc_ctrl_num)  
      IF EXISTS(SELECT doc_ctrl_num  
        FROM  artrx (NOLOCK) WHERE  doc_ctrl_num = @doc_ctrl_num AND  trx_type = 2032)  
      BEGIN  
        SELECT @doc_ctrl_num = NULL  
        CONTINUE  
      END  
      IF EXISTS( SELECT doc_ctrl_num FROM  arinpchg (NOLOCK) 
        WHERE  doc_ctrl_num = @doc_ctrl_num AND  trx_type = 2032)  
      BEGIN  
        SELECT @doc_ctrl_num = NULL  
        CONTINUE  
      END  
    END -- End While Loop  
  END -- End @type <> 'I'  
  -- End of SCR 22477 code changes  
   
  if @@error != 0     return @@error  
  
  IF @result !=  0  
  BEGIN  
    select @err = 10  
    RETURN @err  
  END  
  
  
-- update next_inv_no set last_no=last_no+1 where last_no=last_no  
-- if @@error != 0 begin  
--  return @@error  
--  end  
--  
-- select @invno=last_no from next_inv_no  
-- if @@error != 0 begin  
--  return @@error  
--  end  
  
  if (@invno is null OR @invno < 1) return -1  
end  
  
select @ord_tot = @ord_tot - @ord_incl   
select @sub_tot = @sub_tot - @tax_incl   
  
select @o_ord_tot=isnull(total_amt_order,0),  
  @o_ord_disc=isnull(tot_ord_disc,0),  
  @o_sub_tot=isnull(gross_sales,0),  
  @o_tot_disc=isnull(total_discount,0),  
  @o_invno=isnull(invoice_no,0),  
  @o_invdate=invoice_date,  
  @o_tot_inv=isnull(total_invoice,0),  
  @o_edi_inv=isnull(invoice_edi,'N')  
from orders_all (nolock)  
where order_no=@ordno and ext=@ordext  
  
if (@o_ord_tot != @ord_tot or @o_ord_disc != @ord_disc or @o_sub_tot != @sub_tot or @o_tot_disc != @tot_disc or  
    @o_invno != @invno or @o_tot_inv != @tot_inv or @o_edi_inv != @edi_inv)   
begin  
  update orders_all WITH (ROWLOCK) set total_amt_order=@ord_tot,  
 tot_ord_disc=@ord_disc,  
 gross_sales=@sub_tot,  
 total_discount=@tot_disc,  
 invoice_no=@invno,  
 invoice_date=@invdate,  
 total_invoice=@tot_inv,  
 invoice_edi=@edi_inv  
  where order_no=@ordno and ext=@ordext  
  
  if @@error != 0  
    return @@error  
end  
  
if @doc_ctrl_num > ''   
begin  
  if exists (select * from orders_invoice (NOLOCK) where order_no=@ordno and order_ext=@ordext)   
  begin  
    update orders_invoice WITH (ROWLOCK) set doc_ctrl_num=@doc_ctrl_num  
    where order_no=@ordno and order_ext=@ordext  
  end   
  else   
  begin  
    insert orders_invoice WITH (ROWLOCK)( order_no, order_ext, doc_ctrl_num )  
    select @ordno, @ordext, @doc_ctrl_num  
  end  
  
  if @@error != 0   
    return @@error  
end  
  
return 1  
GO
GRANT EXECUTE ON  [dbo].[fs_updordtots] TO [public]
GO
