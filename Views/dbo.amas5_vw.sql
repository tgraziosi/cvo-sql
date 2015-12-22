SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                





CREATE VIEW [dbo].[amas5_vw] AS
SELECT 
	co_asset_id,
	trx_type = case trx_type
		when  10  then 'Addition'
		when  20  then 'Improvement'
		when  30  then 'Disposal'
		when  40  then 'Revaluation'
		when  41  then 'Impairment'
		when  42  then 'Adjustment'
		when  50  then 'Depreciation'
		when  60  then 'Depreciation Adj.'
		when  70  then 'Partial Disp.'
		when  100 then 'Activate Added Assets'
		when  110 then 'Activate Imported Assets'
		when  120 then 'Retire Disposed Assets'
		end,
	posting_flag = case posting_flag
		when  0   then 'Ready'
		when  1   then 'Posted'
		when  2   then 'Validated'
		when  3   then 'Invalid'
		when  4   then 'Recovered'
		when  5   then 'On Hold'
		when  100 then 'Depreciated'
		end,
	date_apply=apply_date,
	date_last_modified=last_modified_date,
	date_posted,
	user_name = ISNULL(user_name,'UNKNOWN'),
	key_type = 10000 + trx_type,
	key_1 = convert(varchar(20),co_trx_id),


	x_date_apply=isnull(datediff( day, '01/01/1900', apply_date) + 693596,0),
	x_date_last_modified=isnull(datediff( day, '01/01/1900', last_modified_date) + 693596,0) ,
	x_date_posted=isnull(datediff( day, '01/01/1900', date_posted) + 693596 ,0)


FROM 
	amtrxhdr amtrxhdr LEFT OUTER JOIN CVO_Control..smusers smusers ON amtrxhdr.modified_by = smusers.user_id 
WHERE	amtrxhdr.posting_flag >= 0











	

  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amas5_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amas5_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amas5_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amas5_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas5_vw] TO [public]
GO
