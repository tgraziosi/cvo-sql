SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create function [dbo].[f_get_debit_promo_orig_order](@cust_code varchar(10), @promo_id varchar(20),
@promo_level varchar(30), @start_date datetime)
returns @rettab table (cust_code varchar(10), 
                        promo_id varchar(20),
                        promo_level varchar(30), 
                        start_date datetime,
                        order_no int,
                        invoice_no int
                        )
as                       
begin
    insert into @rettab
    select top 1 o.cust_code, co.promo_id, co.promo_level,  o.date_entered, o.order_no, o.invoice_no 
    From orders o inner join cvo_orders_all co 
    on co.order_no = o.order_no and co.ext = o.ext  
    where o.cust_code = @cust_code 
    and co.promo_id = @promo_id 
    and co.promo_level = @promo_level 
    and @start_date >= dateadd(dd, datediff(dd,0,o.date_entered), 0)
    return
end
GO
