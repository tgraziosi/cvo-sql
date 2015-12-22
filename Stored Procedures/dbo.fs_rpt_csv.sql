SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_csv] @start datetime, @stop datetime,
                 @cust varchar(10), @stat1 char(1), @stat2 char(1),
                 @backord varchar(10), @part varchar(30), @loc varchar(10), @ship_to varchar(8) AS


declare @print char(1)

select @print = 'Z'
if @stat1 = 'T' and @stat2 = 'T' select @print = 'S'

  SELECT dbo.adm_cust.customer_code,   
         dbo.adm_cust.customer_name,   
         dbo.ord_list.order_no,   
         dbo.ord_list.order_ext,   
         dbo.ord_list.line_no,  
         dbo.ord_list.part_type, 
         dbo.ord_list.part_no,   
         dbo.ord_list.description,   
         dbo.ord_list.ordered,   
         dbo.ord_list.shipped,   
         dbo.ord_list.curr_price,   
         dbo.ord_list.price_type,   
         dbo.ord_list.uom,   
         dbo.ord_list.location,   
         dbo.orders_all.status,   
         dbo.orders_all.date_entered,   
         dbo.orders_all.date_shipped,   
         dbo.orders_all.sch_ship_date,   
         @start,   
         @stop,   
         @stat1 ,   
         @stat2,   
         @backord,   
         @part,   
         @loc,   
         @cust,
         dbo.glcurr_vw.currency_mask,
	   @ship_to								--MSHIPTO 
   FROM dbo.adm_cust (nolock)
   join dbo.orders_all (nolock) on ( dbo.orders_all.cust_code = dbo.adm_cust.customer_code )
   join dbo.ord_list (nolock) on ( dbo.orders_all.order_no = dbo.ord_list.order_no ) and  
         ( dbo.orders_all.ext = dbo.ord_list.order_ext )
   left outer join dbo.glcurr_vw (nolock) on (dbo.orders_all.curr_key = dbo.glcurr_vw.currency_code)
   WHERE ( dbo.adm_cust.customer_code like @cust ) AND 
	   ( @ship_to = '%' OR                                -- MSHIPTO
	   ( orders_all.ship_to = @ship_to ) )  AND               -- MSHIPTO
         ( dbo.orders_all.who_entered LIKE @backord ) AND  			-- mcruz 08/21/00
         ( dbo.orders_all.status >= @stat1 ) AND  
         ( dbo.orders_all.status <= @stat2 ) AND  
         (( @stat1 < 'R' AND  
         dbo.orders_all.sch_ship_date >= @start AND  
         dbo.orders_all.sch_ship_date <= @stop ) OR  
         ( @stat1 >= 'R' AND @stat1 < 'V' AND
         dbo.orders_all.date_shipped >= @start AND  
         dbo.orders_all.date_shipped <= @stop ) OR 
         ( @stat1 = 'V' AND  
         dbo.orders_all.sch_ship_date >= @start AND  
         dbo.orders_all.sch_ship_date <= @stop )) AND  
         ( dbo.orders_all.type = 'I' ) AND  
         ( dbo.ord_list.part_no like @part ) AND  
         ( dbo.ord_list.location like @loc )  AND
         dbo.orders_all.printed < @print 
ORDER BY dbo.adm_cust.customer_name ASC,   
         dbo.ord_list.part_no ASC,   
         dbo.orders_all.sch_ship_date ASC,   
         dbo.ord_list.order_no ASC,   
         dbo.ord_list.order_ext ASC,   
         dbo.ord_list.line_no ASC
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_csv] TO [public]
GO
