SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARUPDateActvityAmtonOrder_SP]              	@update_type         smallint    
					    
AS

BEGIN

CREATE TABLE #t1 (
	no int,
	cust_code varchar(8),
	ship_to   varchar(8),
	salesperson varchar(8),
	territory   varchar(8),
	hstat	char(1),
	hrate	decimal(20,8),
	orate	decimal(20,8),
	amt_home decimal(20,8),
	amt_oper decimal(20,8),
	price_code char(8) )

CREATE INDEX #t1ndx ON #t1 (no, hstat)	

DECLARE	@hprecision decimal(20,8), @oprecision decimal(20,8)
DECLARE @n1 int, @n2 int

INSERT	#t1
SELECT	isNull(o.order_no,0),
	isNull(o.cust_code,''), 
	isNull(o.ship_to,''), 
	isNull(o.salesperson,''), 
	isNull(o.ship_to_region,''), 
	isNull(o.status,'N'), 
	isNull(o.curr_factor,1), 
	isNull(o.oper_factor,1), 
	isNull(o.total_amt_order - o.tot_ord_disc + o.tot_ord_tax + o.tot_ord_freight,0),
	isNull(o.total_amt_order - o.tot_ord_disc + o.tot_ord_tax + o.tot_ord_freight,0),
	isNull(c.price_code,'')
  FROM	orders_all o (nolock), adm_cust_all c (nolock)
 WHERE	o.status >= 'N' and o.status <= 'R' and o.type = 'I' and o.cust_code = c.customer_code

INSERT	#t1
SELECT	isNull(o.order_no,0),
	isNull(o.cust_code,''), 
	isNull(o.ship_to,''), 
	isNull(o.salesperson,''), 
	isNull(o.ship_to_region,''), 
	isNull(o.status,'N'), 
	isNull(o.curr_factor,1), 
	isNull(o.oper_factor,1), 
	isNull(o.gross_sales - o.total_discount + o.total_tax + o.freight,0),
	isNull(o.gross_sales - o.total_discount + o.total_tax + o.freight,0),
	isNull(c.price_code,'')
  FROM	orders_all o (nolock), adm_cust_all c (nolock)
 WHERE	o.status = 'S' and o.type = 'I' and o.cust_code = c.customer_code

SELECT @hprecision = glcurr_vw.curr_precision
  FROM glcurr_vw, glco
 WHERE glcurr_vw.currency_code=glco.home_currency 

SELECT @oprecision = glcurr_vw.curr_precision
  FROM glcurr_vw, glco
 WHERE glcurr_vw.currency_code=glco.oper_currency 

SELECT @n1 = 0
SELECT @n2 = max(no) FROM #t1

WHILE @n1 < @n2
BEGIN

   SELECT @n1 = min(no) FROM #t1 WHERE no > @n1

   UPDATE #t1
      SET amt_home = round( amt_home * hrate, @hprecision )
    WHERE no = @n1 and hrate >= 0

   UPDATE #t1
      SET amt_home = round( amt_home / abs(hrate), @hprecision )
    WHERE no = @n1 and hrate < 0

   UPDATE #t1
      SET amt_oper = round( amt_oper * orate, @oprecision )
    WHERE no = @n1 and orate >= 0

   UPDATE #t1
      SET amt_oper = round( amt_oper / abs(orate), @oprecision )
    WHERE no = @n1 and orate < 0

END

IF @update_type = 1
BEGIN

   INSERT #existing_orders
   SELECT cust_code, '', sum(amt_home), sum(amt_oper), 0
     FROM #t1
 GROUP BY cust_code

END

IF @update_type = 2
BEGIN

   INSERT #existing_orders
   SELECT salesperson, '', sum(amt_home), sum(amt_oper), 0
     FROM #t1
 GROUP BY salesperson

END

IF @update_type = 3
BEGIN

   INSERT #existing_orders
   SELECT territory, '', sum(amt_home), sum(amt_oper), 0
     FROM #t1
 GROUP BY territory

END

IF @update_type = 4
BEGIN

   INSERT #existing_orders
   SELECT price_code, '', sum(amt_home), sum(amt_oper), 0
     FROM #t1
 GROUP BY price_code

END

IF @update_type = 5
BEGIN

   INSERT #existing_orders
   SELECT cust_code, ship_to, sum(amt_home), sum(amt_oper), 0
     FROM #t1
 GROUP BY cust_code, ship_to

END

DROP TABLE #t1

END
GO
GRANT EXECUTE ON  [dbo].[ARUPDateActvityAmtonOrder_SP] TO [public]
GO
