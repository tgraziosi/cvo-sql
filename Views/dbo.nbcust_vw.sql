SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
                CREATE VIEW [dbo].[nbcust_vw] AS Select c.customer_code, c.customer_name, v.vendor_code, v.vendor_name 
From arcust c, apvend v WHERE c.vendor_code = v.vendor_code AND c.status_type = 1 AND v.status_type = 5 


 /**/
GO
GRANT REFERENCES ON  [dbo].[nbcust_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[nbcust_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[nbcust_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[nbcust_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[nbcust_vw] TO [public]
GO
