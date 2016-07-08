CREATE TABLE [dbo].[arsalesp]
(
[timestamp] [timestamp] NOT NULL,
[salesperson_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_name] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[salesperson_type] [smallint] NOT NULL,
[employee_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_type] [smallint] NOT NULL,
[date_hired] [int] NOT NULL,
[date_terminated] [int] NOT NULL,
[phone_1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[time_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[social_security] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_mgr_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[commission_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[commission_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paid_thru_type] [smallint] NOT NULL,
[user_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[escalated_commissions] [smallint] NULL,
[commission] [decimal] (5, 2) NULL,
[date_of_hire] [datetime] NULL,
[draw_amount] [decimal] (14, 2) NULL,
[territory_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[arsalesp_u_trg] ON [dbo].[arsalesp] 
FOR UPDATE
AS

DECLARE @salesperson_code	varchar(8),
		@i_territory_code	varchar(8),
		@d_territory_code	varchar(8)

SET @salesperson_code = ''
WHILE 1=1
BEGIN
	-- Get the next record to action
	SELECT TOP 1 
		@salesperson_code = i.salesperson_code,
		@i_territory_code = i.territory_code,
		@d_territory_code = d.territory_code
	FROM 
		Inserted i
	INNER JOIN
		Deleted d
	ON
		i.salesperson_code = d.salesperson_code
	WHERE 
		i.salesperson_code > @salesperson_code
		AND i.territory_code <> d.territory_code
	ORDER BY 
		i.salesperson_code
	
	IF @@RowCount = 0
		BREAK

	-- Update customers for this salesperson for the old territory
	UPDATE
		--dbo.arcust
		dbo.armaster_all	-- v1.1
	SET
		territory_code = @i_territory_code
	WHERE
		salesperson_code = @salesperson_code
		AND (territory_code = @d_territory_code OR ISNULL(territory_code,'') = '')	-- v1.2
		AND address_type IN (0,1) -- v1.1
END


-- add commission change to audit log

INSERT CVOARMasterAudit 
	(field_name
	, field_from
	, field_to
	, customer_code
	, movement_flag
	, audit_date
	, user_id) 
SELECT distinct 'slp commission'
	, cast (d.commission as varchar(20))
	, cast (i.commission as varchar(20))
	, i.salesperson_code
	, 2 -- change
	, getdate()
	, SUSER_SNAME() 
	from inserted i 
	INNER JOIN deleted d ON 
	i.salesperson_code = d.salesperson_code
	where isnull(d.commission,0)<>isnull(i.commission,0)
GO
CREATE NONCLUSTERED INDEX [arsalesp_ind_3] ON [dbo].[arsalesp] ([addr_sort1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arsalesp_ind_4] ON [dbo].[arsalesp] ([addr_sort2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arsalesp_ind_5] ON [dbo].[arsalesp] ([addr_sort3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arsalesp] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arsalesp_ind_0] ON [dbo].[arsalesp] ([salesperson_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arsalesp_ind_1] ON [dbo].[arsalesp] ([salesperson_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arsalesp_ind_2] ON [dbo].[arsalesp] ([status_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arsalesp] TO [public]
GO
GRANT SELECT ON  [dbo].[arsalesp] TO [public]
GO
GRANT INSERT ON  [dbo].[arsalesp] TO [public]
GO
GRANT DELETE ON  [dbo].[arsalesp] TO [public]
GO
GRANT UPDATE ON  [dbo].[arsalesp] TO [public]
GO
