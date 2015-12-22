SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/



CREATE VIEW [dbo].[gdsprod_vw]
AS
SELECT     lot_bin_prod1.part_no AS P_Item, lot_bin_prod1.lot_ser AS P_Serial_Lot, lot_bin_prod1.date_tran AS Prod_Date, lot_bin_prod1.qty AS P_Qty, 
                      dbo.prod_list.part_no AS C_Item, dbo.lot_bin_prod.lot_ser AS C_Serial_Lot, dbo.lot_bin_prod.qty AS C_Qty, dbo.prod_list.plan_qty AS T_Planned_Qty, 
                      dbo.prod_list.used_qty AS C_Used_Qty, dbo.prod_list.uom, dbo.prod_list.description, lot_bin_prod1.tran_no AS Prod_No, 
                      lot_bin_prod1.tran_ext AS Ext
FROM         dbo.lot_bin_prod RIGHT OUTER JOIN
                      dbo.prod_list ON dbo.lot_bin_prod.part_no = dbo.prod_list.part_no AND dbo.lot_bin_prod.tran_no = dbo.prod_list.prod_no AND 
                      dbo.lot_bin_prod.tran_ext = dbo.prod_list.prod_ext FULL OUTER JOIN
                      dbo.lot_bin_prod lot_bin_prod1 ON dbo.prod_list.prod_no = lot_bin_prod1.tran_no AND dbo.prod_list.prod_ext = lot_bin_prod1.tran_ext
WHERE     (lot_bin_prod1.direction = 1) AND (dbo.prod_list.direction = - 1)  


/**/
GO
GRANT REFERENCES ON  [dbo].[gdsprod_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gdsprod_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdsprod_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdsprod_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdsprod_vw] TO [public]
GO
