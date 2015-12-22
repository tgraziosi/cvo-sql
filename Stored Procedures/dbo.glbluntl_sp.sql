SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glbluntl.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glbluntl_sp] AS

DECLARE @PASS varchar(18),
 @FAIL varchar(19)

SELECT @PASS = "SET BLUNTLSET=TRUE"
SELECT @FAIL = "SET BLUNTLSET=FALSE"

IF EXISTS (SELECT balance_until
	 FROM glbal
 WHERE ISNULL (balance_until, 0) = 0)
 SELECT @FAIL
ELSE
 BEGIN
 IF EXISTS (SELECT balance_until
	 FROM glbal
 WHERE balance_until = CONVERT(int,""))

 SELECT @FAIL
 ELSE
 SELECT @PASS
 END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glbluntl_sp] TO [public]
GO
