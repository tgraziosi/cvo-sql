SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_cust_anl] @cust varchar(10),@bdate datetime,
@edate datetime  AS

 CREATE TABLE #tshippers (
        order_no   int ,
        order_ext  int ,
        cust_code  varchar(10) ,
        sch_ship_date datetime NULL ,
        date_shipped datetime ,
        ship_amt money NULL  )
 INSERT #tshippers
 SELECT shippers.order_no,     shippers.order_ext , 
        shippers.cust_code,    null ,
        shippers.date_shipped, sum(shippers.shipped * shippers.price) 
 FROM   shippers     
 WHERE  ( shippers.cust_code like @cust ) and     
        ( ( shippers.date_shipped >= @bdate ) and      
          ( shippers.date_shipped <= @edate  ) )   
 GROUP BY shippers.order_no, shippers.order_ext, shippers.cust_code,
          shippers.date_shipped
 ORDER BY shippers.date_shipped, shippers.order_no, shippers.order_ext
 UPDATE #tshippers
 SET    #tshippers.sch_ship_date=o.sch_ship_date
 FROM   orders_all o
 WHERE  o.order_no=#tshippers.order_no and o.ext=#tshippers.order_ext
 SELECT order_no,     order_ext , 
        cust_code,    sch_ship_date ,
        date_shipped, ship_amt ,
        @bdate,       @edate,      
        @cust    
 FROM   #tshippers     
 ORDER BY date_shipped, order_no, order_ext

GO
GRANT EXECUTE ON  [dbo].[fs_cust_anl] TO [public]
GO
