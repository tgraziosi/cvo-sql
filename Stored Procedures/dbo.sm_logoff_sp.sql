SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[sm_logoff_sp]

AS	

RETURN 0

--		IF (EXISTS (select 1 from CVO_Control..dminfo WHERE property_id = 53000) AND SUSER_SNAME() NOT IN ('pltsa', 'sa'))
--			RETURN 0
--
--
--		IF EXISTS (SELECT name FROM sysobjects          
--				WHERE name = 'smspiduser' )     
--		BEGIN
--
--			DELETE smspiduser WHERE spid = @@SPID
--
--			    DELETE smspiduser 
--			    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)
--
--		    
--		END
--
--		IF EXISTS (SELECT name FROM sysobjects          
--				WHERE name = 'smspiduser_vw' )     
--		BEGIN
--		
--			DELETE smspiduser_vw WHERE spid = @@SPID
--
--
--			DELETE smspiduser_vw 
--			    WHERE spid NOT IN (SELECT spid  FROM  master..sysprocesses p)	
--			
--		END
	  

GO
GRANT EXECUTE ON  [dbo].[sm_logoff_sp] TO [public]
GO
