SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                




  
  



CREATE VIEW [dbo].[glchr_vw] AS
SELECT 
	case when o.org_id = ' ' then c.organization_id
	     else o.org_id end as org_id,
  	cast(c.account_code as varchar(36)) as account_code,   
  	c.account_description,
  	c.account_type,
	account_type_description = a.type_description,
  	date_active=c.active_date,
  	date_inactive=c.inactive_date,
	inactive_flag = case c.inactive_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end, 
  	consol_type = case c.consol_type
  		when 1 then 'Weighted average'
  		when 2 then 'Historic'
  		when 3 then 'Spot'
  		when 4 then 'One-to-one'
  		when 5 then 'Zero'
  		when 6 then 'User defined'
  	end,
	consol_flag = case c.consol_detail_flag
		when 0  then 'No'
		when 1  then 'Yes'
	end,
  	c.currency_code,
	revaluate_flag = case c.revaluate_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,
	c.rate_type_home,
 	c.rate_type_oper ,

 	x_date_active=c.active_date,
 	x_date_inactive=c.inactive_date

FROM 
  	glchart c
	INNER JOIN glactype a
		ON c.account_type = a.type_code  
	INNER JOIN ib_glchart_vw o
		ON c.account_code = o.account_code
WHERE o.ib_flag <> 2
	
GO
GRANT REFERENCES ON  [dbo].[glchr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glchr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glchr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glchr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchr_vw] TO [public]
GO
