SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO








-- v1.1 CT 16/04/13 - In order to display credit return fees as an additional line, source view changed
-- v1.2 tag 052813 - handle negative discounts and don't report zero lines.
-- V1.3 TAG 070813 - HANDLE 0 LIST PRICE ITEMS - REPORT THEM AS NET.

CREATE view [dbo].[CVO_BGLog_vw] as

-- select * from CVO_BGLog_source_vw

select 
parent,   
parent_name,                              
cust_code,  
customer_name,                            
doc_ctrl_num,     
type,
--convert(int,datediff(dd,'1/1/1753',inv_date) + 639906) as 
inv_date,
-- V1.3 - 
case when disc_perc > 0 then sum(inv_TOT) else sum(inv_DUE) end as inv_tot,
--sum(inv_tot) inv_tot,                
case when disc_perc > 0 then sum(mer_TOT) else sum(mer_DISC) end as mer_tot,                
sum(net_amt) net_amt,
sum(freight) freight,                
sum(tax) tax,                    
trm,  
sum(mer_disc) mer_disc,               
SUM(inv_due) as inv_due, -- 032817
case when disc_perc < 0 then 0 
        else disc_perc end as disc_perc,  
--case when sum(mer_tot) = 0 then 0 else            
--round(1-(sum(mer_disc)/sum(mer_tot)),2)*100 end as  calc_disc_perc, -- testing
due_year_month,
xinv_date
-- START v1.1
from CVO_BGLog_source_vw2
--from CVO_BGLog_source_vw
-- END v1.1
where inv_tot+mer_tot+net_amt+freight+tax+mer_disc<>0 -- tag 052213
and disc_perc <> 1 -- 053013 - tag
and inv_due <> 0 -- for debit promos
group BY 

parent,   
parent_name,                              
cust_code,  
customer_name,                            
doc_ctrl_num,     
type, 
trm,   
inv_date, 
-- inv_due,           -- 032817     
disc_perc,              
due_year_month,
xinv_date,
rec_type -- v1.1










GO
GRANT REFERENCES ON  [dbo].[CVO_BGLog_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_BGLog_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_BGLog_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_BGLog_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_BGLog_vw] TO [public]
GO
