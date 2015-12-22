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
                  CREATE VIEW [dbo].[aprptchk_ex_vw] AS  SELECT DISTINCT print_batch_num FROM aprptchk_ex 
GO
GRANT REFERENCES ON  [dbo].[aprptchk_ex_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aprptchk_ex_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aprptchk_ex_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aprptchk_ex_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aprptchk_ex_vw] TO [public]
GO
