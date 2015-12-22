SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ebo_logoff]

AS	
	

		IF EXISTS (SELECT name FROM sysobjects          
				WHERE name = 'smspiduser_vw' )     
		BEGIN
		
			DELETE smspiduser_vw WHERE spid = @@SPID


			DELETE smspiduser_vw 
			    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)	
			
		END
	  
	
	                                              
GO
GRANT EXECUTE ON  [dbo].[ebo_logoff] TO [public]
GO
