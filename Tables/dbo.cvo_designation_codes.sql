CREATE TABLE [dbo].[cvo_designation_codes]
(
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_reqd] [smallint] NULL CONSTRAINT [DF__cvo_desig__date___779AA433] DEFAULT ((0)),
[void] [smallint] NULL CONSTRAINT [DF__cvo_design__void__788EC86C] DEFAULT ((0)),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[rebate] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_designation_codes_Upd_Trg		
Type:		Trigger
Description:	Update the description in cvo_cust_designation_codes
Version:	1.0
Developer:	Chris Tyler

History
-------
v1.0	CT	30/03/2011	Original Version
*/

CREATE TRIGGER [dbo].[cvo_designation_codes_upd_trg] ON [dbo].[cvo_designation_codes]
FOR UPDATE
AS
BEGIN
	DECLARE	@code			varchar(10),
			@description	varchar(500)

	SET @code = ''
	
	-- Get the next record to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@code = i.code,
			@description = i.description
		FROM 
			inserted i
		INNER JOIN
			deleted d 
		ON
			i.code = d.code
		WHERE
			i.code > @code
			AND i.[description] <> d.[description]
		ORDER BY 
			i.code

		IF @@RowCount = 0
			Break

		UPDATE
			cvo_cust_designation_codes
		SET
			[description] = @description
		WHERE
			code = @code
	END		
END
GO
GRANT REFERENCES ON  [dbo].[cvo_designation_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_designation_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_designation_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_designation_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_designation_codes] TO [public]
GO
