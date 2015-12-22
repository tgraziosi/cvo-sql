SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
    CREATE VIEW [dbo].[appost_vw] AS select distinct a.vendor_code,  b.vendor_name,  a.trx_type, 
 a.hold_flag, a.org_id from apinpchg a, apvend b where a.vendor_code = b.vendor_code 
GO
GRANT REFERENCES ON  [dbo].[appost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appost_vw] TO [public]
GO
