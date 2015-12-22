SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\getversion.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[getversion_sp] 
				@version smallint OUTPUT

AS
DECLARE 		@strver char(255),
				@pos	 smallint



select @strver = @@version


select @pos = patindex( "%.%", @strver )

select @strver = substring(@strver, @pos-2, 2 )


if ( ascii( @strver ) = 47 )
	select @strver = stuff( @strver, 1, 1, " " )


select @version = convert( int, @strver )



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[getversion_sp] TO [public]
GO
