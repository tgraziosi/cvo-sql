SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[recadjlog_vw]
as 
SELECT r.receipt_ctrl_num,  s.user_name, r.date_change, 
convert(varchar(20), DATEADD(hh,(r.time_change/3600),
		DATEADD(mi,((r.time_change%3600)/60),
		DATEADD(ss,((r.time_change%3600)%60),cast('2000-01-01' as datetime)))), 108) time_change_dt,
r.new_item_code, 
r.new_item_desc, r.old_item_code, r.old_item_desc, r.comment, r.sequence_id,  r.time_change, r.date_change x_date_change
FROM recadjlog r LEFT OUTER JOIN smusers_vw s ON (r.user_id = s.user_id)
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[recadjlog_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[recadjlog_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[recadjlog_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[recadjlog_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[recadjlog_vw] TO [public]
GO
