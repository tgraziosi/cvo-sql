SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glblntmg.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glblntmg_sp] AS

DECLARE @PASS varchar(18),
 @FAIL varchar(19)

SELECT @PASS = "SET BLNTMGSET=TRUE"
SELECT @FAIL = "SET BLNTMGSET=FALSE"

IF (SELECT glupdate_status_flag
	 FROM glco) = 1
 SELECT @PASS
ELSE
 SELECT @FAIL


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glblntmg_sp] TO [public]
GO
