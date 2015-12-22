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





CREATE VIEW [dbo].[amas2_vw] AS
SELECT 
	co_asset_id,
	sequence_id,
	item_description,
	item_code,
	item_quantity,
	original_cost,
	date_item_disposition = item_disposition_date,
	date_last_modified = last_modified_date,
	user_name = ISNULL(s.user_name,"UNKNOWN"),
	manufacturer,
	model_num,
	serial_num,
	item_tag,
	vendor_code,
	vendor_description,
	invoice_num,
	po_ctrl_num,

	x_item_quantity=item_quantity,
	x_original_cost=original_cost,
	x_date_item_disposition = item_disposition_date,
	x_date_last_modified = last_modified_date

FROM
	amitem a LEFT OUTER JOIN CVO_Control..smusers s	ON a.modified_by = s.user_id







/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amas2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amas2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amas2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amas2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas2_vw] TO [public]
GO
