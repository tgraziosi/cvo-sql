SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- select * from arcus_vw
-- exec arcus_sp

CREATE VIEW [dbo].[arcus_vw] as
SELECT    
   t1.address_name,      
    t1.customer_code, 
    case when (select count(affiliated_code) from cvo_affiliated_customers a
        where a.customer_code = t1.customer_code) > 1 then 'Right-click for List'
    else    
     (SELECT top 1 a.affiliated_code FROM
	  cvo_affiliated_customers a
      where a.customer_code = t1.customer_code)
    end AS Affiliated_cust_code,
  
--    t1.affiliated_cust_code, -- tag - 040313
   t1.contact_name,       
   t1.contact_phone,  
   t1.tlx_twx fax, -- Tag - 040113
   t1.attention_name,	--v1.0  
   t1.attention_phone,  --v1.0   
   t1.territory_code,   
    t1.salesperson_code, -- 1.1 - tag 12/2012    
   t1.price_code,  
  t1.state,       -- CVO 
  t1.postal_code,	--v1.0 
  t1.country_code,     -- CVO    
  t1.dunning_group_id,    -- CVO  
  t1.addr_sort1 as cust_type,   -- CVO  
  t1.ftp as BG_Code,     -- CVO   
  na.parent as parent_code,   -- CVO  
  bg.customer_name as buying_group, -- CVO   
  cc2.status_desc as cc_status,  -- CVO   
   t1.nat_cur_code,     
   open_balance = isnull (t2.amt_balance, 0.0),  
   amt_on_acct = isnull(t2.amt_on_acct, 0.0),    
   net_balance = isnull(t2.amt_balance , 0.0) - isnull (t2.amt_on_acct, 0.0),  
   t1.credit_limit,      
   avail_credit_amt =   
    (1-t1.limit_by_home) * ( t1.credit_limit   
     - isnull(t2.amt_balance , 0.0)  
      + isnull(t2.amt_on_acct, 0.0)) +  
    (t1.limit_by_home) * ( t1.credit_limit  
     - isnull(t2.amt_balance_oper , 0.0)  
      + isnull(t2.amt_on_acct_oper, 0.0)),  
   t1.date_opened,      
    t3.status_code,  
  shipped_flag = 'Yes',  
  cv.cvo_print_cm as Print_CM,            -- CVO  
  cv.cvo_chargebacks as Charge_Backs,           -- CVO  
  t1.fin_chg_code, -- CVO - tag - 030713
   x_open_balance = isnull (t2.amt_balance, 0.0),  
   x_amt_on_acct = isnull(t2.amt_on_acct, 0.0),    
   x_net_balance = isnull(t2.amt_balance , 0.0) - isnull (t2.amt_on_acct, 0.0),  
   x_credit_limit=t1.credit_limit,      
   x_avail_credit_amt =   
    (1-t1.limit_by_home) * ( t1.credit_limit   
     - isnull(t2.amt_balance , 0.0)  
      + isnull(t2.amt_on_acct, 0.0)) +  
    (t1.limit_by_home) * ( t1.credit_limit  
     - isnull(t2.amt_balance_oper , 0.0)  
      + isnull(t2.amt_on_acct_oper, 0.0)),  
   x_date_opened=t1.date_opened  
 FROM  
  armaster t1  
 LEFT JOIN aractcus t2 ON  t1.customer_code = t2.customer_code  
 JOIN  arstat t3 ON  t1.status_type = t3.status_type  
 LEFT OUTER JOIN cvo_armaster_all cv ON t1.customer_code = cv.customer_code and t1.ship_to_code=cv.ship_to  --fzambada           -- CVO  
 LEFT OUTER JOIN cc_cust_status_hist cc1 ON t1.customer_code = cc1.customer_code AND cc1.clear_date is NULL   -- CVO  
 LEFT OUTER JOIN cc_status_codes cc2 ON cc1.status_code = cc2.status_code           -- CVO  
 LEFT OUTER JOIN arnarel na ON t1.customer_code = na.child               -- CVO  
 LEFT OUTER JOIN arcust bg ON na.parent = bg.customer_code               -- CVO  
 WHERE  t1.address_type = 0





GO
GRANT REFERENCES ON  [dbo].[arcus_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcus_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcus_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcus_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcus_vw] TO [public]
GO
