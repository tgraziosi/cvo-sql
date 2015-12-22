SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\flcomp.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[flcomp_sp] @fl1 float, @fl2 float, @precision smallint = NULL
AS


IF @precision IS NULL
	SELECT @precision = 2


DECLARE @fl1sign float
DECLARE @fl2sign float

SELECT @fl1sign = SIGN( @fl1 )
SELECT @fl2sign = SIGN( @fl2 )

SELECT @fl1 = FLOOR( ABS( @fl1 ) * POWER( 10, @precision + 1 ) ) / 10
SELECT @fl2 = FLOOR( ABS( @fl2 ) * POWER( 10, @precision + 1 ) ) / 10
	
SELECT @fl1 = @fl1 + 0.5
SELECT @fl2 = @fl2 + 0.5

SELECT @fl1 = FLOOR( @fl1 )
SELECT @fl2 = FLOOR( @fl2 )

SELECT @fl1 = @fl1 * @fl1sign
SELECT @fl2 = @fl2 * @fl2sign


IF @fl1 - @fl2 = 0.0
	RETURN 0

ELSE IF @fl1 - @fl2 > 0.0
	RETURN 1
ELSE
	RETURN 2


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[flcomp_sp] TO [public]
GO
