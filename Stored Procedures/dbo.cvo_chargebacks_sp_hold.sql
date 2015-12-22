SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[cvo_chargebacks_sp_hold] @where_clause varchar(255)
AS
--
-- v4.0	TM	04/16/2012 - Remove any lines where the discount comes out negative
-- v5.0 TM  05/19/2012 - Remove any customer that has a past due balance < 0
-- v6.0 TM  06/09/2012 - Do not pick up invoices already on chargebacks
-- v6.1 TG 07/27/2012 - fix where conditions - add isnull on promo id, and = cutoffdate to not pick up older invoices

IF (object_id('tempdb..#Temp') IS NOT NULL) DROP TABLE #Temp

DECLARE @cutoff_date	int,
		@Create_doc		varchar(1)

SET NOCOUNT ON

SELECT @cutoff_date = convert(int,substring(@where_clause,charindex('=',@where_clause)+1,7))
SELECT @Create_doc = IsNULL(UPPER(substring(@where_clause,charindex('%',@where_clause)+1,1)),'N')

DECLARE @Total_of_invoice decimal(20,8), @days_due int, @date_due int, 
		@id_no int, @customer_code varchar(8), @disc_cback float,
		@ErrFlag int, @terms_code varchar(10)

CREATE TABLE #Temp        
   (customer_code varchar(16),
	cust_name varchar(40),
    doc_ctrl_num varchar(16),        
	date_due int,
	shipped float,   
	invoice_unit float,     
	list_unit float,
    disc_given float,  
    order_ctrl_num varchar(16),
	part_no varchar(30)
   )       

CREATE INDEX #temp_idx1 ON #temp (customer_code, doc_ctrl_num)

INSERT INTO #Temp        
SELECT ar.customer_code, ac.customer_name, ar.doc_ctrl_num, ar.date_due, ol.shipped,
	   ol.price as sell_price, cl.list_price as list_price,
	   (cl.list_price - ol.price) * shipped as total_discount, ar.order_ctrl_num, ol.part_no
  FROM orders_invoice oi
	left join orders_all oh (nolock) on oi.order_no = oh.order_no and oi.order_ext = oh.ext			--v2.0
	left join cvo_orders_all ch (nolock) on oi.order_no = ch.order_no and oi.order_ext = ch.ext		--v3.0
	left join ord_list ol (nolock) on oi.order_no = ol.order_no and oi.order_ext = ol.order_ext
	left join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext and ol.line_no = cl.line_no
	left join inv_master iv (nolock) on ol.part_no = iv.part_no
	left join artrx ar (nolock) on oi.doc_ctrl_num = ar.doc_ctrl_num and ar.trx_type = 2031 and ar.paid_flag = 0
	left join arcust ac (nolock) on ar.customer_code = ac.customer_code
	left join cvo_armaster_all cm (nolock) on ar.customer_code = cm.customer_code and cm.address_type = 0
 WHERE ol.price <> cl.list_price
   AND shipped > 0
   AND oh.user_category NOT IN ('ST-CL')				--v2.0
   AND isnull(ch.promo_id,'') NOT IN ('QOP','EOR','EOS','EAG')	--v3.0 - v6.1 - tag - 072612
   AND ar.paid_flag = 0
   AND ar.doc_ctrl_num > ''
   AND iv.type_code in ('FRAME','SUN')
   AND IsNull(cm.cvo_chargebacks,1) = 1
   AND ar.date_due = @cutoff_date -- v6.1 - change from <= to =
   AND SUBSTRING(ar.doc_ctrl_num,1,2) NOT IN ('FC','CB')
   AND ar.doc_ctrl_num NOT IN (select SUBSTRING(line_desc,1,10) from artrxcdt where doc_ctrl_num like 'CB%')	--v6.0
  

--v4.0
DELETE #temp WHERE disc_given < 0


--
-- Determine if a Customer has a net balance < $0
--
CREATE TABLE #tmp_CustBal
(cust_code			varchar(8),
 shipto_code		varchar(8),
 doc_ctrl_no		varchar(16),
 open_amount		decimal(20,2)
)

CREATE INDEX #temp_idx1 ON #tmp_CustBal (cust_code, doc_ctrl_no)

--
-- GATHER DETAIL
--
INSERT INTO #tmp_CustBal
-- Invoices
SELECT h.customer_code,h.ship_to_code,h.doc_ctrl_num,
	convert(decimal(20,2),h.amt_net - h.amt_paid_to_date) as Open_Amount
  FROM armaster b (nolock), arcust c (nolock), artrxage a (nolock)	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 WHERE a.trx_type = 2031
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and a.date_due = @cutoff_date -- v6.1 - chage from <= to =
UNION
-- OA Cash Receipts
select h.customer_code,h.ship_to_code,h.doc_ctrl_num,h.amt_on_acct * -1
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2111
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and h.amt_on_acct > 0
UNION
-- OA Credit Memos
select h.customer_code,h.ship_to_code,h.doc_ctrl_num,ROUND((h.amt_on_acct * -1),2)
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2161
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and ROUND(h.amt_on_acct,2) > 0
order by h.customer_code, h.ship_to_code

--
CREATE TABLE #tmp_CustBal_Open
(cust_code			varchar(8),
 open_amount		decimal(20,2)
)
--
-- SUMMARIZE TOTAL OPEN BY CUSTOMER/SHIP TO
--
INSERT INTO #tmp_CustBal_Open
select cust_code, sum(open_amount)
  from #tmp_CustBal
group by cust_code
order by cust_code
--
DELETE FROM #tmp_CustBal_Open WHERE open_amount > 0
DELETE FROM #temp WHERE customer_code in (select cust_code from #tmp_CustBal_Open)
--
--

-- v5.0 BEGIN
CREATE TABLE #past_due_bal (amount float, on_acct float, age_b1 float, age_b2 float, age_b3	float, age_b4 float,
					 		age_b5 float, age_b6 float, home_curr varchar(8), age_b0 float)

DECLARE @Net_past_due float

DECLARE pd01 CURSOR FOR Select distinct customer_code from #Temp Order By customer_code
OPEN pd01
FETCH NEXT from pd01 INTO @customer_code
WHILE (@@fetch_status=0)
BEGIN
	INSERT #past_due_bal EXEC cc_summary_aging_sp @customer_code, '4', 0, 'CVO', 'CVO'
	SELECT @Net_past_due = age_b2 + age_b3 + age_b4 + age_b5 + age_b6 FROM #past_due_bal
	IF @Net_past_due < 0
	BEGIN
		DELETE FROM #temp WHERE customer_code = @customer_code		-- If Past Due < 0 Then remove
	--select 'DELETED '+@customer_code
	END
	DELETE #past_due_bal	-- Clear dat out
	FETCH NEXT from pd01 INTO @customer_code
END 
CLOSE pd01 
DEALLOCATE pd01
-- v5.0 END


IF @Create_doc = 'Y'
BEGIN

	CREATE TABLE #TempSum
		(id_no int IDENTITY(1,1),
		 customer_code varchar(16),
		 disc_CBack float  
		)        
		
	INSERT INTO #TempSum (customer_code, disc_CBack)
	SELECT customer_code, SUM(disc_given)
	  FROM #temp
	GROUP BY customer_code
	ORDER BY customer_code
	
	DECLARE ap01 CURSOR FOR 
		Select id_no, customer_code, disc_CBack from #TempSum
		Order By id_no

	OPEN ap01
	FETCH NEXT from ap01 INTO @id_no, @customer_code, @disc_cback
	WHILE (@@fetch_status=0)
	BEGIN

	BEGIN TRANSACTION

      --Get the doc_ctrl_num      
      DECLARE @doc_ctrl_number_inv  varchar(10)      
      SELECT @doc_ctrl_number_inv =  SUBSTRING(mask,1,10-(SELECT LEN(next_num)       
		FROM ewnumber WHERE num_type = 3004)) + CAST(next_num as varchar(16)) FROM ewnumber WHERE num_type = 3004         

      --Get the next trx_ctrl_num      
      UPDATE ewnumber SET next_num = next_num + 1 WHERE num_type = 3004      

      --trx_ctrl_num   
      DECLARE @control_number_inv varchar(16), @num int     
      EXEC ARGetNextControl_SP 2000, @control_number_inv OUTPUT, @num OUTPUT       

	COMMIT TRANSACTION


	  SELECT @terms_code = terms_code
		FROM arcust
	   WHERE customer_code = @customer_code

	  EXEC dbo.CVO_CalcDueDate_sp @customer_code, @cutoff_date, @date_due OUTPUT, @terms_code

    ---------------------------------------------------------    
    -- Begin Creation Process
    ---------------------------------------------------------    

	CREATE TABLE #TempDet        
		(lne_id int IDENTITY(1,1),
		 customer_code varchar(16),
		 doc_ctrl_num varchar(16),        
	     order_ctrl_num varchar(16),
	     disc_given float
	    )        
           
	INSERT INTO #TempDet (customer_code, doc_ctrl_num, order_ctrl_num, disc_given)
	SELECT customer_code, doc_ctrl_num, order_ctrl_num, disc_given
      FROM #Temp
	 WHERE customer_code = @customer_code

	SELECT @ErrFlag = 0

	BEGIN TRANSACTION
            
	   ---------------------------------------------------------    
          /*arinpchg_all*/    
       ---------------------------------------------------------    

     INSERT into arinpchg_all        
       SELECT   
       NULL as timestamp,        
       @control_number_inv as trx_ctrl_num,       
       @doc_ctrl_number_inv,  
       'ChargeBack Invoice' as doc_desc,  
       ' ' as apply_to_num,  
       0 as apply_trx_type,  
       ' ' as order_ctrl_num,       
       '' as batch_code,        
       2031 as trx_type,  
       @cutoff_date as date_entered,              
       @cutoff_date as date_applied,              
       @cutoff_date as date_doc,           
       @cutoff_date as date_shipped,             
       @cutoff_date as date_required,        
       @date_due as date_due,       
       @date_due as date_aging,        
       armaster.customer_code as customer_code,   
       ' ' as ship_to_code,  
       armaster.salesperson_code as salesperson_code,  
       armaster.territory_code,  
       '' as comment_code,  
       '' as fob_code,       
       '' freight_code,     
       armaster.terms_code as terms_code,      
       '' as fin_chg_code,  
       '' as price_code,          
       '' as dest_zone_code,  
       armaster.posting_code as Posting_Code,      
       0 as recurring_flag,        
       '' as recurring_code,  
       armaster.tax_code as tax_code,      
       '' as Customer_PO,        
       0 as total_weight,           
       @disc_cback as amt_gross,         
       0 as amt_freight,                       
       0 as amt_tax,              
       0 as amt_tax_included,         
       0 as amt_discount,                      
       @disc_cback as amt_net,          
       0 as amt_paid,      
       @disc_cback as amt_due,                 
       0 as amt_cost,       
       0 as amt_profit,         
	   1 as next_serial_id,        
       1 as printed_flag,       
       0 as posted_flag,        
       0 as hold_flag,        
       ' ' as hold_desc,       
       1 as user_id,      
       armaster.addr1,  
       armaster.addr2,  
       armaster.addr3,  
       armaster.addr4,  
       armaster.addr5,  
       armaster.addr6,  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',
       0,      
       0,      
       0,      
       ' ',  
       ' ',  
       ' ',  
       NULL,  
       0,  
       0,  
       'USD' as nat_cur_code,        
       'BUY' as rate_type_home,        
       'BUY' as rate_type_oper,        
       1 as rate_home,        
       1 as rate_oper,        
       0,  
       NULL,  
       NULL,  
       NULL,  
       'CVO' as org_id,        
       armaster.country_code,  
       armaster.city,  
       armaster.state,  
       armaster.postal_code,  
       ' ',  
       ' ',  
       ' ',  
       ' '  
      FROM  arcust armaster  
      WHERE @customer_code = armaster.customer_code   

	IF @@error <> 0 
		SELECT @ErrFlag = 10
        
       ---------------------------------------------------------    
						/*arinpcdt*/    
       ---------------------------------------------------------   
  
       INSERT INTO arinpcdt    
           SELECT   
           NULL as timestamp,         
           @control_number_inv as trx_ctrl_num,        
           @doc_ctrl_number_inv,  
           TDet.lne_id as sequence_id,         
           2031 as trx_type,         
           ' ' as location_code,         
           ' ' as item_code,         
           0 as bulk_flag,         
           @cutoff_date as date_entered,  
           doc_ctrl_num + ' / ' + order_ctrl_num as line_desc,       
           1 as qty_ordered,        
           1 as qty_shipped,        
           ' ',  
           tdet.disc_given as unit_price,      
           0,  
           0,  
           0 as serial_id,         
           armaster.tax_code as tax_code,       
           '4920000000000',       
           0,  
           0 as amt_discount,         
           0,  
           '' as rma_num,         
           ' ',  
           0 as qty_returned,        
           0 as qty_prev_returned,         
           ' ',   
           0,
           0,      
           0,   
           tdet.disc_given as extended_price,  
           0 as calc_tax,         
           '' as reference_code,         
           '' as new_reference_code,         
           ' ',  
           'CVO' as org_id         
          FROM  arcust armaster, #TempDet tdet  
		 WHERE @customer_code = armaster.customer_code   
		   AND @customer_code = tdet.customer_code

	IF @@error <> 0 
		SELECT @ErrFlag = 20

       --------------------------------------------------------    
           /*arinpage*/    
       ---------------------------------------------------------    
  
     INSERT INTO arinpage  
       SELECT   
        NULL,         
        @control_number_inv as trx_ctrl_num,        
        1,         
        @doc_ctrl_number_inv,  
        ' ',  
        0,  
        2031 as trx_type,        
        @cutoff_date as date_applied,      
        @date_due as date_due,   
        @date_due as date_aging,  
		@customer_code,  
        armaster.salesperson_code,  
        armaster.territory_code,  
        armaster.price_code,  
        @disc_cback   
       FROM  arcust armaster  
       WHERE @customer_code = armaster.customer_code     
          
	IF @@error <> 0 
		SELECT @ErrFlag = 30

       --------------------------------------------------------    
           /*arinptax*/    
       ---------------------------------------------------------    
        
      INSERT INTO arinptax    
        SELECT    
          NULL as timestamp,          
          @control_number_inv as trx_ctrl_num,        
          2031 as trx_type,    
          1 as sequence_id,    
          armaster.tax_code as tax_type_code,       
          @disc_cback as amt_taxable,         
          @disc_cback as amt_gross,    
          0 as amt_tax,           
	      0 as amt_final_tax         
        FROM   arcust armaster  
       WHERE @customer_code = armaster.customer_code
 
	IF @@error <> 0 
		SELECT @ErrFlag = 40


	IF @ErrFlag = 0
		BEGIN
			COMMIT TRANSACTION
		END
	ELSE
		BEGIN
			ROLLBACK TRANSACTION
		END
  

	DROP TABLE #TempDet

	FETCH NEXT from ap01 INTO @id_no, @customer_code, @disc_cback

end 

close ap01 
deallocate ap01

DROP TABLE #TEMPSUM

END


SELECT *,@cutoff_date as cutoff_date,@Create_doc as create_doc FROM #temp ORDER BY customer_code

DROP TABLE #TEMP
DROP TABLE #past_due_bal



GO
GRANT EXECUTE ON  [dbo].[cvo_chargebacks_sp_hold] TO [public]
GO
