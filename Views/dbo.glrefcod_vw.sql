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
                  CREATE VIEW [dbo].[glrefcod_vw]  AS SELECT r.reference_code  FROM glref r, glratyp t, glrefact a,  gltrxedt ed 
 WHERE r.reference_type = t.reference_type  AND a.reference_flag = 3  AND a.account_mask = t.account_mask 
 AND ed.account_code LIKE t.account_mask 

 /**/
GO
GRANT REFERENCES ON  [dbo].[glrefcod_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glrefcod_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glrefcod_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glrefcod_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glrefcod_vw] TO [public]
GO
