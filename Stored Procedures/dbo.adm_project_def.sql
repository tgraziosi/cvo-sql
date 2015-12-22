SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[adm_project_def]
		@project1	varchar(75),
		@project2	varchar(75),
		@project3	varchar(75),
		@gl_acct_code	varchar(32),
		@reference_code	varchar(32),
		@sub_code	varchar(30),
		@tran_type	char(1)	AS


-- Tran Type:
--	'P'	=	PO
--	'R'	=	RTV
--	'I'	=	Inventory Adjustments
--	'M'	=	Matching

DECLARE @project varchar(75)

SELECT @project=''

select @project, @project,@project

return

GO
GRANT EXECUTE ON  [dbo].[adm_project_def] TO [public]
GO
