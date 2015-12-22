SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glckref.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 
CREATE PROCEDURE [dbo].[glckref_sp]

	@ctype		varchar(1),
	@reference_type	varchar(8),
	@reference_code	varchar(32) = ''

AS

SET NOCOUNT ON


IF @ctype = '1'
BEGIN
	IF 
	(
	SELECT count(*) FROM glreftyp
		WHERE	reference_type = @reference_type
	) > 0 
		BEGIN
			SELECT 1
		END
	ELSE
		BEGIN
			SELECT 0
		END
END

IF @ctype = '2'
BEGIN
	IF 
	(
	SELECT count(*) FROM glreftyp a, glref b
		WHERE	a.reference_type = b.reference_type and
			a.reference_type = @reference_type
	) > 0 
		BEGIN
			SELECT 1
		END
	ELSE
		BEGIN
			SELECT 0
		END
END

IF @ctype = '3'
BEGIN
	IF 
	(
	SELECT count(*) FROM glref
		WHERE	reference_type = @reference_type and
			reference_code = @reference_code
	) > 0 
		BEGIN
			SELECT 1
		END
	ELSE
		BEGIN
			SELECT 0
		END
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glckref_sp] TO [public]
GO
