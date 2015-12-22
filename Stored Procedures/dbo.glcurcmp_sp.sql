SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glcurcmp.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glcurcmp_sp] AS

DECLARE @PASS varchar(18),
 @FAIL varchar(19)

SELECT @PASS = "SET CURCMPSET=TRUE"
SELECT @FAIL = "SET CURCMPSET=FALSE"

IF EXISTS (SELECT 1
	 FROM glco
 WHERE ISNULL (company_code, "NULL") = "NULL"
 AND ISNULL (home_currency, "NULL") = "NULL")
 SELECT @FAIL
ELSE
 BEGIN
 IF EXISTS (SELECT 1
	 FROM glco
 WHERE company_code = ""
 OR home_currency = "")

 SELECT @FAIL
 ELSE
 IF EXISTS (SELECT 1
	 FROM glbal
 WHERE ISNULL (currency_code, "NULL") = "NULL")

 SELECT @FAIL
 ELSE
 SELECT @PASS
 END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glcurcmp_sp] TO [public]
GO
