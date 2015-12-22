SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_get_q_project]
		@project1	varchar(75),
		@project2	varchar(75),
		@project3	varchar(75),
		@gl_acct_code	varchar(32),
		@reference_code	varchar(32),
		@sub_code	varchar(30),
		@tran_type	char(1),
		@type		char(1),
		@ifind		int 		AS


-- Tran Type:
--	'P'	=	PO
--	'R'	=	RTV
--	'I'	=	Inventory Adjustments
--	'M'	=	Matching


-- Type = '1'  Find Procedure Show All     
-- 	       '0'  Validate Passed Project      
-- 	       'F'  Find First Project           
-- 	       'P'  Find Previous Project        
-- 	       'N'  Find Next Project            
-- 	       'L'  Find Last Project            

-- ifind = 1  -Find/Validate Project 1
-- 	       2  -Find/Validate Project 2
-- 	       3  -Find/Validate Project 3

DECLARE @project varchar(75), @desc varchar(255), @info varchar(255)

SELECT @project = '',@desc ='', @info=''

SELECT @project, @desc, @info

return

GO
GRANT EXECUTE ON  [dbo].[adm_get_q_project] TO [public]
GO
